# OpenAI 双地区门控独立源码复核（R30）

日期：2026-10-11。审阅者：device_tests。范围为只读源码审查；本轮未构建、安装、启动设备、读取 API Key、调用定位/网络或执行测试。下列“静态闭合”不等于真机/API 验收 PASS。

## 候选锚点

| 文件 | SHA-256 |
| --- | --- |
| OpenAIRegionGate.swift | d18859eb8db477c7ef70c2f00cc3065f6973e1d022fbb6d8c40dcb75681e2e72 |
| AIService.swift | 57adb6f848ac9d0fd755753ed16c59a47ac013cb17b9e525929966005dde501f |
| AIConfiguration.swift | 35858ec11309cc20f92b7886b3f8e25db7cddb925b4e832f470940474c74e3e9 |
| AISettingsView.swift | 7e8be2f317e7d4312cf34f8ebf7602246495967cededa57319195e5783bf92a5 |
| PlanningView.swift | 1b686402865bee71ce8e6564b691b104176d58b42122c05a4f8d827292ab1af1 |
| AIReleaseGateTests.swift（当时 12 方法，新增交错用例由 root 后续补入） | a0ba9da13431af4c374413945b58fcb84bbaca8d9cd74d589d5e9a3dcd7320a5 |

## 已回报并静态闭合的缺口

1. R29 的 `authorizeRequest()` 返回至非 MainActor `AIService.send` 后，曾存在失效事件与实际网络请求创建之间的窗口。R30 `AIService.swift:19` 唯一 OpenAI 传输进入 `@MainActor OpenAIRegionGate.send`；Gate 172–184 行在网络重验后检查取消、位置新鲜度与 revision，并在没有 await 的同一片段登记、启动任务。135–137 行失效时先清登记，再取消任务并结束 continuation。189/193 行通过移除登记保证取消和迟到回调不会重复恢复；195 行交付响应前再次检查权限/TTL。此原 P1 静态闭合，交错测试尚待执行。
2. Settings 可能先把失效 OpenAI 偏好迁到 GLM，令 Planning 的区域回调看见 GLM 而跳过清选项。`PlanningView.swift:76` 现对任意 providerName 改变都清 selected 并撤销 preview，补齐该回调次序。生成仍捕获 provider/model，服务层不会因 OpenAI 拒绝而改用另一厂商发送。静态闭合；UI 交错尚未实测。

## 当前安全边界

- Policy 15–18 行：CN、未知/非法 ISO2、未来时间、超过 120 秒或 mocked 位置均拒绝。定位探针 76–80 行还拒绝已知软件模拟及 accessory 来源。checkAvailability 145 行在 Country.is 请求前拒绝这些不合格定位。
- 每次 OpenAI send 都重新查询网络国家；权限变化、网络路径变化、后台和 TTL 失效会撤销状态并取消登记的请求。network/position 的 revision 检查防止旧检查重新启用已撤销状态。这里只能保证观察到的 OS 事件处理与任务管理；不能证明操作系统尚未报告的网络物理变化不存在。
- UI 不提供模拟可用性参数；未确认 OpenAI 时 Picker 仅 GLM/Qwen/DeepSeek。测试注入构造器不由 App/UI 路径调用，默认生产路径使用真实 CoreLocation 与 Country.is。
- Country.is GET 无 body/Authorization；只解码 country，未保留返回 IP。Apple 地理编码使用单次位置，Gate 持有国家、时间和 revision，未把坐标/IP 添加到 AI 事项 payload、普通偏好或日志。Settings 明确披露 Apple 地理编码及 Country.is 收到网络出口 IP；AI payload 仍是单次随机 ID、标题、地点名称、时间窗、时长和灵活性。
- Gemini 仍禁用，旧密钥未删除；OpenAI 区域失效也不删除其密钥。不把可用厂商列表和区域允许状态混为一项。

## 必须补齐的执行证据（全部 NOT_RUN）

