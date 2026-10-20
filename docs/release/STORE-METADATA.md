# Store metadata — 1.0.0

Prepared 2026-10-11. Updated local drafts for pending-pin confirmation and dual-country OpenAI availability; not yet synchronized to saved ASC fields. Copy-ready drafts; this document does not save fields or submit the app. Existing saved fields are recorded in EXTERNAL-CONFIGURATION.md. First release offers GLM/Qwen/DeepSeek without the OpenAI country gate, plus OpenAI only after successful dual-country verification; all services still depend on provider availability. Confirm the exact submitted candidate before using the review instructions.

Counts include spaces and line breaks inside each field, excluding code fences. Apple documents Keywords as 100 bytes and Review Notes as 4,000 bytes; both are checked in UTF-8 as well as characters. Description and optional What’s New are checked at 4,000 characters; promotional text at 170. [Apple field reference](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).

## en-US

### Name

22 characters; 24 UTF-8 bytes. Limit: 30 characters.

```text
Waypoint — Map & To-Do
```

### Subtitle

27 characters; 27 UTF-8 bytes. Limit: 30 characters.

```text
Places, plans and reminders
```

### Promotional Text

159 characters; 159 UTF-8 bytes. Limit: 170 characters.

```text
Put tasks on the map, plan time to travel and take your itinerary with you. Local planning works without an AI key; optional AI uses your own provider account.
```

### Keywords

97 characters; 97 UTF-8 bytes. Limit: 100 bytes.

```text
itinerary,travel,planner,appointments,errands,schedule,calendar,reminder,location,route,checklist
```

### Description

3089 characters; 3091 UTF-8 bytes. Limit: 4000 characters.

```text
Bring places, tasks and reminders together with Waypoint. See your plans on a map, leave time to travel and keep the details close.

PLAN AROUND PLACES
Search for a place, tap to select a nearby place, or press and hold for the exact map point. Review the pin/place card and confirm before editing. Add a title, time, duration and notes, then open Apple Maps for directions. Review your day and mark tasks complete.

MAKE ROOM TO TRAVEL
Keep fixed appointments at their scheduled times. Arrange flexible tasks within the time windows you choose, using available route estimates and weather buffers. Review conflicts and suggested changes before applying them. Plan up to eight tasks at a time.

REMEMBER AND SHARE
Choose local reminder timing and notification modes. Export a date range as plain text, Markdown or an ICS calendar file, then copy or share it.

OPTIONAL AI, YOUR CHOICE
Local planning needs no AI account or API key. Optional AI planning supports GLM/BigModel, Alibaba Cloud Qwen, DeepSeek and OpenAI using your own provider account and API key. Provider fees are separate. Review the disclosure and agree before selected tasks are sent. Notes, coordinates and persistent task IDs are not included, but place names may contain precise addresses. Provider policies and account eligibility apply. When AI settings opens, regional availability is checked only if iOS location permission was already granted; that screen does not request new permission. OpenAI requires both known country codes to differ from CN (mainland China). Apple reverse geocoding determines the physical country; Country.is receives the exit IP for network-country lookup, not tasks, keys or device coordinates. Unknown, mainland China (CN) or failed results keep OpenAI unavailable.

LOCAL TASK STORAGE
Tasks are saved on your device. No Waypoint account is required. This version does not offer account-based sync or import/restore, so export important plans before removing the app.

SERVICE LIMITS
Weather is available only within Apple Weather’s returned forecast range. Routes, traffic estimates, weather and AI suggestions are planning aids; check actual conditions and appointment times. External services and notification delivery depend on connectivity, permissions and system settings.

SUBSCRIPTION
Creating, editing, completing tasks and planning require an active annual subscription or eligible trial. The US annual price is USD 9.99. Eligible Apple accounts may receive a 7-day free trial, which renews into the paid annual subscription unless canceled. Prices and eligibility vary by storefront; Apple displays the final terms before purchase. Cancel at least 24 hours before the current period ends. Manage or cancel in Apple subscription settings. Existing tasks remain available to view, delete and export after access expires.

Privacy: https://geruyang.github.io/waypoint-support/privacy/
Terms: https://geruyang.github.io/waypoint-support/terms/
Standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Support: https://geruyang.github.io/waypoint-support/
```

