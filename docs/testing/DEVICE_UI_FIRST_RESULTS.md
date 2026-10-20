# 首轮真实设备 XCTest 结果

时间：2026-10-11 08:23–08:24 UTC；iPhone 17 Pro Max，iOS 27.0.1（24A446），Xcode 26.6（17F113）；App 1.0.0 (1)，team VA8X63NPCS。

命令：`bash docs/testing/DEVICE_RUN_UI.sh`，7 个 UI selectors + 1 个真实 WeatherKit selector。`-jobs 1`、parallel-testing=NO、仅真机；memory_guard start<68%、stop≥75%；起始 52.4%、采样峰值 **62.4%**，未触发 guard；退出 **65**。

## 实际状态

| 项目 | 实际结果 | 证据 |
| --- | --- | --- |
| 最新候选构建/签名 | 成功构建测试产品；codesign verify deep strict exit0 | 同名log；公开profile JSON |
| WeatherKit当前天气 | **FAIL**，实际AuthService无法生成JWT；WeatherDaemon.WDSJWTAuthenticatorServiceListener.Errors Code=2 | log:1151；真实 XCTest failure attachment |
| WeatherKit +1小时预报 | **NOT RUN**，current失败后未进入 forecast调用 | 测试顺序与实际错误 |
| WeatherKit归属 | 不单独宣称PASS；未生成完整成功数据附件 | 原测试失败附件仅记录真实错误 |
| UI首启 | **NOT RUN / BLOCKED_AUTOMATION_MODE** | UI Runner在用例之前初始化失败 |
| UI创建/编辑/持久化/删除 | **NOT RUN / BLOCKED_AUTOMATION_MODE** | 同上 |
| UI取消草稿 | **NOT RUN / BLOCKED_AUTOMATION_MODE** | 同上 |
| UI地图选点/坐标持久化 | **NOT RUN / BLOCKED_AUTOMATION_MODE** | 同上 |
| UI文本/Markdown/ICS导出 | **NOT RUN / BLOCKED_AUTOMATION_MODE** | 同上 |
| UI五提供商SecureField/测试Keychain | **NOT RUN / BLOCKED_AUTOMATION_MODE** | 同上 |
| UI英文smoke | **NOT RUN / BLOCKED_AUTOMATION_MODE** | 同上 |

xcresult summary `totalTestCount=2, failedTests=2` 的两项分别是实际 WeatherKit XCTest 和 **Runner基础设施错误**；不能解读为2个产品用例失败，不能把7UI写成执行失败或通过。UI实际执行0个、截图0张。已导出真实天气错误JSON附件1个，不虚构屏幕附件。

Runner错误：`MapToDoUITests-Runner (1947)` failed to initialize for UI testing，`com.apple.dt.XCTest.XCTFuture Code=1000` / `Timed out while enabling automation mode.`，log:1162/1195。

## 证据文件

- `DEVICE_EVIDENCE/UI-and-weather-first.log`
- `DEVICE_EVIDENCE/UI-and-weather-first.xcresult`
- `DEVICE_EVIDENCE/UI-and-weather-first-summary.json`
- `DEVICE_EVIDENCE/UI-and-weather-first-attachments/manifest.json`
- `DEVICE_EVIDENCE/UI-and-weather-first-attachments/7AE734E4-A3E0-4553-B554-2ED546297C9C.json`，名称为 DEVICE_LIVE_WEATHERKIT_FAILURE。
- `DEVICE_EVIDENCE/UI-first-profile-public.json`：当前App profile的team/bundle/device匹配、WeatherKit=true、time-sensitive=true，未输出私钥。

本次已运行候选可执行文件 SHA256 `d758b65b4dc2f86a8b66d7ae7f9e5e318ae0f00bc1233ed34113887fc4c16790`；debug dylib `fc8421eadaf35861adc7a1074e1d08a299f9ad404ec02bde40cac43d1c6d27fe`。后续候选另记，不能复用本结果冒称最终代码通过。

## Automation mode只读诊断与必要操作

- 失败后重新读设备：passcodeRequired=false，unlockedSinceBoot=true，DDI build17F113、contentIsCompatible=true、isUsable=true、XCTest-24904，设备能安装/启动且实际执行app-hosted XCTest。
- Xcode26.6包含iOS26.5 SDK，但[Apple release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_6-release-notes)与[官方support表](https://developer.apple.com/xcode/system-requirements)给出的设备调试支持为iOS15及以后。因此不能仅因iOS27.0.1高于SDK就断言版本不兼容；这些信息也不证明UI自动化协议没有问题。
- CLI目前无法确认iPhone“设置→开发者→启用UI自动化”开关或屏幕上的单独AutomationMode授权。请用户本人检查开关，并在下一次已协调的XCTest启动时关注屏幕：若出现Enable UI Automation/输入设备密码授权，用户本人输入并确认。未观察到提示前，不能断言它已出现。
- [Apple开发工具工程师说明](https://developer.apple.com/forums/thread/693273)将该设备密码提示解释为额外安全授权，并说明没有受支持的自动密码输入方式。该讨论由iOS15起，不能据此保证iOS27本例原因或一次操作必然修复。不移除密码、不修改系统安全设置、不盲目重试。

## WeatherKit诊断边界

当前签名与embedded profile均包含WeatherKit，实际服务仍AuthCode2。根据[Apple官方账户文档](https://developer.apple.com/help/account/services/weatherkit/)，App ID需同时在App Services和Capabilities启用WeatherKit。主会话检查账户后台；本agent不改账号设置、不读取私钥、不改用未授权天气服务。App Service尚未核验，不把它缺失当作已确定根因；若两处都正常，仍须排查Apple认证/backend问题。

重任务资源已交回主会话；后续重试需主会话独占放行和设备自动化前提确认。本轮没有真实购买、未知API Key请求、模拟器启动或用户真实Keychain修改。
