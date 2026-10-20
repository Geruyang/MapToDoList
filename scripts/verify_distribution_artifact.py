#!/usr/bin/env python3
"""Offline strict archive/IPA check. Does not build, export, upload or mutate inputs."""
import argparse
import hashlib
import json
import plistlib
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

TEAM = 'VA8X63NPCS'
BUNDLE = 'com.waypoint.maptodo'
MARKERS = (b'--demo-access', b'--seed-demo', b'--uitesting', b'--native-map-attribution-probe', b'--map-selection-diagnostics',
           b'R44_TEST_ONLY_MAP_SELECTION_TRACE', b'WAYPOINT_MAP_DIAGNOSTIC', b'WAYPOINT_DEMO_ACCESS',
           b'WAYPOINT_RUN_NOTIFICATION_DEVICE_TESTS',
           b'WAYPOINT_NOTIFICATION_DEVICE_TEST_OWNS_SYNC')

def command(args):
    result = subprocess.run(args, capture_output=True)
    if result.returncode:
        raise ValueError('Command failed: ' + args[0] + ' (exit ' + str(result.returncode) + ')')
    return result.stdout, result.stderr

def plist(data):
    start = data.find(b'<?xml')
    if start >= 0:
        data = data[start:]
    return plistlib.loads(data)

def inspect(app, expected_build):
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    command(['codesign', '--verify', '--deep', '--strict', str(app)])
    _, signature = command(['codesign', '-dv', '--verbose=4', str(app)])
    signature = signature.decode('utf-8', 'replace')
    out, err = command(['codesign', '-d', '--entitlements', ':-', str(app)])
    entitlements = plist(out if out.strip() else err)
    profile_data, _ = command(['security', 'cms', '-D', '-i', str(app / 'embedded.mobileprovision')])
    profile = plistlib.loads(profile_data)
    profile_entitlements = profile.get('Entitlements', {})
    privacy = app / 'PrivacyInfo.xcprivacy'
    privacy_valid = privacy.is_file() and isinstance(plistlib.loads(privacy.read_bytes()), dict)
    test_bundles = sorted(str(p.relative_to(app)) for p in app.rglob('*.xctest'))
    debug_files = sorted(str(p.relative_to(app)) for p in app.rglob('*')
                         if p.is_file() and (p.name.endswith('.debug.dylib') or p.name == '__preview.dylib'))
    executable = app / info.get('CFBundleExecutable', '')
    markers = []
    for path in [executable, *app.rglob('*.dylib')]:
        if path.is_file():
            content = path.read_bytes()
            markers += [marker.decode() for marker in MARKERS if marker in content]
    checks = {
        'strictCodesign': True,
        'appleDistribution': 'Authority=Apple Distribution:' in signature,
        'signatureTeam': ('TeamIdentifier=' + TEAM) in signature,
        'profileTeam': profile.get('TeamIdentifier') == [TEAM],
        'bundle': info.get('CFBundleIdentifier') == BUNDLE,
        'version': info.get('CFBundleShortVersionString') == '1.0.0',
        'build': str(info.get('CFBundleVersion')) == str(expected_build),
        'family': info.get('UIDeviceFamily') == [1],
        'getTaskAllowFalse': entitlements.get('get-task-allow') is False,
        'profileGetTaskAllowFalse': profile_entitlements.get('get-task-allow') is False,
        'noProvisionedDevices': 'ProvisionedDevices' not in profile,
        'notEnterpriseProfile': not profile.get('ProvisionsAllDevices', False),
        'applicationIdentifier': entitlements.get('application-identifier') == TEAM + '.' + BUNDLE,
        'weatherkit': entitlements.get('com.apple.developer.weatherkit') is True,
        'timeSensitive': entitlements.get('com.apple.developer.usernotifications.time-sensitive') is True,
        'profileWeatherkit': profile_entitlements.get('com.apple.developer.weatherkit') is True,
        'profileTimeSensitive': profile_entitlements.get('com.apple.developer.usernotifications.time-sensitive') is True,
        'privacyManifestValid': privacy_valid,
        'noTestBundles': not test_bundles,
        'noDebugArtifacts': not debug_files,
        'noDebugMarkers': not markers,
    }
    return {'checks': checks, 'passed': all(checks.values()), 'bundle': info.get('CFBundleIdentifier'),
            'version': info.get('CFBundleShortVersionString'), 'build': str(info.get('CFBundleVersion')),
            'family': info.get('UIDeviceFamily'), 'team': TEAM,
            'testBundles': test_bundles, 'debugArtifacts': debug_files,
            'debugMarkersFound': sorted(set(markers))}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('artifact', help='Absolute .xcarchive or .ipa path')
    parser.add_argument('--build', default='3')
    parser.add_argument('--output', required=True, help='Absolute JSON output path')
    args = parser.parse_args()
    artifact, output = Path(args.artifact), Path(args.output)
    report = {'artifact': str(artifact), 'expectedBuild': args.build, 'passed': False}
    try:
        if not artifact.is_absolute() or not output.is_absolute():
            raise ValueError('Artifact and output paths must be absolute')
        if artifact.suffix == '.xcarchive' and artifact.is_dir():
            apps = list((artifact / 'Products' / 'Applications').glob('*.app'))
            if len(apps) != 1:
                raise ValueError('Archive must contain one application')
            report.update(inspect(apps[0], args.build))
        elif artifact.suffix == '.ipa' and artifact.is_file():
            report['IPASHA256'] = hashlib.sha256(artifact.read_bytes()).hexdigest()
            with tempfile.TemporaryDirectory(prefix='waypoint-verify-') as directory:
                root = Path(directory)
                with zipfile.ZipFile(artifact) as archive:
                    for member in archive.infolist():
                        destination = (root / member.filename).resolve()
                        if not destination.is_relative_to(root.resolve()):
                            raise ValueError('Unsafe ZIP member path')
                        if (member.external_attr >> 16) & 0o170000 == 0o120000:
                            raise ValueError('ZIP symlinks not accepted')
                    archive.extractall(root)
                    for member in archive.infolist():
                        mode = (member.external_attr >> 16) & 0o777
                        if mode:
                            (root / member.filename).chmod(mode)
                apps = list((root / 'Payload').glob('*.app'))
                if len(apps) != 1:
                    raise ValueError('IPA must contain one application')
                report.update(inspect(apps[0], args.build))
        else:
            raise ValueError('Expected existing .xcarchive directory or .ipa file')
    except Exception as error:
        # Never emit profile/certificate/command output; it can contain account data.
        report['error'] = type(error).__name__
        report['errorSummary'] = str(error) if isinstance(error, ValueError) else 'Artifact check failed; inspect locally'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'passed': report['passed'], 'output': str(output)}))
    return 0 if report['passed'] else 1

if __name__ == '__main__':
    sys.exit(main())
