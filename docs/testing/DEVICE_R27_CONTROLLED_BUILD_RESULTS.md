# R27 / Title 导航候选构建：中断，未安装

2026-10-11。两冻结源码输入：UItest `4f94c048ab2d00cd6674fe40b91c942dcee867555618d6a44581ea0ef2c8ce87`，SubscriptionView `b27123aac7537122f5f21c33400b375922472ae09c3a56933e6f2f19ecbab017`。63个原始输入文件hash已保存 `R27-title-nav-inputs.json` / `R27-title-nav-Controlled-inputs.json`。没有xcodegen/clean/新增文件target变更，没有签名凭证或产品逻辑另改。

## 真实两次证据

1. 正式start<72预检：`R27-title-nav-Debug-build.log`，baseline72.4%，守卫拒启exit75。xcodebuild未执行，xcresult未创建，旧证据保留。
2. root技术裁决授权唯一新路径controlled Debug增量：start<73、stop75、0.5s采样、sole heavy、outerjobs1、`SWIFTC_MAXIMUM_DETERMINISM=1`。`R27-title-nav-Controlled-Debug-build.log` baseline72.5%，127行首次守卫触发样本75.0%，中断exit75。不是BUILD SUCCEEDED，无成功候选，未安装/测试/重试。

本轮首次在实际Xcode pipeline确认环境控制生效：56/82行 `remark: SWIFTC_MAXIMUM_DETERMINISM overriding -j`，对应MapToDo与MapToDoTests的note。虽然默认driver命令仍可显示生成的-j8，该环境覆盖已真实由driver识别，不能与之前-j1...-j8无效覆盖混同。Debug保留incremental/batch/-Onone；未应用Release WMO设置，也不宣称限制linker/Clang/SDK扫描或整个系统内存。

没有观测到Swift源码编译error；因guard中断，DerivedData产物可能是混合或不完整状态，**禁止作为可安装或发布候选**。不要依据未完成code signing或部分link步骤断言签名/hash候选成功。尚无Release归档或上传，用户80硬限与75guard未抬高；触发75样本不能作为连续内存峰值保证。

结束后只读ps没有xcodebuild/swift-frontend仍运行，slot已释放。`R27-interrupted-install-container-proof.json`证明两installed App容器仍与成功J1完全相同（Main857536D8...、RunnerE638D471...），没有新安装。现有回归结果仍只对应J1。

## 现有J1回归（独立历史，不外推R27）

勿扰后EnglishMarketSmoke真实FAIL42.870s，peak69.8%，snapshot正常；此次audit元素是Manage or cancel subscription被floating tab覆盖，CTA深字浅绿清楚、没有私人通知。root/ui_design已确认，R27未来源码隐藏paywall tab但未新构建验证。

Gallery3实际3/3PASS，peak71.7%，中文/EN/AXXXL21图与hierarchy已导出独立review。AX动态字号heading增高>1.4倍断言通过，三末端CTA完整高于tab frame。ui_design独立确认R22三个CTA完整、R24 normal editor全文完整；不冒称AX長title全通过。

Titles2实际0/2PASS、2FAIL、peak73.3%，均最大辅助字号周期在旧compiled source331等待title失败；normal输入/保存重开/readonlyText完整性断言已执行。tap location confirm前曾滚向Form下部，随后未滚回title；root已在未来testsource加向顶部scroll且保留原value/高度/readonly/relaunch断言。仅4张NORMAL PNG，AXfailure只有已有录屏/查询debugtxt，未取帧；不伪造原始failure截图。

Key-export2 guard一次baseline72.1≥72拒启exit75，0cases，未循环重试。

Readonly StoreKit独立1/1PASS，peak73.3%，USA annualUSD9.99/7day intro/eligible true，entitlements=[]，Sandbox交易仍UNPROVEN；不是完整权益生命周期验证。
