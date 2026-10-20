import Foundation

@MainActor enum AccessPolicy {
    static var isDemo: Bool {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        return args.contains("--uitesting") && args.contains("--demo-access")
        #else
        return false
        #endif
    }
    static var canWrite: Bool { isDemo || SubscriptionStore.shared.hasAccess }
}
