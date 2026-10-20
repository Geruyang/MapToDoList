# 重启后 R27：独立证据复核

2026-10-11。root串行执行，本agent仅只读核验、导出已有附件和准备脚本；未接管root session18106，未build/test/launch/install/购买。旧timeout、通知干扰、titles失败、两次memory拒启/中断证据全部保留。

## 候选身份与真实结果

- UI source SHA256：4f94c048ab2d00cd6674fe40b91c942dcee867555618d6a44581ea0ef2c8ce87。
- SubscriptionView SHA256：b27123aac7537122f5f21c33400b375922472ae09c3a56933e6f2f19ecbab017。
- root的94个bundle文件hash逐项重算 **0 mismatch**；两App `codesign --verify --deep --strict`再次exit0；profile/team/UDID/entitlements复核已写 `R27-after-restart-independent-proof.json`。
- 主debug dylib SHA256：afe414687178c4ecd9c7fbf4a79d322c79d422c9174403c331c7fadfd26e7da0。完整hash：`R27-after-restart-bundle-sha256.json`。
- 两install JSON真实success：Main容器D2111C14-66C9-4C22-95D3-A4D9FE9A5655；Runner容器FD3CE12B-2B58-455C-A859-D3489B75B783。

| 重启后证据 | 实际结果 | 采样峰值 |
| --- | --- | ---: |
| R27-after-restart-Debug-build | TEST BUILD SUCCEEDED；实际driver determinism override存在 | 70.6% |
| R27-after-restart-install | 每App一次安装success | 67.6% |
| R27-after-restart-english | 1/1PASS，65.765s | 68.3% |
| R27-after-restart-titles2 | 2/2PASS，editable82.622s、readonly81.537s | 70.5% |
| R27-after-restart-key-export2 | 1PASS（只读三格式43.895s）/1FAIL（AI168.241s），exit65 | 73.6% |

本候选已执行的5项UI：**4PASS/1FAIL/0SKIP**。English的未filter contrast、付费页管理/法律入口、关闭后4tabs恢复、无权益创建门禁sheet关闭后Map可用都实际通过。Titles包含normal与AXXXL、完整value/高度、保存重启、readonly静态文本且不可编辑；之前titles失败由测试先滚回title的补丁修复，不能删除原失败。

## AI失败的最小诊断

唯一failure为compiled `WaypointUITests.swift:470`：最终relaunch后选OpenAI，直接查询SecureTextField.exists。此前四provider循环的SecureField类型、掩码、空Save禁用、Done收键盘、非空Save、metadata、取消确认保留、明确确认删除、缺key禁删除均执行且没有assertion failure；provider选择重启持久化与Gemini不可选检查也已到达。但完整case仍FAIL，不能改称PASS。

附件manifest：`R27-after-restart-key-export2-attachments/manifest.json`；日志 `R27-after-restart-key-export2.log`。FE3974C0-D305-4586-94FF-805F8562C39F.png是四循环完成、重启之前的截图，已view_image核无私人通知，画面停在可选AI/provider、model、policy区，设备密钥Section在下方未露出。**不是最终失败截图**。最晚legacy snapshot9B58C464-B10E-486E-8385-6A28E3F37005仅单个选项元素，不能据它断言全Form缺控件。

源码AISettingsView将provider放在可选AISection，而SecureField在更下方独立设备密钥Section；中间有多行model/policy内容。与已通过loop不同，final查询没有先scroll。证据支持lazy Form viewport的测试假设问题，没有证明产品安全字段损坏。最小建议：OpenAI.tap后 `XCTAssertTrue(scrollToElement("ai.key"))`，随后保留原SecureTextField.exists，必要时增加hittable与重启后该区域截图。此报告不修改source；新source需独立review和必要候选/单case回归，不重跑全suite来掩盖差异。

## iPhone-only静态配置（R28尚未产物验证）

用户明确首版仅iPhone。project.yml SHA eb4a1c9f354519f0c24b10de2a3f1327bcd2ff8988abe78fab7efee834f6fe26；pbxproj SHA a28eda04eea7df93df77c40223bf1f02e612ef28defd2b0294ed017ff9a11d55。独立读取确认8个XCBuildConfiguration（project Debug/Release及App/Unit/UI各Debug/Release）均family1，无family2 override或外链xcconfig。

但当前R27实际Info.plist仍UIDeviceFamily **[1,2]**；新配置仅source，**R28未build/install/runtime**。下一有效产物必须读取UIDeviceFamily==[1]。此配置不证明最低支持iOS17的runtime通过；iOS17专项仍未跑，不能以取消原生iPad范围代替OS兼容验证。

资源当前超过新任务准入，无root授权的重工作全部暂停。只读Sandbox新脚本/manifest已prepare但NOT_RUN，见 `DEVICE_R27_REMAINING_MATRIX.md`。
