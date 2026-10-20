#!/usr/bin/env python3
"""Run only this task's child process, interrupting it before 80% physical-memory use.
macOS conservative used estimate: wired + anonymous + resident compressor.
External processes can change usage between samples; this is a guard, not an OS quota.
"""
import argparse
import os
import re
import signal
import subprocess
import sys
import time


def used_percent():
    total = int(subprocess.check_output(['sysctl', '-n', 'hw.memsize'], text=True))
    output = subprocess.check_output(['vm_stat'], text=True)
    size = int(re.search(r'page size of (\d+) bytes', output).group(1))
    values = {key: int(value) for key, value in re.findall(r'^([^:\n]+):\s+(\d+)\.', output, re.M)}
    pages = sum(values[k] for k in ('Pages wired down', 'Anonymous pages', 'Pages occupied by compressor'))
    return pages * size / total * 100


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--sample', action='store_true')
    parser.add_argument('--start-below', type=float, default=68)
    parser.add_argument('--stop-at', type=float, default=78)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    used = used_percent()
    print(f'Memory used estimate: {used:.1f}%', flush=True)
    if args.sample:
        return 0
    if not 0 < args.start_below <= args.stop_at <= 78:
        parser.error('Thresholds must satisfy 0 < start-below <= stop-at <= 78')
    if used >= args.start_below:
        print('Not started: insufficient memory headroom.', flush=True)
        return 75
    command = args.command
    if command and command[0] == '--':
        command = command[1:]
    if not command:
        parser.error('Command required')
    peak = used
    process = subprocess.Popen(command, start_new_session=True)
    try:
        while process.poll() is None:
            time.sleep(0.5)
            used = used_percent()
            peak = max(peak, used)
            if used >= args.stop_at:
                print(f'Memory guard interrupted child at {used:.1f}%.', flush=True)
                os.killpg(process.pid, signal.SIGINT)
                try:
                    process.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
                return 75
        print(f"Peak sampled memory: {peak:.1f}%", flush=True)
        return process.returncode
    except KeyboardInterrupt:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGINT)
        return 130

if __name__ == '__main__':
    sys.exit(main())
