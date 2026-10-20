# 独立代码审查（集成中候选）

审查时间：2026-10-11；状态：原两项 findings 与手工选点时区路径已复核修复；当地时间显示一致性仍建议统一。

范围：Core、App、地图/事项、通知、导出、本地/AI规划、天气、原生 UI、订阅、`project.yml` 与 Configuration。此为源码审阅，不能替代真机运行。工程仍在整合，不将当前行号视为最终交付行号。

## [P1] AI 子集预览遗漏未选中事项冲突

位置：`MapToDo/Features/Planning/PlanningView.swift:64` 和 `MapToDo/Features/AI/AIService.swift:54`。

规划页面仅将选择发送的事项传给 AIService；parse 仅对该子集重建 proposed 并检测相邻重叠。未选中固定事项不在检测范围内，且 TaskStore.replaceSchedule 仅校验固定状态与窗口。因此 AI 只要建议把选中灵活事项放到未选中固定事项的时间，预览就显示零冲突并允许应用，最终行程重叠。

复现：固定事项 F 为 01:00–02:00；灵活事项 L 为 00:00 最早开始、04:00 最晚结束、60 分钟。只选择 L 发送，模型返回 L 开始 01:00。真实 parser 输入 `[L]` 得到 changes=1/conflicts=0；输入完整 `[L,F]` 得到 changes=1/conflicts=1。

已执行独立 harness `docs/testing/DEVICE_REVIEW_REPRO.swift`，直接编译真实 TaskItem/AIConfiguration/AIService/LocalPlanner 源码，未联网、未访问 Keychain、未修改 App 数据。命令：

```sh
xcrun swiftc MapToDo/Core/TaskItem.swift MapToDo/Features/AI/AIConfiguration.swift MapToDo/Features/AI/AIService.swift MapToDo/Features/Planning/LocalPlanner.swift docs/testing/DEVICE_REVIEW_REPRO.swift -o /tmp/waypoint-device-review-repro
/tmp/waypoint-device-review-repro
```

输出：

```text
selectedOnly changes=1 conflicts=0
completeSnapshot changes=1 conflicts=1
REPRODUCED: selected-only validation misses the unselected fixed event overlap
```

建议：继续只发送选中事项；在本地使用完整未完成事项快照验证返回变更及冲突，应用前再次核验完整快照。新增未选中固定事项冲突回归测试。

## [P2] 地图搜索新建事项遗漏地点时区

位置：`MapToDo/Features/Map/MapScreen.swift:77`。

主地图搜索结果创建 TaskItem 时未传入 `item.placemark.timeZone`，模型默认使用 `TimeZone.current.identifier`。因此美西设备搜索东京、直接从结果创建时，事项标记 America/Los_Angeles，DatePicker 和导出把设备时间当东京当地时间，与明确的地点当地时间要求不符。地点更换入口 `TaskEditorView.swift:81` 已使用 placemark.timeZone，两个入口不一致。

复现：设备时区 America/Los_Angeles → 搜索东京地点 → 直接打开新建 → 查看时区文本，显示美西时区；再在编辑器里更换到同一地点，才更新为东京时区。地图任意点击也没有时区查询，应有明确时区选择/解析或说明，而不能默认宣称地点时间。

建议：搜索结果透传有效 placemark 时区；无法解析的地图点击提供明确可选时区/降级说明。增加跨时区事项创建与导出回归测试。

## 本次未发现可证实的同级缺陷的重点路径

- 密钥只写入本服务/账号的 Keychain 条目，使用 WhenUnlockedThisDeviceOnly；不存在源码 Key、UserDefaults Key 或输出 Key 的日志路径。
- StoreKit 权益来自 verified currentEntitlements，并检查产品 ID、过期和撤销；DEBUG demo 绕过限定测试启动参数，Release 分支返回 false。
- TaskStore 对损坏/重复 ID/无效内容进入只读状态，保留原文件；写入先完成原子保存才发布新 tasks。
- replaceSchedule 拒绝固定事项修改或越过灵活窗口，批量变更失败不会部分写入。
- 通知同步通过 revision 与 synchronizing 合并重入，取消 owned 请求后重新安排最新快照；通知数量限制为最近 60 个，超限有说明。
- 导出按设备 Calendar 的日边界和 exclusive next-day 边界包含末日全天；单项输出使用事项时区；ICS 使用 UTC、TEXT escaping 与 75-octet 折行。
- 天气仅用命中该小时的预报；无数据时抛错，不把当前天气伪装成远期预报；真实 WeatherKit 签名能力与网络成功仍待设备验证。

