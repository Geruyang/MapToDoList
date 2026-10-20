# 已安装候选 no-install 真机 UI 验证

官方UseDestinationArtifacts首启smoke 1/1 PASS，guard72.9%/peak74.2%。后续已安装20UI实际 **18PASS /1FAIL /1SKIP**，guard基线72.3%、峰值73.2%，未触发75%中断。xcodebuild exit65来自唯一UI断言失败；资源已释放。

本轮没有编译或重新安装。两个安装容器前后完全相同（Runner BAA655BB、Main17C3883D），`UI-noinstall-all20-container-proof.json`记录对应前后完整URL。旧built Main launcher SHA6f4f35...、debug dylib d6a72c9...、UI测试bundleSHA7d3b336...，完整94个bundle文件SHA见`UI-noinstall-all20-bundle-file-sha256.json`。候选边界不得仅用当前22项源码替代：本轮运行的是已安装20项的旧测试二进制。

## 证据位置

全部在 `DEVICE_EVIDENCE/`：UI-noinstall-all20.log/.xcresult、summary/tests/cases JSON、全附件目录UI-noinstall-all20-attachments/manifest.json；中文/EN/AXXXL专用UI-noinstall-gallery/manifest.json及candidate.json。

三gallery各7PNG=6个主屏+Today_SCROLL_END，另AXXXL Map hierarchy。三用例均PASS，包含所选coffee详情title准确非空、末端Add hittable。最大字号先在同机对照Today heading高度>正常1.4倍的运行断言通过；实际数值旧built test没有附件，不能编造。独立视觉review指出normal中英末端Add仍被floatingtab部分遮挡，hittable不能代替视觉完整；这是下一候选修补项，并未被本轮PASS关闭。

## 唯一失败：四服务密钥保存按钮触达

失败于第一个GLM、输入无效sentinel后的ai.key.save。trace在20.43s首次查询button，之后12次“Keyboard exists、629→246内容drag”，每次button仍exists但notHittable，39.98s触达断言失败，没有明确Tap Save动作。不能写按钮不存在，也不能未经enabled观察就判为产品输入绑定或键盘遮挡。

现场输入前hierarchy：`UI-noinstall-all20-attachments/4834FB1F-9EB8-4F0B-94F2-89FCE4781048.txt`。完整activity：`UI-noinstall-key-save-activities.json`。原录像43663E5B-7916-4E8B-ABFC-BF0097274322.mp4。原录像38–39秒经macOS avconvert passthrough截取并QuickLook导出的诊断缩略图：`DEVICE_AI_KEY_FAILURE_FRAMES/DEVICE_AI_KEY_FAILURE_TAIL.mov.png`，只读工具处理无Appbuild。尾帧Save row可见，键盘像素未出现，GLM metadata已有key（可能来自旧独立testservice）；SecureField录像像素遮蔽，不能据此推断真实输入为空。disabled状态旧trace未记录，精确根因尚待新候选分层断言。

下一候选owner已加FocusState、keyboard Done/submit/interactive dismiss；测试仍保留四服务保存/取消保留/确认删除/无key禁删/重启、Gemini不可选，并明确空输入Save disabled→输入掩码非空/nonplaceholder→Done收键盘→非空Save enabled→触达/实际保存结果。新Done不存在于本轮旧产物，不尝试旧no-install用新源冒称修复。

## 通知skip及Restore实际状态

通知拒绝用例trace406行明确XCTSkip：reminders.authorize已不存在，权限已决定；本轮没有系统拒绝操作。原第三轮真实点“不允许”PASS另有证据保留，不能将本轮skip写成新拒绝PASS。activity `UI-noinstall-notification-skip-activities.json`。

Restore35秒用例PASS仅支持有界timeout/重试/退出恢复路径：11.35s点restore，27.84smessage出现并进入“超时不能授予权益”检查；截图 `UI-noinstall-all20-attachments/2F3BBA87-18AA-4B68-B4DB-C9EB8F5505C4.png` 显示系统Sign in to Apple Account及空账号/密码，旧built did not attach raw message string。29.97s XCTest默认interruption handler自动点Cancel，32.07s确认取消后关闭Paywall。没有输入账号密码、purchase、成功恢复或verified Sandbox交易证据。不能以此PASS声称Sandbox账户认证/购买生命周期完成。activity `UI-noinstall-restore-activities.json`。未来新增SandboxSubscriptionDiagnosticsTests将无fixture只读真实metadata，无transaction时明确sandbox环境未证实。

## 实际逐项结果

| 用例 | 状态 | 秒 |
| --- | --- | --- |
| `WaypointUITests/testBlankTitleCannotBeSaved()` | Passed | 15.597 |
| `WaypointUITests/testCancelCreationDoesNotPersistTask()` | Passed | 34.852 |
| `WaypointUITests/testCompletionSurvivesRelaunch()` | Passed | 19.819 |
| `WaypointUITests/testCreateEditPersistAndDeleteTask()` | Passed | 61.004 |
| `WaypointUITests/testEmptyExportDisablesCopy()` | Passed | 11.304 |
| `WaypointUITests/testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall()` | Passed | 30.389 |
| `WaypointUITests/testEnglishScreenshotGalleryOfPrimaryScreens()` | Passed | 26.352 |
| `WaypointUITests/testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess()` | Passed | 42.295 |
| `WaypointUITests/testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission()` | Passed | 12.646 |
| `WaypointUITests/testFourAIProvidersUseSecureInputAndCanSaveAndDeleteKeysWhileGeminiIsUnavailable()` | Failed | 41.141 |
| `WaypointUITests/testLargestAccessibilityTypeScreenshotGalleryOfPrimaryScreens()` | Passed | 55.310 |
| `WaypointUITests/testLiveMapSearchSelectsResult()` | Passed | 20.561 |
| `WaypointUITests/testLocalPlanningProducesPreviewWithoutChangingSavedTasks()` | Passed | 45.789 |
| `WaypointUITests/testMapPointOpensEditorAndPersistsChosenLocation()` | Passed | 29.577 |
| `WaypointUITests/testMapSearchFieldAcceptsAndRetainsQuery()` | Passed | 10.997 |
| `WaypointUITests/testNotificationDenialKeepsAppUsable()` | Skipped | 12.157 |
| `WaypointUITests/testReminderSettingsDoNotRequestPermissionOnEntry()` | Passed | 10.313 |
| `WaypointUITests/testScreenshotGalleryOfPrimaryScreens()` | Passed | 25.902 |
| `WaypointUITests/testSubscriptionShowsRestoreAndManagementWithoutClaimingPurchase()` | Passed | 34.940 |
| `WaypointUITests/testTodayScreenAccessibilityAudit()` | Passed | 10.572 |

## 新候选准备状态

22UI源码（新增editable/readonly长title normal+AX；gallery完整CTA frame；AI Done/enabled诊断）及Sandbox诊断均尚未build/runtime验证。readonly标题新Text语义检查全文label且无TextField/TextView，Save disabled；不因不可编辑的Text.isEnabled含义误判。构建脚本DEVICE_BUILD_INPUT_LAYOUT_CANDIDATE.sh使用build-for-testing、start<70/stop75/jobs1，无并行/无模拟器。计划DEVICE_INPUT_LAYOUT_NEXT_PLAN.md：构建→签名/hash→只安装一次→之后focused7UI no-install→只读Sandbox→全22另阶段。最新准入71.2%，未构建/重装，等资源满足条件。
