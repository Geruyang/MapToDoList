# OpenAI 轻量真实 HTTP 验收

执行：2026-10-11 12:24 UTC。用户授权使用桌面受保护.env中的测试Key，并知晓API独立计费。测试进程内部读取Key；未输出、复制、截图、提交或写入App/仓库；未修改密钥文件。只使用Python标准库HTTPS，无build/simulator/Xcode/device操作。证据：[sanitized JSON](OPENAI_HTTP_RESULT.json)。

## 实际结果

1. 唯一 `GET https://api.openai.com/v1/models`：HTTP200，返回127个模型，精确ID `gpt-6.1-sol` 在该账户真实列表中。鉴权与该ID账户列示状态已验证，不据此推断所有账户可用或生成已通过。
2. 唯一 `POST https://api.openai.com/v1/responses`：HTTP429，安全记录的error_type为 `insufficient_quota`。收到额度拒绝后立即停止，不重试、不充值、不另建Key、不自动换模型。

输入是虚构“Fictional public library visit”与公开“New York Public Library, Manhattan”，仅一个每请求随机编号事项。没有真实用户事项、备注、坐标或稳定事项ID。请求使用当前 `AIService.openAIRequestBody` 同形的model/input/reasoning.low/store.false，并额外加入测试安全上限 `max_output_tokens:512`。指令前缀读取当前Swift源码，与实际拼接方式对应；API Key只在Authorization头，禁止redirect，不打印headers/原始HTTP错误body。

## 判断与局限

- **PASS**：真实HTTPS鉴权、模型列表、账户列示gpt-6.1-sol。
- **BLOCKED BY QUOTA**：真实生成，故无法验证成功Responses envelope、模型返回JSON、用量或建议质量。
- **NOT_RUN**：真实Swift AIService/Keychain/iOS UI端到端、App内取消/应用流程、其他供应商真实请求。
- 本HTTP脚本复刻已检查Swift请求格式，不能称为直接运行AIService，也不能将429当作完整request body接受证明。
- 没有输出供应商原始error message/error body；非白名单error_code记为unrecognized_or_missing，保留已知类型insufficient_quota足以说明阻塞，不泄露凭证。

## 内存与次数

两请求总数2；无无限循环/重试。运行前采样72.3%，子进程启动72.1%，监测峰值72.5%。进程在主会话阈值收紧通知到达前采用start<76/stop78；实际峰值仍低于后续统一stop75。此执行结束后无追加联网请求；今后使用start<74/stop75。本脚本未启动任何heavy工作。

充值或调整账户余额需用户单独决定；本验收不做自动充值。额度解决后如需再次生成，应在新的明确授权/调用额度范围与内存守卫下重跑，并继续区分HTTP协议测试与App端到端验收。

## 本轮只读模型复验：ChatGPT订阅方案已取消

2026-10-11 13:35 UTC，用户取消ChatGPT订阅模式，继续保留OpenAI及其他服务API Key方案；未实施任何SIWC源码，因此不需要撤销订阅认证代码。用户明确授权只复用最初受保护Desktop/Waypoint-API-Key.env，测试进程内读取，不读取keys.txt、Codex auth或其他Key，不复制/改动密钥文件。

本轮唯一 `GET https://api.openai.com/v1/models` 未取得HTTP响应，安全记录为 `URLError`，即停止，无自动重试。因为没有返回目录，不执行可选 `/v1/models/gpt-6.1-sol`。没有POST生成、充值、余额/org/项目查询，没有输出模型目录正文、账户资料、Key/headers/error body。凭证重定向禁止。

[本轮安全JSON](OPENAI_MODEL_READONLY_RESULT.json) 保存method/path与异常类别；URLError不能判定Key失效、鉴权成功或模型不可见。历史GET200列出gpt-6.1-sol及随后POST429 insufficient_quota事件完整保留，但不能当作本轮成功验证。

memory_guard start<74/stop75：启动71.5%，峰71.8%。没有build/sim/device或源码变更。

静态合同核对：当前AIService.swift:79仍通过openAIRequestBody调用API `/responses`，:98–99 helper仍model/input字符串/reasoning.low/store:false；没有OAuth/SIWC模式或自动收费fallback。responseText与parse仍严格处理API envelope、completed/截断、临时TaskID、窗口和冲突。历史 [DEVICE_AUDIT_COMBINED_RESULTS.md](DEVICE_AUDIT_COMBINED_RESULTS.md) 明确记载AIParsingTests/testOpenAIRequestExplicitlyDisablesResponseStorage、testOpenAIResponsesEnvelopeExtractsOutputText、testTruncatedOpenAIResponseIsRejected、testTransmissionIDsAreTemporaryAndMapBackLocally等PASS。本轮只是只读核对这些源码/历史记录，没有重新执行测试。

**本轮结果：BLOCKED_NETWORK（模型只读查询），生成NOT_RUN。** 不证明App联网生成成功，也不等同余额/额度已改变；不强求余额或请求重试。

## 只读网络定位与一次已授权 GET 复查（最终结果）

主会话要求进一步定位网络，而非将URLError等同鉴权失败。此前catch未存reason对象，无法事后输出具体reason_type/errno/ssl verify_code；没有编造其类型或消息。

- 一次无Key HEAD固定官方 `/v1/models`：HTTP401。缺认证属于预期，证明当时DNS/TLS/HTTP路径连通；不代表带Key鉴权。
- 仅一次已授权GET复查，用原始受保护.env：HTTP200，`target_model_visible=true`（gpt-6.1-sol）。没有详情GET、POST或更多retry。
- 复查脚本已加入安全exception_type/reason_type、整数errno/verify_code分类，禁止message/body/headers；本次成功，无异常字段可报告。原URLError记录保留为历史未决，不归为鉴权失败。
- 安全证据：[无凭证网络定位](OPENAI_NETWORK_DIAGNOSIS_RESULT.json)、[唯一GET复查](OPENAI_MODEL_READONLY_RETRY_RESULT.json)。没有输出完整模型目录/账户资料或Key。
- HEAD守卫峰74.3%，GET复查启动/峰72.5%，均低于stop75；start<74检查已执行。无build/sim/device操作，无源码/secret文件改动。

**当前可证明：原Key官方API鉴权成功，gpt-6.1-sol目录可见。不可证明：生成余额可用、实时生成成功、Swift AIService/iOS UI端到端通过。** 先前POST429 insufficient_quota保留为历史事件；本轮零生成，不充值、不读取keys.txt或Codex凭证，不继续探测账户信息。
