# R31 Restore / Map 独立复核

2026-10-11，device_tests。只读产品源码；仅修改授权的 `MapToDoUITests/WaypointUITests.swift` 单个恢复测试。未构建、安装、启动设备、购买、调用 AppStore.sync 或处理账户密码。

| 文件 | SHA-256 |
| --- | --- |
| SubscriptionStore.swift | cc9688cd3d7c941fb4707663e90355fdf62f1a4bc1608b147f9ac6818e132ce9 |
| SubscriptionView.swift | 9c895839d67e3cbd875e34fe4ded3dee32b02fd60bb5beb5bb1c331c46418c3c |
| SubscriptionTimeout.swift | b948e2d1555925885fe0b4e853d781fcd98ca1bf0ee11dc0ac05fbe3b4fc36f9 |
| SubscriptionConcurrencyTests.swift | c907264950c65457d14483dc79eb9558e65e904b19a7f1921d392b0aa3f32e11 |
| MapLocationService.swift | bf275ecf0be4d997f3e0644d718f7b9c53ba1a7454b4476254332e6c8f6301c8 |
| MapScreen.swift | 3d7dd57a1e08a22d97d08bd6614ff1b8026f682bd74be4f0d52dbce28e135671 |
| MapTests.swift | b98526fdaf0beadb707819ef5d447379fb9b9b4c77674a609c8e82548a0edd26 |
| WaypointUITests.swift 更新后 | e97ff5032bf76f0d50f9b198e926cde4b5b73478b8fd0638344201f81d94a7a3 |

恢复：sync 默认 120 秒，读取权益另有 15 秒。Stop 先清 restoreOperationID、busy/phase，再取消本机 waiter；269/285 行在 sync/reader 返回后都检查 operationID 与 cancellation。旧 waiter 的 defer/catch 也检查身份，不能覆盖新的恢复状态。stop 不声称取消 Apple 交易，不全局禁用后续真实 Transaction.updates 对 verified 权益的重新核对。只读未发现新确定性 P1。

9 项 SubscriptionConcurrencyTests 的目标为旧快照/新撤销排序、应用时已过期、卡住价格加载时继续核对权益并允许重试、sync 与 reader 独立期限、非合作 sync 超时、reader 超时、停止等待文案及 busy、停止后旧 sync、停止后旧 snapshot 与后续合法授予/撤销。晚结果部分用单次 Task.yield 观察，不能把它说成系统真实交易已回调的证据；生产的身份门控与 timeout 单次 winner 同时参与隔离。该版执行状态由 parent 运行产物决定，本轮 NOT_RUN。

地图：MapLocationRequestState 仅 explicit pending intent 可 finish，finish 立即消费 intent；MapLocationResult 每次完成有独立 UUID。MapScreen 监听 result.id，因此同坐标再次定位与仅经度改变都能重新移动相机。失败完成含 nil coordinate，消耗 intent 而不移动；初始与 cancel 后孤立回调被拒绝。新增三项纯测试覆盖这些目标，MapTests 总计六项。它们不等于真实 CoreLocation 权限/定位服务通过，也未覆盖 cancel 后立即发起另一请求时旧系统回调与新 intent 的重叠；当前 SDK 回调本身没有独立 request token，本次不把该未覆盖情况夸大为已证实缺陷。

UI 恢复方法调整：等待可观测 Stop 或真实结果，预算 145 秒覆盖 120+15；等待中核验 Done 和 Stop 可达；停止后验证准确文案、busy 消失、retry enabled/hittable（只检查，不再发第二次 sync）。真实快速返回走实际结果分支。出现系统账户 alert 则明确 XCTSkip，等待用户完成，不读/填/取消密码。不再假设清 UI 测试数据会撤销已有 Apple 权益；记录初始 hasAccess 后验证停止/失败/超时没有凭空授予无权益账号。

`git diff --check` 通过；未 parse/build/test。没有削弱 Stop 文案、请求可重试或无虚假权益断言。

