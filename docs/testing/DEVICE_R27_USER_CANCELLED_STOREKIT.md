# 用户报告取消后的 R27 只读 StoreKit 状态

2026-10-11。用户反馈试用按钮显示购买取消、恢复超时、从未出现Sandbox购买面板，未购买。root授权现已安装R27的一次独立只读diagnostic；没有编译、安装、purchase、AppStore.sync、购买史reset、SKTestSession或账户日志访问。其他source新改动未入此次R27。

用户明确撤销旧内存限制。本次使用新的sampling-only wrapper，**没有start/stop阈值或memory kill**；jobs1、无并行、唯一heavy slot保持。原历史guard文件/证据未删除，不把已撤销阈值沿用于此次运行。

## 真实结果

`R27-user-cancelled-storekit-readonly.log/.xcresult`，summary **1/1PASS、0FAIL、0SKIP、exit0**，运行1.682s；baseline68.78%，最高采样69.64%。开始/结束只读ps均为0个残留xcodebuild/xctest进程，slot已释放。

真实脱敏payload：`R27-user-cancelled-storekit-readonly-attachments/A5401B0B-B8E1-4E57-8F78-9B76940CD45C.json`。

| 字段 | 实际返回 |
| --- | --- |
| Storefront | USA / 143441 |
| Product | com.waypoint.maptodo.annual |
| 类型/周期 | Auto-Renewable / 1 Year |
| 年价 | 9.99 USD / US$9.99 |
| Intro | FreeTrial / 7 Day / USD0.00 / periodCount1 |
| Eligible | true |
| currentEntitlements | [] |
| Sandbox transaction environment | UNPROVEN：无匹配已验证交易可读取 |
| canMakePayments | NOT_COLLECTED：现有method不包含，未为此改source |
| purchase / restore / reset attempted | 全部false |

**PASS仅适用于实际商品/资格元数据断言，不代表购买、恢复、试用权益或Sandbox生命周期通过。** 当前没有 matching entitlement，与用户“未购买”反馈一致，但不能由空数组推断用户取消的具体原因。Product可获取不能证明支付权限、正确Sandbox登录或某次购买面板环境。

本次只读own-run log未发现purchase cancellation/error事件；因为没有调用purchase，它不能解释前一次用户操作。没有扩大到sysdiagnose、账户日志、密码或认证数据。root/subscriptions继续依据源码和必要单一诊断定位，用户本人认证/授权界面由root及时交接。
