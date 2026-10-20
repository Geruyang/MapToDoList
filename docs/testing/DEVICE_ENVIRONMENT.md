# 真机环境报告

检查时间：2026-10-11 00:55 America/Los_Angeles（07:55 UTC）。

本报告仅记录实际命令结果；环境检查通过不等于 App 功能通过。

| 项目 | 观测结果 | 状态 |
| --- | --- | --- |
| Xcode | 26.6，Build 17F113 | PASS：环境 |
| 真机 | iPhone 17 Pro Max（iPhone18,2），iOS 27.0.1（24A446） | PASS：可识别 |
| CoreDevice ID | `2050E692-2C1D-5D9D-967A-EABA499B386F` | 供运行命令使用 |
| 连接 | `available (paired)`；wired；tunnel connected | PASS：连接 |
| Developer Mode | enabled | PASS：环境 |
| DDI 服务 | available | PASS：环境 |
| 锁状态 | passcodeRequired=false；unlockedSinceBoot=true | PASS：当前可调试 |
| 签名身份 | 1 个有效 Apple Development、2 个 Apple Distribution | PASS：存在公开身份；没有读取私钥 |
| 工程与源码 | 检查时工作目录为空，尚非 Git 仓库 | PENDING：待工程生成 |
| 真机签名构建 | 尚未执行 | NOT RUN |
| 安装/启动 | 尚未执行 | NOT RUN |
| 7 项功能 | 待统一需求名称与候选构建 | NOT RUN |

证据命令：

```sh
xcodebuild -version
security find-identity -v -p codesigning
xcrun devicectl list devices
xcrun devicectl device info details --device 2050E692-2C1D-5D9D-967A-EABA499B386F
xcrun devicectl device info lockState --device 2050E692-2C1D-5D9D-967A-EABA499B386F
```

`security find-identity` 只查询公开证书身份。没有导出 Keychain、读取敏感 Key、修改签名配置或执行购买。设备序列号等无关标识不保存在报告中。

此前设备 unavailable 的观测已被本次 available 的结果取代。若后续连接状态变化，应新增实际结果，不能用本次环境 PASS 推断后续可用。

## 实际签名尝试与团队标识复核

主会话第一次真实签名构建失败，日志 `build/device-build.log:35` 与 `:36`：

```text
No Account for Team "PX8ZG2Y7AH".
No profiles for 'com.waypoint.maptodo' were found.
BUILD FAILED
```

因此当前安装与全部真机功能执行为 **BLOCKED_BY_SIGNING**，设备本身仍为 `available (paired)`。未对 unsigned/simulator App 执行安装，不移除 entitlements，不使用其他 App 的 profile。

随后独立只读核验公开开发证书，发现上次采用的 team ID 不正确：

```sh
security find-certificate -c 'Apple Development: Ge Ruyang (PX8ZG2Y7AH)' -p | openssl x509 -noout -subject -issuer -dates
```

证书 subject 的 `OU=VA8X63NPCS` 才是开发团队 ID；`CN=Apple Development: Ge Ruyang (PX8ZG2Y7AH)` 的括号值不是 team。证书有效期为 2026-09-03 至 2027-09-03。只查看证书公开内容，未访问私钥。

只读解码 Xcode UserData 目录现有 8 个 provisioning profiles：均为团队 `VA8X63NPCS`；存在含当前目标设备的开发 wildcard `VA8X63NPCS.*`，但全部缺少 WeatherKit 与 time-sensitive entitlement，没有可直接支持本 App 完整能力的现存 profile。没有写入或复用这些文件。

已建议主会话使用真正团队 ID `VA8X63NPCS` 和原始 entitlements 正规重新尝试自动 provisioning。该建议不等于构建已通过；需要新日志确认账户可用与新 profile 已获得。更早的 `No Account` 只证明对错误 team 的查询失败，不能据此断言真正团队也无账户。

## 第二阶段：真实签名、安装与启动成功

