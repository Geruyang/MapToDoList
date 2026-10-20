# 真机 UI XCTest 执行准备

**USER RESUMED**：用户明确恢复真机测试，主会话已授予本轮唯一重资源slot。候选源码冻结，执行29项UI-review回归，start<70%、stop75%、jobs1、无并行/无模拟器，保留历史证据。此前暂停期间未执行设备操作。

最终准备计数：20UI+3SubscriptionTimeout+6AIReleaseGate=29；仅脚本语法/源码静态核验，未xcodegen、未build/test。

2026-10-11，收到主会话授权准备后，只读检查；未启动构建或模拟器。需主会话释放唯一重任务资源后执行。

- 真机：iPhone 17 Pro Max，iOS 27.0.1。
- Xcode destination UDID：`00008150-00066CE13C43C01C`；CoreDevice ID 为 `2050E692-2C1D-5D9D-967A-EABA499B386F`，两者不可混淆。
- 项目/方案：`MapToDo.xcodeproj` / shared `MapToDo`；方案 TestAction 有 `MapToDoTests` 与 `MapToDoUITests`，parallelizable=NO，无独立 testplan。
- 开发团队：`VA8X63NPCS`；保留原始 WeatherKit/time-sensitive entitlements。
- 用例文件：`MapToDoUITests/WaypointUITests.swift`，class `WaypointUITests`。
- 数据隔离：`--uitesting` 采用独立 JSON 文件；DEBUG Keychain service `com.waypoint.maptodo.ai.ui-testing`，不影响用户真实 Key。
- 不执行真实扣费、未知 Key 请求或 AppStore.sync 购买恢复 UI；首轮只选择安全用例。
- 内存硬上限 80%；`memory_guard.py` 在低于 68% 时才启动、78%时停止，`-jobs 1`、并行测试关闭、禁止同时运行模拟器。

## 首轮 7 项用例

1. `testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission`：无 demo access、测试数据隔离下导航与无静默通知请求。
2. `testCreateEditPersistAndDeleteTask`：明确 demo access 下创建、编辑、重启持久化、删除。
3. `testCancelCreationDoesNotPersistTask`：取消与重启无新增。
4. `testMapPointOpensEditorAndPersistsChosenLocation`：地图选点、保存与地点保留。
5. `testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess`：seed数据、无demo权益的读出/导出。
6. `testFiveAIProvidersUseSecureInputAndCanSaveAndDeleteKeys`：无效sentinel仅写独立测试Keychain，绝不联网。
7. `testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall`：英文导航、导出、规划与订阅文案，无购买。

UI owner 已修复并冻结两点：地图选点验证非空真实/降级地点、合法坐标及重启后保留；附件统一 `WAYPOINT_` 前缀，可以如实用于真机证据。DEVICE agent 不改其他 owner 文件。

## 命令形态（仅准备，未执行）

```sh
python3 scripts/memory_guard.py --start-below 68 --stop-at 78 -- xcodebuild test -project MapToDo.xcodeproj -scheme MapToDo -destination 'platform=iOS,id=00008150-00066CE13C43C01C' -jobs 1 -parallel-testing-enabled NO -allowProvisioningUpdates -derivedDataPath build/DeviceUIData -resultBundlePath docs/testing/DEVICE_EVIDENCE/UI-first.xcresult -only-testing:MapToDoUITests/WaypointUITests/testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission -only-testing:MapToDoUITests/WaypointUITests/testCreateEditPersistAndDeleteTask -only-testing:MapToDoUITests/WaypointUITests/testCancelCreationDoesNotPersistTask -only-testing:MapToDoUITests/WaypointUITests/testMapPointOpensEditorAndPersistsChosenLocation -only-testing:MapToDoUITests/WaypointUITests/testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess -only-testing:MapToDoUITests/WaypointUITests/testFiveAIProvidersUseSecureInputAndCanSaveAndDeleteKeys -only-testing:MapToDoUITests/WaypointUITests/testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall DEVELOPMENT_TEAM=VA8X63NPCS
```

执行后记录完整 command/log/result bundle、构建版本/哈希、内存 sampled peak、每项 pass/fail/skip、所有截图附件。不把 demo 创建通过当作真实订阅开通；不把 WeatherKit entitlement 签名成功当作真实天气返回。

## 独立真实 WeatherKit 用例

`MapToDoTests/DeviceIntegrationTests/testLiveWeatherKitCurrentForecastAndAppleAttribution` 使用 fresh WeatherProvider actor 和公开旧金山坐标，验证 current、+1小时精确覆盖预报与 Apple attribution，保留 JSON XCTAttachment。没有用户位置和未知 Key。真机 API/签名/数据失败为 FAIL；模拟器由于物理硬件前提不满足，明确 XCTSkip，**该 skip 不是天气通过**。普通逻辑单测建议仍显式排除此 class。

主会话须重新 xcodegen 将新文件加入工程（本准备时 project.pbxproj 尚无 DeviceIntegrationTests 引用），然后用同样 memory_guard 与真机 destination 单独执行：

```sh
python3 scripts/memory_guard.py --start-below 68 --stop-at 78 -- xcodebuild test -project MapToDo.xcodeproj -scheme MapToDo -destination 'platform=iOS,id=00008150-00066CE13C43C01C' -jobs 1 -parallel-testing-enabled NO -allowProvisioningUpdates -derivedDataPath build/DeviceUIData -resultBundlePath docs/testing/DEVICE_EVIDENCE/Weather-live.xcresult -only-testing:MapToDoTests/DeviceIntegrationTests/testLiveWeatherKitCurrentForecastAndAppleAttribution DEVELOPMENT_TEAM=VA8X63NPCS
```

可以在主会话授权下把此 only-testing selector 加入同一个 7UI 真机命令，形成 7UI+1live=8项；报告仍将天气联网与demo UI结果分开。所有命令都仅为准备，未经独占放行未运行。
