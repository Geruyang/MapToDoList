# Privacy manifest 与 App Privacy 发布审查

审查日期：2026-10-11。只读产品代码与官方资料；仅新增本报告，没有修改 `PrivacyInfo.xcprivacy`、产品源码、凭证或 ASC，没有运行 build/test/simulator。供应商实际账户模式、保留设置和日志仍按 [AI 隐私审查](AI-PRIVACY-REVIEW.md) 的 Unknown/NOT_RUN 处理，不替发布主体作供应商选择。本报告完成后冻结。

## 结论与责任边界

`MapToDo/PrivacyInfo.xcprivacy` 的 `NSPrivacyCollectedDataTypes` 在初次审查时为空；主会话已补充两类数据，现行值见文末首版复审。**当前支持第三方 AI 且允许默认留存模式的发布形态下，应在上线前补充；不建议原样以空数组签核发布。** 这不是 plist 格式错误，也不能仅凭一次上传未报错宣称隐私合规。源码明确向服务发送用户事项内容，既有政策审查已发现多个默认模式会保留请求；应用没有技术或合同保证所有允许配置都仅即时处理后丢弃。最终具体条目/布尔值/用途须随实际允许的服务、账户模式与政策签核，不能将某一家 ZDR 套用到所有 BYOK。若以后产品限制到经核实严格即时处理且无可读留存的模式，空收集数组才可重新评估。

Privacy manifest 是包内结构化声明，用于描述本应用数据收集、tracking 及 required reason API；Xcode 汇总它与链接的 SDK 清单生成 privacy report。第三方 SDK 自己的清单承担 SDK 收集；本应用用自己的 URLSession 直接接入远端 AI，不是链接一个可替我们申报的 AI SDK，因此不能借 SDK 清单规则省略本应用发起的处理。报告辅助填写 ASC，**不会代替 ASC 问卷或公开隐私政策**。[Apple：manifest 数据声明](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests)、[Apple：manifest 文件](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)

