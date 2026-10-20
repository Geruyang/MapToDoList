# 真机安装启动证据方案

构建由主会话统一执行。本 agent 不抢占构建，也不改签名设置。独立核验公开开发证书后确认真正团队 ID 为 `VA8X63NPCS`；首次误用证书 CN 括号值 `PX8ZG2Y7AH` 的构建失败，详情见 `DEVICE_ENVIRONMENT.md`。以下命令待主会话提供候选 signed `.app` 绝对路径后执行。

1. 记录候选 commit（若有）、bundle ID、短版本/构建号、签名状态、权限和证据时间。
2. 重新核验设备 available、Developer Mode、当前锁状态，避免用旧状态推断。
3. 安装候选，保存 `devicectl` 原始日志和 JSON；安装失败记录实际错误，不改团队或 provisioning profile。
4. 不带 `--uitesting` 或 demo 参数启动真实模式，记录启动 PID；查询 App 安装清单确认 bundle 与版本。启动应为空数据、无静默权限请求、无虚构订阅权益。
5. 对需要固定数据的自动化测试另用明确 DEBUG demo flags，不能将 demo 结果标为生产权益通过。
6. 需要 UI、锁屏、网络、Sandbox 的场景分别运行并保存证据。`devicectl` 安装/启动输出无法证明提醒投递、屏幕布局或订阅交易完成。

示例命令（`waypoint_candidate_app` 由协调者提供，不能误填为模拟器 App）：

```sh
waypoint_device_id=2050E692-2C1D-5D9D-967A-EABA499B386F
waypoint_evidence_dir="$PWD/docs/testing/DEVICE_EVIDENCE"
mkdir -p "$waypoint_evidence_dir"
xcrun devicectl list devices
xcrun devicectl device info lockState --device "$waypoint_device_id"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$waypoint_candidate_app/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$waypoint_candidate_app/Info.plist"
/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$waypoint_candidate_app/Info.plist"
codesign --verify --deep --strict "$waypoint_candidate_app"
codesign -d --entitlements :- "$waypoint_candidate_app"
xcrun devicectl device install app --device "$waypoint_device_id" "$waypoint_candidate_app" --timeout 60 --json-output "$waypoint_evidence_dir/install.json" --log-output "$waypoint_evidence_dir/install.log"
xcrun devicectl device process launch --device "$waypoint_device_id" --timeout 60 --json-output "$waypoint_evidence_dir/launch.json" --log-output "$waypoint_evidence_dir/launch.log" "$waypoint_bundle_id"
xcrun devicectl device info apps --device "$waypoint_device_id" --bundle-id "$waypoint_bundle_id" --json-output "$waypoint_evidence_dir/app.json"
```

只读取本 App 的公开签名与 entitlements，不读取私钥/Keychain用户内容，不导出设备全量应用清单，不向他人分享，不执行真实购买。设备标识仅为本地复现命令服务，序列号不进入报告。

devicectl 注意：launch 的 command-specific flags（如 --console / --terminate-existing）必须放在 bundle 之前，否则可能被作为 App 参数；进程 executable 是 URL，字符串过滤使用 `executable.path ENDSWITH "/MapToDo.app/MapToDo"`，不直接对 executable 使用 CONTAINS。

## 不能用命令输出替代的待跑项目

- 通知锁屏实际投递、声音/专注模式下实际表现、点击通知进入对应事项。
- VoiceOver焦点读出、触控目标、动态字体裁切、系统分享接收。
- 实际 MapKit/WeatherKit/AI 网络成功及断网恢复。
- 真机 Keychain 数据保护/锁屏访问，本地测试和 App Store Sandbox 中验证交易与恢复。
- Instruments/测量工具记录的电量、发热及后台活动。

若没有可用真机 UI 自动化或现场交互，应清楚写 BLOCKED（交互/观测能力），仍保留安装启动的真实成功或失败记录。