| 场景 | 必要断言 |
| --- | --- |
| 未确认/CN/unknown/stale/mock/权限撤销 | OpenAI transport 次数 0；不得先读正式 Key |
| country 查询进行中 invalidate，随后迟到成功 | 不恢复 isAllowed；OpenAI transport 次数 0 |
| OpenAI transport 已启动后 invalidate | 请求取消，调用失败，迟到 callback 不产生 success；无 continuation 双重恢复 |
| 调用者 Task 取消 | 已登记任务取消；取消先于登记也不能启动请求 |
| 正常允许的 mock transport | 一个请求，响应成功，body/Auth 只交 api.openai.com；不调用真实 Key/API |
| 前台、后台、网络改变及权限撤销真机行为 | UI 隐藏/撤销 OpenAI，既有选项与 preview 清除，用户重新确认厂商后才发送 |

在上述新交错用例执行前，不复用此前 AIReleaseGate 原 6 项 PASS 来声称 R30 地区门控已通过。R27 手机已安装候选没有该地区功能。

## 政策口径

当前代码实现用户要求的“定位和网络都明确在中国大陆以外”，测试明确允许 HK/MO。此必要条件不等于 OpenAI 官方支持地区白名单；官方 [API supported countries](https://developers.openai.com/api/docs/supported-countries) 是独立适用条件。这里记录边界，未擅自扩展用户范围或改国家策略。

## R30 封口回归新增（源码冻结，NOT_RUN）

root 后续授权 device_tests 独占测试文件添加五项 URLProtocol 回归，现类共 17 方法。新 `AIReleaseGateTests.swift` SHA-256 为 `0bed4c23a94a25d0f74b3adb474c4883633d8495ae6a2c2fcb8c189effe4cb7a`；上表保留审阅时旧 SHA 历史。

- US/US 允许的请求返回实际 mock Data/HTTP response，断言首次检查加发送前两次 country 查询与一次 OpenAI 请求。
- CN/nil/ZZ 定位拒绝，country 与 OpenAI 请求数均为零。
- 发送前 country 查询挂起期间 invalidate，随后 country 返回 US，OpenAI 请求数仍为零。
- 已启动 OpenAI 请求 invalidate，调用以 CancellationError 结束且底层 stopLoading 一次；延迟成功响应尝试不产生调用成功。
- 调用者 Task.cancel，同样观察 CancellationError 与 stopLoading 一次。

每个 fixture 的独立 routing token 在 URLProtocol 注册表内查找；所有请求均被截获，缺失路由也报错而不访问网络。共享注册表、计数、held 请求与停止状态加锁。迟到响应 stub 遵循 stopLoading 后禁止调用 URLProtocolClient 的系统约定；它与 URLSession 取消 completion 共同覆盖已撤销调用不能成功，不假装绕过 SDK 强行投递一个已停止请求的响应。等待 operation.result 有两秒预算，defer 取消操作、撤销 gate 并关闭会话。没有直接观察私有 finishTransport 的调用次数。

本轮仅 `git diff --check` 通过。未 parse、编译或执行这些用例；无真实 API、钥匙串或设备操作。parent 负责纳入新构建与实际执行证据。

## R30 构建冻结后的 defaults 复核

在 parent 单独运行 build-for-testing 期间只读复核，未改源码。`AISettingsView.swift` 最新 SHA 为 `6214189fb45c7b903e89a828462867af60452f04760b5ef9d56ea059bdf4b939`：provider/model 的 AppStorage 初值及待删除 provider 都为 GLM / glm-5.3。Planning 的初值相同，SHA 保持 `1b686402865bee71ce8e6564b691b104176d58b42122c05a4f8d827292ab1af1`。

Planning 76 行厂商改变立即清事项选择并撤销工作；79–82 行区域失效时清除 OpenAI 选择并迁移。112–137 行发送前检查当前 OpenAI 可用性，捕获明确 provider/model，成功返回与最终本机复核后都核对 revision。没有 OpenAI 请求失败后重试 GLM 的代码。

`AISelectionPolicy.migrate` 的无偏好 fallback 仍是 OpenAI / gpt-6.1-sol；其默认 openAIAllowed=false 会归一化为 GLM，因此正常首启迁移结果仍为 GLM。记录这项实现细节，未将其说成 Settings 当前默认 OpenAI，也未改冻结候选。
