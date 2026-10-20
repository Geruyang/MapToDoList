import SwiftUI

struct PlanningView: View {
 @EnvironmentObject private var store: TaskStore
 @ObservedObject private var openAIRegion = OpenAIRegionGate.shared
 @Environment(\.openURL) private var openURL
 @State private var startDate = Calendar.current.startOfDay(for: Date())
 @State private var endDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
 @State private var revision = UUID()
 @State private var showSubscription = false
 @State private var work: Task<Void, Never>?
 @State private var mode = TravelMode.driving
 @State private var preview: PlanPreview?
 @State private var busy = false
 @State private var error: String?
 @State private var selected: Set<UUID> = []
 @State private var sourceTasks: [TaskItem] = []
 @State private var pendingAIConsent: AIPlanningConsent?
 @State private var showAIConsent = false
 @AppStorage("ai.provider") private var providerName = AIProvider.glm.rawValue
 @AppStorage("ai.qwen.region") private var qwenRegionName = QwenRegion.singapore.rawValue
 @AppStorage("ai.qwen.workspace") private var qwenWorkspace = ""
 @AppStorage("ai.model") private var model = "glm-5.3"
 private var currentAISelection: AISelection { AISelectionPolicy.normalized(providerName:providerName,model:model,openAIAllowed:openAIRegion.isAllowed) }
 var body: some View {
  NavigationStack {
   List {
    Section("行程规划") {
     DatePicker("开始日期",selection:$startDate,displayedComponents:.date).accessibilityIdentifier("planning.start").onChange(of:startDate) { _,value in if endDate < value { endDate=value } }
     DatePicker("结束日期",selection:$endDate,in:startDate...,displayedComponents:.date).accessibilityIdentifier("planning.end")
     Picker("出行方式",selection:$mode) { ForEach(TravelMode.allCases) { Text(LocalizedStringKey($0.title)).tag($0) } }
     Button { generateLocal() } label: { Label(LocalizedStringKey(busy ? "正在计算…" : "生成本地计划"),systemImage:"route") }.accessibilityIdentifier("planning.generate").disabled(busy || store.tasks.filter{ !$0.isCompleted }.isEmpty)
     if busy { ProgressView(); Button("取消规划") { revision=UUID(); work?.cancel(); busy=false; preview=nil } }
    }
    Section("AI 可选增强") {
     NavigationLink { AISettingsView() } label: {
      HStack {
       Text("AI 服务")
       Spacer()
       VStack(alignment:.trailing,spacing:2) {
        Text(currentAISelection.provider.rawValue)
        Text(currentAISelection.model).font(.caption).foregroundStyle(.secondary)
       }
      }
     }
     ForEach(planningTasks) { task in
      Button { if selected.contains(task.id) { selected.remove(task.id) } else { selected.insert(task.id) } } label: { HStack { Text(task.title); Spacer(); Image(systemName:selected.contains(task.id) ? "checkmark.circle.fill" : "circle") } }.accessibilityLabel("选择发送事项 \(task.title)")
       .accessibilityValue(Text(LocalizedStringKey(selected.contains(task.id) ? "已选中" : "未选中")))
       .accessibilityAddTraits(selected.contains(task.id) ? .isSelected : [])
     }
     Button("生成 AI 建议") { prepareAIConsent() }.disabled(busy || !planningTasks.contains(where:{selected.contains($0.id)})).accessibilityIdentifier("planning.ai.generate")
    }
    if let preview {
     Section("预览：\(preview.changes.count) 项时间调整") {
      ForEach(preview.changes.keys.sorted(by:{$0.uuidString < $1.uuidString}),id:\.self) { id in
       if let task = store.tasks.first(where:{$0.id == id}), let date = preview.changes[id] {
        VStack(alignment:.leading) { Text(task.title); Text("\(LocalTimeFormatter.string(task.scheduledAt, timeZoneIdentifier: task.timeZoneIdentifier, includeDate: true)) → \(LocalTimeFormatter.string(date, timeZoneIdentifier: task.timeZoneIdentifier, includeDate: true))").font(.caption) }
       }
      }
      if preview.changes.isEmpty { Text("没有可应用的时间调整。") }
      ForEach(Array(preview.conflicts.enumerated()),id:\.offset) { _,message in Label(message,systemImage:"exclamationmark.triangle").foregroundStyle(.orange) }
      ForEach(Array(preview.notices.enumerated()),id:\.offset) { _,message in Text(message).font(.caption) }
      Button("应用预览中的时间调整") {
       guard AccessPolicy.canWrite else { showSubscription=true; return }
       guard sourceTasks == store.tasks else { error=String(localized: "事项已变更，请重新生成计划。"); self.preview=nil; return }
       store.replaceSchedule(preview.changes); self.preview=nil
      }.disabled(preview.changes.isEmpty || !preview.conflicts.isEmpty).accessibilityIdentifier("planning.apply")
      Button("放弃预览",role:.cancel) { self.preview=nil }
     }
    }
    if let error { Section { Text(error).foregroundStyle(.red) } }
   }.navigationTitle("规划")
   .sheet(isPresented:$showSubscription) { SubscriptionView() }
   .confirmationDialog(String(localized: "发送到 \(pendingAIConsent?.selection.provider.rawValue ?? currentAISelection.provider.rawValue)？"),isPresented:$showAIConsent,titleVisibility:.visible,presenting:pendingAIConsent) { consent in
    Button("同意并发送") { generateAI(consent) }.accessibilityIdentifier("planning.ai.confirm")
    Button("查看服务政策") { pendingAIConsent=nil; openURL(consent.selection.provider.privacyPolicy) }.accessibilityIdentifier("planning.ai.policy")
    Button("取消",role:.cancel) { pendingAIConsent=nil }.accessibilityIdentifier("planning.ai.cancel")
   } message: { _ in
    Text("发送所选事项的标题、地点名称、时间窗口、时长、灵活性标志和本次随机编号。不发送备注、坐标或稳定事项 ID。地点名称可能包含精确地址，API 用量由服务商计费。")
   }
   .onAppear { normalizeAISelection() }
   .onDisappear { invalidatePreview() }
   .onChange(of:startDate) { _,_ in invalidatePreview() }
   .onChange(of:endDate) { _,_ in invalidatePreview() }
   .onChange(of:mode) { _,_ in invalidatePreview() }
   .onChange(of:selected) { _,_ in invalidatePreview() }
   .onChange(of:providerName) { _,_ in selected.removeAll(); invalidatePreview() }
   .onChange(of:model) { _,_ in invalidatePreview() }
   .onChange(of:qwenRegionName) { _,_ in invalidatePreview() }
   .onChange(of:qwenWorkspace) { _,_ in invalidatePreview() }
   .onChange(of:store.tasks) { _,_ in invalidatePreview() }
   .onChange(of:openAIRegion.isAllowed) { _,allowed in
    if !allowed && providerName == AIProvider.openAI.rawValue {
     selected.removeAll(); invalidatePreview(); normalizeAISelection()
    }
   }
  }
 }
 private func normalizeAISelection() {
  let selection=AISelectionPolicy.migrate(openAIAllowed:openAIRegion.isAllowed)
  if selection.provider.rawValue != providerName { selected.removeAll() }
  providerName=selection.provider.rawValue; model=selection.model
 }
 private func invalidatePreview() {
  revision=UUID(); work?.cancel(); work=nil; busy=false; preview=nil; error=nil
  pendingAIConsent=nil; showAIConsent=false
 }
 private var planningTasks: [TaskItem] {
  let end = Calendar.current.date(byAdding:.day,value:1,to:Calendar.current.startOfDay(for:endDate)) ?? endDate
  return store.tasks.filter { !$0.isCompleted && $0.scheduledAt >= Calendar.current.startOfDay(for:startDate) && $0.scheduledAt < end }
 }
 private func generateLocal() {
  guard AccessPolicy.canWrite else { showSubscription=true; return }
  busy=true; error=nil; preview=nil; sourceTasks=store.tasks
  let token=UUID(); revision=token
  let tasks=planningTasks
  let travelMode=mode
  work = Task {
   let result = await PlanningService().preview(tasks:tasks,mode:travelMode)
   guard revision == token, !Task.isCancelled else { return }
   let checked=await PlanningService().validateFinal(preview:result,allTasks:sourceTasks,mode:travelMode)
   guard revision == token, !Task.isCancelled else { return }
   preview=checked; busy=false
  }
 }
 private func prepareAIConsent() {
  guard AccessPolicy.canWrite else { showSubscription=true; return }
  guard providerName != AIProvider.openAI.rawValue || openAIRegion.isAllowed else {
   selected.removeAll(); normalizeAISelection()
   error=String(localized: "OpenAI is unavailable until both location and network checks confirm a region outside mainland China.")
   return
  }
  let rangeTasks=planningTasks
  let tasks=rangeTasks.filter { selected.contains($0.id) }
  guard !tasks.isEmpty else { return }
  guard rangeTasks.count <= 8 else { error=String(localized: "一次最多发送 8 项事项。"); return }
  pendingAIConsent=AIPlanningConsent(selection:currentAISelection,providerName:providerName,model:model,qwenRegionName:qwenRegionName,qwenWorkspace:qwenWorkspace,allTasks:store.tasks,tasks:tasks,selected:selected,startDate:startDate,endDate:endDate,mode:mode,service:AIService())
  showAIConsent=true
 }
 private func generateAI(_ consent: AIPlanningConsent) {
  pendingAIConsent=nil
  guard AccessPolicy.canWrite else { showSubscription=true; return }
  guard consent.allTasks == store.tasks, consent.selected == selected,
        consent.startDate == startDate, consent.endDate == endDate, consent.mode == mode,
        consent.providerName == providerName, consent.model == model,
        consent.qwenRegionName == qwenRegionName, consent.qwenWorkspace == qwenWorkspace,
        consent.selection == currentAISelection,
        consent.selection.provider != .openAI || openAIRegion.isAllowed else {
   error=String(localized: "发送内容已变更，请重新确认。")
   return
  }
  busy=true; error=nil; preview=nil; sourceTasks=consent.allTasks
  let token=UUID(); revision=token
  let travelMode=consent.mode
  let service=consent.service
  let provider=consent.selection.provider
  let selectedModel=consent.selection.model
  let tasks=consent.tasks
  work = Task {
   do {
    let result = try await service.suggest(tasks:tasks,provider:provider,model:selectedModel)
    guard revision == token, !Task.isCancelled else { return }
    let checked=await PlanningService().validateFinal(preview:result,allTasks:sourceTasks,mode:travelMode)
    guard revision == token, !Task.isCancelled else { return }
    preview=checked
   } catch { if revision == token, !Task.isCancelled { self.error=error.localizedDescription } }
   if revision == token { busy=false }
  }
 }
}

private struct AIPlanningConsent {
 let selection: AISelection
 let providerName: String
 let model: String
 let qwenRegionName: String
 let qwenWorkspace: String
 let allTasks: [TaskItem]
 let tasks: [TaskItem]
 let selected: Set<UUID>
 let startDate: Date
 let endDate: Date
 let mode: TravelMode
 let service: AIService
}
