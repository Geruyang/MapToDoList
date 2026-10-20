# 用户授权多候选 OpenAI Key 轻量验收

日期：2026-10-11。用户明确授权复用 Desktop/keys.txt 原文件中的候选；本轮不读先前新建.env，不创建更多Key，不复制/改写原密钥文件，不将Key存入App/仓库。采用OpenAI key skill的保护规则，复用授权已明确，无重复确认。

安全inventory：按原文件出现顺序提取语法可识别的sk-候选并去重，共47个。只报告数量与1-based ordinal，不输出片段、指纹、原文件、HTTP原始错误正文或包含凭证的异常。文件内文字不作为指令执行。以后如选定ordinal，需要运行时按同一规则重新读取原文件，而非把Key落盘到新位置。

## 实际结果

- ordinal 1–21：各一次POST，均HTTP401，classification=authentication_rejected。
- ordinal 22：网络或响应解码错误，未获得可记录的HTTP status；立即停止，未重试。
- 剩余25个候选未尝试。没有selected_ordinal。
- 未出现200、400、403、404或429；不能将未尝试/网络未决候选归类为无效。
- 未查询模型列表、余额、organization、project或其他账户信息；每candidate仅一次限量生成请求，无自动retry或并发。

证据：[安全JSON结果](OPENAI_CANDIDATE_RESULT.json)。只含ordinal/status/classification、请求安全参数和局限，无secret。

## 请求与边界

固定官方HTTPS `https://api.openai.com/v1/responses`，禁自动重定向。body与已读取当前Swift helper同形：gpt-6.1-sol、reasoning.low、store:false；测试额外max_output_tokens512。一个虚构事项“Fictional public library visit”、公开“New York Public Library, Manhattan”、临时UUID；没有真实用户事项、备注、坐标或稳定事项ID。

HTTP200将立即停止遍历，即使token上限导致strictJSON不完整也不换Key；未知或非quota型429立即停止，不以换Key绕过rate limit；通用协议/服务错误也停止。本轮实际在22的网络/解码失败停止。后续规则已收紧为模型名/schema统一问题同样先停止报告，不将此类系统问题当作候选鉴权失败。

运行守卫start<74、stop75，启动70.7%、峰71.3%；没有build/simulator/Xcode/device操作。只验证Python HTTP代理请求而不是直接运行Swift AIService/Keychain/iOS UI；本轮没有成功鉴权/生成，不能称App E2E或真实JSON输出通过。上一轮另一个.env账号的列表成功不代表这些candidate鉴权成功。

本轮已结束，不自动继续22或23。原文件可能有可用未测候选，也可能是22网络暂时故障，具体仍未知；后续继续须按主会话明确运行边界进行。

## 后续已授权逐项完成（最终状态）

主会话确认用户已有逐项测试授权，不需重复询问。旧22脚本没有记录异常类型，因此无法从既有证据可靠还原DNS/TLS/timeout/JSON，未编造类型。随后一次不带Key的官方 `HEAD /v1/models` 返回HTTP401，证明当时TLS/HTTP连通正常。

从23继续：ordinal23–47各一次POST，全HTTP401 authentication_rejected；无200、429或统一协议/模型拒绝。随后主会话明确允许对唯一暂时网络未决22做一次复查，22返回HTTP401。该新结果明确鉴权拒绝，但不证明旧22异常的历史具体原因。

**最终47个候选均有HTTP401结果；0个未测/最终未决，selected_ordinal=null。未找到可以直接用于OpenAI官方API的候选。** 不将此结论推广为其他OpenAI兼容代理/供应商端点是否可用；本次从未向这些端点发Key。

总量48次串行POST（每候选一次，22仅一次有明确授权的网络复查）+1次无KeyHEAD。没有成功生成、没有自动重试或速率限制换Key绕过、没有余额/org探测或充值。原文件未修改，未创建新的secret文件；没有保存Key片段或指纹。

保护：start<74/stop75，续测启动71.2%、峰71.4%；22复查启动71.8%、峰71.9%。所有子进程结束；不再自动请求。

证据：

- [初测1–22](OPENAI_CANDIDATE_RESULT.json)
- [续测23–47](OPENAI_CANDIDATE_RESUME_RESULT.json)
- [22一次复查](OPENAI_CANDIDATE_22_RECHECK_RESULT.json)

以上仍仅Python source-shaped HTTP协议测试；没有真实Swift AIService/iOS App E2E通过证据。应用成功生成验收保持BLOCKED（没有可用官方API候选），不伪称使用无效凭证完成。