## 后续 R31 map4 实际失败定位与采证补充

parent 运行记录 `DEVICE_EVIDENCE/R31-map4.log`：四例均在原 helper line187 查询 `map.selection.confirm` 三次后 isHittable 断言失败；尚未执行 coords/cancel/confirm/save。必须撤回将此行误读为坐标故障的归因。其他 56 项逻辑通过以 parent 的真实产物为准，本轮未重跑。

existing 视频导出末帧 `R31-map4-attachments/4ACCBBEA-CBAC-4035-A6AE-7929A3BA4475-last.png` 经本 agent view_image：地图预览、事项名、31.22310/121.44530、打开事项及取消选择均完整可见，无键盘/系统 modal。该帧是 derived video frame，不冒称原始失败截图。point 视频的 `15649976…-last.png` 已到 teardown 后 Springboard，不能据它判断按钮。旧 snapshot `533AC52F…` 仅有 application root 与空 children，不能提供实际按钮 ID。

MapScreen parent VStack 的 `map.selection.card` 与 AnyLayout 包含的子按钮 ID 可能存在 SwiftUI AX 桥接覆盖，但静态和现有附件不足以证实。中文真实按钮 label 由资源核对为“打开事项”/“确认地点”/“取消选择”；英文为 Open task / Confirm place / Cancel selection。仅在新完整 UI 层级确认 Button type/label 可定位且 ID 失真时，才可考虑精确 label locator，继续保持 isHittable 与实际 tap 验证。

获授权 helper ONLY 新增断言前完整 `app.debugDescription` 文本附件及截图，原 marker、未开 editor、confirm/cancel hittable 与坐标返回断言全部保留。新 `WaypointUITests.swift` SHA 为 `6571497892a8dd1f49ecd8c3ff24cf842cc1ed1cb8c3e7372b1dcf586f687756`。此采证源码 NOT_RUN，无产品修改或设备操作。

## R31 ui3 结果及 R32 测试修正

parent 实测终局：EN 1 PASS，AI 1 FAIL，Restore 1 SKIP，peak71.8%。AI 三厂商 save/delete 循环均执行完，但 relaunch 后长 Form 未滚动便读取 ai.provider.label/value，Find retry 后失败，整例仍 FAIL。R32 单点补 `scrollToElement(ai.provider)` 与 `savedProvider.isHittable`，再执行原 DeepSeek 持久化、Gemini/OpenAI 隐藏及 SecureField 断言。与 Map 采证合并后 UITests SHA 为 `0ee42d777fab55c74a6b35f4d4d1aa1d267108250ceb737600d8b54ec7566ce0`，diff-check 通过，未构建/执行。

Restore 原始 activities：09:19:18.117 点 Restore，09:19:19.917/19.950 检测 Springboard alert，随后 teardown。该 case 单独导出 manifest 为 `DEVICE_EVIDENCE/R31-restore-alert-attachments/manifest.json`；没有原始 PNG/完整系统 AX 树，含视频 `562DCF69-F050-4D7E-B0BA-1861584C7424.mp4`。

只读使用 avconvert Passthrough 截取原视频 13–13.6 秒并 QuickLook 生成 `restore-alert-at13s.mov.png`（derived frame，非原始 XCTest 截图），本 agent 已 view_image：标题 **Sign in to Apple Account**；Apple Account / Password 均为空输入 placeholder，Cancel/OK、键盘可见。没有 Sandbox / Environment 文本或购买确认信息。故这次 SKIP 的实际阻塞为系统 Apple 账户登录，不能泛称 Automation 提示，也不能凭商品数据或该提示认定 Sandbox 交易环境。未填账号/密码、未点系统确认/取消、未再次调用 sync。已及时报告 parent 请求用户必要操作；现有账号已登录的用户反馈与这次系统提示同时记录，不要求用户重复不相干的 Runner 信任步骤。
