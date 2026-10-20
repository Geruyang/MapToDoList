# Waypoint 发行文件

此目录保存本机已有的 1.0.0 Build 2、3、4 发行产物。最新候选为 Build 4；本次 2026-10-19 上传没有重新构建、重新签名或改变二进制内容。

每个版本目录包含：

- `MapToDo.ipa`：原始 App Store 发行 IPA。
- `Waypoint-*.xcarchive.zip`：完整 Xcode Archive，包含 App、发行签名元数据及 dSYM；用 macOS Archive Utility 或 `ditto -x -k` 解压。
- `ExportOptions.plist`、`DistributionSummary.plist`、`Packaging.log`：对应原始导出记录。

`SHA256SUMS` 和 `manifest.json` 提供所有版本文件校验和。可在此目录执行 `shasum -a 256 -c SHA256SUMS`。

这些 IPA 使用 App Store 发行方式签名，正常分发需经 Apple App Store 或 TestFlight 流程，不能作为任意设备的直接侧载包。

最新历史提交凭据：2026-10-12 02:48 America/Los_Angeles，App 1.0.0 (4)、年度订阅、订阅群组已提交审核，手动发布。此目录不证明此后审核通过或上线；Build 2/3 是已被替代的历史候选。

签名包中的 provisioning profile 和签名证书链是发行文件固有内容，原样保留；本目录不含签名私钥、P12、App Store Connect API 私钥或模型 API Key。
