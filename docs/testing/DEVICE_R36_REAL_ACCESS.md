# R36 真实订阅解锁完整回归

2026-10-11，device_tests 独立只读核验日志、xcresult、冻结 inputs/bundle SHA 与 R35 交易附件。本轮未改测试或启动设备/build。

**实际 1 PASS / 0 FAIL / 0 SKIP**：`WaypointUITests/testRealSubscriptionUnlocksCreateEditPersistAndDeleteWithoutDemoAccess()`，88.257 秒，exit0；内存 baseline57.32%、peak58.07%。`R36-real-access.xcresult` 独立 summary 已保存为 `DEVICE_EVIDENCE/R36-real-access-independent-summary.json`；日志为 `R36-real-access.log`，附件 manifest 为 `R36-real-access-attachments/manifest.json`。

通过范围：三次 launch 都 demoAccess:false，只操作 UI 测试任务 namespace；实际“订阅有效”、无本地测试权益标识，无只读、title 为 enabled 输入及 Save enabled；disposable事项创建→原生全选精确替换编辑→Save→重启后真实权益仍 active→精确标题持久化→删除→再次重启任务不返。没有该用例主动 purchase/sync/SKTestSession，不触碰用户生产任务，不缩短/放松标题断言。

冻结测试 SHA 为 `b562f7aa99f8e403b93f271ad6f9e8e452c6e9aa913134ebaa1d9b2536344175`。独立比较 R35/R36 两份 94-file bundle manifest，所有 Main App 文件 hash 相同；变化仅 Runner executable、测试 bundle/调试产物及其签名。source inputs 仅 UITests 变化。故 R36 完整通过验证的是已安装 R35 产品修补配合确定性输入 helper；不把旧 R35 拼接标题的失败删掉。

R35只读附件 `2676560F-06A9-4D56-9E63-AB99C39ED79E.json` SHA `abd971098e0bed6fe699e711c92f5b9039adcab1950f4913d605193b6ee0f88d` 已亲读：current仍空，latest/status交易均verified exactSKU Sandbox、subscribed、expiry17:33:32Z >now16:48:16Z、无撤销/upgrade；Appcached hasAccess由false变true。结合 R36 无demo的实际写入/重启完整通过，原“Apple有效订阅但App仍只读”的缺口有闭合证据；单独 query PASS不代表购买交互通过，二者证据分别保留。

**Restore 尚未闭合**：R35 restore UI 整例 FAIL 在“停止等待后 busy消失”。原日志15.48–15.55秒明确识别 late系统 **Sign in to Apple Account** alert；不是仅凭anyAlert猜认证。该提示在尝试tap Stop时出现，XCTest默认 interruption handler主动点系统Cancel，再合成 App事件；不是我们测试代码填/取消账号。不能把被系统中断后的失败直接认定产品 stop逻辑坏了。需用户认证状态明确后独立验证实际 Stop/Done/重试和restore真实结果；这次未证明真实Sandbox恢复完成。交易续订、到期/撤销、通知锁屏投递等仍各自保留覆盖缺口。
