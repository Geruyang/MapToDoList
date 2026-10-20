# 使用已安装 artifacts 的 UI smoke

第二次无编译smoke `Runner-smoke-after-mainapp-verify` 实际UI执行0；xcresult仅1条Runner基础设施错误，不是首启用例断言失败。用户已看见主App地图，但Runner再次被FBS Security拒绝。准入73.2%，峰值73.9%，没有guard中断，未编译/改源。

只读设备证据发现Runner安装容器由先前直接launch成功的 `3B363780-D9F9-4C4A-B296-917B9DD66E71` 变成 `BAA655BB-836E-4EC4-85DA-2D66F8B3F003`。本地Runner/App Mach-O SHA仍与Audit-fixes-combined相同。这证明test-without-building未编译，但没有保证不重新安装；容器替换与验证状态回退相关，尚不能据此证明Apple具体缓存/PPQ机制。

Xcode26.6本机官方手册 `Contents/Developer/usr/share/man/man5/xcodebuild.xctestrun.5` 第233–267行明确：UseDestinationArtifacts=true使用destination既有artifacts，测试时不安装artifacts。须排除TestBundlePath/TestHostPath/UITargetAppPath，并指定TestHostBundleIdentifier、TestBundleDestinationRelativePath和UITargetAppBundleIdentifier。

已准备 `DEVICE_RUNNER_NOINSTALL.xctestrun`（format2）与 `DEVICE_RUN_NOINSTALL_SMOKE.sh`，仅已构建20UI里的FirstLaunch单项。Host为 `com.waypoint.MapToDoUITests.xctrunner`；Bundle路径 `__TESTHOST__/PlugIns/MapToDoUITests.xctest`；UITarget为 `com.waypoint.maptodo`。TestingEnvironmentVariables存在；没有3个本地安装Path；plutil与脚本语法检查通过。此为静态schema检查，尚未成功实际执行，不声称运行通过。

主会话授权此流程前置一次当前Runner直接launch，本轮新容器仍拒绝：`Runner-noinstall-precheck-launch.json/.log/-guard.log`，准入73.6%、峰值73.7%，CoreDevice10002→FBS Service1→FBS3/Security。前置不满足，**没有启动no-install XCTest**，也没有重装/重编译/删除App/改变证书安全设置。

现在需要的本人操作是打开这次新安装的Runner；不是重复开发者Trust，也不再改已能显示地图的主App。待该外部状态改变后，按已授予流程授权只执行一次UseDestinationArtifacts smoke，start<74%、stop75%、0.5秒采样、jobs1、无模拟器。记录前后安装容器以确认没有重新安装。若出现新OS提示或运行错误立即报告，不自动循环。

## 用户确认后的实际准入

用户已经确认打开当前新Runner并返回桌面。主会话授权执行no-install smoke，若PASS再继续20UI。只读before快照确认Runner仍BAA655BB容器、Main仍17C3883D容器；guard实际76.5%，超过start<74%，因此exit75立即拒启。`Runner-noinstall-smoke.log`仅Memory used estimate/Not started；没有xcodebuild进程、device launch、安装或xcresult，也没有新FBS安全拒绝证据。不能把内存拒启解释为用户手动验证失败。

本次真实log保留不覆盖。后续需主会话释放内存与新准入通知、使用新结果文件名；当前不轮询重试或提高阈值，设备安装保持不变。
