import SwiftUI

struct AISettingsView: View {
 @AppStorage("ai.provider") private var providerName = AIProvider.glm.rawValue
 @AppStorage("ai.qwen.region") private var qwenRegionName = QwenRegion.singapore.rawValue
 @AppStorage("ai.qwen.workspace") private var qwenWorkspace = ""
 @AppStorage("ai.model") private var model = "glm-5.3"
 @ObservedObject private var regionGate=OpenAIRegionGate.shared
 @Environment(\.scenePhase) private var scenePhase
 @State private var regionRefreshRevision=UUID()
 @State private var regionRefreshTask: Task<Void,Never>?
 @FocusState private var isKeyFocused: Bool
 @State private var key = ""
 @State private var keySaved: Bool?
 @State private var showDeleteConfirmation = false
 @State private var deletionProvider = AIProvider.glm
 @State private var deletionRegion = QwenRegion.singapore
 @State private var models: [String] = []
 @State private var message: String?
 @State private var busy = false
 @State private var refreshRevision = UUID()
 @State private var refreshTask: Task<Void, Never>?
 private var provider: AIProvider { AISelectionPolicy.normalized(providerName:providerName,model:model,openAIAllowed:regionGate.isAllowed).provider }
 var body: some View {
  Form {
   Section("选择分析方式") {
    Text("按日期导出记录，再自行粘贴或上传到服务商的模型中分析；无需在本 App 配置 API Key。")
     .fixedSize(horizontal:false,vertical:true)
     .accessibilityIdentifier("ai.analysis.exportHelp")
    NavigationLink { ExportView() } label: {
     Label("导出记录供分析",systemImage:"square.and.arrow.up")
    }.accessibilityIdentifier("ai.analysis.export")
    Text("也可以在下方配置服务商的 API Key，再到“规划”页在 App 内分析。API 用量按服务商规则计费。")
     .fixedSize(horizontal:false,vertical:true)
     .accessibilityIdentifier("ai.analysis.apiHelp")
   }
   Section("可选 AI 增强") {
    Picker("服务", selection: $providerName) { ForEach(AIProvider.eligibleProviders(openAIAllowed:regionGate.isAllowed)) { Text($0.rawValue).tag($0.rawValue) } }
     .accessibilityIdentifier("ai.provider").disabled(busy)
     .onChange(of: providerName) { _,_ in models = []; model = provider.models[0]; key = ""; message = nil; cancelRefresh(); normalizeSelection(); reloadKeyStatus() }
    if provider == .qwen {
     Picker("Qwen 地域",selection:$qwenRegionName) {
      ForEach(QwenRegion.allCases) { Text(LocalizedStringKey($0.title)).tag($0.rawValue) }
     }.accessibilityIdentifier("ai.qwen.region").disabled(busy)
      .onChange(of:qwenRegionName) { _,_ in models=[]; key=""; message=nil; cancelRefresh(); reloadKeyStatus() }
     if QwenRegion(rawValue:qwenRegionName) != .singapore {
      TextField("Workspace ID（模型列表刷新需要）",text:$qwenWorkspace).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("ai.qwen.workspace").disabled(busy)
     }
    }
    Picker("官方模型", selection:$model) { ForEach(Array(Set((models.isEmpty ? provider.models : models) + [model])).sorted(),id:\.self) { Text($0).tag($0) } }
    TextField("自定义模型 ID", text:$model).textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("ai.model.custom")
    Button("刷新可用模型") { refreshModels() }.disabled(busy).accessibilityIdentifier("ai.models.refresh")
   }
   Section("设备密钥") {
    VStack(alignment:.leading,spacing:6) {
     Text(provider.rawValue).font(.headline)
     if provider == .qwen { Text(LocalizedStringKey((QwenRegion(rawValue:qwenRegionName) ?? .singapore).title)) }
     Text(LocalizedStringKey(keySaved == true ? "此设备已保存 API Key" : keySaved == false ? "此设备尚未保存 API Key" : "无法确认密钥保存状态"))
      .accessibilityIdentifier("ai.key.saved")
    }.fixedSize(horizontal:false,vertical:true)
    SecureField("输入新的 API Key", text:$key)
     .focused($isKeyFocused)
     .submitLabel(.done)
     .onSubmit { isKeyFocused=false }
     .textInputAutocapitalization(.never).autocorrectionDisabled().accessibilityIdentifier("ai.key")
    Button("保存到钥匙串") { isKeyFocused=false; do { try AIKeychain.save(key.trimmingCharacters(in:.whitespacesAndNewlines),provider:provider); key=""; keySaved=true; message=String(localized: "已保存到此设备钥匙串。") } catch { message=error.localizedDescription } }.disabled(key.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty).accessibilityIdentifier("ai.key.save")
    Button("删除此服务密钥",role:.destructive) {
     deletionProvider=provider; deletionRegion=QwenRegion(rawValue:qwenRegionName) ?? .singapore; showDeleteConfirmation=true
    }.disabled(keySaved != true).accessibilityIdentifier("ai.key.delete")
   }
   if let message { Section { Text(message).fixedSize(horizontal:false,vertical:true).accessibilityIdentifier("ai.status") } }
  }.scrollDismissesKeyboard(.interactively)
   .toolbar {
    ToolbarItemGroup(placement:.keyboard) {
     if isKeyFocused {
      Spacer()
      Button("完成") { isKeyFocused=false }.accessibilityIdentifier("ai.key.done")
     }
    }
   }
   .navigationTitle("AI 设置")
   .onAppear { normalizeSelection(); reloadKeyStatus() }
   .task { startRegionRefresh() }
   .onChange(of:scenePhase) { _,phase in
    if phase == .active { startRegionRefresh() }
    else { cancelRegionRefresh() }
   }
   .confirmationDialog("删除保存的 API Key？",isPresented:$showDeleteConfirmation,titleVisibility:.visible) {
    Button("删除密钥",role:.destructive) {
     do {
      try AIKeychain.delete(deletionProvider,qwenRegion:deletionRegion)
      key=""; message=String(localized: "此服务密钥已删除。"); reloadKeyStatus()
     } catch { message=error.localizedDescription; reloadKeyStatus() }
    }.accessibilityIdentifier("ai.key.delete.confirm")
    Button("取消",role:.cancel) { }
   } message: {
    Text("将从此设备删除 \(deletionDescription) 的 API Key。服务商账号和已有记录不会删除。")
   }
   .onDisappear { isKeyFocused=false; cancelRefresh();cancelRegionRefresh() }
   .onChange(of:qwenWorkspace) { _,_ in models=[]; cancelRefresh() }
   .onChange(of:regionGate.isAllowed) { _,allowed in if !allowed { models=[];cancelRefresh();normalizeSelection();reloadKeyStatus() } }
 }
 private func startRegionRefresh() {
  guard regionRefreshTask == nil else { return }
  let token=UUID();regionRefreshRevision=token
  regionRefreshTask=Task {
   await regionGate.refreshIfLocationAuthorized()
   if regionRefreshRevision == token { regionRefreshTask=nil }
  }
 }
 private func cancelRegionRefresh() {
  regionRefreshRevision=UUID();regionRefreshTask?.cancel();regionRefreshTask=nil
  regionGate.cancelSilentRefresh()
 }
 private func cancelRefresh() {
  refreshRevision=UUID(); refreshTask?.cancel(); refreshTask=nil; busy=false
 }
 private func refreshModels() {
  let snapshot=AIModelRefreshSnapshot(provider:provider,region:QwenRegion(rawValue:qwenRegionName) ?? .singapore,workspace:qwenWorkspace)
  let service=AIService(); let token=UUID(); refreshRevision=token; busy=true
  refreshTask=Task {
   defer { if refreshRevision == token { busy=false } }
   do {
    let fetched=try await service.models(provider:snapshot.provider)
    try Task.checkCancellation()
    guard refreshRevision == token, snapshot.matches(provider:provider,region:QwenRegion(rawValue:qwenRegionName) ?? .singapore,workspace:qwenWorkspace) else { return }
    models=fetched
    message=snapshot.provider == .glm ? String(localized:"智谱官方模型目录已刷新；账号开通状态在生成时核验。") : String(localized:"账号可用模型列表已刷新。")
   } catch { if refreshRevision == token, !Task.isCancelled { message=error.localizedDescription } }
  }
 }
 private func normalizeSelection() {
  let selection=AISelectionPolicy.migrate(openAIAllowed:regionGate.isAllowed)
  providerName=selection.provider.rawValue; model=selection.model
 }
 private var deletionDescription: String {
  if deletionProvider == .qwen {
   let region: String
   switch deletionRegion {
   case .singapore: region=String(localized: "国际 · 新加坡")
   case .beijing: region=String(localized: "中国 · 北京")
   case .virginia: region=String(localized: "美国 · 弗吉尼亚")
   }
   return deletionProvider.rawValue + " · " + region
  }
  return deletionProvider.rawValue
 }
 private func reloadKeyStatus() {
  do { keySaved=try AIKeychain.contains(provider,qwenRegion:QwenRegion(rawValue:qwenRegionName) ?? .singapore) }
  catch { keySaved=nil; message=error.localizedDescription }
 }
}
