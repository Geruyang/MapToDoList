# 真机覆盖清单

**R36 真实权益完整通过**：no-demo create/edit精确替换/save/relaunch/delete/relaunch单例1PASS/0FAIL/0SKIP，88.257s，peak58.07；与R35全部54个Main App文件hash相同，仅Runner测试更新。R35诊断Appcached已false→true，结合真实Sandbox有效交易证据，原已订阅仍只读缺口有完整闭合依据。Restore仍因late Apple Account登录中断FAIL，不能等价判Stop产品坏或已恢复。详见 `DEVICE_R36_REAL_ACCESS.md`。以下R34/R31条目保留历史。

**R34 订阅关键新证据**：只读query1PASS，current=[]，但latest/status均verified exactSKU Sandbox、subscribed、有效期较now余3150.7s、无撤销/升级，Appcached hasAccess仍false。Sandbox有效交易已经证实，App权益应用是待修发布P1；不需重复购买，不把query PASS等同App access PASS。详见 `DEVICE_R34_ENTITLEMENT_EVIDENCE.md`。owner后续修复源码尚不代表已安装R34已修好。

**当前 R31/R32 状态**：parent R31 新逻辑 56 PASS；新地图预览 4例 0/4，均止于确认按钮 isHittable，未走坐标/取消/保存；ui3 为英文1PASS、AI最后Picker虚拟化1FAIL、Restore因实际“Sign in to Apple Account”弹窗1SKIP。R32只加完整Map预断言AX/截图与AI Picker读取前滚动，尚待新结果。恢复120s/15s和静态Release诊断排除不等于实Sandbox交易验证。当前认证待用户，禁止自行手机操作/构建/测试。精确候选与剩余最小队列见 `DEVICE_R32_RELEASE_GATES.md` 和 `DEVICE_R31_RESTORE_MAP_REVIEW.md`。以下均为保留历史，原“最新”措辞仅指当时阶段。

**最新实际状态（新J1候选）**：build-for-testing/strict signature/两App各一次install成功；构建峰74.8%，实际Swift最后-j8，未声称inside-j1生效。focused8首次实际1个snapshot timeout FAIL、1个中断、6个NOT_RUN，guard越75第一次样本76.7停止，完整结果未finalize。随后同installed binary、旧极简UseDestinationArtifacts配置、同EnglishMarketSmoke单case43.839s执行到live paywall审计，无snapshot timeout；真实contrast FAIL元素为系统notification遮挡Subscription导航标题。没有完整UI case PASS，待用户勿扰后单case验证。两种EN分析说明/Export导航往返与实际年价/intro CTA均已执行到，但不能外推全7项PASS。独立ReadonlySandbox **1/1PASS**（此单次准入start73/stop75；peak73.3）：USA annualUSD9.99/1Year、7Day FreeTrial、eligible=true；matching entitlements=[]，Sandbox交易环境仍UNPROVEN。详见 `DEVICE_INPUT_LAYOUT_J1_RESULTS.md`、`DEVICE_SNAPSHOT_CONFIG_CONTROL_RESULTS.md`、`DEVICE_SANDBOX_READONLY_RESULTS.md`。

**上一候选历史状态，不能转移为新候选通过**：官方no-install smoke 1/1 PASS；旧已安装20UI为18PASS/1FAIL(ai.key.save触达)/1SKIP(通知权限已决定)，双App容器前后严格不变，峰值73.2%。中文/EN/AXXXL共21张旧gallery已交独立review；normal末端CTA视觉遮挡已在新候选修补但新gallery未闭合，不能以hittable关闭。Restore实际15秒等待超时后系统登录框被默认XCTest Cancel，无购买/成功恢复/verified Sandbox交易。详见 `DEVICE_NOINSTALL_UI_RESULTS.md`。

**USER RESUMED**：用户明确恢复真机测试，主会话已授予本轮唯一重资源slot。候选源码冻结，执行29项UI-review回归，start<70%、stop75%、jobs1、无并行/无模拟器，保留历史证据。此前暂停期间未执行设备操作。

