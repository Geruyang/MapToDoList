# Input-layout J1 新候选真实记录

2026-10-11。本轮恢复四 provider API Key 范围，取消旧 ChatGPT subscription 登录方案。原证据未覆盖；source frozen 后执行一次构建与每个 App 各一次安装。

## 构建与身份

`Input-layout-J1-build.log/.xcresult`：build-for-testing exit0，TEST BUILD SUCCEEDED，基线71.8%，采样峰值74.8%，start<72/stop75/0.5s。保留原 DerivedData、batch、incremental 和 indexstore。四产品 UI 修补、最新中英分析方式文案、22 UI source 与 Sandbox diagnostic 均入新候选。

重要：命令行 OTHER_SWIFT_FLAGS确为字面 `$(inherited) -j1`，但实际 SwiftDriver 日志60/150/263行顺序 `-j1 ... -j8`。Swift 官方 Driver.swift 的 parseIntOption使用getLastArgument，因此有效并发上限仍8，**未证明内层j1生效**。不为该 flag 重新构建。

strict codesign --verify --deep --strict 两 App均exit0。公开签名leaf SHA256两者相同 `e49a66d5bf0c2e2df71ba5c9ae1549e12c10f6fb76e6581a69edfdcbf5bd8e19`；Team VA8X63NPCS；两profile包含真实UDID且未过期，PPQCheck=true。主 App WeatherKit/time-sensitive entitlement=true，get-task-allow=true（Debug开发签名，不是商店发布归档）。见 `Input-layout-J1-*.app-signing.json` 与全部94regular文件hash清单 `Input-layout-J1-bundle-file-sha256.json`。

| 产物 | SHA256 |
| --- | --- |
| 主 launcher | cb40f9b1bcd1d099ec2f7fd3a2cbdd8cbf82ebc41f838eb6c73a2a57da2e94cc |
| 主 debug dylib（实际逻辑） | b16498fd9e4fcc3404042b2c1d579edf9e4f04dfeb3022fa24bcdb550824d313 |
| Unit bundle | dbf9104364e109216a5eed3805c9904d0b9c73b65ec09612acd00f26958596c3 |
| UI bundle | fa2d52ee88012937f567e344d764062a42437a5887c42cadbd1d4672219681db |
| UI source | eb3f392ef22bfc7bb173acc748207fe71a2f0d9544290fb729ddf6c3bbc0825e |

`Input-layout-J1-install.log`：两 App各install一次成功exit0，采样峰值72.8%；未uninstall/重装循环/证书更改。新 Main 容器857536D8-4D27-4C2D-98BA-C813AE270534，Runner E638D471-6F2C-4C70-A02F-EEFC33335340。安装后 App/Runner都真实启动成功，没有本轮security拒绝。

## Focused8：0 PASS / 1 FAIL / 1 INTERRUPTED / 6 NOT_RUN

`Input-layout-focused.log`、未完整finalize的 `.xcresult`，UseDestinationArtifacts=true；基线72.7%，守卫在0.5s采样第一次发现越75时76.7%，中断自身进程，exit75。不能把75停止阈值称实际峰值；guard采样不是OS配额。未见80以上样本，不把离散采样视为连续峰值保证。

| 用例 | 实际状态 |
| --- | --- |
| EnglishMarketSmoke（含分析方式/导出/已加载paywall contrast） | FAIL：136.239s，Failed to get matching snapshots / Timed out while evaluating UI query；尚在English Today tab基础查询，未执行新增AI/export/paywall断言 |
| EnglishScreenshotGallery | 已开始，因memory guard中断；不记PASS/FAIL/SKIP |
| Chinese gallery | NOT_RUN |
| AXXX L gallery | NOT_RUN |
| Long editable title | NOT_RUN |
| Long readonly title | NOT_RUN |
| Four provider secure Key / Done / save / confirmation delete | NOT_RUN |
| Existing readonly history / three export formats | NOT_RUN |

新候选0个UI通过，不能把旧候选18PASS迁移为本轮。新分析说明/KeyDone/CTA末端/长title/paywall contrast实际验证仍未闭合。没有真实Key调用/购买/账号密码输入。全22未启动。

`Input-layout-focused-container-proof.json`：before/after两个URL严格相等，证明本轮no-install没有重装。

## 只读失败诊断与导出限制

guard中断后 `.xcresult/Info.plist` 缺失，xcresulttool summary/tests/activities均error64；空JSON不是有效结果，不能称完整导出。保存原始 Data 与 Staging全部内容，不伪造Info.plist，不修改旧bundle。

原始Data中两块有真实PNG签名，逐字节复制、SHA记录在 `Input-layout-focused-raw-pngs/manifest.json`；已view_image查看English Today与Map，无可见系统modal。因缺finalized活动映射，case归属尚未证实，不能当已验收gallery或paywall截图。229MB原始MP4仍留原处，未做重型视频解码。

Staging Session-MapToDoUITests日志：965行App无alerts，1223行SpringBoard无alerts；2997/4608/5050行每轮30秒UI query timeout，XCTFuture Code1000。testmanagerd.log证明authorize session成功（PID2394）。当前证据不支持新trust/automation拒绝，也不足以归因产品逻辑或系统modal；下一次若授权重试，应单case而非重复全组。设备Orientation Face Up/Portrait变化反复记录，原因未证明。

ReadonlySandbox独立UseDestinationArtifacts配置已准备，保留新generated Apple unit-host注入环境，且没有StoreKitConfiguration/localfixture配置。此处截至focused停止时 **NOT_RUN**；商品metadata不能单独证明Sandbox交易环境。