### What's New

0 characters; 0 UTF-8 bytes. Limit: 4000 characters.

Leave blank for the initial release. Do not describe this version as an update.

## zh-Hans

### Name

22 characters; 24 UTF-8 bytes. Limit: 30 characters.

```text
Waypoint — Map & To-Do
```

### Subtitle

13 characters; 39 UTF-8 bytes. Limit: 30 characters.

```text
把地点、日程和提醒放在一起
```

### Promotional Text

60 characters; 164 UTF-8 bytes. Limit: 170 characters.

```text
把待办放在地图上，为出行留出时间，再将行程复制或导出。本地规划无需 AI 密钥；可选 AI 规划使用你自己的服务商账户。
```

### Keywords

29 characters; 69 UTF-8 bytes. Limit: 100 bytes.

```text
地图,待办,日程,行程,提醒,规划,出行,清单,地点,日历
```

### Description

1208 characters; 2756 UTF-8 bytes. Limit: 4000 characters.

```text
用 Waypoint 将地点、待办和提醒放在一起。在地图上查看安排，为路程留出时间，随时带走你的行程。

围绕地点安排一天
搜索地点、轻点选择附近地点，或长按选取精确地图点；查看标记与地点卡片，确认后再编辑标题、时间、时长与备注，再打开 Apple 地图导航。查看当天事项，并记录完成状态。

为出行留出时间
固定约会保持原定时间；灵活事项在你设定的时间窗内安排，结合可用的路线估计和天气缓冲。查看冲突与建议，确认后再应用。每次可规划最多 8 项事项。

提醒与导出
选择本地提醒的提前时间和通知模式。按日期范围导出纯文本、Markdown 或 ICS 日历文件，复制或使用系统分享。

AI 由你选择
本地规划无需 AI 账户或 API Key。首版可选 AI 规划支持 GLM/BigModel、阿里云 Qwen、DeepSeek 和 OpenAI，使用你自己的服务商账户与密钥，费用由服务商另行收取。查看披露并同意后，才发送所选事项。备注、坐标与稳定事项编号不会发送，但地点名称可能包含精确地址。服务商政策与账户资格要求适用。打开 AI 设置时，仅在已授予 iOS 定位权限的情况下检查地区，该页不请求新权限。OpenAI 仅在实际所在国家与网络出口国家的已知代码均非中国大陆 CN 时开放：Apple 逆编码解析所在国家；Country.is 接收出口 IP 查询网络国家，不接收事项、密钥或设备坐标。未知、中国大陆（CN）或失败结果会关闭 OpenAI。

事项保存在设备上
无需 Waypoint 账户。本版不提供账户同步或导入恢复，请在卸载应用前导出重要安排。

外部服务的限制
天气仅覆盖 Apple 天气返回的预报范围。路线、路况估计、天气与 AI 建议是规划辅助，请核实实际情况和约会时间。外部服务与通知投递受网络、权限及系统设置影响。

年度订阅
创建、编辑、完成事项及规划需要有效年度订阅或符合资格的试用。美国年费为 9.99 美元。符合 Apple 资格要求的账户可获得 7 天免费试用；如未取消，试用结束后转为付费年度订阅并自动续订。各商店价格与资格可能不同，购买前以 Apple 显示的条款为准。请至少在当前周期结束前 24 小时取消，可在 Apple 订阅设置中管理。权益过期后，已有事项仍可查看、删除与导出。

隐私政策：https://geruyang.github.io/waypoint-support/privacy/
使用条款：https://geruyang.github.io/waypoint-support/terms/
标准 EULA：https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
支持：https://geruyang.github.io/waypoint-support/
```

### What's New

0 characters; 0 UTF-8 bytes. Limit: 4000 characters.

Leave blank for the initial release. Do not describe this version as an update.

## Review Notes — English (recommended for the shared review field)

3682 characters; 3702 UTF-8 bytes / 4,000 bytes.

