# R34 有效 Sandbox 交易与 App 权益不一致

2026-10-11，device_tests 独立只读复核。R34 是已安装的冻结候选；owner 后续源码变化不属于该产物，不把待修源码写成 App 已恢复访问。

原始附件：`DEVICE_EVIDENCE/R34-entitlement-diagnostic-attachments/BA576C2E-1790-448A-AE17-84E1A62A2B83.json`。SHA-256：`63209af70b521dcf8b94ec05cfee9a9fa7d7a9a7834e49446baecd0aca5e7be4`。本 agent 亲读全附件，未操作设备。

| 项目 | 实际值 |
| --- | --- |
| read-only query | 1 PASS，exit0，peak53.13%；只说明查询完成 |
| currentEntitlements | 空数组，读完成无异常 |
| latest | verified，com.waypoint.maptodo.annual，Sandbox |
| subscription status | subscribed；transaction verified，renewal verified |
| transaction purchaseDate | 2026-10-11T16:33:32.000Z |
| signedDate | 2026-10-11T16:35:06.958Z |
| observed now | 2026-10-11T16:41:01.293Z / 01.299Z |
| expirationDate | 2026-10-11T17:33:32.000Z，较观察 now 余约3150.7秒 |
| revocation / isUpgraded | null / false |
| gracePeriodExpirationDate | null，本次状态不是 grace |
| pure current App policy | 对 latest/status transaction 均 true |
| App cached hasAccess | 前后均 false |

在这个观察时刻，有效 verified Sandbox exact-SKU 交易证据成立，不能再把交易环境写为 UNPROVEN，也无需重复用户购买。真正仍未通过的是 App 权益应用和正常写入/规划访问：默认 reader 依赖 currentEntitlements，而该接口空数组与另两项只读接口结果不一致。新 latest/status 与 now 对照排除了这笔交易在该时刻因过期、撤销、upgraded、错误 SKU 或未验证而被拒绝；没有凭 signedDate 距今约354秒宣称设备绝无 clock drift。

这是发布 P1，不能用“已验证购买返回”直接授予无期限本机权益。owner 正实施最小 verified-status fallback，并回归空 current +有效状态、过期/撤销/upgraded/不匹配/未验证、reader deadline与旧结果保护。完成后须核 exact source SHA，再由 root 统一新产物运行，验证实际 hasAccess、既有/新建事项、规划以及恢复结果；不把 R34 query PASS 改为购买交互或 App access PASS。

诊断没有直接调用 purchase/sync/finish/reset，也未输出账户、交易 ID、token、JWS 或 receipt。其 `transactionFinishAttempted=false` 只指该 method；正常 App Transaction.updates 仍可能完成已验证交易。

## R35 待运行修复的独立静态复核

owner SubscriptionStore SHA `c49c191cb3e4de5273c3df400e610c2ca092f60668557b87867033b0a7ab8735`，SubscriptionTests SHA `356b1c676fd06c7450682bdbff8a632108c33739e03ea7816a4e90aae4ee6dca`，均独立重算一致。本 agent 未写该产品修补，只读审查通过最小变更：只有 current 无 matching 结果时，才对 exact live Product + subscription.status 用总 10 秒预算回退；生产正向 status 必须 transaction 与 renewal 双 verified，state=subscribed，双方 productID exact，未来 expiry、无撤销、无 upgrade。current matching 出现任何未验证/过期/撤销/upgrade/无期限证据直接否决，不查旧正向 status。

fallback 不取 latest-only 来授予，不缓存 sticky 权益，不凭 purchase success授予；network/timeout返回空快照。原 apply 保留 entitlementRevision 与应用当时 Date 复核，晚的旧读取不能覆盖新撤销，过期 timer 会重新读取。当前 R34 的真实 status 满足所有正向条件。九项新增纯回归加旧两项共11，覆盖 R34成功分支、过期/nil、撤销/upgrade、双验证、双SKU、四类非subscribed状态、非合作超时晚结果、显式current否决及有效current不访问网络/错误关闭。owner parse PASS，但本 agent 未执行；新产物与 App access 仍 NOT_RUN。

parent 另授权本 agent 写独立真实权益 UI：`WaypointUITests/testRealSubscriptionUnlocksCreateEditPersistAndDeleteWithoutDemoAccess()`，UITests SHA `64948f94d31fcd93756ed46faadb24f742cbddf25f7f97648b5fed781ff95643`。三次 launch 均 demoAccess:false；首次 reset 仅 UI 测试任务命名空间；实际订阅有效且无本地测试标识才检查新建编辑，title 要求 enabled TextField/TextView，无 readonly、Save enabled，disposable 事项创建→编辑→重启后再次真实active及title核对→删除→再重启不得回来。没有 purchase/sync/SKTestSession，不碰用户生产任务；缺失/过期 precondition 明确失败，不伪造权益。

该自写 UI 用例仅为运行计划，不作为产品独立审查通过的证据。产品审查依据是 owner 精确源码与 R34 原始 payload。测试只 diff-check，本 agent 未编译/运行或操作手机；parent 统一 R35 构建后才能闭合发布 P1。

## R35 实际运行与测试输入修正

parent 实际 R35 unit23/23 PASS。RealAccess 整例仍 **FAIL**：初次与重启后“订阅有效”均已确认，创建/编辑/Save/重启有实际子步骤，但 log281 的精确 title 是 editedTitle+createdTitle 拼接，原 helper tap 后按字符数 backspace 假设 caret 在末尾，长多行 title 实际光标在开头，旧文字未删除便前插新标题。不能把这次输入边界错误归因订阅再次变成只读，也不能把整个 case 写成 PASS。

仅为该新 RealAccess 用例增加 `replaceTaskTitleExactly`：非空输入调用原生精确 Select All/全选 MenuItem/Button，必须 hittable；单次 delete 后必须观察值 empty/placeholder，才输入完整原测试 title；输入后与保存前都核精确值。缺菜单则附完整 AX+截图并 FAIL，不盲目继续，不缩短 title。旧全局 replaceText 与所有其他测试不变。新 UITests SHA `b562f7aa99f8e403b93f271ad6f9e8e452c6e9aa913134ebaa1d9b2536344175`，diff-check PASS，尚未 parse/build/执行。本 agent 未操作设备或修改冻结产品源码；parent 决定新候选运行。
