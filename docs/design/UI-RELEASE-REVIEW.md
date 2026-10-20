# 行迹 Waypoint — UI 发布审查（修补后复核）

更新：2026-10-11。前半部为gallery之前的SOURCE复核快照，后续实施修补不自动算运行PASS；**最新真实设备视觉结论见文末「真实设备截图复核」**。本agent未构建、未启动模拟器、未执行购买。SOURCE关闭仅表示代码路径修补，行号对应当时读取快照。

**最新结论已由 UI-noinstall-gallery 更新（见文末新候选章节）**：21张中/EN/AXXXL真机图、2张同run英文导出/付费附件、1张AI失败录像尾帧全部独立查看。旧R19顶部裁切、R20已有事项空新建真实关闭。发布前仍需新运行证据确认正常字号Today CTA可见、AX详情完整标题、暗色付费主按钮对比；这三项已追加SOURCE修补，尚不属于已测新binary。AI保存唯一失败原因未确认，不能直接写键盘遮挡。

结论：R01、R02、R03、R04、R06、R07和R09已关闭SOURCE。R05旧错误清理已修，pending重复购买仍未修。最小P1代码余项合并为五组：pending状态、密钥状态/删除、到期只读提示、大字号布局与44pt触区、面向用户的错误文案。地图/规划视觉与英文复数等为P2完善。

## 判级和证据

SOURCE-CLOSED：复读到解决原问题的代码，交互待验。SOURCE-OPEN：当前代码仍存在具体缺口。SOURCE-PARTIAL：只修部分。RENDER-PENDING：未渲染，不能宣称实际遮挡或命中失败。P0为正式发行配置阻塞；P1为本轮发布质量门槛，不等同于Apple必然拒审；P2为视觉/理解完善。

