# R33 模拟器地图选点复测

R33产品＋R32严格UI测试，未修改任何产品或测试源码，没有操作真机。复用既有iOS26.2 (23C54) iPhone17ProMax/x86_64模拟器 `9B92CCDE-87A5-49CE-B0BE-9DD271313987` 和 `/tmp/Waypoint-StoreKit-R30-Simulator`，独占单重任务槽、jobs1、parallel-testing-enabled NO，无额外测试。

构建 **exit0**。唯一 `testMapPointOpensEditorAndPersistsChosenLocation` 实际 **0 PASS / 1 FAIL / 0 SKIP**，test-without-building **exit65**，case耗时20.303秒。仍失败于 `WaypointUITests.swift:190` 的 `map.selection.pin.exists`。原严格断言保留；continueAfterFailure=false，未到confirm/cancel isHittable、打开编辑、保存或重启持久化阶段。

完整preassert AX和真实截图已串行导出并目视核对。局部AX修复与整例结果分开：

| 元素 | R32 AX | R33 AX | 本轮证据范围 |
| --- | --- | --- | --- |
| 已选地点标题 | map.selection.card | map.selection.card，仅标题使用 | 父级不再覆盖子元素 |
| 坐标Other | map.selection.card | map.selection.coordinates | label `37.77290, -122.43255`，frame `{{32.0,782.7},{133.3,14.3}}` |
| 取消Button | map.selection.card | map.selection.cancel | label取消选择，frame `{{32.0,817.0},{67.7,20.3}}` |
| 确认Button | map.selection.card | map.selection.confirm | label确认地点，frame `{{340.3,817.0},{67.7,20.3}}` |
| 选点标记 | 缺失 | 仍缺失 | Map无AX内容、AnnotationContainer无子节点；截图底图空白且无可见pin |

因此，本轮实际确认三个独立ID恢复；没有证明按钮isHittable断言通过，也没有证明整例通过。pin与地图空白原因尚未唯一确定，不能归于已修复的父ID覆盖，不能放宽测试绕过。

56项冻结输入全部匹配。R33 freeze SHA `b5689c56d83589341efe6a0f13a5b9270e2649964b8cd2266d224621db6f5ec7`；MapScreen SHA `75251fa977fd7a96f8eeb1ac4f48175fbe2f76d694690a7d6320d858c1e3f832`；不变UITest SHA `0ee42d777fab55c74a6b35f4d4d1aa1d267108250ceb737600d8b54ec7566ce0`。86个构建产物已记录，manifest SHA `ba0940ac19f32cb4f35ed4b3983111ad2676ee53e7667ae2555430bddf095cf1`；xctestrun SHA `e424bc9e16663ae6cc881ca7eacc2c86dd4018a508c620bb5ea7d361eaa2b1be`。本DD已被R33重建，名字中的R30只表示复用路径，当前候选不可再称R30。

唯一执行命令（绝对路径与完整参数另见process.json）：

```sh
xcodebuild test-without-building \
  -xctestrun /tmp/Waypoint-StoreKit-R30-Simulator/Build/Products/MapToDo_iphonesimulator26.5-arm64-x86_64.xctestrun \
  -destination 'platform=iOS Simulator,id=9B92CCDE-87A5-49CE-B0BE-9DD271313987' \
  -only-testing:MapToDoUITests/WaypointUITests/testMapPointOpensEditorAndPersistsChosenLocation \
  -jobs 1 -parallel-testing-enabled NO \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 180 \
  -maximum-test-execution-time-allowance 180 \
  -resultBundlePath /Users/geruyang/AIProject/MapToDoList/docs/testing/SIMULATOR-results/R33-sim-mapdiag.xcresult
```

证据：`SIMULATOR-results/R33-sim-mapdiag-build.log/.xcresult`、build-process.json、preflight.json、artifact-hashes.json、process.json、summary.json、tests.json、cleanup.json及测试xcresult。附件manifest记录5项，所有serial export exit0。

- [完整断言前AX](/Users/geruyang/AIProject/MapToDoList/docs/testing/SIMULATOR-results/R33-sim-mapdiag-attachments/C4BC4479-86F9-40C7-983B-2F1EFA1FC2D7.txt)，SHA `78333e6b0f83704568fac8de3b00c830a66ea2dbc7dbd16aaccfe4553b7dbc0c`。
- [真实断言前截图](/Users/geruyang/AIProject/MapToDoList/docs/testing/SIMULATOR-results/R33-sim-mapdiag-attachments/6A8482FD-761F-44FD-81A2-CB597559244E.png)，SHA `5d2a2ac215260917c437bc53c758debc284a7baf7ad00dcfa232eee4eb67a67b`。

用户已撤销80%上限，本轮MEMORY_SAMPLE_ONLY没有阈值或内存中断。构建baseline53.0%、samplepeak61.3%；测试baseline56.3%、samplepeak77.2%。测试完成模拟器已自动Shutdown，显式shutdown149仅为already Shutdown；cleanup确认状态Shutdown，ps无launchd_sim、RuntimeRoot子进程或xcodebuild残留。重任务槽已立即交回root，后续仅做轻量证据导出，没有新build/test。
