import Foundation
import Security

enum QwenRegion: String, CaseIterable, Identifiable {
 case singapore, beijing, virginia
 var id: String { rawValue }
 var title: String {
  switch self { case .singapore: return "国际 · 新加坡"; case .beijing: return "中国 · 北京"; case .virginia: return "美国 · 弗吉尼亚" }
 }
 static var selected: QwenRegion { QwenRegion(rawValue:UserDefaults.standard.string(forKey:"ai.qwen.region") ?? "") ?? .singapore }
 var host: String {
  switch self { case .singapore: return "dashscope-intl.aliyuncs.com"; case .beijing: return "dashscope.aliyuncs.com"; case .virginia: return "dashscope-us.aliyuncs.com" }
 }
 var baseURL: String { "https://" + host + "/compatible-mode/v1" }
 var models: [String] {
  let common=["qwen3.8-max", "qwen3.7-plus", "qwen-plus"]
  return self == .virginia ? common + ["qwen-plus-us"] : common
 }
 func modelsBaseURL(workspace: String) throws -> String {
  if self == .singapore { return "https://dashscope-intl.aliyuncs.com/api/v1" }
  guard !workspace.isEmpty, workspace.range(of:"^[A-Za-z0-9-]+$",options:.regularExpression) != nil else {
   throw AIError.message(String(localized: "此地域的官方模型列表接口需要 Workspace ID；请填写后刷新，或查看官方候选并自定义模型。"))
  }
  let region=self == .beijing ? "cn-beijing" : "us-east-1"
  return "https://\(workspace).\(region).maas.aliyuncs.com/api/v1"
 }
}

enum AIProvider: String, CaseIterable, Identifiable {
 case glm = "GLM", qwen = "Qwen", deepSeek = "DeepSeek", openAI = "OpenAI", gemini = "Gemini"
 static let availableProviders: [AIProvider] = [.glm,.qwen,.deepSeek,.openAI]
 static func eligibleProviders(openAIAllowed:Bool)->[AIProvider] { availableProviders.filter { $0 != .openAI || openAIAllowed } }
 var isAvailable: Bool { Self.availableProviders.contains(self) }
 func requireAvailable() throws {
  guard isAvailable else { throw AIError.message(String(localized: "Gemini 在此版本中不可用，请选择其他服务。")) }
 }
 var id: String { rawValue }
 var baseURL: String {
  switch self {
  case .glm: return "https://open.bigmodel.cn/api/paas/v4"
  case .qwen: return QwenRegion.selected.baseURL
  case .deepSeek: return "https://api.deepseek.com"
  case .openAI: return "https://api.openai.com/v1"
  case .gemini: return "https://generativelanguage.googleapis.com/v1beta"
  }
 }
 var models: [String] {
  switch self {
  case .glm: return ["glm-5.3", "glm-5.1", "glm-5"]
  case .qwen: return QwenRegion.selected.models
  case .deepSeek: return ["deepseek-flash", "deepseek-v4-pro"]
  case .openAI: return ["gpt-6.1-sol", "gpt-6-astra", "gpt-6-luna"]
  case .gemini: return ["gemini-3.8-flash", "gemini-3.6-flash", "gemini-3.1-pro-preview"]
  }
 }
 var privacyPolicy: URL {
  switch self {
  case .glm: return URL(string:"https://docs.bigmodel.cn/cn/terms/privacy-policy")!
  case .qwen: return URL(string:"https://www.alibabacloud.com/help/en/model-studio/data-retention-policy")!
  case .deepSeek: return URL(string:"https://cdn.deepseek.com/policies/en-US/deepseek-privacy-policy.html")!
  case .openAI: return URL(string:"https://developers.openai.com/api/docs/guides/your-data")!
  case .gemini: return URL(string:"https://ai.google.dev/gemini-api/terms")!
  }
 }
 var documentation: URL {
  let links: [AIProvider:String] = [.glm:"https://docs.bigmodel.cn/cn/guide/models/text/glm-5.3", .qwen:"https://www.alibabacloud.com/help/en/model-studio/models", .deepSeek:"https://api-docs.deepseek.com/api/list-models/", .openAI:"https://developers.openai.com/api/docs/models", .gemini:"https://ai.google.dev/gemini-api/docs/models"]
  return URL(string: links[self]!)!
 }
}
struct AIModelRefreshSnapshot: Equatable {
 let provider: AIProvider
 let region: QwenRegion
 let workspace: String
 func matches(provider:AIProvider,region:QwenRegion,workspace:String) -> Bool {
  self.provider == provider && (provider != .qwen || (self.region == region && self.workspace == workspace))
 }
}
struct AISelection: Equatable {
 let provider: AIProvider
 let model: String
}
enum AISelectionPolicy {
 static func normalized(providerName: String, model: String, openAIAllowed:Bool = false) -> AISelection {
  guard let provider=AIProvider(rawValue:providerName), provider.isAvailable,provider != .openAI || openAIAllowed else {
   return AISelection(provider:.glm,model:AIProvider.glm.models[0])
  }
  let value=model.trimmingCharacters(in:.whitespacesAndNewlines)
  return AISelection(provider:provider,model:value.isEmpty ? provider.models[0] : value)
 }
 /// Only non-secret preferences are migrated. Existing Keychain items are untouched.
 @discardableResult static func migrate(defaults: UserDefaults = .standard,openAIAllowed:Bool = false) -> AISelection {
  let selection=normalized(providerName:defaults.string(forKey:"ai.provider") ?? AIProvider.openAI.rawValue,model:defaults.string(forKey:"ai.model") ?? "gpt-6.1-sol",openAIAllowed:openAIAllowed)
  if defaults.string(forKey:"ai.provider") != selection.provider.rawValue { defaults.set(selection.provider.rawValue,forKey:"ai.provider") }
  if defaults.string(forKey:"ai.model") != selection.model { defaults.set(selection.model,forKey:"ai.model") }
  return selection
 }
}

