# 第五轮审查修补真机回归与 UI Runner 深入诊断

本轮获用户恢复、信任完成/解锁确认及主会话唯一重slot授权。冻结候选执行 `DEVICE_RUN_AUDIT_COMBINED.sh`，共选择60项=40logic+20UI，jobs1、无并行/无模拟器。只执行一次，未修产品/测试源码，没有盲目重试。

## 实际结果

**40逻辑全部PASS；20UI实际执行0，NOT RUN/BLOCKED_DEVICE_EXECUTION_VALIDATION。** xcresult41条=40PASS+1Runner基础设施错误，0SKIP。新源码包括最终全量邻居转场/目标时刻天气验证、workspace竞态/精细时间、商品加载timeout与权益并发保护。此40项通过对应本轮candidate，不表示网络交通/真实订阅/UI通过。

启动sample与guard实际准入均71.9%，本轮仅特批start<72%、stop75%。0.5秒采样，峰值74.6%，未触发中断；结束sample72.2%，xcodebuild exit65来自Runner启动拒绝。用户内存硬上限80%；资源slot已释放。

证据：`Audit-fixes-combined.log/.xcresult`、`Audit-fixes-combined-summary.json`、`Audit-fixes-combined-tests.json`、`Audit-fixes-combined-cases.json`、`Audit-fixes-combined-artifact-sha256.txt`。全部位于 `DEVICE_EVIDENCE/`。附件manifest仅Complete Issue Description，无中文/英文/最大辅助字号新截图、无字号生效证据；不使用旧gallery代替。

## 签名及设备只读核验

| 项 | App宿主（本轮实际执行40测试） | UI Runner（启动被拒） |
| --- | --- | --- |
| Bundle | com.waypoint.maptodo | com.waypoint.MapToDoUITests.xctrunner |
| Team | VA8X63NPCS | VA8X63NPCS |
| 实际leaf SHA1 | 7B1C5A1BAA33E9EF735548F51F15424020BA8095 | 相同 |
| 实际leaf SHA256 | e49a66d5bf0c2e2df71ba5c9ae1549e12c10f6fb76e6581a69edfdcbf5bd8e19 | 相同 |
| Profile | 46fba18a-962d-41ec-b1b3-ea4eaad68aca，explicit App ID | ae6e042c-c9a4-4600-9ba3-cfd2bb7e608d，wildcard |
| 到期 | 2027-10-11 | 2027-09-03 |
| 设备UDID包含/实际signer在profile内 | true/true | true/true |
| PPQCheck | true | true |
| get-task-allow | true | true |

Runner签名application-identifier为VA8X63NPCS.com.waypoint.MapToDoUITests.xctrunner，符合profile VA8X63NPCS.*；keychain group同一前缀。`codesign --verify --deep --strict` exit0；leaf是公开证书，只提取公开DER用于指纹，没有私钥/Keychain操作。独立info apps确认Runner已安装。设备passcodeRequired=false/unlockedSinceBoot=true；DDI build17F113 contentIsCompatible=true/isUsable=true，XCTest24904。此前成功执行18UI的Final-logic-and-ui日志也使用同一leaf+wildcard Runner，因此没有证据支持不同证书/Team或简单OS/DDI不兼容。

具体证据：`Audit-fixes-combined-public-signing-comparison.json`、`Audit-fixes-combined-runner-signature-check.txt`、`Audit-fixes-combined-installed-runner.json`、`Audit-fixes-combined-ddi-services.json`、`Audit-fixes-combined-lock-state.json`。

## 一次单独Runner launch

主会话明确允许一次小型直接启动诊断；未重build/test、不删App、不改安全配置。`devicectl device process launch`直接启动相同已安装Runner，exit1，链路：CoreDeviceError10002 → FBSOpenApplicationServiceErrorDomain1/RequestDenied → FBSOpenApplicationErrorDomain3/Security。SBMainWorkspace在进程启动之前拒绝，文字仍是invalid signature/inadequate entitlements/profile not explicitly trusted。没有XCTestSession握手、测试执行或App崩溃stack。

证据：`Audit-fixes-combined-direct-runner-launch.json/.log`。这是唯一额外launch，之后停止；不是20项UI测试的替代运行。

## 与“已经信任证书”不同的下一步

