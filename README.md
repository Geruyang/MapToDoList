# 行迹 Waypoint

原生 iOS 地图待办：把地点、时间、提醒和行程放在一起。首版面向海外市场，英文优先，支持简体中文。SwiftUI · iOS 17+ · 无第三方运行依赖。

## GitHub 源码与发行快照

仓库地址：[Geruyang/MapToDoList](https://github.com/Geruyang/MapToDoList)。官网入口：[Waypoint 支持网站](https://geruyang.github.io/MapToDoList/)。

本仓库保存 App 全部源码、Xcode 工程、单元/集成和 UI 测试、配置、开发与发行文档、精选发布截图，以及 `distribution/` 下的现有 Build 2/3/4 发行文件。最新候选是 **1.0.0 Build 4**，Build 2/3 保留作历史产物，不作为当前推荐构建。

发行 IPA、完整 `.xcarchive` 压缩包、导出配置和 SHA-256 清单见 [distribution/README.md](distribution/README.md)。当前 48 个产品输入与 Build 4 冻结清单一致；上传过程没有重新构建 App。完整测试覆盖及未执行项仍以各候选报告为准。

GitHub 快照不包含原始 `.xcresult`、设备测试录屏、未筛选的诊断截屏、DerivedData、编译中间文件或秘密凭据。完整源码不依赖这些历史大文件来编译。`website/` 是支持站点源码，与 App 运行后端无关。

## 打开与运行

用 Xcode 26.6 打开 `MapToDo.xcodeproj`，选择 `MapToDo` scheme 和 iPhone 模拟器运行。工程由 `project.yml` 生成；修改工程结构后执行 `xcodegen generate`。首次真实启动是空数据；API Key 不随项目提供。

```sh
xcodegen generate
python3 scripts/memory_guard.py -- xcodebuild -project MapToDo.xcodeproj -scheme MapToDo -destination 'generic/platform=iOS Simulator' -jobs 1 CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- build
```

仅 Debug 可用的演示启动参数：`--uitesting --reset-data --seed-demo --demo-access`。使用独立数据文件、明确演示横幅；Release 不包含此权益绕过。正常开发与发行不能把演示模式当真实订阅。

## 功能

- Apple MapKit 搜索、地图选点与待办标记，事项增删改、完成状态和 Apple 地图导航。
- 提前提醒、声音/静音/时效模式、本地权限控制、最近60条提醒队列。更多事项在下一次打开App时补充排程；系统设置影响最终投递。
- 日期范围导出纯文本、Markdown、ICS，复制到剪贴板或系统分享；已保存的数据读出不受订阅过期影响。
- 固定约会保持时间，灵活事项在时间窗内排程，MapKit ETA与WeatherKit缓冲、冲突与降级解释。单次最多8项，限制路网请求数量；分段规划长行程。
- 首版支持 GLM / Qwen / DeepSeek / OpenAI 可选规划。密钥放系统钥匙串，模型可选、在线刷新、手动输入。仅主动选中并生成的事项发送云端，备注和坐标不发送。
- 当前与事项时刻天气，Apple Weather归属，超出预报范围明确不可用。
- StoreKit2年度订阅，已确认美元年费9.99，符合资格用户7天试用。试用是Apple introductory offer，须经系统购买确认；价格以App Store返回值为准。

## 必须完成的发行配置

1. 将 Signing Team 与 bundle ID 调整为正式发行身份；启用 WeatherKit 和 Time Sensitive Notifications capability。原生 WeatherKit需要对应App ID服务开通，单纯写entitlement不等于服务已经可用。
2. App Store Connect创建 `com.waypoint.maptodo.annual` 一年期自动续期产品，已设置美元9.99和1周免费试用（用户已确认价位）；税务、协议与最终销售范围仍须核验。App使用StoreKit返回的本地价格。
3. Scheme 内 `.storekit` 仅用于本地交易测试。TestFlight/生产使用App Store实际商品；外部购买、sandbox真实账户和服务商Key联调需要各自账户环境。
4. 各AI厂商API按其账户额度另行收费，年订阅不含用户自带API调用费用。模型官方核验来源见 `MapToDo/Features/AI/MODEL-SOURCES.md`；实时可用性以账户模型列表为准。
5. 填写真实开发者联系信息、支持URL、公开隐私政策URL及App Store隐私问卷，校核各发行地区服务可用性。本地保留的最新审核回执为 2026-10-12 02:48（America/Los_Angeles）：1.0.0 Build 4、年度订阅和订阅群组三项已提交，等待审核；保留手动发布。该回执不证明其后已通过或上线。

## 架构与协作

- `MapToDo/Core/`：TaskItem、TaskStore原子本机存储、AccessPolicy。
- `MapToDo/Features/`：Map、Reminders、Export、Planning、AI、Weather、Home、Settings、Subscription。
- `MapToDo/Design/`：浅深色主题和基础组件。
- `MapToDoTests/`、`MapToDoUITests/`：算法/存储/导出/权益/天气与真实UI测试。
- `docs/design/INTERFACES.md`：共享接口契约。
- `docs/design/UI-SPEC.md`：全页面视觉与交互方案。
- `docs/superpowers/`：产品方案及实施分工。
- `docs/testing/`：独立模拟器与真机矩阵、日志与已知未执行项。

当前测试的真实通过/失败/未执行状态，以测试报告及 `.xcresult` 为准；代码存在不等于联网能力、真机通知或生产购买已验收。

## 发布前迭代与资源限制

首版之后继续功能回归、真机联调、视觉与无障碍修复，再准备发行候选。发布门槛与外部依赖见 `docs/release/RELEASE-READINESS.md`。

本机最多同时运行一个构建/测试和一个模拟器，构建使用 `-jobs 1`、测试关闭并行。`scripts/memory_guard.py` 在估算内存低于68%时才启动，达到78%中断自己的子进程，为用户要求的80%留余量；它是采样保护，不是操作系统硬配额。测试结束关闭该轮模拟器，勿终止用户其他应用。
