# ASC App Privacy 提交矩阵

2026-10-11，首版GLM/Qwen/DeepSeek/OpenAI，Gemini禁用。仅源码和官方资料审查；初轮仅新增报告；后续主会话授权更新manifest和官网隐私页（未发布），本轮未修改ASC、读取Key、构建或启动模拟器。主会话报告40项logic PASS且真机UI smoke在进行，本报告不将这些结果视为供应商留存/隐私验证。

## 提交用结论

回答“是否收集数据”：**Yes**。本次发现API级明确默认日志依据，原content+preciselocation两条清单不足以覆盖全部已确认类别。建议ASC新增 **User ID、Other Usage Data、Performance Data、Other Diagnostic Data**，并同步最终manifest/公开政策；后续官方API条款核查及发布主体解释已闭合Coarse Location和Device ID为Yes，现为最终八类。四者是应用实际API调用产生的日志，不是供应商官网注册联系人/付款信息。下表所有Yes的Linked均Yes、Tracking均No；身份关联和训练不等于广告tracking。

最关键新证据：[Qwen官方 Model monitoring](https://www.alibabacloud.com/help/en/model-studio/model-telemetry)说明默认平台审计日志包含API key ID、调用时刻/模型、token用量、延迟、状态/错误，可查询最多30天；完整prompt/response inference日志另需手动开启。具体API请求的这些数据已超出即时请求存在；监控按workspace/API key关联，足以支持下列身份、活动和技术诊断类别。本文没有假定所有四家都保存完全相同日志，也没有启用/访问任何用户日志。

## 应用实际发送边界

源码 `AIService.send/suggest/models`：正文为临时任务UUID、标题、locationName、UTC开始/窗口结束、时长、灵活性、排程指令与模型；四家用Authorization Bearer API Key；设置Content-Type application/json；URLSession产生一般HTTP/网络信息（服务可见源IP）。GLM公开模型目录无Key/事项，其他模型列表有Key但无事项。无自定义IDFA、设备ID、电子邮箱、电话、姓名、支付卡号、浏览轨迹/点击分析、崩溃/设备性能报告字段。

任务notes/经纬度/提醒/完成状态/天气路线结果不加入AI正文。供应商自己网站另外收集的注册邮箱/手机号、信用卡、客服工单、cookie、浏览器设备ID不因BYOK自动变成本App的数据类型；不能照抄整公司隐私政策。API账户认证可使已外发数据关联账户，但不代表App又发送了该账户注册邮箱或支付信息。

## ASC逐项可填写矩阵

| ASC数据类型 | 收集 | 用途 | Linked | Tracking | 实际依据/边界 |
|---|---|---|---|---|---|
| Other User Content | **Yes** | App Functionality + Other Purposes | Yes | No | 原始标题/日程正文与生成输出；允许默认正文保留。Other依据GLM平台允许的匿名研究/模型改进，非Gemini；这是用途映射判断，非某笔数据训练实证。 |
| Precise Location | **Yes** | App Functionality + Other Purposes | Yes | No | locationName可为可定位的精确计划到访地点，进入同一prompt；无坐标不代表降精度。 |
| User ID | **Yes** | App Functionality + Other Purposes | Yes | No | Qwen默认审计日志持久记录API key ID并归workspace；DeepSeek政策同时覆盖自动分配userID/deviceID及DeviceNetwork模型改进用途，按主会话一致解释加入Other。不是“任意鉴权token都要选Yes”，也不是每请求分配标识的实测；随机任务UUID本身不是用户ID。 |
| Other Usage Data | **Yes** | App Functionality | Yes | No | Qwen默认记录调用时间、模型、token用量等API使用活动。用于服务运营/监控，不凭空添加广告或Analytics目的。 |
| Performance Data | **Yes** | App Functionality | Yes | No | Qwen默认记录first-token latency与call duration，用于异常监控与排障；属于技术性能数据，不仅限于App启动耗时。 |
| Other Diagnostic Data | **Yes** | App Functionality | Yes | No | Qwen默认审计状态、错误码/错误信息用于排障；不能因为没有上传CrashReport就否认API诊断数据。 |
| Product Interaction | **No（不重复声明）** | — | — | No | 未发送App点击/滚动/页面事件；现有API调用使用数据以Other Usage Data申报，不因同一调用同时机械重复分类。若未来明确上传AI按钮事件应重新评估。 |
| Crash Data | **No** | — | — | No | App无第三方崩溃上报；API错误不是App崩溃日志。Apple自行收集的诊断不归本开发者披露。 |
| Device ID | **Yes** | App Functionality + Other Purposes | Yes | No | 主会话采用直接BYOK账户访问政策的一致解释：DeepSeek政策Device/Network段覆盖自动分配设备标识，EEA用途表将Device and Network Personal Data列服务及模型改进。是供应商政策覆盖的标识，不是App发送IDFA，也非已实测每次API创建新ID。 |
| Name / Email / Phone / Other User Contact Info | **No** | — | — | No | 应用没有相应字段外发；供应商网站账户资料不是App自动收集。自由标题偶然包含姓名等按Other User Content处理。 |
| Physical Address | **No，联系地址语义** | — | — | No | 应用请求事项目的地而非用户住宅/邮寄联系方式；可定位目的地已Precise Location。若新增请求用户家庭联系地址则再申报。 |
| Payment Info / Credit Info / Other Financial Info | **No** | — | — | No | App无支付资料外发；Apple支付与供应商另站BYOK计费不可照抄。 |
| Purchase History | **No，当前设备内处理** | — | — | No | StoreKit读取验证权益在设备内消费，无开发者服务端/第三方上传交易或购买记录；不把Apple独立交易处理归开发者。 |
| Health / Fitness / Sensitive Info / Contacts | **No（专门类型）** | — | — | No | 无请求这些专门数据；自由标题潜在敏感内容仍Other User Content，不能全勾。 |
| Emails or Text Messages / Photos or Videos / Audio / Gameplay / Customer Support | **No** | — | — | No | 当前无此类上传或App内消息/支持内容处理；模型文本prompt不等于用户短信/邮件。 |
| Browsing History / Search History | **No，当前开发者数据流** | — | — | No | App无此类日志外发；地图搜索为Apple MapKit。供应商网页cookie不等于应用嵌入分析SDK。 |
| Advertising Data / Environment Scanning / Hands / Head / Other Data Types | **No** | — | — | No | 无相关采集流程；已能归入具体类别的数据不另外全选Other Data Types。 |
| Coarse Location | **Yes** | App Functionality + Other Purposes | Yes | No | DeepSeek API条款5.5纳入隐私政策；BYOK用户以自己的账户直接访问API，服务从源IP推导近似位置。用途含安全/地点回答，政策EEA用途表也包含模型改进的Location Personal Data。 |

数据类型、linked/tracking和网络IP分类依据：[Apple App Privacy](https://developer.apple.com/app-store/app-privacy-details/)、[Apple数据类型枚举](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatype)、[Apple用途枚举](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacycollecteddatatypes/nsprivacycollecteddatatypepurposes)。API活动归OtherUsageData、API key ID归UserID是按Apple定义所作映射，Apple没有针对每家BYOK的专门自动答案。

## 四家默认API留存：能证明什么

| 服务 | 官方API/政策证据 | 对提交的实际含义 |
|---|---|---|
| OpenAI | [API Data controls](https://developers.openai.com/api/docs/guides/your-data)：默认滥用监测日志可含prompt/response、派生classifier metadata，通常最多30天；API正文默认不训练。system data涵盖metadata/usage；ZDR/MAM需资格。 | 当前store:false不消除默认安全正文日志。已支持content披露；该文不枚举本App IP的每个安全日志字段，不据其网站隐私推断邮箱/设备ID。 |
| Qwen | [Retention policy](https://www.alibabacloud.com/help/en/model-studio/data-retention-policy)：国际默认推理正文不超过30天，安全/法律例外；[Model monitoring](https://www.alibabacloud.com/help/en/model-studio/model-telemetry)：默认API审计有上述身份/使用/性能/错误字段。 | 足以新增四个Yes，无需四家都同样保留才申报；未把手动inference日志当默认已启用。北京/其他地域合同差异不取消已允许支持模式的聚合披露。 |
| GLM | [BigModel官方政策](https://docs.bigmodel.cn/cn/terms/privacy-policy.md)定义开放平台包括API；规定必要期限保留、可匿名研究/模型算法训练。某些IP/设备信息段落明确是客服场景。 | Other仍有依据，但客服或网页信息不能拿来证明本App API留存设备型号/IP全部字段。当前chat/completions具体日志字段/期限未获专门保证。 |
| DeepSeek | [官方2026-02-10政策](https://cdn.deepseek.com/policies/en-US/deepseek-privacy-policy.html)一般服务列输入、日志、训练与IP推导近似位置，同时明确下游终端规则由开发者负责。 | 后续核查Open Platform条款5.5明确纳入该政策，BYOK直接账户源IP的近似位置处理范围已闭合；仍不能凭空承诺固定30天、每笔prompt训练或特定账户退出设置。 |

## 剩余真正无法确认项（限定到具体问题）

1. **Coarse Location已闭合；不再要求每endpoint独立专文**：[DeepSeek Open Platform Terms](https://cdn.deepseek.com/policies/en-US/deepseek-open-platform-terms-of-service.html)导言明确适用API，5.5纳入官方Privacy Policy处理账户用户个人数据；[Terms of Use](https://cdn.deepseek.com/policies/en-US/deepseek-terms-of-use.html)1.1也包含API。本App BYOK直连，IP来自该用户访问，不是开发者代理隐藏的IP。policy的Location条款明确自动从IP推导近似位置用于安全/地点回答；EEA用途表将Location列入模型改进。故按已允许范围声明CoarseLocation/AppFunctionality+Other/LinkedYes/TrackingNo。下游开发者应自己披露的例外不否定DeepSeek自身处理账户用户访问数据。不是仅因所有HTTP有IP就申报，而是该供应商政策有实际地理用途。

   **Device ID已由发布主体确认解释闭合**：主会话重新阅读DeepSeek官方政策后，采用与来源IP相同的直接BYOK账户访问范围，将其明确自动分配设备标识纳入DeviceID/LinkedYes/TrackingNo/AppFunctionality+Other。EEA用途表Device and Network Personal Data包括服务功能及模型改进。此为政策覆盖的供应商处理，不证明App主动发IDFA/IDFV或每次API请求创建标识；未进行账号日志/抓包实测。此决定不扩张为供应商独立官网全部联系人/支付/cookie类型。
2. **额外用途而非额外类型**：GLM账户优先合同是否排除匿名模型改进、DeepSeek API训练退出/留存承诺；未确认前维持现行内容/地点Other，不能称已验证每笔训练。Qwen默认运营监控支持AppFunctionality，不能仅有监控图就推断广告或产品行为Analytics；若实际合同另作行为分析须加目的。
3. **严格适用范围**：Qwen模型监控页面注明支持随模型不同，本文针对App实际Qwen文字模型而非图像/音频/第三方直连模式；若发布主体限定所有可用模式不受此默认审计，应有官方证据再改四项Yes。没有必要为供应商独立网站注册/账单类型继续保留泛Unknown。

## MapKit / WeatherKit及最终同步

WeatherKit官方说明位置用于天气、不会关联个人身份或跨请求追踪。[Apple WeatherKit](https://developer.apple.com/weatherkit/)。Apple Maps有自己的搜索、路线与定位隐私处理说明。[Apple Maps & Privacy](https://www.apple.com/legal/privacy/data/en/apple-maps/)。本App仅用原生服务，保存任务/天气内存/权益在设备内，不把Apple服务结果上传自建后端；Apple App Privacy明确开发者不负责Apple独立收集。AI外发精确目的地仍需本App披露，不能借Apple框架规则免除。

本轮已按授权在manifest补四个API日志类别及CoarseLocation、DeviceID，共八类型；官网隐私页已补Qwen默认审计与DeepSeek源IP近似位置/自动设备标识说明，尚未发布。正式提交前由主会话填写相符ASC并生成最终Privacy Report；原先CoarseLocation待定已由API条款纳入关系闭合。只读审查不是供应商console验证、抓包、App Review批准；本轮未操作ASC。


## 本轮静态校验与变更

2026-10-11授权后更新`MapToDo/PrivacyInfo.xcprivacy`与`website/privacy/index.html`，无发布/构建。新增日志类均linked=true、tracking=false；OtherUsageData/PerformanceData/OtherDiagnosticData为AppFunctionality，UserID以及CoarseLocation/DeviceID为AppFunctionality+Other。原内容/精确地点与required reason保留。新增Qwen监控、DeepSeekOpen Platform条款链接使用官方地址；静态校验结果由执行记录报告，未声称供应商账户或HTTP请求实际联调通过。


### 最终八类冻结

主会话已裁定DeviceID的直接BYOK账户政策覆盖解释；八类为OtherUserContent、PreciseLocation、CoarseLocation、UserID、DeviceID、OtherUsageData、PerformanceData、OtherDiagnosticData。全部LinkedYes、TrackingNo；内容/精确位置/近似位置/DeviceID/UserID用途AppFunctionality+Other，其余三类AppFunctionality。其余类别按应用实际可发数据流保留当前判断，不扩为供应商网站全部资料。本轮审计到此停止扩展；供应商账户实际设置/每次请求行为仍未实测，最终提交与网站发布由主会话负责。
