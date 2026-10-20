import SwiftUI
#if DEBUG
import MapKit
#endif

@main struct MapToDoApp: App {
    @StateObject private var store = TaskStore()
    @StateObject private var reminders = ReminderService.shared
    @Environment(\.scenePhase) private var scenePhase
    // Service integration tests own their isolated fictional snapshots. Normal App
    // lifecycle synchronization remains enabled for every Release build and ordinary launch.
    private var notificationIntegrationOwnsSynchronization: Bool {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        return environment["WAYPOINT_RUN_NOTIFICATION_DEVICE_TESTS"] == "1"
            && environment["WAYPOINT_NOTIFICATION_DEVICE_TEST_OWNS_SYNC"] == "1"
        #else
        return false
        #endif
    }
    @ViewBuilder private var rootContent: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitesting") &&
            ProcessInfo.processInfo.arguments.contains("--native-map-attribution-probe") {
            // Diagnostic: the native Map alone, without Waypoint annotations,
            // overlays, cards, branding, or custom controls. Public Shanghai point.
            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012))))
                .mapStyle(.standard(elevation: .flat))
                .accessibilityIdentifier("map.nativeAttributionProbe")
        } else {
            RootView()
        }
        #else
        RootView()
        #endif
    }
    var body: some Scene {
        WindowGroup {
            rootContent
                .environmentObject(store)
                .task { await SubscriptionStore.shared.refresh() }
                .task(id: store.tasks) {
                    if !notificationIntegrationOwnsSynchronization {
                        await reminders.synchronize(tasks: store.tasks)
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task {
                            await SubscriptionStore.shared.refresh()
                            if !notificationIntegrationOwnsSynchronization {
                                await reminders.synchronize(tasks: store.tasks)
                            }
                        }
                    }
                }
                .alert("需要留意", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                    Button("知道了") { store.errorMessage = nil }
                } message: { Text(store.errorMessage ?? "") }
        }
    }
}