App Privacy 是产品页面向用户的披露，发布方须核实应用与合作服务的实际收集/关联/用途并持续更新。Apple 的收集定义关注离开设备后是否可访问超过即时服务请求所需时间；本地存储本身不算收集。逐次同意、功能可选和 BYOK 不自动构成可省略披露；AI 排程属于应用功能，不能直接套用偶发反馈表例外。不同选项/地区的收集须合并披露。这里只负责开发者自身处理；Apple 独立通过 MapKit/WeatherKit 收集的数据不机械归入开发者收集。[Apple：App Privacy](https://developer.apple.com/app-store/app-privacy-details/)

## 当前证据

- `AIService.suggest` 发送选中事项原始 `title`、`locationName`、UTC `start/endWindow`、时长、是否灵活、每次随机任务编号，以及所选模型与协议配置。无 notes/经纬度/提醒/天气路线正文。
- 请求以用户 API Key 认证服务账户；原始标题/地址未匿名化。随机任务编号减少稳定记录关联，不等于使内容或服务账户不可关联。
- OpenAI `store:false` 只是一项请求选项，不证明组织零保留、安全日志关闭或其他供应商相同行为。实际保留/训练/区域详见已有审查。
- 应用没有广告/IDFA/数据经纪调用证据；任意公网 endpoint、身份关联或训练用途本身不等于 Apple 定义的 tracking。
- 本地提醒偏好与 Qwen 配置通过本应用 `UserDefaults.standard`；导出清理通过本应用临时目录文件的 `contentModificationDateKey`。

## 建议的精确 manifest 值

下表是交发布主体核验的映射，不是已经应用的配置。每个收集条目需 `NSPrivacyCollectedDataType`、`NSPrivacyCollectedDataTypeLinked`、`NSPrivacyCollectedDataTypeTracking`、`NSPrivacyCollectedDataTypePurposes`。枚举必须采用 Apple 官方值，不能自造 `TaskTitle`、`Schedule`、`AITraining` 等枚举。[Apple：数据类型枚举](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype)、[Apple：用途枚举](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatypepurposes)

| 源码数据/实际处理 | 官方类型建议 | 当前建议与待核实事项 |
|---|---|---|
| 原始标题、事项时间/窗口/时长/灵活性等用户编排内容 | `NSPrivacyCollectedDataTypeOtherUserContent` | 允许正文留存的模式应声明；`Purposes` 至少 `NSPrivacyCollectedDataTypePurposeAppFunctionality`（排程/安全/服务功能）。没有证据前不能只因内容个性化就选 ProductPersonalization。 |
| `locationName` 指向可准确定位的计划到访地点，可为完整地址/特定 POI | `NSPrivacyCollectedDataTypePreciseLocation` | 推荐按支持的最高实际精度声明；无坐标不证明不精确。发布主体确认是否可关联用户计划位置以及实际可定位精度。若产品另有仅城市级独立收集再评估 `NSPrivacyCollectedDataTypeCoarseLocation`，不机械重复两者。 |
| 地点字段中的住宅/邮寄等用户物理联系地址 | `NSPrivacyCollectedDataTypePhysicalAddress` | 条件项：若实际以联系地址语义收集应加；任意商店/场馆目的地不要机械当用户联系地址。与 PreciseLocation 分别核验。 |
| 服务账户认证与可留存账户关联元数据 | `NSPrivacyCollectedDataTypeUserID` | 待账户/合同核实；Key 仅瞬时认证且不留存不自动成为所收集ID。临时任务编号是记录ID，不能自动当用户ID。 |
| 请求频次/模型/token用量等被留存并用于使用分析 | `NSPrivacyCollectedDataTypeProductInteraction` 或 `NSPrivacyCollectedDataTypeOtherUsageData` | 按实际日志语义选，不二者机械同时勾；分析目的确证后加 `NSPrivacyCollectedDataTypePurposeAnalytics`。 |
| 技术性能/网络诊断日志 | `NSPrivacyCollectedDataTypePerformanceData` 或 `NSPrivacyCollectedDataTypeOtherDiagnosticData` | 条件项；IP需按实际用途归类，不自动等于DeviceID或位置。供应商可能有日志不等于已经确认全部类型。 |

对已确认留存的事项内容，`Linked=true` 是当前保守且有依据的建议：服务账户认证、原始内容及位置仍可与个人关联；证明发送前不可重新识别并且服务不重新关联后才能改 false。**本报告不替未知账户签核此布尔值**。`Tracking=false` 与顶层 `NSPrivacyTracking=false`/空 domains 在当前无广告追踪证据下有源码支持；仍应核实合作服务用途，若证实 tracking 需另行修改披露和合适授权流程。不要把普通 AI API 域名全部列成 TrackingDomains。[Apple：linked 与 tracking](https://developer.apple.com/app-store/app-privacy-details/)

供应商为自身模型改进/其他用途使用保留内容时，须核实是否需增加 `NSPrivacyCollectedDataTypePurposeOther`；不能只写 AppFunctionality 掩盖已确认的额外用途。`NSPrivacyCollectedDataTypePurposeAnalytics` 专指用户行为/产品分析，不与所有训练自动画等号；安全/防欺诈可属于 AppFunctionality。最终用途是数据实际如何使用，不由应用发送按钮决定。[Apple：用途定义](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatypepurposes)

## Required reason API：当前两项可以保留

| 类别 | 现有 reason | 与当前源码的吻合性 |
|---|---|---|
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | 读写仅本应用可访问的偏好/本地记录。没有共享suite、读取其他应用或系统偏好的证据；此reason不授权这些行为。 |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | 导出清理读取本应用临时容器内文件的修改时间，符合访问 app container 文件元数据的用途。 |

以上是 API 访问理由，不是数据收集类型/目的，也不是 URLSession/AI 的额外授权 reason。没有为网络发送自造 required API reason；未发现需要机械添加 DiskSpace/SystemBootTime 的直接源码证据。本次不是最终二进制/所有依赖扫描，最终归档仍需核查实际 bundle。准确 reason 来自官方当前键值表：[Apple：NSPrivacyAccessedAPITypeReasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons)、[Apple：required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)。

## 发布主体下一步

1. 确定本版本实际允许的供应商、地域、付费/免费模式、留存/训练设置；为内容、身份关联与日志类型获取可用合同/政策证据。Unknown不能签成“没有”。
2. 按上述映射补齐已确认的 `NSPrivacyCollectedDataTypes`，与 ASC App Privacy、公开政策及发送前说明一致；未来支持的新模式重新审查。仅改ASC不能让包内空声明变得准确。
3. 最终归档确认 manifest 已进目标资源，生成 Xcode Privacy Report，与正式 ASC 回答逐项核对。此步本轮 **NOT_RUN**；未运行构建或上传，不声称已获得 App Review 批准。

本轮仅给出可审查的修订建议，未替未知供应商/发布方选值，未修改源 manifest。

## 主会话已落实的最小披露

主会话此前已补OtherUserContent与PreciseLocation，linked=true、tracking=false，用途AppFunctionality及Other。初次用途依据包含Gemini免费模型改进；首版决定禁用Gemini后，该依据不再适用。现行四服务版本的重新判定如下，不沿用Gemini作为Other理由。是否保存ASC问卷及最终归档由主会话记录，本报告不推定其状态。


## 首版禁用 Gemini 后复审（2026-10-11，现行结论）

用户决定首版关闭Gemini；本报告的发布范围为GLM、Qwen、DeepSeek、OpenAI。Gemini相关前文保留为历史/未来重新启用时的审查资料，不能用于当前Other用途或当前年龄/计费门槛的依据。关闭实现由AI负责人处理，本轮未构建验证UI/调用边界，正式归档前须确认Gemini不能选择、刷新或生成，包括旧偏好回退。

manifest实际路径为 `MapToDo/PrivacyInfo.xcprivacy`，不是 `Configuration/PrivacyInfo.xcprivacy`。本轮读取的两条数据声明均为OtherUserContent与PreciseLocation，linked=true、tracking=false、purposes=[AppFunctionality, Other]。**本轮判定无需删Other，未改manifest值**；原因不是“未知就多报”，而是仍启用的BigModel开放平台官方政策明确容许独立于排程/安全功能的匿名化研究和模型改进用途。此项是基于现行允许处理范围的应用，而非声称某个已发送样本被训练。

- **GLM有独立公开依据**：[BigModel开放平台隐私政策](https://docs.bigmodel.cn/cn/terms/privacy-policy.md)的定义/范围包括开放平台API；其信息使用条款容许对收集信息匿名研究、统计分析、预测和改善产品，并提及匿名数据机器学习或模型算法训练。政策的匿名化定义要求不可识别、不可复原；应用发送前没有匿名化标题/地址，服务后续处理成匿名数据不取消最初的收集。将超出实时排程/安全的模型训练用途映射到Apple的Other，是本次审查判断；不是Apple专门发布的“GLM训练=Other”结论。具体API账户是否有更优先的合同禁止训练、是否仅即时匿名化且无可读留存，仍未验证。
- **DeepSeek是额外风险依据，不是API实证**：[2026-02-10官方政策](https://cdn.deepseek.com/policies/en-US/deepseek-privacy-policy.html)列出输入内容、训练/改进、留存和下游开发者披露责任。其范围措辞不足以独自证明本应用每笔chat/completions被训练；未发现覆盖当前API账户的禁止训练/零留存合同。禁止用“没有找到账户保证”反向证明实际训练，也禁止拿它保证无训练。需补API账户合同/DPA/开关证据。
- OpenAI默认API不训练、Qwen国际政策的保留/账户控制，不能成为其他服务相同用途的证明；授权共享、Qwen中国地域和账户特约继续按原AI报告核验，不新增未经证实的用途。

在四服务聚合披露下，标题/行程与可定位地点一起组成送往GLM的正文，允许的模型改进可能作用于正文，因此两类保留AppFunctionality+Other有一致依据。若取得适用于本版本所有可用GLM/API账户的合同证据证明这些输入绝不用于此类额外目的，且其余服务也无该目的，才应移除Other。不是以当前未运行真实请求来推定零收集；也不是将安全日志自动当Other。

### ASC可确定项与尚未确定项

| 项目 | 当前结论 |
|---|---|
| 是否可以选Data Not Collected | 不可以：当前发布允许留存服务处理原始用户内容/地点，未保证全部实时丢弃。 |
| Other User Content / Precise Location | Yes；用户标题/计划与可精确定位的地点正文。无经纬度不等于无精确地点。 |
| 上述两类关联用户 | Yes；API账户认证且内容未在发送前去标识化，随机记录ID不足以证明不可关联。 |
| 上述两类用途 | App Functionality与Other Purposes；Other依据现行GLM政策允许的模型改进，非已关闭Gemini。最终提交需发布主体接受该政策解释及核验账户特约。 |
| Tracking | 当前代码/已审政策无广告测量、广告跨站关联、数据经纪证据，维持No有依据；不能把训练或账户关联当tracking。合作方实际额外用途仍需最终签核。 |
| User ID / Usage / Diagnostics / IP分类 / 联系地址 | 尚不能从正文源码和通用政策一次性决定；需供应商实际API日志、账户关联、保留和用途证据，不因网页cookie条款机械勾全部类型，也不以未知签成No。 |
| 其他类别/其他处理 | Apple独立收集、StoreKit/支持页面等须整App合并审查；本报告AI结论不替代完整问卷。 |

本轮检查仅官方政策、源码和plist文本；未读取用户Key/供应商console，未运行真实AI请求、build/test/simulator，未改ASC或网站。manifest的两数据条目及reason保持原值；文档已撤销Gemini作为现行Other依据。未来供应商/模式变化必须再次更新清单与ASC。
