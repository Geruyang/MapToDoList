# 候选构建内存只读评估

2026-10-11：未运行 xcodebuild / xcodegen / 安装 / 测试，未更改构建脚本参数或准入阈值。

## 实际增量与设置证据

以现有 `build/DeviceData/Build/Intermediates.noindex/.../Objects-normal/arm64/*-OutputFileMap.json` 中的源码与对应 object 时间戳比较：产品仅 AISettingsView.swift、TodayView.swift、TaskEditorView.swift、SubscriptionView.swift 四文件新于 object；UI WaypointUITests.swift 新于 object；SandboxSubscriptionDiagnosticsTests.swift 为旧 unit 输出映射未包含的新文件。此为文件系统增量证据，不能保证依赖分析只重编这六个文件。

`DEVICE_EVIDENCE/Audit-fixes-combined.log:87` 的真实 SwiftDriver 命令包含 `-Onone -enable-testing -j8 -enable-batch-mode -incremental -index-store-path .../Index.noindex/DataStore`。外层 `xcodebuild -jobs 1` 没有把 SwiftDriver 内层上限改成 1。

当前 Debug 为 -Onone / 默认 singlefile+batch/incremental；Release wholemodule/-O 不适用于这轮 Debug build-for-testing。project.yml 没有显式 OTHER_SWIFT_FLAGS、batch 或 indexing 覆盖。

本机 Xcode26.6 原始 Swift.xcspec（SwiftBuild.framework/SWBBuildService.bundle/PlugIns/XCBSpecifications.ideplugin/Contents/Resources）370行 batch 默认 YES，1347行 index-store Condition受 COMPILER_INDEX_STORE_ENABLE 控制；497行 OTHER_SWIFT_FLAGS 是附加编译器 flags。同一内置 swiftc -help 确认 `-j <n>` 为并行命令数。

## 建议（尚未执行）

优先保留当前 DerivedData、Debug、增量、签名、testing 和优化设置，仅在命令行增加 `OTHER_SWIFT_FLAGS='$(inherited) -j1'`，同时保留外层 `-jobs 1`、不并行测试和现有 guard。这限制 Swift frontend 并发，不改变语言模式或产品逻辑。首次实际允许构建后必须核对 SwiftDriver 最终命令是否采用有效 `-j1`，不能凭设置存在宣称成功。

可另加 `COMPILER_INDEX_STORE_ENABLE=NO` 停止构建时 IDE 索引输出，不影响 App 功能与 XCTest。索引 flag 变化可能扩大当前增量重编范围；目前没有本项目实测内存收益，不能承诺只编四个产品文件或固定减少若干百分点。

暂不建议先关 batch：Swift 官方说明 batch 分摊重复 parse/typecheck；单文件模式即使 j1 有较低单 job 潜力，也可能更慢，且改变编译 invocation。需要它时再用 `SWIFT_ENABLE_BATCH_MODE=NO`，而不是使用 wholemodule、降低 safety checks 或测试覆盖来节约资源。

不 clean、不删 module cache、不改 SDK / architecture / Debug optimization / sanitizers / source，不使用未证实的全局 env 或系统设置。guard 仍 start<70 / stop75，用户硬80上限不变。

官方依据：Apple [Build settings reference](https://developer.apple.com/documentation/xcode/build-settings-reference) 定义 COMPILER_INDEX_STORE_ENABLE 为是否构建时生成索引；Swift [CompilerPerformance](https://github.com/swiftlang/swift/blob/main/docs/CompilerPerformance.md) 解释并行 frontend 与 batch；Swift [Options.swift](https://github.com/swiftlang/swift-driver/blob/main/Sources/SwiftOptions/Options.swift) 的 `-j` 带 doesNotAffectIncrementalBuild 属性，索引路径不同属性，不能把编译缓存与增量重编等同。

## 历史 guard 总运行峰值

| 证据 | 起点 | 峰值 | 差值百分点 |
| --- | ---: | ---: | ---: |
| device-guarded（较早签名 build） | 51.8 | 60.8 | 9.0 |
| Release-archive-first | 64.0 | 68.9 | 4.9 |
| Unit-and-weather-second | 60.0 | 63.3 | 3.3 |
| Final-logic-and-ui | 69.7 | 72.9 | 3.2 |
| UI-review-regression | 69.5 | 73.5 | 4.0 |
| Audit-fixes-combined | 71.9 | 74.6 | 2.7 |

数据来自原始 log 中 Memory used estimate / Peak sampled memory。含测试运行的峰值不能拆成单独编译峰值；其他用户进程也会改变整体系统内存。这些观察不是未来构建上限保证。
