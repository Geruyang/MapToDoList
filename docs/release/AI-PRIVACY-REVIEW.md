# AI 隐私发布审查

更新：2026-10-11。首版当前范围是 **GLM、Qwen、DeepSeek、OpenAI**。用户决定关闭Gemini；其条款只在文末Historical段保留，不是首版用途或年龄门槛的依据。本轮仅整理报告，未构建或启动模拟器；用户已暂停真机回归。新增6项测试只有源码，**未运行**。没有真实用户API Key，四服务真实请求、账户设置与删除联调均 **NOT_RUN**；既往天气/其他逻辑验证不能替代AI验证。

## 当前结论与源码状态

不能宣称所有数据只在本机、全部AI不训练/不留存，或在ASC选择Data Not Collected。AI是逐次同意后发送的可选功能，第三方账户与保留政策仍可能让正文与身份关联。BYOK不免除应用披露责任。[Apple App Review 5.1.2(i)](https://developer.apple.com/app-store/review/guidelines/#data-use-and-sharing)

当前源码已有完整发送字段、所选服务/模型、每次随机编号、地点可能为精确地址、费用/保留政策与处理地域说明，逐次“同意并发送”及取消动作；OpenAI请求显式`store:false`。这些是源码状态，不是界面、真实请求或账户配置已经验收通过。

Gemini关闭源码现包含：`AIProvider.availableProviders`仅四服务；`requireAvailable()`拒绝禁用提供商；`AIService.models`、`suggest`、底层`send`在调用前检查可用性；设置Picker使用四服务列表，旧偏好迁移由当前配置代码处理。保留Gemini协议/解析代码不意味着允许使用；实际UI、旧偏好回退及调用拒绝仍须按文末清单验证。

## 当前四服务实际外发

证据入口：`AIService.suggest/send/models`、`AIConfiguration`、`AIKeychain`、`PlanningView.generateAI`与`AISettingsView`。

| 字段/信息 | 当前源码行为 |
|---|---|
| `id` | 每次请求新UUID；映射只在本机，响应恢复本地ID，不发稳定TaskItem UUID。 |
| `title`、`location` | 原始标题和locationName；地点可能是完整地址或精确POI。 |
| `start/endWindow` | UTC ISO8601绝对时间；不直接发timeZoneIdentifier。 |
| `durationMinutes/flexible` | 时长与是否灵活，当前编码为字符串。 |
| Prompt/model | 上述数据嵌入排程指令，发送模型ID与生成配置。 |
| Authentication | 所选四服务使用Keychain读取的Key作Authorization Bearer；Key不放URL、UserDefaults或日志。 |
| Transport | 服务可见源IP、请求时间、HTTP/网络元数据；具体留存与用途未验证。源码未显式发送IDFA、设备标识符或联系人。 |

只发送范围内选中且未完成事项；正文无notes、经纬度、提醒设置、createdAt、完成标志、天气/路线结果。未选中事项仅参与本机及Apple路线/天气复核。删除本机Key不能撤销供应商已保留的请求或账户日志。Qwen地域/Workspace ID/模型偏好存本地偏好，不是密钥。

当前可用路径：OpenAI`/v1/responses`；GLM`/api/paas/v4/chat/completions`；DeepSeek`/chat/completions`；Qwen所选地域`/compatible-mode/v1/chat/completions`。OpenAI`store:false`减少Responses应用状态保存，不能证明ZDR、安全日志或缓存关闭。没有创建Conversations、文件、向量库、后台任务；原始响应不写入TaskStore，确认应用后保存建议时间。

模型刷新：OpenAI/DeepSeek/Qwen列表请求使用所选服务Key，不发送事项；Qwen北京/弗吉尼亚Workspace ID进入官方workspace子域；GLM读取官方公开目录，不发Key/事项。进入设置、切换模型/日期或订阅不自动生成AI正文。

## 四服务政策与未确定项

以下为公开官方政策审查；账户合同、模式和控制开关未核实，不能把一家的ZDR套用于其他服务。

| 提供商 | 官方政策与当前判断 | 尚未确定 |
|---|---|---|
| OpenAI | API正文默认不训练，除非选择共享；标准滥用监测可能保留30天。现有`store:false`不请求持久Responses状态。[Data controls](https://developers.openai.com/api/docs/guides/your-data) | 实际组织ZDR/MAM、共享开关、区域处理和缓存。 |
| Qwen | 国际政策默认prompt/response不超过30天，法律/安全可延长；有状态功能另有期限。ZDR有企业/地域/workspace/模型资格限制，暂存可到24小时。[Retention](https://www.alibabacloud.com/help/en/model-studio/data-retention-policy)、[Regions](https://help.aliyun.com/en/model-studio/regions/) | 新加坡默认不等于ZDR；北京合同不能套国际政策；实际日志、训练排除与区域/推理设置。 |
| DeepSeek | 2026-02-10一般政策列输入、训练/改进、保留及中国处理，并明确下游应用开发者披露责任。[Privacy policy](https://cdn.deepseek.com/policies/en-US/deepseek-privacy-policy.html) | API专门合同/训练退出/实际保留。不能由一般政策或未找到例外证明每笔API被训练，也不能承诺不训练、30天或ZDR。 |
| GLM / BigModel | 开放平台政策范围包含API；允许对收集信息匿名研究/分析/预测及机器学习或模型算法训练，并描述必要期限保留和中国境内存储。[Privacy policy](https://docs.bigmodel.cn/cn/terms/privacy-policy.md) | 实际API账户是否有优先禁止训练合同、可读留存期限/即时匿名化、DPA与地域。不得套国际Z.ai政策。 |

GLM公开允许的额外模型改进，是当前保留`Other Purposes`的独立依据；不依赖已关闭Gemini，也不声称任何样本实际用于训练。应用发送前没有匿名化标题/地址，服务后续匿名衍生处理不证明最初无收集。映射到Apple Other是本次审查判断，具体账户特约仍待核实；所有允许模式均获得排除此用途的证据后才能考虑移除。DeepSeek一般政策是补充风险依据，不是API实际训练实证。

## Manifest与ASC当前建议

现行`MapToDo/PrivacyInfo.xcprivacy`包含`OtherUserContent`和`PreciseLocation`，linked=true、tracking=false、AppFunctionality+Other。本轮复审维持值；详细责任边界、准确枚举/reason与依据见[Privacy manifest审查](PRIVACY-MANIFEST-REVIEW.md)。Manifest不替代ASC问卷或公开政策。

Apple收集定义包含离开设备后超出实时请求所需时长的可访问留存；功能可选、BYOK、逐次同意不自动符合豁免。[App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

| ASC项 | 当前可确定/未确定 |
|---|---|
| Data Not Collected | 不可选；当前允许默认留存服务处理用户内容/地点。 |
| Other User Content / Precise Location | Yes；原始事项内容及可定位地点。无坐标不等于无精确位置。 |
| Linked to user | 上述两类Yes；账户认证与原始内容未在发送前去标识化，随机记录ID不等于匿名用户。 |
| 用途 | 两类App Functionality+Other Purposes；Other依据现行GLM允许的额外改进，发布主体仍需签核账户特约与该解释。安全/防欺诈不自动归Other。 |
| Tracking | 当前代码及已审资料无广告测量/跨站广告关联/数据经纪证据，No有依据；实际合作方额外用途仍须最终签核。训练或账户关联本身不是tracking。 |
| UserID、Usage、Diagnostics、IP、联系地址/城市级位置 | 未确定；核实实际API日志、留存/关联与用途，不把Unknown填No，也不凭空勾全部类型。 |

自由标题不要求机械勾所有可能敏感类别；应用明确请求的地点字段须按其精度处理。API网页cookie条款不能推定本应用嵌入这些SDK。Apple独立通过MapKit/WeatherKit收集的数据不机械归入开发者收集；订阅、支持页面及整App流程另需合并签核。IP分类取决于用途，不固定等于DeviceID。

## 当前验收与发布待办（均不能当已通过）

用户暂停真机；以下留给恢复验证后的最终归档。6项新增测试源码未运行，不将代码存在写成PASS。

1. 四服务选择：英文/简体中文仅GLM/Qwen/DeepSeek/OpenAI；Gemini不可选。分别显示正确政策、地区和发送字段，取消及输入变更不外发。
2. 旧偏好：保存旧Gemini服务/模型后重开设置与规划，应回退有效OpenAI服务/模型，并同步持久偏好；不出现隐藏但仍使用Gemini的情况。
3. 服务拒绝：直接以Gemini调用模型刷新与生成，在读Key/发网络请求前返回不可用；底层send同样有检查。验收对象是拒绝路径，非Gemini训练提示。
4. 当前四服务披露：完整字段、temporary IDs、precise addresses、retention与Agree and send；Qwen SG/Beijing/Virginia区域一致，GLM/DeepSeek中国处理说明与官方政策链接正确。
5. 执行新增6项回归及相关AI解析/规划测试；核对OpenAI请求`store:false`、两次传输临时ID不同/正确恢复、本地原事项不变。测试结果由实际执行日志记录，此报告不代填。
6. 提供真实Key后才验证四服务实际请求/response、payload字段、账户保留/计费/训练控制、日志和删除权执行；此前均NOT_RUN。没有真实Key不宣称联网联调通过。
7. 发布主体核实GLM/DeepSeek合同与Qwen地域、OpenAI账户控制；补齐身份/Usage/Diagnostics未知项，使manifest、ASC、公开政策、逐次同意说明一致，并在最终归档生成Privacy Report。

## Historical：Gemini旧审查（不适用首版）

旧五服务方案曾审查[Gemini Terms](https://ai.google.dev/gemini-api/terms)与[Logs policy](https://ai.google.dev/gemini-api/docs/logs-policy)：免费模式训练/人工审核、付费与日志差异、EEA/UK/瑞士付费条件、年龄及API Client业务用途条款。此前曾保留相应同意提示、计费与年龄决策门槛，并将免费模型改进作为Other依据之一。

用户现选择首版关闭Gemini，以上不再是当前验收项目、Other用途依据或未决首版RELEASE GATE。未来重新启用时必须重新核实当时官方条款、目标年龄/用户范围、地域与账户计费/留存，再决定产品与商店披露；ASC内容评级不能替代供应商合同许可。保留源码解析/协议及历史说明不代表功能已重新启用。
