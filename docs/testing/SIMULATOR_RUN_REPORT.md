# 行迹 Waypoint 模拟器运行报告

## 当前实际结果：R30 本地 StoreKit 4/4 PASS

后续用户撤销了80%内存限制；主会话授予唯一重任务资源，执行 R30 冻结候选的独立 simulator build-for-testing（exit0），随后在既有 iOS26.2 `9B92CCDE-87A5-49CE-B0BE-9DD271313987` 完成本地恢复1项与其余试用/refund/过期3项，**4/4 PASS，0 FAIL，0 SKIP**。两次 test-without-building 均 exit0，没有Code3/notEntitled。只采样内存、无停止阈值，峰值分别80.1%与81.1%；未使用旧DD。

完整证据与候选hash见 [R30本地StoreKit实际结果](SIMULATOR_R30_STOREKIT_RESULTS.md)。该设备已Shutdown，owned/runtime残留0，重任务槽已明确交回。没有运行真实Sandbox交易或当前UI；R31源码在R30构建后有意解锁，本轮仅绑定R30产物，不代表R31已验证。

以下第一至四轮以及旧内存准入记录均为历史，不再作为当前限制。首版现为iPhone-only，旧iPad路线不在当前发行范围。

## 环境

- 日期：2026-10-11；设备：iOS 26.5 iPhone 17 Pro。
- UDID：`D11C7BCC-E156-4D69-9BB2-A7D3C6358353`。
- 工程/scheme：`MapToDo.xcodeproj` / `MapToDo`；Debug；Swift 5；专用 DerivedData `/tmp/Waypoint-SimulatorUITest-DD`。
- UI 测试采用独立任务文件 `--uitesting`；创建场景仅在 DEBUG 测试以 `--demo-access` 绕过订阅并要求显式演示标记。重启持久化不再传 `--reset-data`、`--seed-demo`。
- 真实 API 密钥与真实购买未使用。StoreKit 生命周期由独立订阅模块的本地 `SKTestSession` 测试负责；本报告只记录 UI 和实际运行到的服务状态。

## 历史只读准入与旧候选状态（已被后续R30执行取代）

- 第一至四轮是历史记录，模拟器没有完成 UI 用例可计为通过。真机证据由 `DEVICE_*` 报告独立记录，不移作本报告的模拟器 PASS。
- 本轮准备开始时主会话报告内存基线 **68.5%**，且真机测试拥有唯一重任务资源；模拟器历史启动约增加 18 个百分点，当前没有准入余量。本轮未启动、未继续轮询。
- 后续统一单设备、`-jobs 1`、不并行，模拟器仅在基线 **低于 55%** 且主会话放行后准入，守护 **75%** 停止、0.5 秒采样。用户硬上限 80%；采样停止机制不等于连续峰值保证。旧的停止阈值提议已撤销。
- 该次准备时产品为 **GLM / Qwen / DeepSeek / OpenAI 四家可用，Gemini 不开放**，共22个UI测试源码；此前五家、18项只属于历史版本。
- `/tmp/Waypoint-SimulatorUITest-DD` 是 **01:26 历史候选，已过期**。只读核对时 MapScreen 为 02:12、TaskEditor 为 05:41、UITests 为 06:36，均比产物新；不能用旧 `test-without-building` 验证当前源码。主会话统一修改测试并准备单次新构建，本轮不创建测试源或运行命令。

## 第一轮：构建失败，UI 未运行

实际命令（日志使用 shell 重定向保存）：

```sh
xcodebuild test -project MapToDo.xcodeproj -scheme MapToDo -configuration Debug -destination 'platform=iOS Simulator,id=D11C7BCC-E156-4D69-9BB2-A7D3C6358353' -derivedDataPath /tmp/Waypoint-SimulatorUITest-DD -only-testing:MapToDoUITests -parallel-testing-enabled NO -resultBundlePath docs/testing/SIMULATOR-results/ui-round-01.xcresult CODE_SIGNING_ALLOWED=NO
```

结果：exit 65，编译失败。`MapScreen.swift:46:70`，`type 'PointOfInterestCategories' has no member 'includingAll'`。已向主会话与地图实现者报告；地图实现者随后移除无效参数，保留默认 POI。测试者未修改产品。

证据：`SIMULATOR-results/ui-round-01.log`，`SIMULATOR-results/ui-round-01.xcresult`。不计任何 UI 用例通过。

## 第二轮：资源限制中断，未完成 UI 用例