两profile实测PPQCheck=true。[Apple provisioning profile更新文档](https://developer.apple.com/help/account/provisioning-profiles/provisioning-profile-updates)说明符合其团队条件的development/ad-hoc App首启需要在设备上完成PPQ联网验证，网络受阻时可能无法启动；并提供7天offline development profile作为官方受限网络方案。由此推断本次应定位Runner独立App的设备执行验证状态，不能把用户已完成的Trust操作简单判作未完成。

[Apple论坛原始事件及DTS回复](https://developer.apple.com/forums/thread/818403)记录2026-03曾出现相同Security/Unable to Verify症状，DTS确认当时PPQ服务问题已修复。该历史事件只证明这种错误可能来自验证服务，不能据此宣称2026-10-11有Apple故障。

本机Mac对https://ppq.apple.com一次无凭证GET实测HTTP200/TLS校验0/0.660s（headers日期10:46:03Z），仅证明Mac线路通，**不证明iPhone能连接或该Runner已获验证**；证据`Audit-fixes-combined-ppq-mac-probe.txt/-headers.txt`。

当前能确定的根因层级：已安装且本地签名/profile匹配的Runner被设备执行安全校验拒绝；PPQ具体网络/缓存原因尚未从设备日志证实。最小下一诊断由用户在手机保持联网时点独立灰色图标MapToDoUITests-Runner，观察实际系统提示；若提示Unable to Verify/需要联网，核对该Runner验证状态和iPhone到PPQ的网络，必要时用可用蜂窝线路进行一次验证。这与重复“信任开发者”不同，也不需要删除App/重置设置。若网络始终受限，主会话可另行授权针对Runner创建官方7天offline开发profile，保留原全局证书和App WeatherKit配置；这是可实施的配置方案，尚未执行，不能当作已定位或已解决。

### 用户手动打开后的状态变化

用户随后保持联网手动打开独立Runner，反馈进入后返回桌面。主会话允许基于该外部状态变化的一次轻量直接launch验证，禁止build/install/delete/certificate改动。本次 `devicectl device process launch` exit0并返回Launched application；此前FBS Security拒绝消失，证明该时刻设备安全验证层已经放行。guard只对此轻CLI特批start74/stop75，准入/峰值均73.6%，0.4秒完成。证据 `Runner-after-manual-verify-direct-launch.json/.log/-guard.log`。

该后续结果不覆盖上面的真实40PASS/20NOT RUN；Runner直接launch不是XCTest，可能缺test配置而自行退出，不能称UI smoke或20UI通过。无需重复要求已完成的Trust；后续最小test-without-building smoke仍待start72准入及主会话授权，未知OS automation prompt尚无法保证不存在。

## 逐项证据

| 实际执行用例 | 结果 |
| --- | --- |
| `AIParsingTests/testChangedTaskConflictsWithLongUnselectedAppointment()` | PASS |
| `AIParsingTests/testCompletedFlexibleTaskCannotBeMoved()` | PASS |
| `AIParsingTests/testFineFractionalTimestampRoundtripKeepsExactLowerBound()` | PASS |
| `AIParsingTests/testFixedTimeSuggestionIsRejected()` | PASS |
| `AIParsingTests/testFractionalSecondsAndOffsetRepresentSameInstant()` | PASS |
| `AIParsingTests/testGeminiConcatenatesTextPartsAndSkipsThoughts()` | PASS |
| `AIParsingTests/testKeychainErrorsDescribeRecoveryWithoutRawStatusCodes()` | PASS |
| `AIParsingTests/testMalformedResponseIsRejected()` | PASS |
| `AIParsingTests/testModelRefreshSnapshotRejectsChangedWorkspace()` | PASS |
| `AIParsingTests/testOpenAIRequestExplicitlyDisablesResponseStorage()` | PASS |
| `AIParsingTests/testOpenAIResponsesEnvelopeExtractsOutputText()` | PASS |
| `AIParsingTests/testOutsideWindowIsRejected()` | PASS |
| `AIParsingTests/testQwenRegionalEndpointsMatchOfficialDomains()` | PASS |
| `AIParsingTests/testSerializedTimeDoesNotLoseFractionalWindowPrecision()` | PASS |
| `AIParsingTests/testTransmissionIDsAreTemporaryAndMapBackLocally()` | PASS |
| `AIParsingTests/testTruncatedOpenAIResponseIsRejected()` | PASS |
| `AIParsingTests/testUnrelatedHistoricalConflictDoesNotBlockNewChanges()` | PASS |
| `AIParsingTests/testUnselectedFixedAppointmentBlocksApply()` | PASS |
| `AIParsingTests/testValidFlexibleWindowSuggestion()` | PASS |
| `AIReleaseGateTests/testEnabledCustomModelIsPreserved()` | PASS |
| `AIReleaseGateTests/testGeminiGenerationIsRejectedBeforeAuthentication()` | PASS |
| `AIReleaseGateTests/testGeminiModelRequestsAreRejectedBeforeAuthentication()` | PASS |
| `AIReleaseGateTests/testMigrationOnlyChangesNonSecretPreferences()` | PASS |
| `AIReleaseGateTests/testOldGeminiSelectionMovesToValidOpenAIModel()` | PASS |
| `AIReleaseGateTests/testReleaseOffersExactlyFourProviders()` | PASS |
| `PlanningFinalValidationTests/testFinalWeatherDependencyReceivesChangedTargetDate()` | PASS |
| `PlanningFinalValidationTests/testOutsideRangeNeighborIsIncludedAndBlocksInsufficientTransfer()` | PASS |
| `PlanningFinalValidationTests/testTargetTimeWeatherBufferCanMakeTransferConflict()` | PASS |
| `PlanningTests/testFixedTimeRemainsAndFlexibleMovesPastTravel()` | PASS |
| `PlanningTests/testImpossibleWindowReportsConflict()` | PASS |
| `PlanningTests/testWeatherBufferConsumesGapWithoutMovingFixedItem()` | PASS |
| `PlanningTimeoutTests/testOperationThatIgnoresCancellationDoesNotHoldWaiter()` | PASS |
| `SubscriptionConcurrencyTests/testForegroundRechecksEntitlementsDuringStuckProductRequestAndTimeoutAllowsRetry()` | PASS |
| `SubscriptionConcurrencyTests/testOlderActiveSnapshotCannotOverwriteNewerRevocation()` | PASS |
| `SubscriptionConcurrencyTests/testSnapshotAlreadyExpiredAtApplyCannotGrantAccess()` | PASS |
| `SubscriptionTests/testExpiredAndRevokedEntitlementsNeverGrantAccess()` | PASS |
| `SubscriptionTests/testOnlyExpectedActiveSubscriptionGrantsAccess()` | PASS |
| `SubscriptionTimeoutTests/testLateResultCannotReplaceANewOperationResult()` | PASS |
| `SubscriptionTimeoutTests/testNonCooperativeOperationTimesOutWithoutWaitingForItsResult()` | PASS |
| `SubscriptionTimeoutTests/testSuccessfulOperationReturnsVerifiedWorkResultBeforeDeadline()` | PASS |

| 选中UI用例 | 结果 |
| --- | --- |
| `testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission` | NOT RUN：设备执行校验阻塞 |
| `testCreateEditPersistAndDeleteTask` | NOT RUN：设备执行校验阻塞 |
| `testCancelCreationDoesNotPersistTask` | NOT RUN：设备执行校验阻塞 |
| `testBlankTitleCannotBeSaved` | NOT RUN：设备执行校验阻塞 |
| `testMapSearchFieldAcceptsAndRetainsQuery` | NOT RUN：设备执行校验阻塞 |
| `testMapPointOpensEditorAndPersistsChosenLocation` | NOT RUN：设备执行校验阻塞 |
| `testLiveMapSearchSelectsResult` | NOT RUN：设备执行校验阻塞 |
| `testCompletionSurvivesRelaunch` | NOT RUN：设备执行校验阻塞 |
| `testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess` | NOT RUN：设备执行校验阻塞 |
| `testEmptyExportDisablesCopy` | NOT RUN：设备执行校验阻塞 |
| `testReminderSettingsDoNotRequestPermissionOnEntry` | NOT RUN：设备执行校验阻塞 |
| `testSubscriptionShowsRestoreAndManagementWithoutClaimingPurchase` | NOT RUN：设备执行校验阻塞 |
| `testLocalPlanningProducesPreviewWithoutChangingSavedTasks` | NOT RUN：设备执行校验阻塞 |
| `testScreenshotGalleryOfPrimaryScreens` | NOT RUN：设备执行校验阻塞 |
| `testEnglishScreenshotGalleryOfPrimaryScreens` | NOT RUN：设备执行校验阻塞 |
| `testLargestAccessibilityTypeScreenshotGalleryOfPrimaryScreens` | NOT RUN：设备执行校验阻塞 |
| `testTodayScreenAccessibilityAudit` | NOT RUN：设备执行校验阻塞 |
| `testFourAIProvidersUseSecureInputAndCanSaveAndDeleteKeysWhileGeminiIsUnavailable` | NOT RUN：设备执行校验阻塞 |
| `testNotificationDenialKeepsAppUsable` | NOT RUN：设备执行校验阻塞 |
| `testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall` | NOT RUN：设备执行校验阻塞 |
