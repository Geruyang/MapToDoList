# R32 模拟器地图选点诊断

R31产品＋R32未放宽的UI测试，iOS26.2 (23C54)、既有 `9B92CCDE-87A5-49CE-B0BE-9DD271313987`，xcresult型号iPhone17ProMax/x86_64。没有操作真机或修改源码。R32-inputs 56文件全部匹配，freeze SHA `89e14368da4de6ae5d3be5c707a976b00d527d947a8148a7e3fa753753032b20`。

构建exit0；唯一 `testMapPointOpensEditorAndPersistsChosenLocation` 实际 **0 PASS / 1 FAIL / 0 SKIP**、exit65，27.860秒。失败点为 `WaypointUITests.swift:190` 的 `map.selection.pin.exists`；由于continueAfterFailure=false，未执行后面的confirm/cancel isHittable断言，更没有保存/重启阶段。不是内存中断，SAMPLE_ONLY峰值83.1%。

预断言完整AX树及截图已经真实保存、串行导出。可确认两件独立事实：

1. 父级ID覆盖：截图中取消与确认按钮清楚可见；AX记录取消选择和确认地点两Button的identifier均是`map.selection.card`，分别frame `{{32.0,817.0},{67.7,20.3}}` 和 `{{340.3,817.0},{67.7,20.3}}`。坐标Other的identifier也为card，label `37.77290, -122.43255`。`map.selection.confirm`、cancel、coordinates的独立ID均未暴露。因此不能把旧confirm查询失败归为按钮不在屏幕或只由遮挡造成。
2. 模拟器地图/pin未出现：AX的Map无内容，AnnotationContainer无子节点，`map.selection.pin`缺失；截图地图底图空白，没有可见pin。原因未唯一确定，不能把pin缺失归因于同一个card父ID，也不能绕过pin断言把整例算通过。

证据全部在 `SIMULATOR-results/`：`R32-sim-mapdiag-build.log/.xcresult`、preflight.json、artifact-hashes.json（SHA `80d6908c0349af5d4394c6d17749dd825a7db004a71b3d94dbcdfe21a394cfab`）、process.json、summary.json、tests.json及`R32-sim-mapdiag.xcresult`。

附件：`R32-sim-mapdiag-attachments/37E2C446-5C8F-4952-9DEC-CA398C8ACF9F.txt` 是完整preassert hierarchy，`2EE40E18-F920-4892-BC13-8AB50C568F1E.png` 是真实preassert截图；manifest记录5个附件。截图与层级均已目视核对。serial export均exit0，没有SQLite初始化并行冲突。

Xcode测试结束后模拟器自动Shutdown，显式shutdown返回already Shutdown；inventory/ps确认无runtime、launchd_sim或xcodebuild残留。唯一heavy slot已先交回root。随后root仅让map owner移除父级ID并挂到标题，测试保持严格；R33复测另记，不覆盖本轮失败证据。