```text
Waypoint — Map & To-Do requires no app account or sign-in. The first launch has no sample tasks. On Map, search a place, tap to snap to a nearby place or press and hold for an exact point; review the pending pin/card and confirm before editing a task. Creating, editing, completing tasks and generating/applying plans require an active verified subscription or eligible Apple introductory trial.

Subscription: Settings > Subscription & trial. Product: com.waypoint.maptodo.annual. US price: USD 9.99/year; actual localized price and eligibility are shown by StoreKit and Apple’s purchase sheet. Eligible Apple accounts may receive a one-week free trial, then annual renewal. Restore Purchases and Manage or Cancel Subscription are on this screen. After access expires, existing tasks remain viewable, deletable and exportable. Viewing these flows requires no AI credentials.

Planning: Create fixed or flexible tasks, open Plan and use Generate local plan. Local planning requires no AI key; review the preview before applying. Up to eight tasks can be planned at once. Route estimates use Apple MapKit and may be unavailable; the app explains fallback/conflict conditions. Weather uses Apple WeatherKit and is limited to the forecast dates the service returns. Neither route nor weather estimates guarantee arrival times or safety.

Optional AI: Settings > AI settings supports only GLM/BigModel, Qwen, DeepSeek and OpenAI in this release. Gemini is not exposed and cannot send requests. Users supply their own provider account and API key; provider charges and eligibility apply. Local planning remains available without a provider account. On Plan, select tasks and check the displayed provider and model. The send confirmation lists transmitted fields and offers “Agree and send” or “View Provider Policy.” Qwen region remains a control in AI settings. The request includes titles, place names, time windows, durations, flexibility and newly generated request IDs. Notes, coordinates and persistent task UUIDs are excluded; place names may be precise addresses. Keys are in device Keychain. OpenAI uses store:false; this is not a Zero Data Retention guarantee. The confirmation links to the selected provider’s policy; it does not display a provider retention or processing-region summary. OpenAI is hidden and its service calls rejected unless both physical and network country-code results explicitly differ from mainland China’s CN code after AI settings checks availability using existing location authorization. There is no manual “Check availability” button and this screen does not request new location permission. Apple reverse geocoding resolves physical country; Country.is receives only exit IP/request metadata, not tasks, keys or device coordinates. Unknown/error/CN closes OpenAI access; the other providers are not gated by this check, and service availability is not guaranteed. No developer AI credentials or test account are supplied.

Reminders are local notifications, enabled only after the user requests permission. The nearest 60 eligible reminders are scheduled, and reopening refreshes the queue. Delivery depends on iOS permissions, Focus and notification settings. Map search and manual selection work without device-location permission.

Support: https://geruyang.github.io/waypoint-support/
Privacy: https://geruyang.github.io/waypoint-support/privacy/
Terms: https://geruyang.github.io/waypoint-support/terms/

This note describes intended review paths and current implementation. It does not assert that real provider-account requests or the complete production/sandbox purchase lifecycle have been tested. There is no Release demo-access bypass.
```

## 审核备注 — 简中备选（不要与英文合并粘贴）

1213 characters; 2793 UTF-8 bytes / 4,000 bytes.

