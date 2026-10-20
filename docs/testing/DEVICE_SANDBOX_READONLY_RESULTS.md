# 真实只读 StoreKit 商品诊断

2026-10-11，已安装 Input-layout-J1候选，不重编、不安装，官方UseDestinationArtifacts app-hosted MapToDoTests配置，仅选择 `SandboxSubscriptionDiagnosticsTests/testReadOnlyLiveProductEligibilityAndVerifiedEntitlementMetadata`。未运行UI、录屏、SKTestSession、purchase、AppStore.sync、history reset，也没有读取密码或输入账户信息。

**实际 1/1 PASS，0 FAIL，0 SKIP，exit0**。测试执行1.067秒。root在释放自己的浏览器缓存后按先前单case约1.7pp观察，为此单次只读unit诊断授权start<73（不是构建/UI准入）；stop75和0.5s采样不变。baseline72.6%，采样peak73.3%，未触发停止。资源已释放。

证据 `DEVICE_EVIDENCE/Sandbox-readonly-live.log/.xcresult`、summary.json、attachments/manifest.json，以及真实 payload `Sandbox-readonly-live-attachments/7B5FD7FD-6832-4A36-A05F-7D7ECA4E1A3F.json`。

| 字段 | 服务实际返回 |
| --- | --- |
| Storefront | USA / 143441 |
| Product ID | com.waypoint.maptodo.annual |
| Type | Auto-Renewable Subscription |
| 年价 | 9.99 USD / display US$9.99 |
| 订阅周期 | 1 Year |
| Intro | FreeTrial / 7 Day / periodCount1 / USD0.00 |
| Eligible | true |
| 当前 matching entitlement | 空数组 |
| Verified transaction.environment | 无交易可读，**UNPROVEN** |
| 购买/恢复/reset | 全部false |

本次PASS仅证明实际商品、周期、intro和账户资格metadata满足该单测断言。Product本身不能证明Sandbox environment；没有订阅交易、future-expiry或当前权益验证，不算成功购买/恢复/取消/Pending/撤销/到期生命周期通过。XCTest资源中虽然含storekit fixture文件，此独立运行配置没有启用任何fixture，且该方法不创建SKTestSession。

`Sandbox-readonly-container-proof.json` 两App before/afterURL严格相等；新Main/Runner签名与容器同J1候选。app-host真实启动没有新增Trust阻塞。

后续如用户明确同意且人在现场：先在Apple购买panel确认Environment: Sandbox，再由本人输入密码/FaceID/侧键确认；不能自动购买或将真实交易与本地fixture混合。完成后读取已验证sandbox交易和future expiry，再验证权益/取消/恢复等。当前method记录expiry且验证environment，但尚缺明确future-date断言；已通知subscriptions owner/root协调，在新的测试源和候选未验证前不宣称其已覆盖。