最新第四轮结果：6项AIReleaseGate+3项SubscriptionTimeout全部PASS；20项UI执行0，`BLOCKED_DEVICE_CERTIFICATE_TRUST`。Runner本地codesign严格核验通过、profile有效且包含该设备，iPhone仍明确拒绝开发证书trust。无新版UI截图，等待用户处理设备信任后主会话重新授权，资源slot已释放。详见 `DEVICE_UI_REVIEW_RESULTS.md`。上一轮67项结果继续保留，不因产品修补推断UI通过。

第五轮用户确认已信任/解锁后实际执行60项合并选择：**40logic全部PASS，20UI执行0**。同一证书/团队、有效profile、可用DDI及解锁已核实；一次Runner直接launch仍被SBMainWorkspace安全验证拒绝。两profile PPQCheck=true，进一步应定位Runner独立App设备联网验证状态，不能重复假定用户未Trust。Mac PPQ HTTP200不能证明手机线路。峰值74.6%（本轮特批start72/stop75，0.5秒采样），无中断、资源已释放。详见 `DEVICE_AUDIT_COMBINED_RESULTS.md` 的40逐项PASS/20NOT RUN和官方验证文档；所有新gallery仍NOT RUN。

最新外部状态已改变：用户联网手动打开Runner后返回桌面，获准一次轻CLI直接launch **PASS（PID2203、exit0）**，此前安全验证拒绝已放行。此操作准入/峰值73.6%，特批轻操作start74/stop75，无build/install/XCTest；无需重复现场Trust，但不能推断UI通过。最小smoke/新gallery仍NOT RUN，等待重任务start72准入与授权。

随后获准无编译单项start74/stop75 smoke：**实际1UI FAIL**，Runner进入用例，但 `app.launch`启动主App `com.waypoint.maptodo`被设备安全校验拒绝。阻塞对象从Runner转为主App；不是4Tab/通知断言失败。峰值74.1%、无中断，未购买/读密码/编译/重试。详见 `DEVICE_RUNNER_SMOKE_RESULTS.md`；无新版gallery。

检查状态：真实签名、安装与启动成功；第三轮完整真机 **67项：56 PASS/11 FAIL/0 SKIP**，其中49 app-hosted XCTest（48logic+1真实WeatherKit）全通过、18UI为7通过/11失败。用户开启UI Automation后旧阻碍已解除；失败分类与真实服务payload见 DEVICE_FINAL_SUITE_RESULTS.md。下一轮20UI回归尚未运行，不能将源码修补计为PASS。

状态含义：PASS = 有对应运行证据；FAIL = 实际结果违背要求；NOT RUN = 尚未运行；BLOCKED = 有具体环境、权限或交互阻碍。源码审阅不能替代真机 PASS。

需求来源：`docs/superpowers/specs/2026-10-11-waypoint-design.md` 与 `docs/design/INTERFACES.md`，2026-10-11 当前版本。

## 7 项功能验收

