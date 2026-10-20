# 新候选分阶段设备验证

本轮source仅freeze，未编译/安装/测试。最新准入sample71.2%，超过build start<70%；不提高阈值、不轮询、不拿旧built尝试新Done/22项/Sandbox诊断。

1. `bash docs/testing/DEVICE_BUILD_INPUT_LAYOUT_CANDIDATE.sh`：先核sample<70，再xcodegen、guard70/75、0.5s采样、jobs1 `build-for-testing`。生成App/Runner/Unit测试bundle，新证据Input-layout-candidate-build；不install或launch。BUILD SUCCEEDED后核验strict codesign、实际Team/profile/device/WeatherKit entitlement，记录三个Mach-O SHA及测试bundleSHA。
2. 一次安装App与Runner：`xcrun devicectl device install app --device 2050E692-2C1D-5D9D-967A-EABA499B386F --json-output <新evidence> build/DeviceData/Build/Products/Debug-iphoneos/MapToDo.app`，再相同CLI安装MapToDoUITests-Runner.app。禁止uninstall/密码读取/证书安全配置更改。只读info apps记录两个新容器；若设备验证拒绝，准确区别App与Runner，不再重复安装。
3. 之后测试全部采用官方 `UseDestinationArtifacts=true`。以build-for-testing生成的xctestrun为配置依据，移除三个本地安装路径，设置当前Host/Bundle/UITarget的destination识别键，不安装artifacts。记录每阶段前后容器，断言相等。
4. focused 8UI：长editable title、长readonly title2；中文/英文/最大辅助字号gallery3（全CTA frame高于tab）；四provider1（空输入disabled、掩码已输入、Done收键盘、非空Save enabled、保存/取消/删除/重启、Gemini不可选）；readonly历史三格式导出1（新Text只读语义）；现有英文market1增强等待实际商品/资格/CTA截图与无filter contrast审计，不tap购买。新结果Input-layout-focused，不运行旧binary，不降低断言。以 `DEVICE_PREPARE_FOCUSED_NOINSTALL.py <新generated.xctestrun> <新output.xctestrun>` 生成8项UI配置；unit-host Sandbox注入环境单独审阅新生成配置后才运行。
5. 仅 `SandboxSubscriptionDiagnosticsTests/testReadOnlyLiveProductEligibilityAndVerifiedEntitlementMetadata`，单独app-hosted no-install配置，不含StoreKitConfiguration及本地fixture，不调用purchase/sync/reset/SKTestSession。返回真实annual/USD9.99/7day metadata和intro eligibility。existing verified transaction若存在必须environment sandbox且拒绝xcode；无transaction明确环境未证实，不冒称Sandbox生命周期通过。新结果Sandbox-readonly-live。
6. 全22UI作为下一阶段；前述focused/服务真实结果先报告，不自动扩大未授权任务。测试准入及停止遵循主会话该阶段授权（当前no-install start<74/stop75，build70/75），无模拟器/无并行。每阶段证据不可覆盖。

构建若编译错误，先报告具体文件/行/诊断并按主会话指示处理，不自行改未归属源。当前只通过脚本语法检查，所有新runtime验证仍NOT RUN。