标准沿用Apple [订阅呈现](https://developer.apple.com/app-store/subscriptions/)、[触控与可读性](https://developer.apple.com/design/tips/)、[Larger Text评估](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/)。下面是当前代码结论，不是泛泛标准清单。

## 每项最新状态

| ID / 原级别 | 当前状态 | 复读证据与准确剩余 |
|---|---|---|
| R01 / P0 政策支持 | **SOURCE-CLOSED；HTTP确认；App内打开待验** | Core/AppLinks.swift:4–8真实support/privacy/terms/mailto。SubscriptionView:46–50正式Link；Settings:23–30、49–50有支持/联系/完整政策。三个公开网页只读GET均HTTP200且含Ge Ruyang和邮箱。本轮未发布，商店元数据/法律审核不由UI复核代替；不能仍将政策草案列为当前阻塞。 |
| R02 / P1 今日误删 | **SOURCE-CLOSED；交互待验** | TodayView:38–44确认dialog，64只设置pendingDeletion；取消不调用remove，确认才删。TaskEditor:103–105同等保护。附任务名属P2，不再保留原直接误删阻塞。 |
| R03 / P1 草稿丢失 | **SOURCE-CLOSED；交互待验** | TaskEditor:20–33初始快照/dirty检查；96取消触发确认；99–101继续/放弃；130 interactiveDismissDisabled保护dirty草稿。下滑当前被阻止，非自动弹确认，但原丢失路径已保护；测嵌套sheet和取消。 |
| R04 / P1 无可见关闭 | **SOURCE-CLOSED；触区/交互待验** | SubscriptionView:7 dismiss、13–17「完成」及subscription.close。sheet/push均有退出动作；44pt未显式约束归R13，不重复开无关闭缺陷。 |
| R05 / P1 旧错误/pending | **SOURCE-PARTIAL；pending OPEN** | SubscriptionStore:47/92刷新和恢复前清message，旧错误已修。82 pending只写message，无isPending；67购买guard仅isPurchasing，View:32禁用仅isPurchasing/isRefreshing。pending返回defer:70重置后可再次购买，refresh还清pending文字。 |
| R06 / P1 旧参数预览 | **SOURCE-CLOSED；交互待验** | PlanningView:70–76监控日期/方式/selected/provider/model/Qwen地域，79–80失效清preview/取消work/变revision；91/105、107–108捕获请求配置，异步结果核验revision。测各参数切换。 |
| R07 / P1 AI选中无朗读 | **SOURCE-CLOSED；VoiceOver待验** | PlanningView:43选中/未选value，44 selected trait；中英资源有keys。46「同意并发送」。不可记VoiceOver已通过。 |
| R08 / P1 密钥状态/删除 | **SOURCE-OPEN** | AISettings:44–48仍空SecureField+保存+直接删除；无已配置/未配置、无确认，切provider/地域只清输入。AIConfiguration:94忽略SecItemDelete结果；UI47仍无条件显示已删除。 |
| R09 / P1 默认地点不明 | **SOURCE-CLOSED；优化P2** | TaskEditor:47–48明确San Francisco default，zh-Hans:323–325有旧金山翻译，保存locationName带default。原仅数字坐标不知地点已修；小地图/时区建议降为P2，绝不能叫当前位置。 |
| R10 / P1 到期像可编辑 | **SOURCE-OPEN** | TaskEditor:38–97全可编辑+Save，无无权益提示/只读分支/ObservedObject订阅；仅save:138拦截。Today:51已有task可查看正确；余项是输入很久才知道不能保存。 |
| R11 / P1 地图大字号 | **SOURCE-OPEN；RENDER-PENDING** | MapScreen:24–25固定上下inset，63–84底卡，117–127五搜索结果，无高度边界/有界滚动/AX降级；214–215固定2行title/1行地点。没有截图，不声称已占尽地图。 |
| R12 / P1 长英文布局 | **SOURCE-OPEN；RENDER-PENDING** | WeatherCard:51–67强制左右HStack；Export:32segmented；Theme:47当地日期/时区+时长同Label行。没有ViewThatFits/AX纵排；语义字体已有，不等于AX布局验证。 |
| R13 / P1 小触区 | **SOURCE-OPEN；命中待验** | MapScreen:113clear无44pt；Subscription:15新增完成、46–52footnote政策links无最小触区；WeatherCard:41caption来源无约束。pin/定位/添加/完成圈已44/48，不重复报告。未测实际系统hit范围。 |
| R14 / P1 内部错误文案 | **SOURCE-OPEN** | WeatherPolicy:24仍要求检查WeatherKit签名，Card:98直接展示；AIConfiguration:81仍OSStatus数字主错误，AISettings:46直接展示。未变用户恢复说明。 |
| R15 / P2 地图下一任务 | **SOURCE-OPEN** | MapScreen:79仍prefix(2)含已完成；MapSummary:214–215缺开始时间/时长；82「今日页查看」仍文字，无真实切tab动作。 |
| R16 / P2 规划timeline | **SOURCE-OPEN** | PlanningView:50仍UUID排序changes，52只列改变项，未按建议时间/日期分组或呈现固定任务timeline。Apply/冲突保护已有，不新增旅行模型。 |
| R17 / P2 海外细节 | **SOURCE-PARTIAL** | Export:80已Waypoint文件前缀；Map:125/TaskEditor:172fallback已String(localized:)；WeatherCard:60和WeatherPolicy:33–38用locale weather Measurement，固定C已修。余项普通strings复数、filename缺日期范围、英文demo fixtures/SDKcondition语言待内容验收。不再说全App未本地化。 |
| R18 / P2 统一/iPad/version | **SOURCE-OPEN；RENDER-PENDING** | Subscription:18/22仍系统green、31默认button，未统一canvas/52ptCTA；Settings:34硬编码Version1.0。Today/Subscription无max-width，Map卡全宽。Theme动态色正确；未见截图，不能写暗色/iPad失败。 |

代码根路径为MapToDo/：Theme在Design、AppLinks在Core，其余在Features对应模块；行号后续变化需重新定位。

## 最小P1剩余代码列表（五组）

1. **R05 pending状态。** Subscription负责：独立可观察等待批准状态；pending购买按钮改「等待批准」并阻止重复请求，store guard同样拦截；refresh不因message清理遗失pending。确认后清pending、刷新真实权益。待验Ask to Buy→返回/foreground→关开paywall→批准/拒绝；不授予未验证权益。本审查不推断Apple已经重复收费。
2. **R08密钥状态与删除。** Planning/AI负责：显示provider/region已配置/未配置、重开刷新，不显示完整值；未配置禁用删除，已配置二次确认；检查SecItemDelete成功/不存在/失败，不无条件显示成功。末四位/连接测试是进一步完善，最低要求存在状态+准确安全删除。待验保存重开、Qwen地域独立、删除取消/失败/成功。
3. **R10提前说明权益限制。** Map/tasks负责：详情顶部显示尚无/到期权益，可查看导出但编辑需要订阅；或真只读+解锁编辑。订阅变化可观察，保留草稿/查看/导航/天气/删除；无需为此重做架构。待验expired能在输入前知道限制、购买后保存同一草稿。
4. **R11–R13最小适配与触区。** Map辅助字号/短高度收为1任务+查看今日，搜索有限高度滚动；Weather/TaskRow辅助字号纵排，Export换menu/list；clear、完成、policy/Weather links明确44pt。Map/Weather/Export/UI/Subscription各自负责。修后英语紧凑屏AX5+键盘/五长结果看截图和边缘命中；没有截图就没有PASS。
5. **R14消费者错误文案。** Weather和Planning/AI负责：天气暂不可用+Retry，签名信息留开发报告；密钥没有保存成功+重试，OSStatus不当正文主解释。中英资源同时更新，输入保留，不隐藏真实错误、不泄露密钥。

## 后续渲染和交互验收

SOURCE已关闭不重复实现，测试agent验证同一candidate：R02删除取消/确认、R03草稿取消/下滑、R04付费关闭、R06配置变化清旧preview、R07VoiceOver选中/取消、R09默认位置说明。R01 HTTP200不代替App内Link打开。

集中三套版式证据：英语紧凑AX5（地图搜索+Weather/Export/TaskRow），暗色Map/Today/paywall，iPad横屏Map/Today/paywall；另收商品不可用→retry成功、pending/active/expired状态。截图不替代真实服务请求或交易测试。

本轮没有UI运行PASS，未编辑产品实现或发布外部内容。R15–R18为P2取舍；保留18个历史编号不代表还有18个同等级发布阻塞。

## 真实设备截图复核（最新视觉证据）

证据：DEVICE_EVIDENCE/Final-gallery/manifest.json，将6张attachment对应testScreenshotGalleryOfPrimaryScreens。设备由测试agent确认iPhone17ProMax / iOS27.0.1；原图1320×2868。已逐张调用view_image查看；所有图是中文浅色演示模式。测试launch只设zh-Hans/zh_CN、seed-demo、demo-access，**没有显式设置AX5字号**；不能把看上去较大的中文文本当作最大辅助字号PASS。也没有英文、暗色、iPad、paywall、Weather、Export截图。Gallery测试PASS只表示截图流程执行完，不表示截图页面和业务语义正确。

### 六张逐页结果

| 页面 / 图片文件（位于Final-gallery） | 实际看到的内容 | 可确认结论与限制 |
|---|---|---|
| Map / 28E1F1FA-A12A-410A-AB6D-93044901838C.png | 上海真实地图、3个墨绿pins、今日3项0完成、展开2项卡，地图Tab选中 | **不是空地图，也不是错误Tab。** 地图顶部品牌「行迹」和日期上半部分被演示条截断（R19）；底卡两任务后大块空白（R21）。主地图区域仍可见，未证实AX5操作可用。 |
| Today / A625A4C4-B343-4D01-9195-AA6A836C8F37.png | 今日Tab选中、3任务、完整当地日期GMT+8、分行时长，奶白/墨绿统一 | 任务文本本截图无截断，日期+时长纵排已实际呈现。顶部导出控件仅露下沿（R19）。底部添加CTA被floatingtab盖住大半（R22），但没有scroll-end截图，不能断言末端仍无法露出。 |
| Editor / 710334AA-D36B-43FA-B6E9-86044F27078A.png | 「新建事项」、title/notes/location空，旧金山默认坐标、当天17:07 | **gallery测试意图是点击已有咖啡任务后看详情，实际变空新建**（R20）。默认地点说明清楚，但此截图不是已有详情读取PASS，不能验证当地时区/备注保留。 |
| Plan / C63BFDDA-001E-493D-ADE5-94F310C7B9BC.png | 规划Tab选中，固定锁定说明、日期/交通、生成本地计划和AI配置入口 | 无错Tab；默认表单可读，未见preview/冲突/Apply，不能证明规划完成。AI披露多段正文延伸到tab下面属当前滚动viewport，不单凭它写无法访问。 |
| Settings / 5D494052-4E6B-4C6A-9F23-6A1D43FE8C80.png | 设置Tab选中，品牌卡、偏好/数据/支持三组 | 品牌层次、色彩和分组舒适；底部支持链接未完整显示只是当前滚动位置，不是缺入口证明。没有订阅状态卡/暗色证据。 |
| AI / 011CD9F0-EA80-4496-88A0-C2F3CFB27B4C.png | 设置Tab保持选中，AI子页GLM/glm-5.3、披露与文档链接 | 子页保留设置Tab是正确导航。顶部返回控件只露下沿（R19）；必要说明占屏大、模型ID重复裸露（R23）；密钥区在下方未截图，不能证明key状态/删除修复。 |

### 新增实际缺陷与必要修复

**R19 · P1 / SCREENSHOT-CONFIRMED：演示banner裁切顶部内容。** Map品牌/日期、Today inline导航/导出、AI返回控件被顶部奶绿演示条遮住；Settings/Plan大标题没有同样被裁。RootView外层TabView safeAreaInset和子Navigation/Map布局交界需协调修复，不能只把每页标题手工向下挪固定像素。演示模式也是测试与商店截图使用模式，当前影响截图完整性与操作可见性；尚无非demo截图，因此不外推正式无banner模式也失败。UI implementation已收到图片路径，拟以外层正常VStack布局容纳banner；未验其修补效果。

验收：同一候选demo与非demo、Map/Today/AI标题和toolbar全露；AX字号/横屏无重叠；真实导出/返回可命中。修前6张不可作为最终商店截图。

**R20 · P1 / SCREENSHOT+LOG-CONFIRMED：已有任务打开成空新建。** Gallery代码261–270先点咖啡任务后拍Editor；log 2120–2140附近确认命中task.row.D943…，截图却是空白新建+SF默认位置。无权益读出测试也命中task.row.4B704…后读取task.title为空（log 1250–1283）。这是一致的上下文错误证据，不能归因为「点到了错误Tab」或「所有UI失败是定位环境」。

调查建议：追踪Today.openEditor传入task → editingTask → isPresented sheet → TaskEditor.init及draft；当前两个独立State和bool驱动sheet存在stale capture假设，但本agent未新增运行复现，不把假设称确诊。由owner核验item驱动单一编辑路由或其他实际根因，修复后必须点击3项分别验证稳定ID、标题、备注、地点和时区，并覆盖无权益只读。不要只改导航标题把空新建伪装成详情。

**R21 · P2 / SCREENSHOT-CONFIRMED：地图底卡多余空白。** 两任务后直到卡底有约100pt空区，使地图被更大面积遮挡；current MapScreen已加受限ScrollView，其frame(maxHeight:)仍可能扩展到180pt而非内容高度。这是布局解释线索，最终应按内容实际高度收紧，保留滚动上限。卡每项还缺开始时间，下一任务价值弱（沿R15）。无需为此增加图层或新旅行模型。

**R22 · P2视觉；交互阻塞待验：初始Today主CTA被floatingtab覆盖。** 截图中「添加事项」只读到上半部。应补scroll内容底margin/安全区，让滚到末端时CTA完整落于tab上方；单截图未显示滚到最末端，故不写「用户绝对无法添加」或已确诊点击失败。Settings/Plan/AI底部可继续滚动内容穿过native translucenttab也不能直接算同等缺陷。

**R23 · P2 / SCREENSHOT-CONFIRMED：AI设置说明密度高且模型字段重复。** 首屏长披露占约1/3屏，同一glm-5.3既作picker值又出现无字段标题的文本输入。保持真实数据披露，入口页先用短摘要+「完整发送与保留说明」，生成确认前完整展示必要内容；自定义模型选项开启后再显示带label输入，避免无label的重复modelID。此页还未见key section，不能借此关闭R08。

### 与失败症状交叉，避免误归因

- summary显示67项、56PASS/11FAIL（测试agent分类为49unit+7UI PASS）；gallery只占其中1个已执行测试。视觉review不重标其他失败。
- 两项Missing map.search及map point失败：gallery Map确有搜索field与真实地图，证明该元素并非所有启动路径永久缺失；需对各失败时层级/选Tab/alert/键盘判断，不能用gallery抹掉失败，也不能把全部归为地图加载空。
- ExistingTasks只读title空与R20直接吻合，应先修业务传参；galleryEditor不可当已有任务详情正确证据。
- Today AccessibilityAudit失败日志2530附近目标明确「今日完成进度」ProgressIndicator；failure element附件A6D66566…是细灰进度条，App附件BDA8…与Today同画面。此条本应非交互；优先给summary完整进度accessibleValue、将重复装饰bar隐藏/组合语义，不把进度条盲目变44pt按钮。需重跑audit证明关闭；本轮未能证明其他细link命中已通过。
- EnglishSmoke失败不能由6张中文图判断英语是否已修；LocalPlanning未完成不能由默认Plan图判断路线/preview为何超时；AI/provider、paywall、dirty取消、default位置NotHittable需要各自失败attachment/交互记录。明确不写这些均已视觉PASS。

后续最小截图：修R19/R20后重拍Map/Today/已有Editor/AI；补Today末端CTA、英语AX5 Weather/Export/Map搜索、暗色和paywall状态。当前中文默认表单读取良好，但最大辅助字号、英文与暗色仍为NOT_REVIEWED，不转换前述SOURCE项为运行PASS。

### 截图复核期间已同步的修补（SOURCE已落实，等待新证据）

UI implementation通知后已复读：RootView:8–22把demo条放外层VStack实际占位，移除TabView顶部inset（R19修补源码已落实）；Today:40增加32pt scrollContent底margin（R22待scroll-end确认）；Today:5/51/57及Map:18/30–31/173均改TaskEditorDestination驱动sheet(item:)并以destination.id重建编辑器（R20修补源码已落实，旧gallery仍证明修前失败）；Today:22–26给摘要完整进度value，隐藏重复视觉进度bar辅助元素（对应实际audit细条目标，仍须重跑audit）。

新源码不能覆盖旧截图来声称视觉修好。当前状态：R19/R20为SCREENSHOT_CONFIRMED历史缺陷+SOURCE_FIX_PENDING_DEVICE；R22为SOURCE_MARGIN_PENDING_SCROLL_END；a11y为SOURCE_SEMANTICS_PENDING_AUDIT。R21地图多余空区与R23AI信息密度仍需进一步设计调整或Owner裁决。其他R01–R18前半部状态是gallery前快照，下一轮需要对最终冻结源与新图一起复核，不能当作当前全部源码状态。

## 恢复回归后的最新SOURCE快照（尚无新版UI证据）

主会话反馈：用户恢复后运行计划为29项；目前9逻辑PASS，但20UI执行0，Runner设备信任状态阻塞，**没有新版截图**。前面的Final-gallery只代表旧候选，不能用于关闭新候选视觉门槛。本agent未执行设备或构建操作。

允许只读后再次复读当前代码，前半部「五组P1代码余项」已不代表当前源码缺口，更新如下：

| 项目 | 最新SOURCE结论 | 仍须运行验证 |
|---|---|---|
| R05 pending | SOURCE-CLOSED（原会话内普通购买重复入口） | SubscriptionStore有isPurchasePending、purchase guard，SubscriptionView pending禁用普通购买+检查状态+明确被拒后重试；交易更新/有效权益清pending。不能据代码宣称Ask to Buy/重启/恢复生命周期PASS。 |
| R08密钥 | SOURCE-CLOSED | AISettings显示provider/地域已保存/未保存/未知，onAppear及切换refresh；删除confirmation捕获provider/地域，未保存禁用；Keychain contains/read/delete均检查status，失败不称已删。待实测安全输入、状态切换和取消/失败删除。 |
| R10只读 | SOURCE-CLOSED | TaskEditor ObservedObject subscription、canEdit、Read-only顶部说明、Unlock入口、相关字段和Save禁用、草稿保留说明、权限变化关闭选择sheet。必须与R20一起检查已有数据真的传入。 |
| R11地图适配 | SOURCE-CLOSED（原缺AX/高度分支） | 动态字号/高度compact、受限搜索滚动、收卡至1项；无新AX图，交互余量未知。 |
| R12长英文布局 | SOURCE-CLOSED（原强制横排/segmented） | Weather AX AnyLayout纵排；TaskRow当地时间与时长拆两行；Export改menu。真实英语AX5不裁切和所有格式可选待验。 |
| R13触区 | SOURCE-CLOSED（原显式44pt缺失） | Map clear、付费close/policy links、Weather来源都已44pt约束。代码尺寸不是系统hitRegion PASS，需audit/边缘命中。 |
| R14诊断正文 | SOURCE-CLOSED（原签名术语/OSStatus数字） | Weather改检查网络稍后重试；Keychain userError映射解锁/稍后重试/联系开发者，未把OSStatus编号当正文。失败截图与英文资源调用仍待验。 |
| R19/R20/R22 | SOURCE_FIX_PENDING_DEVICE | 已读到banner外层VStack、TaskEditorDestination sheet(item:)+id、Today bottom margin。旧图不能评价新布局/路由。 |
| R21地图空白 | SOURCE_FIX_PENDING_DEVICE | Map卡改ViewThatFits：内容高度先自然展示，放不下才固定有界ScrollView。尚无新Map图确认空区收紧。 |
| Today进度audit | SOURCE_SEMANTICS_PENDING_AUDIT | 视觉bar辅助隐藏、摘要完整value，不以filter忽略问题。原failure来自ProgressIndicator，需新audit关闭。 |

当前优先待验点而非再改同样源码：①咖啡详情ID/title/notes/上海地点；②Map/Today/AI顶部控件；③Today_SCROLL_END Add可见且hittable；④同设备heading高度>正常1.4倍证明AXXXL生效，之后才评英语Map/Weather/Export/Editor可读；⑤新的hitRegion audit、key状态与pending行为。用户数据/演示任务中文不能直接算英文UI失败。

R15地图时间/未完成优先、R16结果timeline、R17复数/文件日期/英语fixtures、R18品牌付费墙/iPad/version、R23AI密度/重复模型字段仍为P2产品完善或待截图取舍。本轮源码检查没有发现应重新开放已修P1的证据；设备Runner阻塞仍未解除时不频繁轮询，不产出“新版视觉PASS”。

## 新候选 UI-noinstall-all20 独立复核（取代此前无新图状态）

候选锚点：UI-noinstall-gallery/candidate.json，已安装 Audit-fixes-combined artifact，main Mach-O SHA256 **6f4f35da7e5e723cb59f12dc820bf29662c6592de50387afc5905a67a56af595**；本agent不构建/安装/运行，收到并只读上述运行产物。summary及log：20UI=18PASS/1FAIL/1SKIP。三个gallery测试PASS；AXXXL采集前同设备Today heading高度>normal×1.4断言PASS，**没有附数值，不编造具体高度**。三套实际均为暗色；AX套为中文，不能宣称英语+AX组合已覆盖。

图片根目录：`/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/UI-noinstall-gallery/`。以下21PNG已全部view_image，文件名与manifest逐一对应：

| 页面 | 中文 | English | AXXXL（中文） |
|---|---|---|---|
| Map | E0E8C792-CB72-41A6-AA04-CFA97C3D2900.png | 838892D2-CB08-4FD6-B4C5-737ED817783E.png | A120B2DD-7A93-4037-8565-3D370BC53D77.png |
| Today | 97CF10FC-72C1-4D5D-9C3C-0DD9C5FFA9F0.png | 49BC7AB1-58F0-4298-A37D-E44F07D124AB.png | 606AFB90-055B-414C-8808-1A47B793FB76.png |
| Today_SCROLL_END | 007362F5-841B-4B5F-929D-CD8D20C039BC.png | 85F1B9DE-8931-4770-B499-C7AB58140FFB.png | 6917C00D-1C28-49DE-B668-0EC76EB72EC1.png |
| 既有coffee详情 | 8EFB33AE-2DF9-405E-B92D-120987C839E4.png | 76F0117E-5826-4A91-A876-54651612DCF2.png | 72F97B9E-8EC9-4D39-9F0E-B7B1DBD1FCEF.png |
| Plan | A74CBE1E-CC44-4D5C-A8D4-F409EE6F3664.png | E2CCA45C-034B-491D-B6F2-40F44124730E.png | 09920428-3C3E-4EA9-B329-6EFE3CDEA01F.png |
| Settings | C2AC7739-607D-4ED3-8925-32D0995807B3.png | 99675164-3E67-4C9E-80F8-CDDDC4E76EA2.png | 359A2BEB-7F8E-49A2-971D-2B0EA81239E1.png |
| AI | D7FB8ACA-1AA6-481C-8B1C-1C1D5514F336.png | 7B18C2AD-E8FF-4718-A9C4-79DC638EAE83.png | 0B362CEB-8802-460E-A798-50BA2E026939.png |

### R01–R23 的新候选关闭范围

| 既有项 | 最新独立结论 |
|---|---|
| R01 | 正式支持与政策入口存在，中/EN设置截图可见；同run英文paywall政策文字入口可见。前次HTTP200仍有效证据；本轮未点外部链接，不能称App内网络打开全部PASS。 |
| R02/R03/R09 | SOURCE关闭，加本runCreateEditPersistDelete、CancelCreation、BlankTitle相关UI PASS；不等同每条context menu/所有失败存储路径均覆盖。默认位置不明旧缺陷不再开放。 |
| R04 | 可见Done/返回在同run英文paywall图确认；subscription restore/manage展示测试PASS。商品pending/购买系统sheet取消仍不由此证明。 |
| R05 | 原会话内防重购SOURCE关闭；本20UI没有pending/Ask to Buy真交易场景，继续NOT_VERIFIED_LIFECYCLE。 |
| R06 | 本地planning生成preview且原事项不变测试PASS；参数变化失效源码存在，但gallery只有默认配置，不冒称各参数交互已测。 |
| R07 | selected trait/value SOURCE关闭；Today a11y audit PASS只针对Today，不替代AI选择VoiceOver。 |
| R08 | 密钥存在/删除保护SOURCE关闭；新run唯一FAIL停在ai.key.save触达，因此“四服务商保存删除整个流程PASS”仍不可声称，见R25。 |
| R10 | 无demoAccess的ExistingTasksCanExport…UI PASS，确认Readonly详情title正确+文本/Markdown/ICS读出。R20修后数据传入也有三套截图/断言；此范围真实关闭。 |
| R11 | AXXXL Map实际compact收卡、搜索field保留、地图仍为主区域，品牌日期按compact省略为设计行为。普通/EN地图真实加载/3pins、MapSearch/LiveSearch/MapPoint测试PASS；AX五结果/键盘组合仍未截图。 |
| R12 | Today三套当地日期/时间/时长分行可读，AX末端长日期换行完整；英文Export附件确认menu取代segmented。Weather AX不在这些图里，不能整体Larger Text PASS。 |
| R13 | Today contrast/hitRegion/textClipped audit本runPASS；显式44pt SOURCE已落。该audit不覆盖paywall政策/Weather链接所有控件。 |
| R14 | 消费者错误文案SOURCE关闭，gallery没有对应失败画面；不重新报WeatherKit签名正文仍存在。 |
| R15 | Map任务现在展示10:00/13:00及GMT+8，缺任务时间已实际关闭。未完成优先与查看今日快捷仍P2；不因样例中文当英文UI失败。 |
| R16 | 默认规划中/EN清楚，实际preview测试PASS；UUID排序/完整timeline仍P2视觉完善，gallery没有preview页可视觉评分。 |
| R17 | EN导航/页面/字段/日期/时长/导出实际已转换，用户fixture原中文正确保留。复数/filename日期/English自定义fixture仍P2，不是基本翻译阻塞。 |
| R18 | 暗色普通/EN/AX Map/Today/Settings文字层次可读，无墨绿字藏在墨绿底；发现实际paywall CTA对比缺陷升P1 R26。iPad/新light未提供图。版本动态读取仍按SOURCE状态，不拿这些图判断。 |
| R19 | **SCREENSHOT-CLOSED**：中文/EN Map品牌日期、Today导航/导出、AI返回全露；AX顶部banner不盖toolbar。 |
| R20 | **SCREENSHOT+TARGET-ASSERTION-CLOSED**：三套Editor为事项详情，coffee标题/备注/武康路/上海坐标正确；测试title非空且匹配断言PASS，旧空SF新建已消失。AX标题视觉省略是新R24，不能再称上下文为空。 |
| R21 | 仍P2：普通/EN Map卡隐藏按钮到任务之间有明显空隙；AX收卡合理。自然高度修补没有完全消除不必要空白，但不阻断地图操作。 |
| R22 | **部分关闭**：AXXXL scroll-end完整CTA在tab上方且hittable；正常中文/EN两个命名scroll-end的PNG与初始viewport一致，Add文字仍被floatingtab盖大半。测试scrollToElement在isHittable即停，不等于真正滚到末端/文字完全可见。见发布待闭合列表。 |
| R23 | 仍P2：中/EN密集披露+重复模型ID，AX首屏长文占满属预期放大，但配置操作需很多滚动。维持必要披露、优化摘要/展开和自定义字段标签即可；不把长文正常scroll viewport当裁切失败。 |

额外只读图片：同run `/docs/testing/DEVICE_EVIDENCE/UI-noinstall-all20-attachments/62347EC7-24B6-4C2E-8B49-F851AFBFF857.png`（EN_PAYWALL）和 `C599DA93-E2E6-4C2D-BF92-D226699CB0C1.png`（EN_EXPORT）；AI录像尾帧全路径如下。没有查看或读取桌面.env、真实key。输入内容仅安全字段像素遮蔽，不能猜测明文。

### 发布前仍须闭合的P1与最小修复

**R22 · 正常字号Today主CTA视觉。** [英文scroll-end图](/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/UI-noinstall-gallery/85F1B9DE-8931-4770-B499-C7AB58140FFB.png) 和中文007362…的按钮轮廓/label与浮动tab重叠；触达断言PASS不改变视觉缺陷。最小修复是增加真实scroll content尾部padding而非仅contentMargins。实现agent已改ScaledMetric headline的80pt内容尾padding；**这是后于该SHA候选的SOURCE，待新binary**。要求下一轮强制滚到末端，button完整rect/label≤tab.minY，中/EN/AX三种均检查；不用isHittable替代。

**R24 · AXXXL既有详情标题单行省略。** [AX Editor](/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/UI-noinstall-gallery/72F97B9E-8EC9-4D39-9F0E-B7B1DBD1FCEF.png) 可见「街角咖啡，慢…」。任务value正确，但视觉读不到完整名称；只读用户不应靠激活输入/水平移动光标查看内容。最小编辑态TextField(axis:.vertical)，只读态可换行Text，保持task.title标识和值。实现agent已落该SOURCE修补；**当前照片仍是修前binary，不能记PASS**。验证编辑+Readonly的全文值与自然换行高度/保存回读。

**R25 · AI保存验收未闭合，原因待分型。** [失败录像尾帧](/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/DEVICE_AI_KEY_FAILURE_FRAMES/DEVICE_AI_KEY_FAILURE_TAIL.mov.png) 由device_tests从同run录像38–39秒提取，非新操作/生成图。其Save row完整可见、在tab上方，画面**没有键盘像素**；不能确诊“键盘挡住Save”。trace仅证明button.exists=true且notHittable、Keyboard.exists=true；maskedSecureField无法据像素判断输入是否为空，已保存状态也可能是独立UI测试service旧值。

SOURCE：AISettingsView的Save禁用条件为trimmed input为空，正确但尚无失败时isEnabled证据；页面没有FocusState/keyboard Done/scrollDismissesKeyboard。最小先用合成测试key确认field输入非空长度、Save.isEnabled、rect与keyboard frame（不输出真实key或测试明文）；区分输入未进入/disabled、覆盖与测试scroll问题。必要UX补齐是FocusState、键盘「完成」关闭焦点和交互滚动收键盘，保存按钮复用同一校验。**不要仅增加swipe次数或删除失败断言来关闭。** 无根因结论前它是P1验收gate，不是假定已证实UI布局bug。

**R26 · 暗色付费主按钮极低对比。** [EN_PAYWALL](/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/UI-noinstall-all20-attachments/62347EC7-24B6-4C2E-8B49-F851AFBFF857.png) 的Start7-day trial是白字极浅底，几乎不可读，属于实际截图缺陷。源码borderedProminent继承Theme.ink暗色F2F5EC；white/F2F5EC计算约1.10:1。统一actionFill/actionLabel的深字浅底约10.90:1。实现agent已将购买按钮改WaypointPrimaryButtonStyle；**SOURCE已复读，当前候选图仍旧样式**。新运行截图需确认eligible/ineligible/loading/disabled都可读，不把disabled淡化当正常按钮对比验收。

AX Plan099204…的开始日期行有横向溢出迹象，但恰处viewport底部，仅凭此不判“不可选择日期”；补该行完整滚动截图再决定是否新P1。AX Map pin/定位SF图标随字体放大超出固定圆底是P2视觉比例，命中区/标签已保留。

### 优先级裁决与证据边界

本轮已真实闭合旧的空详情与顶部遮挡，且基本英语/暗色/AX收卡不是发布阻塞；**剩余P1为R22、R24、R26新SOURCE的真机复验，以及R25唯一失败的最小诊断和修复验证**。R21空白、R23密度、timeline、英语fixture与iPad布局美化不得与它们混为18项“全都失败”。

Today accessibilityAudit本runPASS，包含contrast/hitRegion/textClipped；NotificationDenial是1SKIP，不假记PASS。无pending交易生命周期、Weather AX、iPad、English+AX组合图；不宣称所有无障碍或所有地区服务验收完成。AppStore价格显示US$9.99取自该运行商品，不以设计预期数字覆盖实际StoreKit显示；本图不是生产价格配置证明。

## Input-layout-focused 中断后两张原始PNG：仅可见范围

manifest位于DEVICE_EVIDENCE/Input-layout-focused-raw-pngs，明确caseAssociation未证明、xcresult finalization中断。两张均独立view_image，不能算focused用例PASS或新版完整gallery。

- `data.0_UofU8JMARxA3aO0FY5g5lQRyHzOmWXFi-xYbawDkU6nwZv_rRzi1NY6YBCcAuwDdfceDTWnPZyhW9DyZW3VcbQ.png`：实际为21:41英文暗色Today，导航/导出完整，3项内容正常，未见modal或错误提示。Add文字仍大半在floatingtab后；视口像初始列表，**没有scroll-end证据，所以看不出真实尾padding改善，也不能据此判尾padding失败**。R22继续待末端rect/全文验证。
- `data.0_dcs53keMgzk7jcr25o8JodTOWw7QsfTvTTxfj5Utz7nbEO-5a5fHZIjD-3cDAQwObJVfZTY6pu10jj4MF4bBTw.png`：实际为21:41英文暗色Map，真实地图+3pins、搜索和今日卡正常，顶部不被banner裁，未见modal或空地图。该图不含Today滚动，不提供padding效果证据。

本次focused因guard76.7%停止，首项EnglishMarketSmoke snapshot timeout FAIL、第二未完成。正常静态画面只能证明取图时内容存在，不能排除snapshot/accessibility服务问题，不能证明交互已恢复或将超时归为产品crash。未新增测试或研究，UI回归仍未闭合；不使用旧截图冒充新结果。

## 已安装 J1：minimal-config 单用例的独立视觉结论

依据 `docs/testing/DEVICE_SNAPSHOT_CONFIG_CONTROL_RESULTS.md` 与 `DEVICE_EVIDENCE/Snapshot-minimal-config-single-attachments/manifest.json`。本次 EnglishMarketSmoke 实际执行 43.839 秒，最终 **1 FAIL（contrast audit）**；已走到 AI 说明、导出往返、商品价格与购买按钮。没有新构建、安装或设备操作；此证据不覆盖 R22 末端、R24 AXXXL 标题或 R25 四服务商保存。

图片根目录：`/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/Snapshot-minimal-config-single-attachments/`。

- **R26 正常暗色 eligible CTA 视觉已改善**：独立裁图 `C2ECAD23-AAC1-48ED-BC91-3D852B87537F.png` 显示深绿字、浅绿底，完整可读的 “Start 7-day free trial”。原白字浅底缺陷在本候选此状态关闭；不能扩展为 loading/disabled/ineligible 或整个无障碍审计 PASS。
- **干净候选付费页**：`640F9D2F-B7AA-4A0B-B3B4-25C6C5EBFE74.png` 没有系统私人通知，Subscription 标题、US$9.99 / year、7 天试用资格及随后自动续费说明、完整购买 CTA 和 Restore purchases 均可见。可以保留为该候选的 subscription review 截图素材，发布前仍需确认提交 binary/商品配置一致；它不是完整长页或生产价格配置的证明。
- **受系统遮挡的图不作产品失败定论**：`911A59F5-66C0-4B0D-A153-D4A017DB712A.png` 实际含外部私人系统通知，遮住导航标题。记录中的失败元素为导航标题裁图 `8B8F29D6-A42F-4C44-B990-65A32912AA11.png`，整页 `B683CD88-9AF9-40FF-8880-FCA3B603F96B.png` 同属受通知干扰的证据。独立 CTA 图与干净全页没有旧对比缺陷；因此本次 FAIL 不足以重新确认 CTA 产品缺陷，**也不能改记 PASS**。这些含通知图仅保留本地诊断，不嵌入报告、聊天或商店材料，不复述内容，不修图移除遮挡。最终无通知、未过滤 contrast audit 待验证。
- **新分析说明可读且符合当前范围**：`4279650F-C260-4C30-9C5B-F4A5D447D5E1.png` 的英文两段完整换行：导出记录自行交给 AI 服务无需 App API key；在 App 内分析则配置自己的 provider API key，费用由 provider 收取。导出入口清楚，没有暗示 ChatGPT 订阅连接已支持。
- **分析导出目的页正常可见**：`2F9FB06B-6944-4D89-96F4-1112D0DD0E7A.png` 显示英文 Export tasks、日期范围、设备时区、格式选择、3 项记录和预览。中文用户样例内容保留正确；该截图不证明外部 AI 上传或真实 API 请求完成。

最小剩余：R22/R24 的指定滚动与 AXXXL 新图、R25 四服务商保存验收、R26 无系统通知的最终未过滤审计。当前不追加产品修补建议；无关美化仍按 P2，不把系统通知遮挡升级为新的产品 P1。

## English-minimal-after-DND：无通知对照仍 FAIL，确认为新的 R27

只读核对本轮 manifest、Complete Issue Description 与三张必要图片；未运行或改动产品。证据根目录为 `/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/English-minimal-after-DND-attachments/`。设备执行报告为 single contrast FAIL、peak69.8%、无 snapshot timeout；不以先前通知解释本轮失败。

**R27 · P1，付费页管理入口被浮动 TabBar 遮挡。** 本轮失败元素裁图 `E4B050C4-BD61-47BA-9FEF-1F8689296A49.png` 显示 “Manage or cancel subscription” 文本上覆盖 Map/Today/Plan 的白色 tab 图标。失败整页 `9DA77339-FDCA-4AAF-BBC3-9B8B1E98A689.png` 无私人系统通知，Subscription 导航标题完整，底部管理入口确实位于浮动 TabBar 后；其对比变差来自真实界面叠层，**不是本轮采集通知干扰，也不是购买按钮配色回退**。Issue Description 只有 “Contrast failed for element”，不能编造审计数值。

购买独立裁图 `842B386E-8461-4349-B9C3-E2E8C10F5A9F.png` 仍为清晰深绿字/浅绿底。R26 的本候选正常暗色 eligible CTA 视觉关闭范围维持；整页价与资格说明可见，实际测试仍 FAIL，不称全页无障碍通过。

关联 SOURCE：`SubscriptionView.swift` 为 ScrollView/VStack，管理 Button 位于恢复购买后、政策 Link 前，只有通用24pt内容padding；`RootView.swift` 的原生 TabView 保持可见。`WaypointPrimaryButtonStyle` 显式 Theme.actionLabel/actionFill 正常，不需要调整全局色tokens或过滤 contrast audit。订阅入口除 Settings NavigationLink push 外，还有 Map/Today/Planning/TaskEditor 四处 sheet。

**最小修补建议**：仅在 SubscriptionView 作用域使用 `.toolbar(.hidden, for: .tabBar)`，让购买/恢复/管理/政策成为独立完整流程；保留现有 Done、返回、管理与政策 actions/IDs。sheet 本来不显示 tab，不应新增导航依赖。不要在 Root 全局隐藏或用全局状态切换，也不要仅追加尾padding：尾padding改善能滚到的末端，仍可能让本次初始viewport中的管理元素被浮动tab实际覆盖。

修补后最小验收：Settings push 初页无 TabBar 遮挡且未过滤 contrast audit；滚动后管理/隐私/条款全文及控件完整可操作；Done/导航返回后四个 tabs 恢复并可切换；至少一个 sheet 入口打开/关闭后原页 tabs 正常。中文/英文、大字号按同规则检查，不能用元素 exists/isHittable 替代可见完整轮廓。root 已接受建议并授权实现agent单文件修补，**此处仅记录建议，SOURCE/runtime 尚待对应新候选证据**。

## 已安装 J1：Input-layout-minimal-gallery3 独立图检

候选 manifest/candidate 位于 `/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/Input-layout-minimal-gallery/`；原始导出位于同层 `Input-layout-minimal-gallery3-attachments/`。21 张原始 PNG 已独立查看，字节 SHA 与整理 manifest 完全匹配，均无私人系统通知；没有重新采集、改图或运行设备。运行为 **3/3 PASS，exit0，peak71.7%**，AX gallery 的同机 heading.height > 默认 ×1.4 验证由测试完成；不编造未附高度数值。

候选锚点：mainDebugDylib SHA256 `b16498fd9e4fcc3404042b2c1d579edf9e4f04dfeb3022fa24bcdb550824d313`；UI test bundle SHA256 `fa2d52ee88012937f567e344d764062a42437a5887c42cadbd1d4672219681db`。当前 SOURCE 已向前移动，**R27 隐藏付费页 tab 的源码变化未进入该 binary**，本 gallery 也不含 Subscription，不用于关闭 R27。

| 风险与范围 | 本轮图片及具体结论 |
|---|---|
| R22 Today 末端主 CTA | **SCREENSHOT-CLOSED**：中文 `08077D68-70AA-4C80-AB72-ACC225249B4E.png`、EN `AC4D9108-337D-41F9-834F-B5FD1C4FD341.png`、AX `505D1C05-6C67-49D9-BCD7-D8407D34536C.png` 均显示完整 Add 轮廓、图标及全文，与浮动 tab 之间有留白；本 run 同时有 frame.maxY ≤ tab.minY 断言。此前 content tail 的具体问题真实闭合。中/EN初始viewport仍会有 CTA 部分位于tab后，但真实末端可以完整滚出；不把初始图误认作scroll-end，也不声称整页未过滤audit已覆盖。 |
| R24 AX 编辑态标题 | **编辑态视觉闭合**：`52846B5A-105C-42EB-BAA4-BE1D73D48E22.png` 为既有 coffee 详情，标题「街角咖啡，慢慢开始」完整两行，备注完整换行，无省略号。普通中/EN详情也正常。Readonly长标题、编辑保存回读及位置更换后的AX顶部仍由专门titles测试验收，不以gallery扩大关闭范围。 |
| 新 AI 分析方式 | 中文 `03171880-02F4-4F9E-ACDA-B84AEF2F02B8.png`、EN `A0E2CF89-C45E-444A-8D07-E18734FE281D.png` 两路说明及导出入口完整可读，区分自行导出无需App key与App内自带 API key/provider计费，符合最新用户范围。AX `49077E0E-D45A-4D49-BD16-3386B3308490.png` 第一段自然换行，导出入口跨viewport底部；第二段不在首屏不是缺失证据。AX导出入口与API字段滚动操作仍未由截图单独证明。 |
| R19/R20 上沿/既有详情 | 中/EN/AX顶部banner、导航、导出/返回均未被banner遮；三个详情均为正确coffee事项，不重新开放空白新建缺陷。 |
| 地图/AX | 中/EN实际地图、3pins和任务卡可见；AX `F1C1C659-14D1-4C27-8759-46B8481C6AA1.png` compact收卡保留地图主舞台、搜索和Add。大号pin/定位图标溢出圆底的比例仍P2；普通地图卡内不必要空隙R21仍P2。 |
| AX 规划日期行 | `404D9520-47D9-44A6-A6BF-1CC54DAE2B69.png` 底部开始日期行仍呈横向溢出/左侧label贴边迹象，日期值又位于浮动tab附近。与旧图同样需要该行完整滚动后截图及选择交互，不能从首屏底部单帧判定控件不可操作；保持待验风险，不把gallery PASS当日期行完整布局PASS。 |

全部图中，普通 Settings/AI/Planning 的长内容也会从浮动tab后经过；其可滚动首屏不能证明永久遮挡或已通过contrast。R27无通知失败有精确audit元素，不能将其结果机械推广为这些页面全失败。此gallery未新增已证实P1；剩余独立视觉/交互重点为 R24 Readonly与保存回读、R25 四服务商保存、R27 新候选付费页及返回tab恢复。R22已关闭，避免继续列作同一发布阻塞。

### titles2 失败的证据限制

device报告 `Input-layout-minimal-titles2` 两例分别64.089s/64.053s FAIL、peak73.3%，同编译版 line331 等待 task.title 失败。附件仅4张 NORMAL截图，没有AX failure PNG；现有录屏未提帧，root要求不额外转码，本agent未处理视频或复读NORMAL图。trace为 t48.76 上滚内容、t51.79 点击 location.confirm、t52.71 等 title 至62.8失效，支持“确认后仍停留Form中段、顶部lazy cell未进入查询树”的待证假设。**不能视觉断定确认页面异常或title数据丢失，也不能称AX保存回读PASS。** 返回顶部再保留全文值/高度/保存回读断言是最小测试修正；等待对应新候选结果，R24仅维持gallery中编辑态样例标题的关闭范围。

## R27-after-restart 新候选：原遮挡独立关闭

只读检查 `/Users/geruyang/AIProject/MapToDoList/docs/testing/DEVICE_EVIDENCE/R27-after-restart-english-attachments/manifest.json` 对应两张新 PNG，以及同层 `R27-after-restart-english-summary.json`。root确认此候选已经构建/签名/安装，非旧J1；本agent未改源码、构建或重跑设备。summary为 **EnglishMarketSmoke 1 PASS、0 FAIL、0 SKIP**；root报告 peak68.3%。

**R27 SCREENSHOT + RUNTIME CLOSED（此英文暗色候选）**：`B21ECA99-10D2-44AF-8F48-EF5A2888BF28.png` 显示 “Manage or cancel subscription” 全文在黑底上完整露出，没有浮动 TabBar 及图标覆盖。`4653749F-36B5-4FD9-BADD-31971D6BAC40.png` loaded paywall 同样隐藏tab，购买 CTA 深绿字浅绿底清楚，US$9.99/year 与7天试用说明可见。二图无私人系统通知；不改图或掩盖任何系统UI。

该测试当前保留未过滤 `.contrast` 审计，并检查管理/政策可触达、Done后4tabs存在且hittable、Today无权益创建的subscription sheet打开/关闭后Map搜索可用。结合真实PASS，这些初页对比、push退出和sheet退出行为均有运行证据。它不是全语言/全部字体/全部购买状态的无障碍证明，也不包含真实购买transaction。

证据边界：B21…图的隐私/条款行位于截图最下沿，不能独立声称政策全文已完整取图；测试hittable支持可操作。若准备审核长页素材，后续需更低viewport完整政策行，当前不为此重开已修R27。R26正常eligible CTA关闭维持，本轮无需额外产品修补建议。

## R27-after-restart titles2/key-export：R24关闭，R25局部通过且整例仍失败

本节只读当前已安装新候选产物，不重测，不读取真实Key或.env。

**R24 SCREENSHOT + RUNTIME CLOSED**：`R27-after-restart-titles2-summary.json` 实际2 PASS；两用例均执行normal/AXXXL编辑保存与terminate/relaunch，且保留全文相等（editable.value/readonly.label）、自然高度 > 单行 ×2.5、maxX不超屏幕、readonly为StaticText及Save禁用断言。只读review四张AX图片，均无私人系统通知：

- `R27-after-restart-titles2-attachments/D594D20F-DFB6-467D-A7D9-E9CF23FF7634.png`、`C5831A01-7909-4488-908F-5AE3461CBACE.png`：编辑长标题自然多行，无横向单行省略；键盘占据下半viewport，因此输入截图本身不包含全部末尾，这不是数据截断证据。
- `0EBB4FBE-8397-4645-B3C0-83217E96402C.png`：保存重开后的长标题一直换行到可见的「末尾完整标记」，没有键盘、ellipsis或单行截断。
- `EE1F6E1D-A2FF-47D9-99E5-33728A5F6CEC.png`：只读提示、禁用Save、长标题开头自然换行真实可见；全部标题超过首屏，完整内容由上述全文label/高度/屏幕宽度断言验证，不冒称单张照片已经展示每个字符。

**R25 原Done/Save触达问题局部已验证，整key用例仍FAIL**：`R27-after-restart-key-export2-summary.json` 为1 PASS/1 FAIL；ExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess 实际43.895s PASS，四provider Key用例168.241s FAIL。独立日志确认 GLM/Qwen/DeepSeek/OpenAI 四轮均完成安全字段非空/遮蔽、Done收键盘、enabled Save点击、已保存状态、取消删除仍保留、确认删除后无key状态及Delete禁用，过程中没有断言失败。Done→Save分别发生在28.94→31.92s、62.99→65.94s、94.81→97.74s、129.32→132.27s，各轮中间keyboard absent断言成功。使用的是UI测试无效凭证，不代表实际provider认证/API费用或请求成功。

唯一失败位于最终relaunch后重新选择OpenAI，t166.95s直接检查 SecureField.exists（编译版line470）。末断言前没有与循环相同的scrollToElement("ai.key")；Form下部lazy field未进入当前viewport是合理待证假设，**不能据exists失败断言产品字段或凭证数据丢失，不能改记整例PASS**。`R27-after-restart-key-export2-attachments/FE3974C0-D305-4586-94FF-805F8562C39F.png` 是四循环完成、relaunch之前的记录，不是失败现场。R25只保留最终重启后字段触达/验收待闭合，不再描述为“四厂商保存按钮全部不可触达”。root/device正在诊断，当前不提出未经证实的产品修补。
