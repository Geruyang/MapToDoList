# 官方 API 模型核验（2026-10-11）

**首版发布可用范围：GLM / Qwen / DeepSeek / OpenAI。Gemini 已由产品年龄定位决定禁用；下表Gemini仅保留技术核验记录，不代表当前可用。UI移除，服务层models/suggest/send均拒绝。旧Gemini偏好迁移为OpenAI/gpt-6.1-sol，不删除旧Keychain项。**

内置列表是核验日期的候选，不保证具体账户或地域已开通。界面支持主动 `GET /models` 刷新及自定义 ID；返回错误不覆盖原计划。Qwen 默认新加坡国际端点，可选择北京/美国弗吉尼亚；地域密钥不可混用。

| 服务 | 精确 API ID | 官方来源与核验证据 |
|---|---|---|
| OpenAI | `gpt-6.1-sol`, `gpt-6-astra`, `gpt-6-luna` | https://developers.openai.com/api/docs/models 原文各卡片 `Model ID`；https://developers.openai.com/api/docs/models/gpt-6.1-sol 是实际 API 模型页，明确支持 Responses 与 low 推理强度，并非从 Codex 工具列表推断。 |
| Gemini | `gemini-3.8-flash`, `gemini-3.6-flash`, `gemini-3.1-pro-preview` | https://ai.google.dev/gemini-api/docs/models 官方 “All Gemini 3 models” 的 Endpoint 表。3.1 Pro 明确标 Preview。 |
| DeepSeek | `deepseek-flash`, `deepseek-v4-pro` | https://api-docs.deepseek.com/api/list-models/ 官方 models 响应 JSON 的 id 字段；展示名分别为 DeepSeek-V4.1-Flash 和 DeepSeek-V4-Pro。 |
| Qwen | `qwen3.8-max`, `qwen3.7-plus`, `qwen-plus` | https://help.aliyun.com/en/model-studio/model-pricing 官方 China (Beijing) Model ID 表。模型地域与账户需匹配。 |
| GLM | `glm-5.3`, `glm-5.1`, `glm-5` | https://docs.bigmodel.cn/cn/guide/models/text/glm-5.3.md 官方示例 `"model": "glm-5.3"`；5.1 官方同路径 .md 示例 `model="glm-5.1"`；5官方页面 https://docs.bigmodel.cn/cn/guide/models/text/glm-5。HTML读取超时时，通过无凭证curl读取官方.md；未读取任何用户Key。 |

GLM 不假设存在账号 /models 端点：刷新读取官方 llms.txt 的模型文档链接，再核对官方 .md 请求示例中的精确 model ID，明确只证明官方目录，账号开通状态在生成时核验。Qwen 使用官方原生模型列表端点，详情见下方地域记录。API实网生成/刷新验证 NOT_RUN（没有用户提供测试密钥，也未申请或创建密钥）。

## 海外 Qwen 地域（2026-10-11）

默认 Singapore，可持久化选择 Beijing / Singapore / US Virginia。精确端点核验自 https://help.aliyun.com/en/model-studio/base-url 的 “DashScope Domain” 官方表：

- Beijing: `https://dashscope.aliyuncs.com/compatible-mode/v1`
- Singapore: `https://dashscope-intl.aliyuncs.com/compatible-mode/v1`
- US Virginia: `https://dashscope-us.aliyuncs.com/compatible-mode/v1`

密钥按 Qwen 地域分开保存到 Keychain，切换不自动复制密钥或重设用户自定义模型。官方明确密钥有地域范围，地域不匹配会401。US无 `-us` 后缀模型可以全球推理，`qwen-plus-us` 在官方地域页示例中用于限定美国推理：https://help.aliyun.com/en/model-studio/regions/。

Qwen模型刷新使用官方原生列表接口（不再假设兼容 `/models`）：https://docs.modelstudio.console.alibabacloud.com/en/model-studio/list-models。公开列表格式为 `output.models[].model`，请求 `page_size=100`。Singapore共享域 `/api/v1/models`；Beijing/Virginia 官方列表文档要求 Workspace 专属域，所以设置提供 Workspace ID 可选字段，否则明确提示无法刷新，不伪造账号列表。生成仍使用所选地域官方共享域。候选地域模型来自官方价格页面各地域表；账号权限以刷新/实际调用为准。未用真实用户Key调用任何地域。