struct AIKeychain {
 private static var serviceName: String {
  #if DEBUG
  if ProcessInfo.processInfo.arguments.contains("--uitesting") { return "com.waypoint.maptodo.ai.ui-testing" }
  #endif
  return "com.waypoint.maptodo.ai"
 }

 private static func query(_ provider: AIProvider, qwenRegion: QwenRegion = .selected) -> [String: Any] {
  [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: serviceName, kSecAttrAccount as String: provider == .qwen ? "Qwen.\(qwenRegion.rawValue)" : provider.rawValue]
 }
 static func save(_ key: String, provider: AIProvider, qwenRegion: QwenRegion = .selected) throws {
  var attributes = query(provider,qwenRegion:qwenRegion)
  attributes[kSecValueData as String] = Data(key.utf8)
  attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
  let existing = SecItemUpdate(query(provider,qwenRegion:qwenRegion) as CFDictionary, [kSecValueData as String: Data(key.utf8)] as CFDictionary)
  let status = existing == errSecItemNotFound ? SecItemAdd(attributes as CFDictionary, nil) : existing
  guard status == errSecSuccess else { throw userError(status) }
 }
 static func read(_ provider: AIProvider, qwenRegion: QwenRegion = .selected) throws -> String {
  var attributes = query(provider,qwenRegion:qwenRegion)
  attributes[kSecReturnData as String] = true
  attributes[kSecMatchLimit as String] = kSecMatchLimitOne
  var result: CFTypeRef?
  let status=SecItemCopyMatching(attributes as CFDictionary, &result)
  if status == errSecItemNotFound { throw AIError.message(String(localized: "请先在 AI 设置中保存此服务的 API Key。")) }
  guard status == errSecSuccess else { throw userError(status) }
  guard let data = result as? Data, let key = String(data:data,encoding:.utf8), !key.isEmpty else {
   throw AIError.message(String(localized: "已保存的密钥无法读取，请重新保存。"))
  }
  return key
 }
 static func contains(_ provider: AIProvider, qwenRegion: QwenRegion = .selected) throws -> Bool {
  var attributes=query(provider,qwenRegion:qwenRegion)
  attributes[kSecReturnAttributes as String]=true
  attributes[kSecMatchLimit as String]=kSecMatchLimitOne
  var metadata: CFTypeRef?
  let status=SecItemCopyMatching(attributes as CFDictionary,&metadata)
  if status == errSecItemNotFound { return false }
  guard status == errSecSuccess else { throw userError(status) }
  return true
 }
 static func delete(_ provider: AIProvider, qwenRegion: QwenRegion = .selected) throws {
  let status=SecItemDelete(query(provider,qwenRegion:qwenRegion) as CFDictionary)
  guard status == errSecSuccess || status == errSecItemNotFound else { throw userError(status) }
 }
 static func userError(_ status: OSStatus) -> AIError {
  switch status {
  case errSecInteractionNotAllowed, errSecAuthFailed:
   return .message(String(localized: "钥匙串暂时无法访问，请解锁设备后重试。"))
  case errSecNotAvailable:
   return .message(String(localized: "系统钥匙串暂时不可用，请稍后重试。"))
  case errSecMissingEntitlement:
   return .message(String(localized: "应用的钥匙串权限配置有误，请联系开发者。"))
  case errSecDecode:
   return .message(String(localized: "已保存的密钥无法读取，请重新保存。"))
  default:
   return .message(String(localized: "密钥操作未完成，请重试；若持续失败，请联系开发者。"))
  }
 }
}
enum AIError: LocalizedError {
 case message(String)
 var errorDescription: String? { if case .message(let value) = self { return value }; return nil }
}
