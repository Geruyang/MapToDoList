# 第三轮完整真机 XCTest：真实结果与失败分类

2026-10-11，iPhone 17 Pro Max，iOS 27.0.1 (24A446)，UDID `00008150-00066CE13C43C01C`。Xcode 26.6；Team `VA8X63NPCS`。用户开启设备 UI Automation 后，真实 UI runner 成功执行，旧 `BLOCKED_AUTOMATION_MODE` 已解除。

执行脚本：`DEVICE_RUN_FINAL_SUITE.sh`。仅真机、`-jobs 1`、不并行；该轮经主会话明确授权 start<70%、stop75%，用户硬上限80%。基线69.7%，采样峰值72.9%，未触发内存中断；结束70.2%。退出65是测试断言失败，不是内存拒绝或 runner 初始化失败。

## 实际计数

**67 项：56 PASS / 11 FAIL / 0 SKIP。** 其中 **49 项 app-hosted XCTest 全部 PASS（48逻辑+1真实 WeatherKit）**；18项UI为7 PASS/11 FAIL。StoreKitLifecycleTests明确排除，不能称本地StoreKit或真实Sandbox购买通过。

原始证据：`DEVICE_EVIDENCE/Final-logic-and-ui.log`、`.xcresult`、`Final-logic-and-ui-summary.json`、`Final-logic-and-ui-tests.json`。全部附件：`Final-all-attachments/manifest.json`。通过的六屏gallery另列 `Final-gallery/manifest.json`。原始证据保留，不会被回归覆盖。

## 真实 WeatherKit 服务

附件 `Final-all-attachments/63B218E3-6BDF-4079-95E0-6F7949681ABF.json`，公开SF坐标37.7749/-122.4194，未读取用户位置。请求/完成 `2026-10-11T09:02:00Z`：当前晴朗无云11.9159°C；+1h请求10:02Z，实际小时forecast采样10:00Z，11.6000°C，降水概率0；current/forecast标志分别false/true。返回Apple Weather attribution、legal URL与light/dark brand URLs。此项是实时联网API结果，不是entitlement推断或mock。

## UI真实结果

| 用例 | 状态 | 观察与后续 |
| --- | --- | --- |
| 首启无通知提示 | PASS | 正常无demoAccess；4Tab可见 |
| 空白标题 | PASS | 拒绝空白保存 |
| 完成状态重启 | PASS | 完成后重启仍完成 |
| 空导出 | PASS | 无事项提示、复制disabled |
| 提醒设置入口 | PASS | 入口不请求通知权限 |
| 通知权限拒绝 | PASS | 实际系统提示点“不允许”，拒绝解释仍可用 |
| 六屏gallery | PASS（截图流程） | 真实地图+3pins；所选事项Editor空草稿是截图发现的产品缺陷，不代表详情正确 |
| 取消创建 | FAIL | iOS27 popover省略role.cancel，只提供PopoverDismissRegion；测试原要求keepEditing按钮 |
| 创建编辑持久化删除 | FAIL | notes输入后键盘开启，整屏swipe未滚动到location.confirm；未完成CRUD端到端 |
| 英文smoke | FAIL | Export格式改menu；选项尚未展开，原测试假设全部常驻可见 |
| 无权益历史导出 | FAIL | 点击现有coffee后task.title为空；Today bool sheet闭包参数问题，真实产品缺陷 |
| 五AI提供商Keychain | FAIL | 首个保存metadata成功；delete确认的原生popover无“取消”按钮，停在此；不能称全部五服务写删通过 |
| 真实地图搜索 | FAIL | 地图选中且输入可见，但Root内容tab.map identifier覆盖map.search |
| 地图输入 | FAIL | 同上；不是MapKit服务失败 |
| 地图选点持久化 | FAIL | 同上Root标识覆盖map.surface；未进行选点保存 |
| 本地规划预览不写入 | FAIL | generate已恢复非busy；apply位于长AI披露之后的Lazy List，原测试原地wait未滚动；需回归确定 |
| 恢复订阅 | FAIL | 点击restore30秒后仍pending/disabled、无message；AppStore.sync网络/账户交互需有界错误处理，不计为恢复成功 |
| Today自动可访问性 | FAIL | 唯一hitRegion指向非交互ProgressIndicator“今日完成进度”，截图为细灰条；保留完整audit，owner修语义 |

确定产品问题已提交对应owner：Root标识放到tabItem Label；Map/Today sheet改item destination；demo banner布局；Today装饰progress hidden，进度Text保留label/value。尚需新候选实际回归，源码修补不能关闭FAIL。

## 下一轮冻结计划

**USER RESUMED**：用户明确恢复真机测试，主会话已授予本轮唯一重资源slot。候选源码冻结，执行29项UI-review回归，start<70%、stop75%、jobs1、无并行/无模拟器，保留历史证据。此前暂停期间未执行设备操作。

原18UI全部回归，因为Root布局与标识涉及所有屏幕。追加英文六屏gallery、最大辅助字号六屏gallery，共20UI；新增gallery断言所选事项title正确、Today末端Add按钮可触达并保存截图。最大字号先比较同设备同屏heading高度有实质增加，再保存真实截图；仅App launch preference，不修改设备Settings。

用户随后决定首版Gemini不开放。下一轮提供商UI已改GLM/Qwen/DeepSeek/OpenAI四项，保留保存/取消保留/确认删除/禁删/重启断言，并在每次menu展开及重启后检查Gemini不可选择。上表仍记录上一轮实际执行的旧五服务用例，不追改历史结果。脚本 `DEVICE_RUN_UI_REVIEW.sh` 将纳入provider可用性/迁移新逻辑与3项SubscriptionTimeout测试；尚未执行。

准备脚本现已纳入 `AIReleaseGateTests` 6项，合计 **29项=20UI+3SubscriptionTimeout+6AIReleaseGate**。新provider源码静态核验：Picker使用availableProviders四项；send/models/suggest先requireAvailable再Keychain读取/网络；旧Gemini偏好迁至OpenAI/gpt-6.1-sol，仅改普通偏好、不删除旧Key。新纯逻辑类仍未运行，不能称通过。脚本包含未来的xcodegen纳入新文件，目前没有执行生成工程。

后续第四轮已经实际执行：AIReleaseGate6/6、SubscriptionTimeout3/3 PASS，20UI因设备开发证书trust拒绝启动而执行0；不是UI通过或20次UI断言失败。真实峰值73.5%，未触发guard，资源已释放；新报告 `DEVICE_UI_REVIEW_RESULTS.md` 保留完整阻塞/签名/profile证据。该后续记录更新上段“准备”状态，不改上一轮67项历史证据。

测试适配保留语义：menu展开后核对三格式；popover dismiss后断言草稿/密钥仍在，再显式确认删除/丢弃；滚动从键盘上方内容区开始；planning仍核对重启后fixed/flexible原时间未变。原49项通过不重复，除非产品逻辑变化使其受影响。

未覆盖：真实定位允许/精确开关/移动，通知允许后的前后台锁屏投递与点击，离线/慢网切换，系统分享接收/ICS实际导入，真正AI请求/模型刷新（无有效测试Key），Sandbox购买/intro/撤销/到期（无可用产品/账户证据），VoiceOver完整读序、深色/横屏/减少动态效果，电量发热测量。这些仍NOT RUN或外部配置BLOCKED，不能以本轮PASS项替代。
