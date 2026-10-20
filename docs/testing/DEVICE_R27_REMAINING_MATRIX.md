# R27准确剩余验证与恢复步骤

截至重启后R27：5项affected UI **4PASS/1FAIL**；iPhone-only R28配置与AI final scroll测试修补尚未产物验证。root持发布裁决，本表不把附加人工覆盖或旧候选结果虚记当前通过。

## 优先需要闭合的功能证据

| 项目 | 已有合格依据 | 仍需做什么 |
| --- | --- | --- |
| 四provider安全配置 | R27四厂商保存/掩码/Done/确认删/取消/缺key禁删子步骤全过，relaunch OpenAI偏好与Gemini不显示也已检查 | 最终SecureField直接exists FAIL；仅修测试滚到实际字段并保留安全role断言，独立review后只回归该case。无需扩产品逻辑 |
| Sandbox交易/当前权益 | 真正联网metadata1/1PASS：USD9.99年费、7dayFreeTrial、eligible=true，entitlements=[]；旧未verified transaction | 等用户手动购买面板明确Environment: Sandbox才由本人认证/确认；读取verified.sandbox、expiry>now、not revoked，确认正常App权益/创建编辑规划；无交易仍UNPROVEN |
| 恢复、续订、取消/到期 | 纯logic expiry/concurrency/timeout有PASS；旧Restore15秒timeout+可退出真实PASS；已有无权益拒绝编辑/可读出导出PASS | 实际Sandbox恢复/周期结束/续订/撤销仍未验证；按可用Apple账户控制做，记录真实结果，不能以timeout或metadata替成功恢复 |
| 本地通知实际投递 | Reminder逻辑去重/窗口/取消等已有PASS，真实权限拒绝和无自发授权已跑 | 需允许权限的正常App，未来事项提醒实际前台/后台/锁屏投递与完成/删除撤销；专注模式状态须记录。这是功能验证缺口，不是permission-denial PASS可替代 |
| iPhone-only最终产物 | project+三targets八Debug/Release配置均family1，静态SHA已核 | R28 build后Info UIDeviceFamily==[1]；当前R27仍[1,2]，不能宣称最终配置通过 |

## 可以复用的未变模块证据

48logic+1liveWeather真实49PASS、后续40logic审查修补PASS；重复/重叠不累计成额外测试总数。产品逻辑若未改，无需每次候选重跑所有logic。既有StoreKit本地4条runtimeCode3失败不改称成功，也不与真实Sandbox混同。

旧no-install20UI18PASS/1FAIL/1SKIP保留旧candidate身份。J1新gallery3真实PASS、21图及独立visual检查已闭合Today正常/EN/AX末端CTA；相应产品源码未变可作为这些独立修补的依据，但不命名R27新gallery。R27 titles2、English paywall+tab恢复、无权益readonly/history三格式导出已真实PASS，避免再次对同一无变化功能全量验证。

**无权益证据已合格且不用购买后强行重复**：R27 English无access创建时呈现paywall、关闭后Map可用；R27 readonly titles normal/AX完整可读且保存禁用；R27 existing-history在无demoaccess下readonly并能导出三格式；之前Core/Pure Subscription expiry门禁PASS。用户一旦购买，真实权益状态改变，不能再要求该账户符合无权益/eligibleintro断言，也不为重复这些断言reset购买史。

## 附加设备/兼容覆盖，保持明确NOT_RUN

- 最低支持iOS17专项runtime，横屏、Light Mode、VoiceOver/VoiceControl/Reduce Motion；首发取消原生iPad不关闭iOS17未知项。
- 真实定位允许/拒绝/精确定位关闭与位置移动；无权限手动选点/真实搜索已由旧UI验证，不能替真实GPS。
- 外部分享表取消和接收App实际导入ICS；ICS文本格式纯logic/三格式预览复制已有依据，不向他人发测试数据。
- 飞行模式/慢网/恢复和地图、天气、AI错误UI；Weather current/+1h/attribution联网已有真实payload，不替离线人工操作。
- 电量/发热前台地图与后台静置测量；未测不能据source推断。
- GLM/Qwen/DeepSeek真实请求、生成质量；当前用户明确OpenAI有效但无余额key仅零generation认证/catalog测试，不强迫消费quota或要求成功生成。

以上是否为当前发布阻塞由root按需求裁决；报告保留未测边界，不随意把必需通知/订阅验证降级为已通过。

## 已prepare的只读Sandbox fresh运行入口（NOT_RUN）

`DEVICE_RUN_R27_SANDBOX_READONLY.sh` 与 `DEVICE_SANDBOX_R27_AFTER_PURCHASE_NOINSTALL.xctestrun`；唯一method为现有app-hosted SandboxSubscriptionDiagnosticsTests，UseDestinationArtifacts=true、start<72/stop75/0.5s、jobs1、无build/install/UI购买/sync/reset/SKTestSession、无fixture。预检/语法/plutil已过；当前没有执行。新路径R27-after-purchase-sandbox-readonly.log/.xcresult不覆盖旧metadata。

流程：root等待用户本人完成购买面板核验与认证；只在Apple面板明确Sandbox时确认，没有Sandbox标识则取消并交回root。随后root正式交回sole slot并检查内存准入，运行现有已安装候选的只读诊断。该method只记录expiry/revocation，root另对脱敏payload明确核verified.sandbox、futureexpiry、notrevoked与正常AppUI access；空entitlements即使metadata单测PASS也不算购买成功。不要收集密码、receipt/JWS或用户账户标识。

Apple [Sandbox overview](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/overview-of-testing-in-sandbox/) 与 [StoreKit Sandbox testing](https://developer.apple.com/documentation/storekit/testing-in-app-purchases-with-sandbox)为操作依据；Sandbox账户与测试控制不代表某次返回Product已证明环境。任何系统密码/FaceID/侧键/允许通知步骤立即交给用户本人。