2026-10-11 01:10 America/Los_Angeles，协调者提供成功的 iphoneos 构建：`build/device-guarded.log:625` 为 BUILD SUCCEEDED。候选路径 `build/DeviceData/Build/Products/Debug-iphoneos/MapToDo.app`，版本 1.0.0 (1)，bundle ID `com.waypoint.maptodo`。

- `codesign --verify --deep --strict`：exit 0。
- 签名 entitlements：team `VA8X63NPCS`、application identifier `VA8X63NPCS.com.waypoint.maptodo`、WeatherKit=true、time-sensitive=true、get-task-allow=true，已保存 `DEVICE_EVIDENCE/entitlements.plist`。
- `devicectl device install app`：exit 0，确认安装正确 bundle；`install.json` / `install.log`。
- 正常 `devicectl device process launch`：exit 0、arguments=[]，PID 1830；`launch.json` / `launch.log`。
- 安装清单：Waypoint，com.waypoint.maptodo，1.0.0 (1)；`app.json`。
- 额外一次启动 PID 1833 后，01:11:18 与 01:11:39 的正确 `executable.path` 过滤均确认进程存在；`process-path.json` / `process-followup.json`。最后一次只读状态见 `process-latest.json`。

当前签名阻碍已解除。**签名能力 PASS、安装 PASS、启动命令 PASS、PID1833 的短时存活 PASS**；WeatherKit 实际网络返回、地图/通知/AI/StoreKit/UI/电量等各功能交互仍为 NOT RUN。未使用 demo、测试 Key、真实购买或启动任何构建/模拟器；遵守系统内存 80% 硬上限。

观测限制与命令纠正：PID1830 在启动 18 秒后未找到，原因不确定，没有崩溃堆栈，不能判定 App 崩溃。一次希望采集 console 的命令把 `--terminate-existing --console` 放在 bundle 后，devicectl 将它们当 App arguments（见 `launch-console.json`），实际仅额外启动；该文件不能当控制台/崩溃证据。随后改为 `executable.path ENDSWITH "/MapToDo.app/MapToDo"` 的只读进程查询取得明确存活证据，不再重复启动。

这一候选仅用于环境安装验证：协调者说明构建期间有少量源码更新，最终候选会重新构建。环境候选 executable SHA256 保存在 `DEVICE_EVIDENCE/environment-candidate-executable.sha256`，不能与最终源码哈希混用。

## 最新实际执行状态

2026-10-11 08:23 UTC首轮真实WeatherKit FAIL（AuthCode2），UI Runner AutomationMode超时导致7UI执行0项；结果完整保留在 DEVICE_UI_FIRST_RESULTS.md 与对应xcresult。随后主会话修正App ID的WeatherKit App Services开关。

2026-10-11 08:34:35–08:35:00 UTC第二轮真机app-hosted测试 **44/44 PASS，0 FAIL，0 SKIP**：43logic + 1真实WeatherKit current/+1h/Apple归属；exit0、guard采样峰值63.3%。全部实际服务数据与case列表已导出，详情见 DEVICE_UNIT_SECOND_RESULTS.md。

此时WeatherKit签名能力与实际服务均PASS；UI/锁屏通知/真实地图路线/StoreKit Sandbox/完整a11y/电量等仍待跑，7UI继续BLOCKED_AUTOMATION_MODE。未更改设备安全设置、未真实购买、未调用未知Key。本页前文是环境演进记录，最新状态以本节与第二轮结果为准。

## 下一步运行门槛

1. 获取统一的 7 项功能需求与最终集成候选版本。
2. 只读检查 bundle ID、部署版本、权限描述、后台能力、通知配置与签名构建设置。
3. 构建给该真机的 Debug App；任何签名失败按原始日志记录，不自动修改凭证或项目签名配置。
4. 使用 `devicectl device install app` 安装，`device process launch` 启动；记下结果和对应构建身份。
5. 分开报告安装/启动、自动化功能断言、手工设备行为。未执行的场景保持 NOT RUN 或说明具体 BLOCKED 原因。
