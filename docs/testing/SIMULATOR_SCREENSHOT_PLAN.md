# 模拟器截图与 XCUITest 执行方案

## 隔离及执行

首轮专用设备为 `D11C7BCC-E156-4D69-9BB2-A7D3C6358353`。内存限制后改为接续主会话唯一已热启动的 iPhone 17 `23D83E41-E786-4BBB-9A3A-261E6598DB6B`；不得重新启动第二台模拟器。以下仅为准备命令，必须等主会话放行才执行：

```sh
python3 scripts/memory_guard.py --start-below 68 --stop-at 75 -- xcodebuild test -project MapToDo.xcodeproj -scheme MapToDo -jobs 1 -destination 'platform=iOS Simulator,id=23D83E41-E786-4BBB-9A3A-261E6598DB6B' -derivedDataPath /tmp/Waypoint-SimulatorUITest-DD -only-testing:MapToDoUITests -parallel-testing-enabled NO -resultBundlePath docs/testing/SIMULATOR-results/ui-tests.xcresult CODE_SIGNING_ALLOWED=NO
```

用户要求内存不超过 80%。所有恢复启动由主会话准入，仅保留一个运行中的模拟器并用 `-jobs 1`；上方守护按最新安排以保守估计在 68% 以下准入、75% 中断，为上限留余量。守护是采样停止机制，不是操作系统硬配额；其他进程增长也会影响内存。资源中断单独记录，不能记产品失败或已通过。

实际工程若使用 workspace 或不同 scheme，按工程调整并在运行报告保留实际命令。每次运行使用独立结果目录；禁止覆盖上一轮失败证据。流程测试固定中文启动参数，英文 smoke 单独传入 `-AppleLanguages (en) -AppleLocale en_US`。

XCUITest 必須等待元素状态，不使用固定长睡眠掩盖时序问题。持久化测试通过 `terminate()` 和 `launch()` 验证；重启时不传重置参数。联网搜索、系统权限、StoreKit、离线与确定性 UI 场景分开记录。仅使用测试占位密钥。

## 截图集合

每张截图来自运行中的 App，XCUITest 附件设为 `.keepAlways`。通用附件名称使用 `WAYPOINT_<case>_<appearance>_<state>`，同一测试源可用于模拟器或真机；实际设备与外观记在对应运行报告。原始截图保留设备尺寸，不编辑成产品证据。

运行完成后的截图导出准备命令：`xcrun xcresulttool export attachments --path <实际结果.xcresult> --output-path docs/testing/SIMULATOR-results/<本轮>-attachments`。读取 manifest 并目视检查所有关键截图后再形成 UI 结论；该命令尚未执行。

| 截图 ID | 目标画面 | 检查重点 |
| --- | --- | --- |
| MAP_EMPTY | 首次启动地图与空列表 | 首屏、空态、导航与地图提示 |
| MAP_SEARCH | 地点搜索候选结果 | 结果可读、选择入口 |
| TASK_EDITOR | 带地点、时间、提醒的新建编辑页 | 字段、键盘遮挡与保存状态 |
| TASK_PERSISTED | 重启后的已保存待办和地图标记 | 标题、地点、日期与状态一致 |
| REM_DENIED | 通知被拒后的提示 | 准确状态与恢复入口 |
| EXPORT_RANGE | 日期范围与格式选择 | 日期边界与三种格式 |
| EXPORT_SHARE | 系统分享预览 | 文件名/扩展名与分享交互 |
| PLAN_FIXED_FLEX | 固定和灵活事项计划 | 时间顺序、路线与说明 |
| PLAN_CONFLICT | 时间/交通/天气冲突 | 冲突位置、严重程度与建议 |
| AI_SETTINGS | 五家提供商设置 | 完整选项、掩码、删除和错误反馈 |
| WEATHER_OUT_OF_RANGE | 预报范围之外 | 无误导天气数据 |
| WEATHER_OFFLINE | 离线无缓存或带时间的缓存 | 来源与更新时间 |
| SUB_OFFER | 可用 StoreKit 产品/试用 | 价格、周期与条件 |
| SUB_ACTIVE | 成功购买后的权益状态 | 当前产品/到期信息 |
| SUB_EXPIRED | 取消续订到期后的状态 | 权益变化和恢复入口 |

地图、列表、编辑、行程、设置、订阅至少各采集一张浅色与暗色截图；长内容编辑/设置另采集最大动态字体截图。避免在密钥显示时截图。

## 结果报告格式

运行报告填写实际开始时间、设备系统、commit（如果存在）、工程/scheme、命令、结果路径、用例数量、失败用例与阻塞范围。每个失败给出最短复现步骤和实际/预期结果；不修改产品代码。修复后只复测受影响场景及必要回归。所有未执行矩阵条目继续标记 NOT RUN 或 BLOCKED。

## 实现规则范围观察

作为独立测试者记录可观察的实现范围与分工偏离，只报告事实及路径/证据，不执行实现者自监督。产品缺陷发给主会话或对应实现者；测试所有权仅限 `MapToDoUITests/` 和 `docs/testing/SIMULATOR*`。