这些结论仅说明所读代码路径；不声明服务调用、实际通知投递、订阅交易、UI 可访问性或电量测试通过。

## 修复复核

### P1 已关闭：AI 子集冲突

最新 `AIService.swift:72` 新增 validate，使用 allTasks 未完成事项构造完整 proposed；`PlanningView.swift:97` 将 sourceTasks 传入。应用前仍要求 sourceTasks == store.tasks，预览有冲突时禁止应用。

独立 harness 更新后实际运行结果：

```text
selectedOnly changes=1 conflicts=0
completeSnapshot changes=1 conflicts=1
locallyValidated changes=1 conflicts=1
FIX VERIFIED: complete local validation blocks the unselected fixed event overlap
```

原 parser 仍对发送子集检查，而完整本地 validate 补上未发送事项；这符合 AI 数据最小化要求。属于轻量逻辑验证，不是联网 AI 或真机通过。

### P2 搜索入口已关闭；手工选点入口仍有同类差距

最新 `MapScreen.swift:112` 搜索新建显式透传 `item.placemark.timeZone`，原搜索入口遗漏已修复。

仍需处理：`MapScreen.swift:45` 任意地图点击使用 TaskItem 的设备时区默认值；`TaskEditorView.swift:35` 确认默认上海也未设 Asia/Shanghai，且当前编辑器无时区 Picker。美西设备手工选东京或明确确认上海时，时间仍按美西；文字改为“时间显示时区”只说明实际值，未达到地点当地时间要求。已发协调者，建议提供明确时区选择，并给默认上海确认设置 Asia/Shanghai。若最终不处理，须把该路径限制写入交付。

最终候选的哈希由主会话统一记录；本报告截至当前已读源码，不宣称后续新增英文资源/Qwen地域设置已审查。

## 后续轻量复核（无构建/模拟器）

- 手工选点差距已关闭：MapScreen:147 反向 geocode；request ID 防止过期响应覆盖；8秒超时明确设备时区降级。TaskEditorView:52–58 与 :110–114 提供手工时区 Picker。默认坐标改为旧金山，默认位置文案不再冒称上海。
- Qwen 地域：默认新加坡；各地域 Keychain account 隔离；AIService 实例捕获 region/workspace，确保请求主机与读出的地域密钥一致。Workspace 只接受字母数字连字符，不能注入任意主机。没有进行未知 Key 实网调用。
- 尚建议统一当地显示：Theme.swift:47 时间行、PlanningView.swift:43 新旧预览、WeatherCardView.swift:52 天气小时仍使用默认设备时区，编辑器 DatePicker 与导出则使用事项时区。海外跨时区情况下同一事项在不同界面会显示不同小时。已建议主会话任务行/规划预览显式事项时区、天气卡接收编辑器时区；今日分组按设备日可明确标注。该建议待最终源码复核。
- 真机环境候选已实际签名/安装/启动，证据独立记在 DEVICE_ENVIRONMENT.md；不将环境候选视为最终源码候选。

跨时区显示补丁已轻量复核：TaskItem.swift:57 的 LocalTimeFormatter 为每次显示显式设置事项 zone，并用对应 date 计算缩写（包括 DST）；Theme.swift:47 与 PlanningView.swift:43 使用事项时区；WeatherCardView.swift:5/:53 读取显示时区，TaskEditorView.swift:79 注入 draft.timeZoneIdentifier。原列表/预览/天气小时不一致建议已关闭。此结论仅为源码复核，未违反独占约束启动编译或模拟器。
