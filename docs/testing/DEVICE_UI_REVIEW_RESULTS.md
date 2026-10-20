# 第四轮真机回归：9项通过，UI Runner信任阻塞

用户已明确恢复真机验证，主会话授予唯一重资源slot。本轮执行已冻结候选，未修源码、未重复启动。脚本 `DEVICE_RUN_UI_REVIEW.sh` 已xcodegen纳入新AIReleaseGateTests；物理设备UDID `00008150-00066CE13C43C01C`，iPhone17 Pro Max/iOS27.0.1，Team VA8X63NPCS，Xcode26.6。

候选边界：9/9 PASS仅对本轮构建App与测试二进制成立，精确SHA在 `UI-review-artifact-sha256.txt`。主会话随后解除源码冻结，让AI/订阅owner修新增缺口；那些新修补未由本轮9项结果验证。即使用户完成证书trust，也不能直接重试，须待全部owner再次freeze并获新单slot授权。

## 实际计数与内存

选择29项（20UI+6AIReleaseGate+3SubscriptionTimeout），实际9项XCTest全部PASS；20UI执行0项、NOT RUN/BLOCKED_DEVICE_CERTIFICATE_TRUST。xcresult统计10条=9通过+1Runner基础设施错误，不能把Runner错误算为1个UI用例失败，也不能写29项通过或20项跳过。

启动前轻量sample69.1%；guard实际准入69.5%，峰值73.5%，stop75%未触发，结束sample70.5%。用户硬上限80%，本轮无模拟器、jobs1、无并行。xcodebuild exit65源自UI Runner启动拒绝；资源slot已经释放。

## 通过的新增逻辑

AIReleaseGateTests六项全部PASS：四provider精确列表；Gemini旧偏好迁至OpenAI及可用模型；可用provider自定义模型保留；只迁普通偏好且保留无关设置；Gemini models与suggest在认证前拒绝。无远程AI调用、无用户Key读取。

SubscriptionTimeoutTests三项全部PASS：非合作操作按deadline超时；迟到结果不能覆盖新操作；deadline前返回真实工作结果。这些是纯逻辑PASS，不代表实际StoreKit恢复或Sandbox交易成功。

## UI阻塞与只读签名核验

xcodebuild明确报：`The application could not be launched because the Developer App Certificate is not trusted.` bundle为`com.waypoint.MapToDoUITests.xctrunner`，下层SBMainWorkspace Security错误含签名/entitlements/profile未显式信任的通用文字。

本地 `codesign --verify --deep --strict --verbose=2` exit0，Runner资源及磁盘签名有效；Authority Apple Development: Ge Ruyang (PX8ZG2Y7AH)，实际TeamIdentifier VA8X63NPCS。Runner使用有效wildcard开发profile `ae6e042c-c9a4-4600-9ba3-cfd2bb7e608d`（2026-09-03创建，2027-09-03到期），该设备UDID在ProvisionedDevices，团队及application prefix匹配；get-task-allow=true。签名/配置只读，未读取私钥、未替换profile、未改设备安全设置。

证据支持设备明确拒绝trust；本地核验不能替代设备安全判定。按Xcode报错需要用户在iPhone Settings > General > VPN & Device Management找到该Developer App并确认Trust，保持解锁，然后再由主会话授权单次重试。等待期间不重复启动。

原始证据：`DEVICE_EVIDENCE/UI-review-regression.log/.xcresult`、`UI-review-regression-summary.json`、`UI-review-regression-tests.json`、`UI-review-runner-signature-check.txt`、`UI-review-runner-entitlements.plist`、`UI-review-runner-profile-metadata.json`、`UI-review-artifact-sha256.txt`。附件目录 `UI-review-attachments/manifest.json` 仅1个Complete Issue Description，无任何新版UI截图。

## UI逐项状态

| 用例 | 实际状态 |
| --- | --- |
| `testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission` | NOT RUN — Runner证书信任阻塞 |
| `testCreateEditPersistAndDeleteTask` | NOT RUN — Runner证书信任阻塞 |
| `testCancelCreationDoesNotPersistTask` | NOT RUN — Runner证书信任阻塞 |
| `testBlankTitleCannotBeSaved` | NOT RUN — Runner证书信任阻塞 |
| `testMapSearchFieldAcceptsAndRetainsQuery` | NOT RUN — Runner证书信任阻塞 |
| `testMapPointOpensEditorAndPersistsChosenLocation` | NOT RUN — Runner证书信任阻塞 |
| `testLiveMapSearchSelectsResult` | NOT RUN — Runner证书信任阻塞 |
| `testCompletionSurvivesRelaunch` | NOT RUN — Runner证书信任阻塞 |
| `testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess` | NOT RUN — Runner证书信任阻塞 |
| `testEmptyExportDisablesCopy` | NOT RUN — Runner证书信任阻塞 |
| `testReminderSettingsDoNotRequestPermissionOnEntry` | NOT RUN — Runner证书信任阻塞 |
| `testSubscriptionShowsRestoreAndManagementWithoutClaimingPurchase` | NOT RUN — Runner证书信任阻塞 |
| `testLocalPlanningProducesPreviewWithoutChangingSavedTasks` | NOT RUN — Runner证书信任阻塞 |
| `testScreenshotGalleryOfPrimaryScreens` | NOT RUN — Runner证书信任阻塞 |
| `testEnglishScreenshotGalleryOfPrimaryScreens` | NOT RUN — Runner证书信任阻塞 |
| `testLargestAccessibilityTypeScreenshotGalleryOfPrimaryScreens` | NOT RUN — Runner证书信任阻塞 |
| `testTodayScreenAccessibilityAudit` | NOT RUN — Runner证书信任阻塞 |
| `testFourAIProvidersUseSecureInputAndCanSaveAndDeleteKeysWhileGeminiIsUnavailable` | NOT RUN — Runner证书信任阻塞 |
| `testNotificationDenialKeepsAppUsable` | NOT RUN — Runner证书信任阻塞 |
| `testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall` | NOT RUN — Runner证书信任阻塞 |

中文/英文/最大辅助字号gallery全部未开始，无字号生效证据；不会发旧gallery代表新版。上一轮49项逻辑及天气PASS与11UI失败保留于DEVICE_FINAL_SUITE_RESULTS.md，本轮未重跑或关闭其UI失败。