| 功能 | 真机操作与重点验收 | 状态 / 证据 |
| --- | --- | --- |
| F1 地图与事项 | 无定位权限搜索/选点；创建含时间、时长、地点、备注的事项；编辑、完成、删除、重启持久化；允许定位后实地核对；打开 Apple 地图导航 | 旧built no-install首启/完整CRUD/取消/完成重启、实际搜索选择及选点重启PASS；新title布局待22项新候选；真实定位/导航NOT RUN |
| F2 本地提醒 | 0/5/15/30/60 分钟；标准/静音/时效；首次主动授权和拒绝恢复；前台/后台/锁屏实际投递；完成/编辑/删除撤销；超过系统限额提示 | 设置不提示/实际拒绝PASS；9项Reminder logic PASS；投递/允许恢复/锁屏NOT RUN |
| F3 导出 | 自选起止日期与末日全天；地点当地时区；特殊字符、跨时区与夏令时；纯文本/Markdown复制及 ICS 分享；过期订阅仍可读出导出 | 旧built空导出、无权益coffee详情+禁编辑+三格式预览/复制PASS；新readonly Text待新候选；系统分享/实际ICS接收NOT RUN |
| F4 本地与 AI 规划 | 固定事项不改时；灵活窗口、旅行时间、天气缓冲、冲突解释；无路况明确降级；预览确认前数据不变；4 提供商模型刷新/自定义（首版Gemini不开放）；Keychain写读删；仅主动生成后发送披露的选中事项 | 19AIParsing+6Gate+3FinalValidation相关logic PASS；旧built本地preview不写入PASS；4服务Key UI ai.key.save触达FAIL，Done/绑定区分待新候选；真实AI请求由主会话另有证据，不混入本agentUI结果 |
| F5 天气 | 所选地点当前/规划时刻天气；Apple WeatherKit 归属；缓存时间；超远日期/离线/签名未开通显示实际错误，不能用当前天气替代未来 | 当前/+1h/Apple归属真实服务PASS；缓存/远期策略真机logic PASS；天气UI/断网操作NOT RUN |
| F6 原生 UI | 4 标签页、奶白/墨绿/珊瑚风格；中文；深色、最大动态字体、VoiceOver顺序、44pt点击目标、键盘遮挡与横竖屏 | no-install中文/EN/AXXXL三套21图及Today完整audit PASS；独立visual normal CTA遮挡待新候选，不以hittable关闭；本轮画面为设备Dark，Light/VoiceOver/横屏等专项NOT RUN |
| F7 年订阅 | `com.waypoint.maptodo.annual`；StoreKit本地化年价与符合资格账户七天 intro；验证交易、取消/Pending/恢复/撤销/过期；真实启动无虚假试用；过期可导出但创建/编辑/规划受限；本地配置与真实沙盒分开 | 旧Restore有界timeout/可重试/退出PASS，系统登录框被XCTest Cancel且无密码/购买；不等于成功恢复。新J1 English单case实际live年价US$9.99/eligible7days/CTA enabled已执行；全case仍因systemnotification遮标题contrast FAIL。新只读diagnostic已构建NOT_RUN，实际Sandbox事务/intro交易/撤销/到期NOT RUN |

每项都必须报告运行构建、步骤、实际结果与证据文件；安装启动成功仅能支持 D01 的启动部分，不足以令 F1–F7 通过。

首次BLOCKED_BY_SIGNING和BLOCKED_AUTOMATION_MODE已解除；原失败证据保留。第三轮天气真实服务再次PASS，通知权限拒绝、完成状态重启、空标题与空导出UI有实际PASS；CRUD/地图/完整导出/规划/五Provider写删/恢复/a11y仍有FAIL，不能称全7功能通过。其余人工操作保持NOT RUN。

## 跨功能设备检查

| ID | 场景与步骤 | 必须观察的结果 | 状态 / 当前限制 |
| --- | --- | --- | --- |
| D01 | 首次安装、冷启动、退出后重启 | 无启动崩溃；主界面可用；数据持久化 | 安装/正常首启UI/完成状态持久化PASS；完整CRUD FAIL待回归；PID1830消失原因未确定 |
| D02 | 定位首次许可、允许/拒绝、精确定位关闭、系统设置恢复 | 权限状态准确；拒绝有可理解的替代流程；真实位置更新 | NOT RUN |
| D03 | 真机移动时地图定位，拒绝/关闭定位后手动搜索选点 | 有权限时真实位置更新；无定位权限仍能创建带地点事项 | NOT RUN：本版没有要求地理围栏提醒 |
| D04 | 定时通知、后台、锁屏、重启后；允许/拒绝通知 | 系统实际投递；权限拒绝可恢复；点击返回App；声音/横幅服从系统设置 | NOT RUN：需锁屏和时间观察；未要求任务深链导航 |
| D05 | 地图/地址/远程服务联网，飞行模式及恢复，慢网 | 在线完成请求；离线不丢任务；错误可恢复；无无穷加载 | NOT RUN |
| D06 | Keychain 首次保存/读取、更新/删除、锁屏可访问性 | 应用仅访问自身条目；密钥不出现在 UI、分享和日志中；锁屏行为符合选用 accessibility | NOT RUN：不读取用户已有凭证 |
| D07 | 系统分享表，预览及取消，重新打开 | 内容正确；个人密钥不进入分享；取消不丢数据；目标应用可接收 | NOT RUN：不向他人发送 |
| D08 | StoreKit 沙盒商品加载、成功、取消、Pending、恢复、到期/撤销 | 权益仅由已验证交易决定；不重复发放；可恢复；错误可理解 | NOT RUN：仅沙盒/本地 StoreKit，禁止实际购买 |
| D09 | VoiceOver、最大 Dynamic Type、深色模式、减少动态效果、横竖屏 | 控件有可读标签和顺序；重点按钮可触达；文字不截断；无仅颜色传递状态 | NOT RUN |
| D10 | 前台地图 10 分钟、后台静置 30 分钟、低电量模式 | 无持续高频定位/网络；无异常发热；用测量证据报告能耗 | NOT RUN：不可据代码猜测电量 |
| D11 | 编辑/完成/删除/重启，通知请求同步 | 保存成功；已有任务一致；取消过期系统请求；不会复活已删除条目 | NOT RUN：本版无围栏/撤销功能要求 |
| D12 | 空标题/非法坐标/窗口不足、损坏持久化文件 | 校验阻止错误保存；原始损坏文件保留；错误可恢复说明 | NOT RUN：本版无分享导入/任务深链要求 |