相同命令，结果路径改为 `SIMULATOR-results/ui-round-02.xcresult`；日志 `SIMULATOR-results/ui-round-02.log`。产品及 UI 测试编译通过；设备首次启动后 runner 进入首个 `testBlankTitleCannotBeSaved`，到 `Wait for com.waypoint.maptodo to idle`，尚无完成用例。

用户新增内存不得超过 80% 的硬限制。主会话协调停止所有新构建/测试后，测试者对自己 PID `6309` 发出 `SIGINT`；30 秒后进程仍未结束，按主会话明确授权 `SIGTERM`，exit 143，确认进程已消失；按后续指令关闭专用模拟器释放资源。此轮标记 **INTERRUPTED (resource limit)**，不记为产品失败，不计任何 UI 用例通过。恢复运行须由主会话准入；当前后续安排已统一为单模拟器、`-jobs 1`、75% 停止。

随后已准备中文固定启动语言 `-AppleLanguages (zh-Hans) -AppleLocale zh_CN`，并增加英文 smoke（Map/Today/Plan/Settings、Export 和 Paywall），资源就绪后受影响场景仍须重跑。代码已准备不代表英文 UI 已运行。

## 用例源与范围

`MapToDoUITests/WaypointUITests.swift` 当前源码范围包含：首启无通知请求、CRUD与重启、取消编辑、空白标题、地图输入、实际地图选点、联网MapKit结果选择、完成状态重启、三格式导出预览/复制、无权益只读与导出、提醒设置与显式拒绝通知、订阅恢复入口、本地规划预览、中英主要页面及最大字体截图、长标题编辑/只读、Today 自动可访问性审计、四家 AI 安全输入/保存/取消删除/确认删除/选择持久化及 Gemini 不开放断言。源码存在不代表已在模拟器执行。

若联网 MapKit 明确返回服务不可用，联网结果测试使用 `XCTSkip` 并保存错误截图，不能计为搜索服务验证通过。通知已在先前安装中决定权限时，首次拒绝场景同样需要独立记录 skip 并重置环境后复跑。

## 第三、四轮：单模拟器仍被内存守护中断

主会话重新授予唯一重任务资源。运行前 `xcodegen generate` 重新纳入最新 AppLinks、PlanningTimeout 等文件；本轮只使用 iOS 26.5 iPhone 17 `23D83E41-E786-4BBB-9A3A-261E6598DB6B`，未启动 D11。准备先验证英文 smoke、截图画廊与 CRUD 三项。

第三轮实际命令：

```sh
python3 scripts/memory_guard.py --start-below 68 --stop-at 75 -- xcodebuild test -project MapToDo.xcodeproj -scheme MapToDo -configuration Debug -jobs 1 -destination 'platform=iOS Simulator,id=23D83E41-E786-4BBB-9A3A-261E6598DB6B' -derivedDataPath /tmp/Waypoint-SimulatorUITest-DD -only-testing:MapToDoUITests/WaypointUITests/testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall -only-testing:MapToDoUITests/WaypointUITests/testScreenshotGalleryOfPrimaryScreens -only-testing:MapToDoUITests/WaypointUITests/testCreateEditPersistAndDeleteTask -parallel-testing-enabled NO -resultBundlePath docs/testing/SIMULATOR-results/ui-round-03-smoke.xcresult CODE_SIGNING_ALLOWED=NO
```

结果：编译阶段未出现错误；内存从 65.7% 到 75.3%，守护停止，exit 75，`TEST INTERRUPTED`，**0 个完成用例**。结果包与 `ui-round-03-smoke.log` 保留。设备为 Shutdown；检查 Runtime 残留进程 **0**，详见 `ui-round-03-residual-processes.txt`；收尾内存 57.8%。

第四轮为减去编译驻留，使用上方同一命令的 `test-without-building`（其余参数相同，结果改为 `ui-round-04-smoke.xcresult`）。内存从 57.6% 到 75.4%，约 21 秒测试准备阶段守护停止，exit 75，`TEST EXECUTE INTERRUPTED`，**0 个完成用例**。`ui-round-04-smoke.log`、结果包均保留；23D 为 Shutdown，Runtime 残留进程 **0**，详见 `ui-round-04-residual-processes.txt`；收尾内存 59.1%。

两轮均为 **INTERRUPTED (resource limit)**，不是产品失败。没有英文 UI、CRUD 或截图画廊通过结论，也没有可导出的实际 App 截图。最新逻辑 XCTest 尚未运行；计划跳过已知 StoreKit runtime 问题的 `StoreKitLifecycleTests`，硬件相关 DeviceIntegration 只能按真实执行后的 skip 记录。

