# 最终 AI 解析真机回归准入记录

主会话授予独占资源，要求仅跑 `MapToDoTests/AIParsingTests`（含新增store:false和临时UUID两项）、jobs1、无UI/模拟器、guard start<68% / stop≥75%。

**未启动 / BLOCKED_MEMORY_ADMISSION**：memory_guard第一步实际采样71.1%，超过68%准入门槛，返回75，输出 `Not started: insufficient memory headroom.`。没有启动xcodebuild，没有编译，没有case，没有xcresult。不能记为测试FAIL或PASS。

证据：`docs/testing/DEVICE_EVIDENCE/AI-final-regression.log`。主会话收到报告后重任务资源已交回；没有终止用户App或修改系统配置。下次重新授权/内存满足时须使用新日志和结果路径，不覆盖本次准入记录。

新增两项测试与其覆盖的最新AI补丁仍NOT RUN；Release最新源码归档PASS是编译/签名结果，不能替代这两项实际断言。
