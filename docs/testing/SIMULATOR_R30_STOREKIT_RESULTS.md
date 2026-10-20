# R30 本地 StoreKit 生命周期实际结果

2026-10-11，独占重任务资源。用户已撤销此前 80% 内存限制，本轮只采样记录，**MEMORY_SAMPLE_ONLY，无阈值取消**。只使用既有 UDID **`9B92CCDE-87A5-49CE-B0BE-9DD271313987`**（显示名 AIFrontier Subscription Tests）；xcresult 实际报告型号 iPhone 17 Pro Max、iOS 26.2 (23C54)、x86_64。

## 候选与执行身份

- 冻结输入：`DEVICE_EVIDENCE/R30-inputs.json`，SHA256 `7312bbf9703ba9892fff5192767f566b3ad41dfdd9de9b0d0cc42965aecad660`；构建前 56 个文件全部匹配，构建结束再次匹配。
- 不执行 xcodegen、clean，不修改产品或测试源。主会话在构建结束后明确解锁 R31 源码；随后测试只绑定 R30 产物，R31 变化不判为污染。
- 独立 DerivedData：`/tmp/Waypoint-StoreKit-R30-Simulator`。
- `build-for-testing` exit 0，`TEST BUILD SUCCEEDED`；`codesign --verify --deep --strict` exit 0，ad-hoc 签名。
- 86 个 regular artifact 文件 SHA256 留在 `SIMULATOR-results/R30-local-storekit-artifact-hashes.json`；测试结束再次逐项检查，0 变化。
- 源与 bundled `MapToDo.storekit` SHA256 一致：`88bb7a535d770d64ca546034f851174993865717ee569fd5def5f3f0af616e11`；商品 `com.waypoint.maptodo.annual`，USD9.99/年、七天试用。
- 生成的 R30 xctestrun SHA256：`e424bc9e16663ae6cc881ca7eacc2c86dd4018a508c620bb5ea7d361eaa2b1be`。两次均 `test-without-building`、`jobs1`、不并行、120 秒单项 allowance；完整实际参数保存在对应 process JSON 和 log。

## 实际结果：4/4 PASS，0 FAIL，0 SKIP

| 场景 | 实际时长 | 运行证据与严格断言 |
| --- | --- | --- |
| off-device 本地购买后，新 Store 恢复 | 0.547s | restore1：1/1 PASS，exit0；无本地缓存 bypass；restore 后有效权益与 local test 标志为真 |
| 合资格七天试用，由实际 Product.purchase 激活 | 0.391s | remaining3：PASS；价格9.99，未购买前无权益；已验证交易环境 `.xcode`、offer `.introductory`；用过后不再符合 intro 资格 |
| refund 后交易监听撤销权益 | 0.971s | remaining3：PASS；不手动 refresh，Transaction.updates 在期限内清除 access/expiration |
| 到期清除权益，恢复不能重新激活 | 1.775s | remaining3：PASS；expireSubscription 后 access false，restore 后仍 false、expiration nil |

两份已完成 `.xcresult` summary/tests 核对计数为 1 与 3，均 Passed，零失败、零跳过。两份日志内 `SKInternalErrorDomain Code=3`、`notEntitled`、`Error saving configuration file` 均为 0 次。

主要证据在 `SIMULATOR-results/`：

- `R30-local-storekit-build.log/.xcresult`，build-process.json、preflight.json。
- `R30-local-storekit-restore.log/.xcresult`，有效 summary 为 `restore-summary.json`，tests 为 `restore-tests-retry.json`。
- `R30-local-storekit-remaining3.log/.xcresult`，有效 summary 为 `remaining3-summary-retry.json`，tests 为 `remaining3-tests.json`。
- artifact-hashes.json、final-validation.json 与 cleanup.json 均使用 `R30-local-storekit-` 前缀。

首次并行导出同一 result bundle 的 summary/tests 发生 xcresulttool SQLite cache 初始化冲突，两项 exit64 并留下空 JSON；随后串行导出到新的 `-retry.json` 文件 exit0、JSON有效。原空文件保留，不用作结果证据，未修改原始 result bundle 的测试内容。

## 资源与清理

| 阶段 | 起始采样 | 最高采样 | 是否按内存停止 |
| --- | --- | --- | --- |
| build | 73.8% | 75.1% | 否，SAMPLE_ONLY |
| restore1 | 69.3% | 80.1% | 否，SAMPLE_ONLY |
| remaining3 | 63.2% | 81.1% | 否，SAMPLE_ONLY |

采样峰值只代表离散观测。Xcode 完成后设备已自动 Shutdown；再次显式 shutdown 返回 already Shutdown，随后 inventory 确认状态 Shutdown，owned descendants 与所有 runtime 残留均 0。没有杀任何进程。**唯一重任务资源已经向主会话明确交回**，后续只进行轻量元数据导出与本报告写入。

## 结论范围

本轮证明 R30 候选在 iOS26.2 的本地 `.xcode` 购买、试用、恢复、refund/过期权益流程可用。旧 iOS26.5 四项 Code3/notEntitled FAIL 仍保留；本轮源码及 fixture 也比旧轮更新，未对同一 R30 产物运行26.5，不能宣称 runtime 是唯一根因或26.5已修复。

本轮没有真实 Sandbox 购买、账号密码、真实扣费或设备 UI 操作；不能代替用户真机的立即取消、restore交互超时或无 Sandbox 标签诊断。Ask-to-Buy两项、取消购买、取消续订仍未在本轮运行。R31正在调整恢复交互时限，本轮也不能作为R31候选的验证。
