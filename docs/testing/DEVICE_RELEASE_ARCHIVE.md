# Release 签名归档验证

状态：**Release archive PASS**，exit0，ARCHIVE SUCCEEDED，采样内存峰值68.9%。2026-10-11 08:46:18UTC生成。先等OpenAI Responses `store:false` 与发送披露修补冻结后，才执行本次归档，因此包含该最新修补、修复后图标与C617.1 manifest。

## 预检与修复

- Release有效配置：Swift5、wholemodule、`-O`，不存在DEBUG编译条件；iOS17+，bundle `com.waypoint.maptodo`，team `VA8X63NPCS`，Automatic，AppIcon资产配置。
- AccessPolicy demo权限、TaskStore test文件/reset/seed、AIKeychain测试service均在 `#if DEBUG` 内；Release不会因测试启动参数获得demo写权限或重置数据。
- 原图标虽1024x1024无alpha，实际RGB全部0、只有1种颜色，是损坏的全黑图。UI owner修复原生绘图脚本与资产后，本agent独立检查1024x1024 RGB、597种颜色、无alpha，并实际查看森林绿地图pin/check，问题关闭。
- ExportView:74–75用`.contentModificationDateKey`读取自身临时导出目录文件时间戳；原PrivacyInfo只列UserDefaults CA92.1。本agent在主会话授权下新增FileTimestamp C617.1，`plutil -lint`通过。[Apple官方理由](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons)适用于访问自身容器文件元数据；声明对应实际自身temp清理路径，不读取其他App文件。
- Info.plist与entitlements plutil均通过；包含WeatherKit/time-sensitive能力及定位用途文本。

## 计划命令与边界

单jobs1、memory_guard start<68%、stop≥75%、真机SDK generic iOS、Release archive；不启动sim/UI，不upload/submit，不导出私钥。使用新log/xcresult/archive路径，旧测试证据保留。

实际执行：

```sh
python3 scripts/memory_guard.py --start-below 68 --stop-at 75 -- xcodebuild archive -project MapToDo.xcodeproj -scheme MapToDo -configuration Release -destination 'generic/platform=iOS' -jobs 1 -allowProvisioningUpdates -derivedDataPath build/DeviceData -archivePath build/release/Waypoint-Release.xcarchive -resultBundlePath docs/testing/DEVICE_EVIDENCE/Release-archive-first.xcresult DEVELOPMENT_TEAM=VA8X63NPCS
```

## 产物实际核验

- 归档：`build/release/Waypoint-Release.xcarchive`，App路径 `Products/Applications/MapToDo.app`。
- Bundle/version：com.waypoint.maptodo，1.0.0 (1)，arm64。
- `codesign --verify --deep --strict` exit0，签名身份 **Apple Development**，teamVA8X63NPCS，get-task-allow=true。这是Release编译的开发签名归档，尚未导出App Store分发签名包；没有upload/submit/export私钥。
- 真实签名entitlements和embedded profile均包含WeatherKit=true、time-sensitive=true；application identifier为VA8X63NPCS.com.waypoint.maptodo。
- 归档内PrivacyInfo.xcprivacy实际包含UserDefaults CA92.1与FileTimestamp C617.1，plutil通过。
- 归档内编译图标有120x120与152x152，原生ImageIO解码后的120图标有365种颜色，独立查看正确地图pin/check。Apple优化PNG不能直接由Pillow解码，已通过sips只读源文件并生成QA副本，未修改归档。
- Release可执行文件strings核查：`--uitesting`、`--demo-access`、`--seed-demo`、`--reset-data`、测试JSON文件名、测试Keychain service全部不存在；归档编译log没有 `-D DEBUG`。
- 可执行文件SHA256：`2bf5e895bddf839653bdf34d0befa41d5d179f136ca1a62d1b33fc82e12819bb`。
- xcresult build summary为0 error、0 tracked warning；原始log有1条metadata工具warning：`Metadata extraction skipped. No AppIntents.framework dependency found.`（本App没有声明AppIntents依赖）。没有签名/资产/隐私编译警告，两种计数口径已分清。
- 采样内存峰值68.9%，低于75%停止门槛与用户80%硬上限；归档完成立即交还重任务资源。

## 证据与未覆盖项

`DEVICE_EVIDENCE/Release-archive-first.log/.xcresult`、`Release-archive-build-results.json`、`Release-archive-entitlements.plist`、`Release-archive-verification.json`、`Release-compiled-icon.png`与`Release-preflight.json`保留全部实际证据。

UI自动化仍等待设备安全授权；本次不跑UI/模拟器/购买。AI新增两项store:false和临时ID逻辑测试尚未在先前44case中执行，后续最终逻辑回归须补充；本次仅证明最新Release源码能优化编译归档与签名。商店分发包、App Store后台配置与审核不由archive成功替代。
