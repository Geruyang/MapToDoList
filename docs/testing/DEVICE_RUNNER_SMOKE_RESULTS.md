# 已构建候选最小 UI smoke：Runner运行，主 App 启动被拒

用户已手动联网打开Runner并确认Sandbox账户登录。主会话只授权一次 `test-without-building`，没有xcodegen/编译/购买/密码读取。证据使用全新 `Runner-smoke-after-manual-verify` 文件名，旧预检73.7%未覆盖。

**实际1项FAIL / 0PASS / 0SKIP。** `WaypointUITests/testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission()`进入执行，11.379秒后在 `WaypointUITests.swift:455` 的 `app.launch()`失败。本次不再是Runner初始化0cases：Runner已启动，但主App **`com.waypoint.maptodo`** 被SBMainWorkspace执行安全验证拒绝，报Developer App Certificate not trusted及FBS Security。不能把新对象混作前面的Runner信任未解除，也不能把此环境失败写成4Tab或通知断言失败。

准入73.5%，本次无编译单项特批start<74%、stop75%、0.5秒采样、jobs1、无并行/无模拟器。峰值74.1%，未触发中断，xcodebuild exit65。执行完成后资源slot释放，未再次launch或重跑测试。

原始log/xcresult、summary/tests JSON位于 `DEVICE_EVIDENCE/Runner-smoke-after-manual-verify*`。附件manifest仅1个Screen Recording与Complete Issue Description，无App已显示后的中文/英文/最大辅助字号截图。不能用这段启动失败录像或旧gallery代表新版UI验收。

实际使用App Mach-O SHA256 `6f4f35da7e5e723cb59f12dc820bf29662c6592de50387afc5905a67a56af595`。此前Audit-fixes-combined40纯逻辑已通过；本次只确认UI Runner放行及主App独立启动阻塞，未验证完整UI。后续需针对主App独立设备执行验证状态诊断，仍不能宣称具体PPQ网络原因已证实；避免重复要求同一个Runner手动信任步骤。