```text
Waypoint 无需应用账户或登录；首次启动没有演示事项。地图页搜索地点，轻点可吸附附近地点，长按选精确地图点；查看待确认标记与地点卡片，确认后再编辑事项。创建、编辑、完成事项以及生成和应用规划需有效订阅或符合资格的 Apple 试用。

订阅入口：设置 > 订阅与试用。商品 ID：com.waypoint.maptodo.annual。美国年费 9.99 美元，实际本地价格和资格以 StoreKit 与 Apple 购买确认页为准。符合资格账户可获一周免费试用，之后按年续订。同页提供恢复购买和管理或取消订阅；过期后已有事项仍可查看、删除和导出。查看这些页面无需 AI 密钥。

规划入口：添加固定或灵活事项，在规划页选择生成本地计划，预览后应用。本地规划无需 AI 账户，单次最多 8 项。路线估计来自 Apple MapKit；不可用时显示降级和冲突说明。天气来自 Apple WeatherKit，仅支持服务返回的预报日期。路线与天气不保证到达时间或安全。

首版 AI 仅开放 GLM/BigModel、Qwen、DeepSeek、OpenAI；Gemini 不展示且不能发送请求。用户在设置 > AI 设置填写自己的账户密钥，服务商费用和资格要求适用。规划页选择事项并核对显示的服务商与模型；发送确认列出传输字段，提供“同意并发送”和“查看服务政策”。Qwen 地域仍是 AI 设置中的选项。内容包括标题、地点名称、时间窗、时长、灵活性和每次新建编号，不含备注、坐标或稳定事项 UUID；地点名称可能是精确地址。密钥存于设备钥匙串。OpenAI 使用 store:false，但不承诺零留存；发送确认链接至所选服务商政策，不展示留存与处理地域摘要。打开 AI 设置时仅使用已有定位授权检查地区，不请求新权限，也没有手动“检查可用性”按钮。实际所在国家与网络国家的已知代码均非中国大陆 CN，OpenAI 才展示并开放请求。Apple 解析位置国家，Country.is 只接收出口 IP 与请求元数据，不接收事项、密钥或设备坐标；未知、失败或 CN 关闭访问。不提供开发者 AI 密钥或测试账户。

本地提醒仅在用户主动请求权限后启用，安排最近 60 项有效提醒，重开应用刷新。投递受 iOS 权限、专注及通知设置影响。地图搜索和手动选点无需设备定位权限。

支持：https://geruyang.github.io/waypoint-support/
隐私：https://geruyang.github.io/waypoint-support/privacy/
条款：https://geruyang.github.io/waypoint-support/terms/

上述说明是当前实现及审核路径，不声称真实服务商请求或生产/sandbox 完整购买生命周期已验证。Release 无演示权益绕过。
```

## Screenshot caption and capture checklist

Capture actual app screens from the exact submitted candidate on iPhone only for the first release. Use fictional appointments entered in the real app; no fabricated UI, generated app screens, Release bypass, debug/demo banner or private data. Use real valid subscription access for gated screens. Do not show AI keys. Captions may sit outside the unchanged app image. Capture the supported iPhone layout. iPad is outside the user-confirmed first-release scope; no iPad screenshots are required or claimed verified. Dimensions and accepted device slots must be verified in App Store Connect by the capture owner. No screenshots were created by this task.

| Order | Actual screen / capture requirement | en-US caption | 简中 caption |
|---|---|---|---|
| 1 | Map with real saved fictional tasks, pins and readable place/time details. | Give your plans a place | 给日程一个地点 |
| 2 | Today list with real fictional tasks and their times. | See your day at a glance | 一眼查看当天安排 |
| 3 | Real task editor showing fixed/flexible settings, without obscured critical fields. | Plan within your own time windows | 按自己的时间窗安排 |
| 4 | Actual local plan preview with fixed task, flexible task and truthful route/weather or unavailable state. Never replace unavailable data. | Review before you apply | 先预览，再应用 |
| 5 | Export screen with actual date range, format menu and real text preview. | Take your itinerary with you | 随时带走你的行程 |
| 6 (optional) | AI settings / consent screen with GLM/Qwen/DeepSeek and OpenAI only if both known country results permit it, no key visible; do not require all four providers to appear or imply the gate was bypassed; avoid implying generated AI output was verified. | Optional AI, with your own account | 自选 AI，使用自己的账户 |

Use this narrative order for supported iPhone captures. Subscription review attachment is separate: capture the actual submitted paywall with StoreKit-returned localized price and eligible-offer state. Do not insert a static 7-day offer when Apple reports ineligible. No claim of weather, traffic, AI, purchases or UI test success is made by this caption list.

## Shared URL / copyright fields

- Support URL: https://geruyang.github.io/waypoint-support/
- Marketing URL: https://geruyang.github.io/waypoint-support/
- Privacy Policy URL: https://geruyang.github.io/waypoint-support/privacy/
- Copyright: 2026 Ge Ruyang
- Terms page and Apple standard EULA are included in each description.

Validation: Python len() and len(UTF-8 encoding) assertions passed for every field above. Empty initial-release What’s New has zero characters. Review-note drafts are alternatives for the single review field. No build, screenshot capture, network account action or publication was performed.
