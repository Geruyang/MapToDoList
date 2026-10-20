# 最终真机逻辑与 UI 测试准备

**USER RESUMED**：用户明确恢复真机测试，主会话已授予本轮唯一重资源slot。候选源码冻结，执行29项UI-review回归，start<70%、stop75%、jobs1、无并行/无模拟器，保留历史证据。此前暂停期间未执行设备操作。

主会话转达用户已确认启用iPhone UI自动化；旧AutomationMode阻碍尚需实际重试证实解除。当前只准备，不build/test，等全员源码冻结与唯一重任务授权。

2026-10-11 08:56 UTC轻量memory_guard sample **69.1%**，高于68%启动门槛；如果运行时仍达到该值，guard必须拒绝启动，不能放宽75%停止阈值/用户80%硬限制。

准备命令：`bash docs/testing/DEVICE_RUN_FINAL_SUITE.sh`。唯一真机destination `00008150-00066CE13C43C01C`，jobs1，parallel NO，guard68/75，正常自动签名，复用DeviceData缓存。

最新冻结源码预期：**48项逻辑 + 1真实WeatherKit + 18UI = 67case**；实际数量与pass/fail/skip以xcresult为准。跳过StoreKitLifecycleTests，不执行真实购买。逻辑包括新增2AI（store:false、临时UUID）、1Keychain恢复错误提示及2Reminder（曾排程提前提醒去重、编辑后重排），此前44case不覆盖这些新增断言。

新证据文件：`DEVICE_EVIDENCE/Final-logic-and-ui.log` 与 `.xcresult`；旧包保留。脚本若发现已有同名文件/结果拒绝覆盖，重试必须新名字。

物理操作与外部环境注意：全部UI中有通知拒绝场景（权限已决定会明确skip）、LiveMapSearch（服务不可用状态可明确skip）、AppStore.sync恢复入口（可能弹Apple账户认证，需要用户本人处理，不能输入未知密码/账户）。没有purchase点击；API配置仅使用独立测试service无效sentinel且不进行AI联网调用。UI数据隔离，不修改用户真实Keychain。

完成后导出全部case、UI截图/自动audit附件、实网Weather JSON与memory实际峰值；保持产品缺陷、测试脚本缺陷、外部阻碍与skip不同口径。用户已授权UI模式不等于测试已经通过。

## 最新适配与准入

UI owner资源已freeze；DEVICE agent在主会话明确授权下仅适配必要UI用例：AI密钥删除先验证确认dialog、取消保留、再次确认删除、metadata无Key/禁删状态；无demoAccess历史导出用例增加读取现有事项、只读标题/保存禁用的断言后继续完整导出语义。仍为18UI用例，不削弱既有断言。

主会话更新PrivacyInfo：OtherUserContent与PreciseLocation，linked=true、tracking=false、purpose functionality+other；此前Release归档是中间候选，最终归档必须包含该新声明与后续UI修补。

最新轻量sample **69.7%**，总内存12GiB：至少再下降约209MiB才能低于68%准入，下降约578MiB可达65%较好headroom；到75%stop还有5.3个百分点。当前不启动、不反复执行会拒绝的build命令，不终止用户App，等待主会话调整任务占用后再实际guard准入。

主会话随后明确授权本轮物理设备独占任务将启动门槛调整为 **<70%**，停止门槛仍 **≥75%**，不关闭用户App，不启动sim。理由：此前实际真机增幅较小（约1.3个百分点；Release约4.8个百分点），75%中断继续保留距用户80%硬上限的余量。脚本已据此更新，只尝试本轮唯一任务；实际起点若≥70%则拒绝并报告，不继续上调阈值。
