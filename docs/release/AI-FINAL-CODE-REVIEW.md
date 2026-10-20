# 冻结候选 AI / 规划最终只读审查

日期：2026-10-11。只读当前源码及行号；不修改产品/测试源码，不构建、不启动模拟器、不外发事项/Key。device_tests 单独运行候选29项，本审查不占测试slot。下列是源码推导的具体问题及最小修复建议，不宣称已动态复现；真实Key联调仍NOT_RUN。

## [P1] 日期边界外的相邻固定事项没有路程复核，可能允许不可达计划应用

证据：PlanningView.swift:87–89 仅按原scheduledAt日期选planningTasks；本地分支:95–100 将范围内集合送PlanningService；AI分支:106–122 同样只将rangeTasks/proposed送路程天气服务。AIService.swift:127–140 在全store中只检查changed与其他active的时间重叠，没有路程间隔。PlanningView.swift:58–62 无conflict即允许Apply。

可复现数据：范围选10月11日；当晚固定A在22:30–23:30，灵活B最早23:00、时长20分钟、窗口到10月12日02:00；次日范围外固定C在00:05开始，距B的真实路程60分钟。A/B路程取10分钟，B可排23:40–00:00。纯时间全局校验认为B与C不重叠；C因开始时间在10月12日被路程复核集合排除，故5分钟转场缺口未成为conflict，B的changes可Apply。起始边界前刚结束的固定事项也有同类问题。

最小建议：最终拟议集合的每个changed事项，与完整active集合中时间相邻的前/后事项复核转场（包括范围外事项）；这些邻居只留在本机Apple ETA/Weather校验，不能自动加入AI发送集合。保留8项“可调整事项”限制，并为边界邻居查询使用既有总预算/明确降级。不改变范围外固定事项时间。回归应给出B→C 60分钟但仅5分钟gap，断言Apply被conflict阻止。

## [P2] Qwen刷新期间可编辑Workspace ID，结果会写入新Workspace配置

证据：AISettingsView.swift:33 Workspace TextField未disabled(busy)、没有workspace onChange失效；:45 refresh只检查refreshRevision。AIService.swift:4–5 在实例初始化捕获region/workspace，因此网络使用旧Workspace ID；读取完成后AISettingsView仍无配置等值检查便更新models。

复现：Qwen Beijing或Virginia，Workspace设A并点击刷新；网络返回前将可编辑Workspace改B。A的模型目录会显示在已标B的配置中，随后用户可能按错误账号候选选模型。provider/region Picker当前disabled(busy)，单窗口直接切换这两项已被阻止；此处无需依赖多窗口假设。

最小建议：刷新时禁用Workspace编辑，或Workspace变更取消refreshTask/更新refreshRevision并清models；刷新结果提交前核对捕获的provider/region/workspace。使用延迟目录fixture验证旧Workspace响应不覆盖新配置。主屏provider/region/model全局AppStorage变更也可采用同一snapshot核对，避免跨窗口竞态，但后者此次未证明当前产品会开放多窗口，不作为另一个已确认bug。

## [P2] 本地排程后仍使用原事项时刻的天气缓冲

证据：PlanningService.swift:15–19 查询输入task.scheduledAt天气并保存buffer；:29 原endDate查询ETA；:49 调用LocalPlanner后可将灵活事项移动到后面的时间/日期。LocalPlanner.swift:20–35 会在整个flexibilityEnd窗口内排新时间。:50只有ETA原时间告知，没有重新检查移动后天气。AI分支PlanningView.swift:119–122按proposed重新检查，故此缺口主要影响本地分支。

复现：B窗口允许跨天；原时刻晴天buffer=0，固定安排迫使B挪到次日大雨时刻buffer=15。最终本地preview仍将B的0分钟天气缓冲用于排程，并允许应用；不会触发次日天气查询。无需真实服务即可用带时刻的天气fixture说明错误来源。

最小建议：生成changes后将最终集合设为固定时间进行一次仅校验的天气/转场复核（不再移动），合并conflicts/notices；天气不可用时显示目标时刻而非原时刻数据。若预算不足，至少明确移动后天气未验证，不能将原天气说明视为新时刻依据。

## [P2] AI输入ISO时间省略小数秒，可能拒绝合理的“保持原时间”输出

证据：AIService.swift:70–71使用默认ISO8601DateFormatter输出不含小数秒的start；:147却将解析后的date与原TaskItem.scheduledAt精确比较。TaskItem的Date可能含亚秒值，且输入未统一归整。

复现：灵活事项scheduledAt = 1970-01-02T03:46:40.500Z，发送start成为03:46:40Z。AI合法地按看到的start返回03:46:40Z，会因date早于原start .500秒而整份拒绝。当前小数秒response解析fixture没有覆盖payload精度这一端。

最小建议：输入窗口使用包含小数秒的格式，或在明确的应用时间粒度下统一序列化/比较边界并保留原日期不变；不要单纯放松窗口允许真实提前。回归覆盖同一亚秒窗口的request→response roundtrip。

## 未发现源码层面的密钥外泄或Gemini gate绕过

- AIConfiguration.swift:31–35只有4家availableProviders；:74–86禁用/未知偏好归一OpenAI/gpt-6.1-sol，只写非秘密偏好，不访问/删除旧Gemini Key。
- AISettingsView.swift:18、23、63、77–79使用归一选择，Picker完全不列Gemini。PlanningView.swift:19、35、69、112–114也使用归一选择。
- AIService.swift:7、25、68在send/models/suggest入口要求available，send:8才读Key；保留Gemini解析分支不会产生网络请求。
- API Key仅进入固定官方域的Authorization请求头；Qwenworkspace仅允许字母/数字/连字符。未发现Key在URL、UserDefaults、日志或错误文本中输出。contains只取Keychain attributes；保存状态不读取Keyvalue。删除有provider/region快照确认并检查SecItemDelete结果。
- OpenAI actual helper :90–92有store=false/low。:69–71及93–101使用每请求随机TaskID，:84–87映射回本机；原TaskItem稳定ID不在prompt正文。标题/地址本身仍可识别用户，故不能将此等同匿名化。
- 同意区域列完整字段、精确地点可能性、保留说明与政策链接，逐次Agree/send；原Gemini可用提示已移除。真实供应商合同、保留配置和prompt/response行为仍未知。
- PlanningView:71–77的输入变更和:70离页均使revision/preview失效；Apply:60再次比较sourceTasks与完整store，避免事项修改后覆盖。时间窗口解析拒绝固定/已完成/重复/范围外建议，全局changed对active两两重叠检查覆盖长约会嵌套。
- PlanningTimeout通过锁与单次continuation结果防迟到二次resume，取消会解除UI等待；不响应取消的外部SDK工作可能后台迟到，这是SDK边界，不代表其物理网络立即停止。

## 交付与候选稳定性

当前产品/测试源码保持冻结。只有本审查文档新增。上述4项应由主会话决定后续候选修复/回归，不在正在测试版本中偷偷修改。优先处理日期边界转场；其余列为可复现功能缺口，无需以风格调整扩大范围。