已向主会话报告单模拟器测试启动阶段增加约 18 个百分点仍触停止阈值；在进一步资源协调前不再重复启动。

## 旧候选产物（历史过期，不可用于当前验收）

第三轮当时生成并编译的 Debug iOS Simulator 产物仍可保留作历史诊断，路径为：

- App：`/tmp/Waypoint-SimulatorUITest-DD/Build/Products/Debug-iphonesimulator/MapToDo.app`。
- UI runner：`/tmp/Waypoint-SimulatorUITest-DD/Build/Products/Debug-iphonesimulator/MapToDoUITests-Runner.app`，测试 bundle 为其 `PlugIns/MapToDoUITests.xctest`。
- 逻辑测试（嵌入 hosted App）：`/tmp/Waypoint-SimulatorUITest-DD/Build/Products/Debug-iphonesimulator/MapToDo.app/PlugIns/MapToDoTests.xctest`，包含本地 `MapToDo.storekit` 资源。

当时曾准备复用 scheme + 同一 DerivedData 的 `test-without-building`；没有独立 `.xctestrun` 文件。该准备方案没有执行，且已因后续源码修改而失效。旧产物不能用于当前候选，必须先由主会话统一构建并记录新产物身份，再讨论仅测试命令。

旧的完整 UI／逻辑准备命令已移除，防止误用过期 binary。后续命令由主会话围绕新候选统一准备，UI、逻辑与设备测试须串行；每轮新 result 路径。完成或中断后检查设备 Shutdown 和 Runtime 路径/PID 残留；不无差别终止进程。

## 历史平台与本地 StoreKit 准备路线

只读 inventory 确认 iOS runtime 仅 **26.2（23C54）／26.5（23F77）**。iOS 17 未安装；deployment target 17 与较新系统运行不能代替最低支持系统验收。

| 批次 | 最小范围 | 状态与边界 |
| --- | --- | --- |
| 新候选准备 | 主会话一次 `build-for-testing`，与模拟器测试分离 | NOT RUN；旧 DD 过期，不能跳过新候选构建 |
| iPad＋最低已安装 runtime | 复用 iPad Air 11 M3、iOS 26.2，`B311F7D1-F39F-411F-BED5-5D794E0A92C1`；英文六屏横竖屏、最大字号、长标题与键盘可达性 | BLOCKED_MEMORY；一台可以合并 iPad 形态与最低已安装系统覆盖。横屏专项由主会话统一准备；本轮不创建源码 |
| 最低支持 iOS 17 | 实际启动、CRUD、导出与权益门禁 | BLOCKED_RUNTIME；未安装 iOS 17，不声称兼容性已验证 |
| 本地 StoreKit | 先单项配置／商品预检 gate；可用才串行现有 6 个 local `.xcode` 生命周期场景 | BLOCKED_RUNTIME；已有 Code 3 不变时不重复整组。取消续订与取消 purchase 仍需独立补测，不能用现有 6 项替代 |

上表属于先前未执行的准备状态：首版后来收敛为iPhone-only，iPad不再列发行验收；本地StoreKit后来在R30/iOS26.2完成4项PASS，见本报告开头。没有测量证据证明某runtime更轻。历史只读inventory中设备均Shutdown；未关闭用户应用、系统进程或Renderer。

真机只读商品诊断的 1/1 PASS 证明实际商品与 intro metadata，未读取到已验证交易，不能代替本地 StoreKit 或 Sandbox 购买／恢复／取消／撤销／到期生命周期。见 `DEVICE_SANDBOX_READONLY_RESULTS.md`，不迁移为本报告 PASS。

## 需另行完成的边界

本报告的模拟器范围内，导出原文件内容/分享交接/日历导入、任意日期范围UI、实际通知请求取消与投递、真实天气可用日期及离线缓存、四家真实API成功响应、完整VoiceOver、最大动态字体、iOS17、Sandbox交易均未闭合。R30本地StoreKit只闭合试用、恢复、refund和过期4项，Ask-to-Buy两项、取消购买和取消续订未运行；不等价于完整订阅UI或Sandbox通过。Gemini本版本不开放，iPad首版不在范围。真机证据独立记录，不用旧PASS替代当前候选。

## 独立范围观察

- 测试者仅修改 `MapToDoUITests/` 与 `docs/testing/SIMULATOR*`；产品编译问题交回地图实现者。
- 首轮编译不通过已保留诊断，未声称未执行检查通过。
- 尚未发布、购买、使用真实密钥或创建子 agent。
