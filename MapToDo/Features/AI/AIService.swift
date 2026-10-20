import Foundation

struct AIService {
 let qwenRegion: QwenRegion = .selected
 let qwenWorkspace: String = UserDefaults.standard.string(forKey:"ai.qwen.workspace") ?? ""
 private func send(provider: AIProvider, path: String, body: [String:Any]? = nil, baseOverride: String? = nil) async throws -> [String:Any] {
  try provider.requireAvailable()
  if provider == .openAI { try await OpenAIRegionGate.shared.requireFreshPosition() }
  let key = try AIKeychain.read(provider,qwenRegion:qwenRegion)
  guard let url = URL(string: (baseOverride ?? (provider == .qwen ? qwenRegion.baseURL : provider.baseURL)) + path) else { throw AIError.message(String(localized: "无效模型地址。")) }
  var request = URLRequest(url: url); request.timeoutInterval = 60
  request.setValue("application/json", forHTTPHeaderField: "Content-Type")
  request.setValue(key, forHTTPHeaderField: provider == .gemini ? "x-goog-api-key" : "X-API-Key")
  if provider != .gemini { request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization"); request.setValue(nil, forHTTPHeaderField: "X-API-Key") }
  if let body { request.httpMethod = "POST"; request.httpBody = try JSONSerialization.data(withJSONObject: body) }
  try Task.checkCancellation()
  let networkResult: (Data, URLResponse)
  do {
   if provider == .openAI { networkResult=try await OpenAIRegionGate.shared.send(request) }
   else { networkResult=try await URLSession.shared.data(for:request) }
  }
  catch { if Task.isCancelled { throw CancellationError() }; throw AIError.message(String(localized: "服务请求失败，请检查密钥、模型、余额与网络。")) }
  let (data,response) = networkResult
  guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw AIError.message(String(localized: "服务请求失败，请检查密钥、模型、余额与网络。")) }
  guard let object = try JSONSerialization.jsonObject(with: data) as? [String:Any] else { throw AIError.message(String(localized: "服务响应无法解析。")) }
  return object
 }
 func models(provider: AIProvider) async throws -> [String] {
  try provider.requireAvailable()
  if provider == .openAI { try await OpenAIRegionGate.shared.requireFreshPosition() }
  if provider == .glm { return try await officialGLMModels() }
  if provider == .qwen {
   let base=try qwenRegion.modelsBaseURL(workspace:qwenWorkspace)
   let object=try await send(provider:provider,path:"/models?page_no=1&page_size=100",baseOverride:base)
   let output=object["output"] as? [String:Any]
   let models=(output?["models"] as? [[String:Any]] ?? []).compactMap { $0["model"] as? String }.filter { $0.hasPrefix("qwen") }
   guard !models.isEmpty else { throw AIError.message(String(localized: "此地域未返回 Qwen 模型；请核对地域密钥、Workspace ID 或使用自定义模型。")) }
   return models.sorted()
  }
  let object = try await send(provider: provider, path: "/models")
  let models: [String]
  if provider == .gemini {
   models = (object["models"] as? [[String:Any]] ?? []).filter { ($0["supportedGenerationMethods"] as? [String] ?? []).contains("generateContent") }.compactMap { ($0["name"] as? String)?.replacingOccurrences(of: "models/", with: "") }
  } else { models = (object["data"] as? [[String:Any]] ?? []).compactMap { $0["id"] as? String } }
  guard !models.isEmpty else { throw AIError.message(String(localized: "此服务未返回模型列表；请使用官方列表或自定义模型。")) }
  return models.sorted()
 }
 private func officialGLMModels() async throws -> [String] {
  // BigModel does not document an account inventory endpoint. Read its public
  // official documentation index and verify IDs in published request examples.
  var request=URLRequest(url:URL(string:"https://docs.bigmodel.cn/llms.txt")!); request.timeoutInterval=15
  let (indexData,response)=try await URLSession.shared.data(for:request)
  guard let http=response as? HTTPURLResponse, (200..<300).contains(http.statusCode), let index=String(data:indexData,encoding:.utf8) else { throw AIError.message(String(localized: "官方模型目录暂时无法获取。")) }
  let pattern="https://docs\\.bigmodel\\.cn/cn/guide/models/text/glm-[0-9]+(?:\\.[0-9]+)?(?:\\.md)?"
  let regex=try NSRegularExpression(pattern:pattern)
  let links=Set(regex.matches(in:index,range:NSRange(index.startIndex...,in:index)).compactMap { Range($0.range,in:index).map { String(index[$0]) } })
  var models=Set<String>()
  for link in links.sorted().reversed().prefix(8) {
   try Task.checkCancellation()
   let url=URL(string:link.hasSuffix(".md") ? link : link+".md")!
   var pageRequest=URLRequest(url:url); pageRequest.timeoutInterval=10
   let (data,_) = try await URLSession.shared.data(for:pageRequest)
   guard let page=String(data:data,encoding:.utf8) else { continue }
   let idRegex=try NSRegularExpression(pattern:"(?:model[ \t]*=[ \t]*|\"model\"[ \t]*:[ \t]*)[\"'](glm-[a-zA-Z0-9.-]+)[\"']")
   for match in idRegex.matches(in:page,range:NSRange(page.startIndex...,in:page)) {
    if let range=Range(match.range(at:1),in:page) { models.insert(String(page[range])) }
   }
  }
  guard !models.isEmpty else { throw AIError.message(String(localized: "官方目录格式已变化，请查看官方文档并自定义模型。")) }
  return models.sorted()
 }
 func suggest(tasks: [TaskItem], provider: AIProvider, model: String) async throws -> PlanPreview {
  try provider.requireAvailable()
  if provider == .openAI { try await OpenAIRegionGate.shared.requireFreshPosition() }
  let transfer=Self.transmissionTasks(tasks)
  let payload = transfer.tasks.map { ["id":$0.id.uuidString, "title":$0.title, "location":$0.locationName, "start":Self.timestamp($0.scheduledAt), "endWindow":Self.timestamp($0.flexibilityEnd), "durationMinutes":String($0.durationMinutes), "flexible":String($0.isFlexible)] }
  let encoded = String(data: try JSONSerialization.data(withJSONObject: payload), encoding: .utf8)!
  let prompt = "为以下事项建议时间。固定事项绝不可移动，灵活事项必须完全落在 start 到 endWindow 窗口。不要编造路况天气。仅输出JSON对象，格式 {\"changes\":[{\"id\":\"UUID\",\"start\":\"ISO8601\"}]}。事项：" + encoded
  let response: [String:Any]
  if provider == .gemini {
   let safe = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
   guard !safe.contains("/") else { throw AIError.message(String(localized: "模型名称无效。")) }
   response = try await send(provider: provider, path: "/models/\(safe):generateContent", body: ["contents":[["parts":[["text":prompt]]]], "generationConfig":["responseMimeType":"application/json"]])
  } else if provider == .openAI {
   response = try await send(provider: provider, path: "/responses", body:Self.openAIRequestBody(prompt:prompt,model:model))
  } else {
   response = try await send(provider: provider, path: "/chat/completions", body:["model":model,"messages":[["role":"user","content":prompt]]])
  }
  var preview=try Self.parse(Self.responseText(response,provider:provider), tasks: transfer.tasks)
  preview.changes=Dictionary(uniqueKeysWithValues:preview.changes.compactMap { remoteID,date in
   transfer.localIDs[remoteID].map { ($0,date) }
  })
  return preview
 }
 static func timestamp(_ date:Date) -> String {
  let value=date.timeIntervalSince1970
  var seconds=floor(value)
  var nanos=Int64(((value-seconds)*1_000_000_000).rounded())
  if nanos == 1_000_000_000 { seconds += 1; nanos=0 }
  let formatter=ISO8601DateFormatter()
  let whole=formatter.string(from:Date(timeIntervalSince1970:seconds))
  return String(whole.dropLast()) + "." + String(format:"%09lld",nanos) + "Z"
 }
 static func openAIRequestBody(prompt: String, model: String) -> [String:Any] {
  ["model":model,"input":prompt,"reasoning":["effort":"low"],"store":false]
 }
 static func transmissionTasks(_ tasks: [TaskItem]) -> (tasks: [TaskItem], localIDs: [UUID:UUID]) {
  var localIDs: [UUID:UUID] = [:]
  let copies=tasks.map { task -> TaskItem in
   var copy=task
   copy.id=UUID()
   localIDs[copy.id]=task.id
   return copy
  }
  return (copies,localIDs)
 }
 static func responseText(_ response: [String:Any], provider: AIProvider) throws -> String {
  var text = ""
  if provider == .gemini {
   guard let candidate=(response["candidates"] as? [[String:Any]])?.first,
         candidate["finishReason"] as? String == nil || candidate["finishReason"] as? String == "STOP",
         let content=candidate["content"] as? [String:Any], let parts=content["parts"] as? [[String:Any]] else {
    throw AIError.message(String(localized: "服务响应无法解析。"))
   }
   text=parts.filter { ($0["thought"] as? Bool) != true }.compactMap { $0["text"] as? String }.joined()
  } else if provider == .openAI {
   guard response["status"] as? String == nil || response["status"] as? String == "completed" else {
    throw AIError.message(String(localized: "服务响应无法解析。"))
   }
   text=(response["output"] as? [[String:Any]] ?? []).filter { $0["type"] as? String == "message" }.flatMap { $0["content"] as? [[String:Any]] ?? [] }.filter { $0["type"] as? String == "output_text" }.compactMap { $0["text"] as? String }.joined()
  } else {
   let choice=(response["choices"] as? [[String:Any]])?.first
   guard choice?["finish_reason"] as? String == nil || choice?["finish_reason"] as? String == "stop" else {
    throw AIError.message(String(localized: "服务响应无法解析。"))
   }
   text=(choice?["message"] as? [String:Any])?["content"] as? String ?? ""
  }
  guard !text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty else { throw AIError.message(String(localized: "服务响应无法解析。")) }
  return text
 }
 static func validate(preview: PlanPreview, allTasks: [TaskItem]) -> PlanPreview {
  var result = preview
  let proposed = allTasks.filter { !$0.isCompleted }.map { task -> TaskItem in var copy=task; copy.scheduledAt=preview.changes[task.id] ?? task.scheduledAt; return copy }.sorted { $0.scheduledAt < $1.scheduledAt }
  // Check each changed task against every other active task: adjacent pairs
  // miss an appointment nested inside an earlier, longer appointment.
  for a in proposed where preview.changes[a.id] != nil {
   for b in proposed where a.id != b.id && a.scheduledAt < b.endDate && b.scheduledAt < a.endDate {
    let first = a.scheduledAt <= b.scheduledAt ? a : b
    let second = first.id == a.id ? b : a
    let message = String(localized: "「\(first.title)」与「\(second.title)」时间重叠。")
    if !result.conflicts.contains(message) { result.conflicts.append(message) }
   }
  }
  return result
 }
 static func parse(_ text: String, tasks: [TaskItem]) throws -> PlanPreview {
  guard let data = text.data(using:.utf8), let json = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any], let changes = json["changes"] as? [[String:String]] else { throw AIError.message(String(localized: "AI 结果格式无效，原计划未修改。")) }
  var preview = PlanPreview(); let formatter = ISO8601DateFormatter()
  let fractionalFormatter = ISO8601DateFormatter(); fractionalFormatter.formatOptions = [.withInternetDateTime,.withFractionalSeconds]
  for row in changes {
   guard let raw = row["id"], let id = UUID(uuidString:raw), let task = tasks.first(where:{$0.id == id}), task.isFlexible, !task.isCompleted, let rawDate = row["start"], let date = (try? Date.ISO8601FormatStyle(includingFractionalSeconds:true).parse(rawDate)) ?? formatter.date(from:rawDate) ?? fractionalFormatter.date(from:rawDate), date >= task.scheduledAt, date.addingTimeInterval(Double(task.durationMinutes)*60) <= task.flexibilityEnd, preview.changes[id] == nil else { throw AIError.message(String(localized: "AI 建议越过时间窗口、修改固定事项或包含无效数据；未应用。")) }
   preview.changes[id] = date
  }
  let proposed = tasks.map { task -> TaskItem in var copy=task; copy.scheduledAt=preview.changes[task.id] ?? task.scheduledAt; return copy }.sorted { $0.scheduledAt < $1.scheduledAt }
  for (a,b) in zip(proposed,proposed.dropFirst()) where a.endDate > b.scheduledAt { preview.conflicts.append(String(localized: "「\(a.title)」与「\(b.title)」时间重叠。")) }
  preview.notices = [String(localized: "AI 建议未核验路况和天气；请核对实际行程后应用。")]
  return preview
 }
}
