# R31 产品 / R32 测试发布门槛独立复核

2026-10-11。device_tests，只读代码/已有产物与报告维护。用户认证待答，本轮没有手机操作、build/test/install、sync 或 purchase。模拟器任务由 simulator_tests 独占执行，不能替换真机证据。最新产品/测试精确 SHA 见 `DEVICE_R31_RESTORE_MAP_REVIEW.md`；测试冻结 SHA 为 `0ee42d777fab55c74a6b35f4d4d1aa1d267108250ceb737600d8b54ec7566ce0`。

## 发布产物边界

- SubscriptionStore 的 UIKit 导入、所有 purchase/restore recordDiagnostic 调用及函数定义均受 `#if DEBUG` 保护。项目 DEBUG 条件只在 Debug；Release 未定义 DEBUG。诊断仅写本机限定 64 KiB JSONL，错误只记录 domain/code 与最多三层 designated underlying link，不序列化 userInfo、账号、密码、交易/JWS。Release 排除目前是静态证据；最终新 Release archive 必须再核编译配置与二进制，旧中间归档不能代表本次源码。
- AccessPolicy 的 demo 写权限只在 DEBUG 且需要 `--uitesting` 与 `--demo-access` 同时存在；Release 返回 false。UI 测试独立 Keychain service 和任务数据路径也仅 DEBUG。最终 Release 应验证签名、WeatherKit/time-sensitive entitlement、app icon、privacy manifest与语言资源，正常启动不带测试参数。
- 当前 `build/DeviceData/.../Debug-iphoneos/MapToDo.app/Info.plist` 只读核得 `UIDeviceFamily=[1]`，首版 iPhone-only Debug 产物已有依据。它不是新 Release archive 证明，也不等于 iOS17 最低版本已实测。
- 方案 RunAction 挂本地 StoreKit fixture；真实 Sandbox 流程必须明确不启用 fixture。产品 metadata、试用资格、已登录账号或 timeout 都不能替代 verified sandbox transaction。

## 七功能准确覆盖与缺口

| 功能 | 已有可复用证据（绑定各历史候选） | 当前必须明确的缺口 |
| --- | --- | --- |
| 地图、事项、持久化、导航 | 历史创建编辑保存重启/删除、长标题 normal+AX、readonly 已过；地图定位 completion 三项新纯测试包含于 parent R31 56 logic PASS | R31 四项新预览流程 0/4，在 confirm.isHittable 止步；确认、精确坐标保存、replace/cancel 尚未验收。真实 GPS 允许/拒绝/移动与外部 Apple Maps 导航仍须独立记录 |
| 本地提醒 | 去重/重入/时间边界等纯逻辑已有 PASS；真实拒绝权限/关闭提醒无自发授权有旧证据 | 允许权限下正常 App 前台/后台/锁屏实际投递、完成/删除撤销未验收；需记录勿扰/声音/横幅配置，不承诺绕过系统 |
| 导出与分享 | R27 无权益 readonly 三格式导出真机 PASS，日期/转义/ICS 等逻辑 PASS | 外部分享取消及实际接收 App 导入 ICS 尚 NOT_RUN；不向他人发送测试内容 |
| 本地规划与 AI | 固定时间/范围外邻居/交通天气冲突等已有纯测试；R31 逻辑含 R30 区域封口 transport mock 回归由 parent 记录 PASS；三厂商 secure-save/delete 子步骤完成 | R31 整 AI UI case 最后 picker 读取 FAIL，R32 滚动修正 NOT_RUN；真实地区改变/撤销权限时 UI 清选项待真机。真实厂商付费生成质量未验，不消耗无余额 OpenAI key quota |
| 天气 | 真机 WeatherKit current/+1h/Apple attribution 真实联网 payload PASS，签名 capability 与门户开通有证据 | 新 Release 身份与实际故障/离线界面、远日期提示待最终候选；历史成功不替换新 entitlement 核验 |
| 设计、语言、可访问性 | 中/EN/AX21图、Today末端CTA、normal/AX长标题与英文paywall/导航多项真机 PASS；R31 EN再次 PASS | R32 Map AX 完整树与确认按钮 hittability 未闭合；VoiceOver/VoiceControl/Reduce Motion、横屏/亮色全流程、耗电/发热尚 NOT_RUN |
| 订阅 | metadata USD9.99/year、7-day FreeTrial、eligible、空权益真实 PASS；expiry/revocation/timeout/concurrency pure PASS；无权益仅只读/导出及门禁 UI PASS | 用户报告取消购买且从未见 Sandbox；R31 Restore 因 Sign in to Apple Account SKIP。verified sandbox 购买、future expiry/not revoked、正常 App 权益、恢复、续订/结束/撤销均未有完整交易证据 |

