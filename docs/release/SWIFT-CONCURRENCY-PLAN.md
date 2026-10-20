# Swift concurrency constraint for a future archive

Read-only tool/spec research, 2026-10-11. No archive/build/simulator, clone, credential access, or existing-candidate change. One local driver planning command printed jobs without executing the compiler.

## Recommended future command settings

Keep memory_guard and Xcode `-jobs 1`. For the Release whole-module archive, append:

```sh
SWIFT_COMPILATION_MODE=wholemodule SWIFT_USE_PARALLEL_WHOLE_MODULE_OPTIMIZATION=NO SWIFT_USE_PARALLEL_WMO_TARGETS=NO
```

The first two are the minimum verified mechanism for Swift WMO backend threads: wholemodule + parallel-WMO NO causes the build system to generate `-num-threads 1` itself, rather than attempting to override a later generated flag using OTHER_SWIFT_FLAGS. The third prevents parallel WMO targets and complements `-jobs 1`; it is available in the installed Xcode spec. `SWIFT_ENABLE_BATCH_MODE=NO` is not a WMO control and is unnecessary here.

For a pipeline that may also compile non-WMO Swift modules, add the driver environment safeguard around the existing memory-guard command:

```sh
SWIFTC_MAXIMUM_DETERMINISM=1 python3 scripts/memory_guard.py --start-below 68 --stop-at 75 -- xcodebuild archive ... -jobs 1 SWIFT_COMPILATION_MODE=wholemodule SWIFT_USE_PARALLEL_WHOLE_MODULE_OPTIMIZATION=NO SWIFT_USE_PARALLEL_WMO_TARGETS=NO
```

This is a prepared command prefix, not a request to rebuild the already successful candidate. The environment override constrains the Swift driver `-j` job count; it does not replace `-num-threads 1`. Retain both controls if both frontend-job and WMO-backend concurrency must be limited. Do not claim these settings cap total App process memory or all linker/LLVM/Clang activity; retain the memory guard.

## Evidence

Installed spec:
`/Users/geruyang/Desktop/Xcode.app/Contents/SharedFrameworks/XCBuild.framework/Versions/A/PlugIns/XCBBuildService.bundle/Contents/PlugIns/XCBSpecifications.ideplugin/Contents/Resources/Swift.xcspec`

- Lines 150–155: hidden `SWIFT_USE_PARALLEL_WHOLE_MODULE_OPTIMIZATION`, Boolean, defaults YES.
- Lines 157–163: hidden `SWIFT_USE_PARALLEL_WMO_TARGETS`, Boolean, defaults YES.
- Lines 353–364: `SWIFT_COMPILATION_MODE=wholemodule` emits `-whole-module-optimization`.
- Lines 368–374: batch-mode setting is ignored under WMO.

Official [swift-build SwiftCompiler source, pinned revision](https://github.com/swiftlang/swift-build/blob/2187330e13e7f7cfba1401a2c7e70c827a56a061/Sources/SWBCore/SpecImplementations/Tools/SwiftCompiler.swift#L1435): lines 1435–1444 explicitly append CPU-count `-num-threads` when WMO parallelism is enabled, append `-num-threads 1` when disabled, and append CPU-count `-j` for non-WMO. Line 730 defines that count as activeProcessorCount. Lines 2740–2744 recognize the wholemodule build setting.

Official [Swift driver](https://github.com/swiftlang/swift-driver/blob/main/Sources/SwiftDriver/Driver/Driver.swift#L2694) determines `-j` separately; its non-empty `SWIFTC_MAXIMUM_DETERMINISM` environment check returns 1 and emits an override remark. This is corroborated by the installed binary, not assumed solely from upstream source.

Local command actually run (job planning only):

```sh
SWIFTC_MAXIMUM_DETERMINISM=1 xcrun swiftc -driver-print-jobs -typecheck -j8 - </dev/null
```

Actual first output:

```text
remark: SWIFTC_MAXIMUM_DETERMINISM overriding -j
```

The remainder is a printed swift-frontend command; `-driver-print-jobs` did not execute it. Local `xcrun swiftc -help-hidden` describes `-j` as parallel commands and `-num-threads` as multithreading threads. Official [Swift Driver WMO documentation](https://github.com/swiftlang/swift/blob/main/docs/Driver.md#whole-module-optimization) also distinguishes the two controls.

## Next verification boundary

At the next necessary archive, confirm the actual Swift command has `-whole-module-optimization -num-threads 1`; non-WMO jobs should emit the determinism override remark despite a generated `-j8`. An installed Xcode build is not assumed byte-identical to upstream swift-build. No next archive was executed by this investigation, and no extra rebuild is warranted solely to test this finding.
