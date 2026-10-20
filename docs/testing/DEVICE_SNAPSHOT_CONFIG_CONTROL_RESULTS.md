# Snapshot 配置对照与真实 contrast 失败

同一已安装 Input-layout-J1候选，同一 EnglishMarketSmoke method，使用旧18PASS运行的极简 UseDestinationArtifacts配置，仅选择该一项。未build/install/修改source/放松断言。

`Snapshot-minimal-config-single.log/.xcresult`：exit65，实际1项FAIL，43.839s，采样峰值73.7%。起始log四舍五入显示72.0%，守卫内部未舍入值通过strict start<72条件。stop75不变。

本次基础Map/Today/Plan/Settings UI查询未复现先前136s的snapshot timeout，成功走到两种English分析方式说明、Export NavigationLink开始/结束日期并返回AI/Settings、实际商品/资格/价格/购买按钮，最后执行未filter的contrast审计才失败。不能把完整用例称PASS或已修复全部UI。

## 配置与基础设施判断

旧极简manifest没有新增generated配置的 PreferredScreenCaptureFormat=screenRecording、UITargetAppPerformanceAntipatternCheckerEnabled=true、UITargetAppEnvironmentVariables、BlueprintProvider等可选项。此次对照支持“测试配置边界差异可能影响snapshot”假设，但不是单flag归因实验，不能宣称哪一flag已证实根因或永久修复。

两轮都有 Supported platforms for the buildables in the current scheme is empty警告，旧18PASS同样出现，不据此归因。DDI contentIsCompatible=true/isUsable=true，DeveloperMode enabled，device booted，passcodeRequired=false/unlockedSinceBoot=true。未发现遗留xcodebuild/swift-frontend；只读发现共享CoreDeviceService约31MB、SWBBuildService约18MB，未杀共享服务。

产品所有源码保持原样；下一步保留轻量配置完成标准断言即可，不必为定位全部可选flags重跑长整组。

## 精确失败与隐私

审计attachment `Complete Issue Description.txt`正文仅“Contrast failed for element”。failure element截图 **8B8F29D6-A42F-4C44-B990-65A32912AA11.png** 显示系统notification遮挡Subscription导航标题。该图与 App截图B683CD88-9AF9-40FF-8880-FCA3B603F96B.png含私人通知内容，仅local evidence；不嵌入报告/聊天，不用于App Store、官网或其他公开发布，不复述其内容。

实际 CTA crop **C2ECAD23-AAC1-48ED-BC91-3D852B87537F.png**：深绿文字浅绿底，显示Start 7-day free trial。live页已显示US$9.99/year与Eligible7days；未tap购买/Restore，未输入账号密码，UImetadata不能证明已完成Sandbox交易。

English分析说明截图 **4279650F-C260-4C30-9C5B-F4A5D447D5E1.png**；导出导航 **2F9FB06B-6944-4D89-96F4-1112D0DD0E7A.png**。完整attachment manifest：`DEVICE_EVIDENCE/Snapshot-minimal-config-single-attachments/manifest.json`。独立ui_design只读review已收到必要路径。

root已向用户即时提出开启勿扰，待其答复后才单case无source改动重试一次；此处不称contrast fix/pass。ReadonlySandbox与UI干扰独立，仍需start<72才执行一项诊断。