## 自动化、设备操作与外部依赖

以下是全覆盖待跑分类，不能将首轮 7UI+1Weather 通过等同整表通过。

| 检查 | 自动可执行范围 | 需要设备/用户操作 | 外部条件 | 当前状态 |
| --- | --- | --- | --- | --- |
| 首启/CRUD/取消/重启/地图选点 | 已冻结7UI中的首启、CRUD、取消、选点 | 设备保持解锁、允许XCTest Runner | 已有正确团队签名 | PREPARED；环境安装启动PASS |
| 定位允许/拒绝/精确关闭 | 可设计系统权限UI断言；现7UI不包含 | 重置/改变系统定位权限、真实移动；既有拒绝状态需恢复 | 无外部账号 | NOT RUN，不能据手动选点通过推断真实定位 |
| 真实地图搜索与导航 | 现有LiveMapSearch用例可额外跑，服务不可用可明确skip | Apple地图实际导航接收；离线/慢网切换 | 真实MapKit网络 | NOT RUN；文本输入测试仅证明输入 |
| 通知权限拒绝 | 现有NotificationDenial用例可额外跑，权限已决定会明确skip | 首次系统提示或恢复通知权限 | 本地系统权限 | PASS：第三轮真实系统通知提示点“不允许”，app解释并仍可用；允许权限/锁屏投递未跑 |
| 通知真实投递 | 可额外编写前台/后台Springboard通知自动断言 | 确认允许权限；锁屏、声音/静音、专注模式实际观察；等待未来触发时间 | 不需要服务账号；系统通知权限/专注设置 | NOT RUN；排程算法单测不等于投递 |
| 通知编辑/完成/删除/全局关闭与60限额 | 纯逻辑ReminderPlan已有覆盖，可额外核对设备pending requests与UI | 锁屏确认取消后无旧提醒；重启后系统请求保留 | 系统权限 | NOT RUN（设备）；需分别检查每种模式与取消路径 |
| 文本/Markdown/ICS导出 | 7UI无demoAccess读出、格式预览、复制；纯格式与日期边界单测 | 系统分享取消/交付到本地目标，Calendar真实解析；不向他人发送 | 无订阅账号；ICS接收app | PREPARED；分享接收NOT RUN |
| 本地规划固定/灵活/预览不写入 | LocalPlanner逻辑单测；现有LocalPlanningPreview UI可额外跑 | 手工核对路程、不同交通方式、应用前后时间 | MapKit真实ETA与WeatherKit真实天气 | NOT RUN（设备）；算法通过不等于实网交通天气 |
| 规划交通/天气降级 | 可对纯规划策略做逻辑断言，真实服务降级需联网/断网运行 | 切换飞行模式/慢网，确认风险与缓冲解释；跨时区/DST人工行程核对 | MapKit、WeatherKit能力已签名 | NOT RUN；不得把降级直线估计标作实际路线成功 |
| AI配置/Keychain | 四提供商SecureField+独立测试service写入删除+配置重启，Gemini菜单不存在 | Keychain锁屏访问需设备锁定；不读正式service | 配置/无效sentinel不需要API账号 | 回归中；UI成功标签不能替代直接Keychain读取证明 |
| AI真实刷新/生成/自定义/地域 | 只有明确用户测试Key时可主动请求；完整快照验证已有逻辑复现 | 用户选择发送并确认披露；检查预览后Apply | GLM/Qwen各地域/DeepSeek/OpenAI有效Key与账户可用模型；本次无Key，Gemini首版禁用 | BLOCKED_EXTERNAL_CREDENTIALS；不调用未知Key、不申请新Key |
| WeatherKit current/+1h/归属 | DeviceIntegrationTests真实物理设备联网，fresh actor，保存JSON数据或FAIL | 不需定位权限；UI缓存/远期/断网恢复需额外操作 | 正确WeatherKit capability及Apple服务网络 | PASS：第二/第三轮真实current/+1h/归属payload；天气UI/离线未跑；模拟器硬件skip不是天气PASS |
| 英文/中文基础导航及付费墙 | 7UI英文Smoke；截图Gallery可额外跑 | 中文/英文最大字体、深色/横屏、VoiceOver焦点与读出 | 无购买账号 | PREPARED；UI基础通过不等于全面a11y |
| 自动可访问性 | 现有TodayScreenAccessibilityAudit（contrast/hitRegion/textClipped）可额外跑 | VoiceOver、减少动态效果、最大字体全屏复核 | 物理设备iOS17+ | FAIL：第三轮非交互progress hitRegion，产品语义修补待回归；自动audit不是完整VoiceOver测试 |
| 本地StoreKit生命周期 | 独立StoreKitTest suite，由主会话串行；明确本地.xcode环境 | 仅本地系统确认，可用模拟环境 | 可用StoreKitTest runtime；当前26.5 Code3问题独立复测 | 由主报告；不得混入真机SandboxPASS |
| App Store Sandbox订阅 | Sandbox产品获取、成功/取消/Pending/恢复/撤销/到期需专门运行 | 用户Sandbox登录和系统购买确认；禁止真实扣费 | ASC正确bundle产品/七天intro/价格点、Sandbox测试账号及签名 | BLOCKED_EXTERNAL_STORE_CONFIGURATION，未设置前不点购买 |
| 权益到期后保留历史导出 | 7UI使用无demoAccess与seed历史证明读出入口；policy单测验证过期撤销 | 真正Sandbox到期/撤销后界面更新、创建编辑规划受限 | Sandbox权益生命周期 | 部分自动PREPARED；真实权益变更NOT RUN |
| 电量/发热/低电量模式 | 可安排独占Instruments测量，不能靠源码代替 | 前台地图10分钟/后台30分钟、低电量模式，记录设备状态 | 测量工具与时间窗口；遵守主机80%内存硬上限 | NOT RUN |

7UI的数据创建使用明确DEBUG demo权限与独立测试数据，只有首启/历史导出/英文Smoke等无demoAccess场景检查未开通状态。不得将demo CRUD通过写成付费订阅已获验证。

## 精确交付候选审阅

- [ ] 记录 Git commit（若存在）、项目路径、App bundle ID、构建版本与设备 OS。
- [ ] 检查权限描述与调用时机、持久化模型、并发主线程边界、通知去重与取消、系统通知限额及删除处理。
- [ ] 检查联网实际 API、请求失败行为、Keychain access control、分享内容、StoreKit 验证与权益恢复。
- [ ] 核查模拟器测试记录中的断言与最终构建一致；模拟器结果不得标作真机通过。
- [ ] 将 7 项需求逐一列入最终表格并附真机执行证据或具体阻碍。

本检查 agent 只拥有 `docs/testing/DEVICE*` 文件；可只读代码与设备环境，不更改签名配置，不读取敏感 Key，不实际购买，不创建子 agent，不发布。
