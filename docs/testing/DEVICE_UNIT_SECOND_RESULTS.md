# 第二轮真实设备逻辑与 WeatherKit 结果

**44/44 PASS，0 FAIL，0 SKIP**：43 项最新逻辑测试 + 1 项真实物理设备 WeatherKit 联网测试。退出 0，TEST SUCCEEDED。没有 UI 或模拟器、没有 StoreKitLifecycle、没有真实扣费/未知 Key 请求。

2026-10-11 08:34:35–08:35:00 UTC（设备控制台中国时区16:34–16:35）；iPhone 17 Pro Max，iOS27.0.1 (24A446)，Xcode26.6 (17F113)，App1.0.0 (1)，开发团队VA8X63NPCS。

主会话已核查并启用App ID的 WeatherKit App Services（之前仅Capabilities开启）；证据由主会话保存在 `docs/release/evidence/weatherkit-enabled.png`。本agent重新xcodegen纳入最新源码，使用allowProvisioningUpdates与正确team进行实际真机单测。当前App embedded profile包含正确bundle/device/WeatherKit/time-sensitive，codesign strict验证通过。首轮AuthCode2失败保留，不抹去；修正后本轮真实服务成功。

## 运行与资源

```sh
python3 scripts/memory_guard.py --start-below 68 --stop-at 75 -- xcodebuild test -project MapToDo.xcodeproj -scheme MapToDo -destination 'platform=iOS,id=00008150-00066CE13C43C01C' -jobs 1 -parallel-testing-enabled NO -maximum-concurrent-test-device-destinations 1 -allowProvisioningUpdates -derivedDataPath build/DeviceData -resultBundlePath docs/testing/DEVICE_EVIDENCE/Unit-and-weather-second.xcresult -only-testing:MapToDoTests -skip-testing:MapToDoTests/StoreKitLifecycleTests DEVELOPMENT_TEAM=VA8X63NPCS
```

只占用已获放行的唯一重任务；采样内存峰值 **63.3%**，未触发75%停止阈值，结束后立即交回资源。首轮结果包未覆盖。

## 实际服务 payload

公开旧金山坐标 37.7749, -122.4194；fresh WeatherProvider actor；请求08:34:58Z，完成08:34:59Z。

| 数据 | 实际响应 |
| --- | --- |
| 当前天气 | 晴朗无云，11.8793°C，降水概率0，sample08:34:59Z，isForecast=false |
| 一小时后目标 | 目标09:34:58Z命中09:00Z逐小时预报，晴朗无云，11.9200°C，降水概率0，isForecast=true |
| 天气缓冲 | 当前和预报均0分钟（本响应条件） |
| 归属 | Apple Weather；实际合法归属URL https://weatherkit.apple.com/legal-attribution.html；实际light/dark mark URLs由WeatherKit返回 |
| 单个实网用例 | testLiveWeatherKitCurrentForecastAndAppleAttribution，PASS，1.649s |

原始响应JSON：`DEVICE_EVIDENCE/Unit-and-weather-second-attachments/E976EC27-DF1C-47F9-8765-B15F347824DD.json`，附件名称DEVICE_LIVE_WEATHERKIT_RESPONSE。测试验证温度finite、目标小时精确覆盖、预报概率范围、当前/预报类型与归属URL，不以固定天气数值作断言。

## 证据与边界

- `DEVICE_EVIDENCE/Unit-and-weather-second.xcresult`：正式Xcode结果包。
- `Unit-and-weather-second.log`：完整命令、构建、实际44case及memory peak。
- `Unit-and-weather-second-summary.json`：total44/pass44/fail0/skip0。
- `Unit-and-weather-second-tests.json`：xcresult完整测试树。
- `Unit-and-weather-second-cases.json`：实际case名称、结果与耗时。
- `Unit-and-weather-second-attachments/manifest.json`：1个真实服务JSON附件；没有UI截图，因为本轮没有UI用例。
- `Unit-and-weather-second-profile-public.json`与`Unit-and-weather-second-binary.sha256`：公开profile与当前二进制SHA256。

本轮43项逻辑测试证明相应逻辑在真机app-hosted环境执行；**不等于**实际通知投递、真实MapKit路线、Keychain UI交互、订阅Sandbox生命周期、完整可访问性或电量通过。WeatherKit current/+1h/attribution实网PASS；天气UI、缓存/断网/远期用户流程仍待UI/设备操作。

7UI仍保持首轮BLOCKED_AUTOMATION_MODE，未获用户确认设备单独自动化授权前不重试。后续最终候选如有新修改需独立标识，本结果不能冒充新增代码已测。
