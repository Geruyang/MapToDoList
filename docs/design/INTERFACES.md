# Shared contract v1 — main coordinator owns Core/App/project
Swift 5 language mode, iOS 17+, module/target `MapToDo`. Native SwiftUI, Foundation, Combine. Shared workspace; edit only your assigned feature/test files. No new agents, no commits by subagents. Build after main generates project. All models below are defined by main in Core; do NOT redeclare.

```swift
struct TaskItem: Identifiable, Codable, Equatable, Sendable {
 var id: UUID
 var title: String
 var notes: String
 var locationName: String
 var latitude: Double
 var longitude: Double
 var scheduledAt: Date
 var durationMinutes: Int
 var isFlexible: Bool
 var flexibilityEnd: Date
 var reminderMinutes: Int // 0 at time, negative disables
 var reminderMode: ReminderMode
 var isCompleted: Bool
 var createdAt: Date
 var timeZoneIdentifier: String
 var coordinate: CLLocationCoordinate2D { get }
 var endDate: Date { get }
 init(id: UUID = UUID(), title: String = "", notes: String = "", locationName: String = "", latitude: Double = 31.2304, longitude: Double = 121.4737, scheduledAt: Date = Date(), durationMinutes: Int = 30, isFlexible: Bool = false, flexibilityEnd: Date? = nil, reminderMinutes: Int = 15, reminderMode: ReminderMode = .standard, isCompleted: Bool = false, createdAt: Date = Date(), timeZoneIdentifier: String = TimeZone.current.identifier)
}
enum ReminderMode: String, Codable, CaseIterable, Identifiable, Sendable { case standard, silent, timeSensitive; var title: String { get } }
enum TravelMode: String, Codable, CaseIterable, Identifiable, Sendable { case walking, driving, transit; var title: String { get } }
@MainActor final class TaskStore: ObservableObject {
 @Published private(set) var tasks: [TaskItem]
 @Published var errorMessage: String?
 func upsert(_ item: TaskItem)
 func remove(_ id: UUID)
 func toggleCompletion(_ id: UUID)
 func replaceSchedule(_ changes: [UUID: Date])
}
```
Views use `@EnvironmentObject var store: TaskStore`. Share only TaskItem values between services. No global automatic sample data: `--uitesting --seed-demo` launch flags provide isolated fixtures, real launch empty. No external AI transmission until user explicitly taps generate after disclosure. No user keys in source, UserDefaults, log or reports.

## Feature public entry points (feature owner implements)
- Map: `MapScreen()`; `TaskEditorView(task: TaskItem?)` presented as sheet, owns dismiss/save; optional `init(task: TaskItem?, coordinate: CLLocationCoordinate2D?, locationName: String?)` allowed if defaults keep first initializer callable. `TaskEditorView(task: TaskItem(title:..., latitude:..., longitude:...))` sufficient for pin creation.
- Reminders: `@MainActor final class ReminderService: ObservableObject`, `static let shared`, `func synchronize(tasks: [TaskItem]) async`, `func requestAuthorization() async -> Bool`; `ReminderSettingsView()`; permission only on explicit user action, do not prompt at app launch. Foreground notification delegate in service. Global notification preference reconciles tasks.
- Export: `ExportView()` consuming store, independent pure formatter API chosen by owner and unit tested.
- Planning: `PlanningView()` consuming store; local plan with fixed-time/ flexible windows, explicit Apply preview, conflict reporting. No silent mutation. Use MapKit ETA and Weather provider contract below. `AISettingsView()` in AI feature. All 5 providers list official current models, live refresh, custom model text, Keychain.
- Weather: `WeatherCardView(latitude: Double, longitude: Double, date: Date)` and `actor WeatherProvider { static let shared; func forecast(latitude: Double, longitude: Double, date: Date) async throws -> WeatherSnapshot }`. `struct WeatherSnapshot: Sendable` fields: `temperatureCelsius: Double`, `condition: String`, `symbolName: String`, `precipitationChance: Double`, `date: Date`, `isForecast: Bool`, `attribution: String`, `bufferMinutes: Int`. Owner defines WeatherSnapshot in Weather feature. Forecast beyond available horizon MUST throw explicit unavailable, never closest current. Native WeatherKit primary, entitlement config main owns. No silently using noncommercial API for paid release.
- UI implementation: `RootView()` with tabs MapScreen / TodayView / PlanningView / SettingsView. Own Home/Settings/Design. TodayView lists store tasks, opens TaskEditorView sheet, completion and export. Settings links ReminderSettingsView, AISettingsView, SubscriptionView. Use real policies in app via local text, no fabricated web URLs. `Theme` tokens optional coordinated with UI designer.
- Subscription: `@MainActor final class SubscriptionStore: ObservableObject`, `static let shared`, `@Published private(set) var hasAccess: Bool`, `func refresh() async`, `SubscriptionView()`. Product `com.waypoint.map todo` NOT valid: actual identifier **`com.waypoint.maptodo.annual`**. Yearly USD 9.90, introductory one week for eligible accounts. No fake local trial. No DEBUG bypass in production. Main integrates gating after readiness. Read/export existing data always available; creation/edit/plan gated on active verified subscription/trial, demo-only UI launch flag can bypass under DEBUG for tests, explicitly labeled demo.

## UI accessibility IDs
`tab.map`, `tab.today`, `tab.planning`, `tab.settings`; `task.add`, `task.title`, `task.location`, `task.notes`, `task.save`, `task.cancel`, `task.delete`; `map.search`; `export.open`, `export.copy`; `planning.generate`; `settings.ai`, `settings.subscription`.

## Testing
Feature owners write `MapToDoTests/<Feature>Tests.swift` if meaningful pure logic; no replacing fixture data with claimed network truth. Simulator agent owns UITests. Main owns CoreTests and project.yml. Only one agent per named test file. Build failures report complete compiler diagnostics; main coordinates fixes. Exact check commands and NOT_RUN limitations documented.