上述必需功能与附加人工覆盖由 root 结合用户范围裁决，不能把 NOT_RUN 改成 PASS，也不需要在每个增量候选重复所有未变逻辑。

## 下一轮最小真机队列（仅准备，不执行）

1. 等用户本人解决当前 Apple 账户提示；不能把任何 system alert 一概当认证，也不能因账号输入框无 Sandbox 标识便确认未知环境购买。不操作密码/FaceID/侧键。
2. 收取 simulator R32-mapdiag 的预断言 AX。R32 helper 附件在确认/取消/坐标之前生成，文本为完整 app.debugDescription，截图为实际预览；它应暴露 type/identifier/label/frame 和重复 card。若仅 application root 或工具 timeout，仍不能归因 parent-ID。先由 owner 修确定问题或依据完整树改精确 locator，再构建一次候选；避免四项相同未知基础失败重跑。
3. parent 统一新候选 build、签名与一次安装后，复用 UseDestinationArtifacts no-install：先 Map 一项诊断，成功后才 Map 其余三项；AI 单项验证 relaunch picker滚动+DeepSeek持久化+隐藏OpenAI/Gemini+secure input。保留所有 hittable、未确认不进 editor、精确坐标、保存重启断言。
4. Restore 单项仅在用户认证状态明确后运行：等待中 Stop/Done 可达，Stop 后准确说明不取消 Apple 购买/订阅、无虚假授权、retry可用；快速真正结束则检查实际结果。120s sync +15s reader 不等于实 Sandbox 恢复成功。
5. 真实 Sandbox 交易由用户本人操作：Apple 购买面板明确 Sandbox 环境后才确认；接着只读现候选 verified entitlement，独立核 environment=sandbox、expiration>now、revocation=nil、正确 product，再看正常 App 写入/规划访问。空权益 metadata PASS 仍是交易 UNPROVEN。账户一旦有权益，不强行重复无权益或初次试用资格断言，不 reset 购买史。
6. 提醒实际投递单独一轮正常 App 人工验收；分享/导航、真实GPS/离线/VoiceOver/电量及最低 iOS runtime 逐项记录。最后生成真正的 Release 产物审查与完整发布缺口说明。

当前无资源门槛脚本执行；用户已撤销原内存硬阈值，旧守卫证据仍保留。未来任务仍由 root 串行分配唯一重资源 slot，禁止用历史许可自行触碰当前认证中的手机。

## R33 最小 Map 标识修复独立复核

MapScreen.swift 精确 SHA `75251fa977fd7a96f8eeb1ac4f48175fbe2f76d694690a7d6320d858c1e3f832`。本 agent 只读核验：唯一产品变化是父 VStack 的 `map.selection.card` 移到预览标题 Text 并增加解释注释。确认/取消/坐标/名称标识、布局、pendingSelection、写入门禁及 confirm→editor / cancel→不保存路径不变。测试 SHA `0ee42d777fab55c74a6b35f4d4d1aa1d267108250ceb737600d8b54ec7566ce0` 保持；card 现在作为预览标题锚点，取消时标题应消失，其他独立断言仍检查真实 marker、按钮 hittability、未确认不进 editor 与精确坐标。

本 agent 亲读 R32 simulator 完整 AX 附件 `SIMULATOR-results/R32-sim-mapdiag-attachments/37E2C446-5C8F-4952-9DEC-CA398C8ACF9F.txt`：行33 的坐标 Other、行35/36 的取消/确认 Buttons 均为 `map.selection.card`，明确证实父 ID 传播。标题也为 card，而地点名仍保留 name。由此修复对应已观察到的标识覆盖，无须放宽或改为 exists 替代 hittable。

R32 simulator summary 的唯一实际失败是 **Selected location must have a distinct map marker**；在 pin 断言止步，未执行确认控件断言，不能写为模拟器 confirm fail。其空白地图/缺 marker 也不能靠这次 card ID 修复记为 PASS。R33 静态审查无阻塞；parent 可统一构建，随后须证明独立子 ID 恢复、正常/AX 操作、先确认再 editor、cancel 不保存及精确坐标持久化。没有设备/build/test 操作。
