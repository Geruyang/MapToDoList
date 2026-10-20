import SwiftUI
import MapKit

struct TaskEditorDestination: Identifiable {
    let id = UUID()
    let task: TaskItem?
    let timeZoneNotice: String?

    init(task: TaskItem?, timeZoneNotice: String? = nil) {
        self.task = task
        self.timeZoneNotice = timeZoneNotice
    }
}

struct TaskEditorView: View {
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var reminders = ReminderService.shared
    @ObservedObject private var subscription = SubscriptionStore.shared
    @State private var draft: TaskItem
    @State private var error: String?
    @State private var confirmDelete = false
    @State private var confirmDiscard = false
    @State private var selectingLocation = false
    @State private var locationConfirmed: Bool
    @State private var showingSubscription = false
    @State private var selectingTimeZone = false
    @State private var timeZoneNotice: String?
    @State private var travelMode: TravelMode = .walking
    private let originalID: UUID?
    private let initialDraft: TaskItem
    private let initiallyConfirmedLocation: Bool

    init(task: TaskItem?, timeZoneNotice: String? = nil) {
        _timeZoneNotice = State(initialValue: timeZoneNotice)
        let initial = task ?? TaskItem()
        let confirmed = task != nil && !(task?.locationName.isEmpty ?? true)
        initialDraft = initial
        initiallyConfirmedLocation = confirmed
        _draft = State(initialValue: initial)
        originalID = task?.id
        _locationConfirmed = State(initialValue: confirmed)
    }
    private var canEdit: Bool { AccessPolicy.isDemo || subscription.hasAccess }
    private var hasUnsavedChanges: Bool { draft != initialDraft || locationConfirmed != initiallyConfirmedLocation }
    private var exists: Bool { store.tasks.contains { $0.id == originalID } }
    var body: some View {
        NavigationStack {
            Form {
                if !canEdit {
                    Section {
                        Label("Read-only", systemImage: "lock").font(.headline).accessibilityIdentifier("task.readonly")
                        Text("A subscription is required to edit. You can still view, navigate, check weather, and delete saved tasks.").font(.subheadline)
                        if hasUnsavedChanges { Text("Your unsaved draft is kept here. Renew access to continue editing and save it.").font(.footnote) }
                        Button("Unlock editing") { showingSubscription = true }.accessibilityIdentifier("task.unlock")
                    }
                }
                Section("事项") {
                    if canEdit {
                        TextField("想做什么？", text: $draft.title, axis: .vertical)
                            .lineLimit(1...)
                            .accessibilityIdentifier("task.title")
                    } else {
                        Text(draft.title)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("task.title")
                    }
                    TextField("备注", text: $draft.notes, axis: .vertical).lineLimit(3...6).accessibilityIdentifier("task.notes")
                    Toggle("已完成", isOn: $draft.isCompleted).tint(Theme.toggleOn).accessibilityIdentifier("task.completed")
                }.disabled(!canEdit)
                Section("地点") {
                    HStack(alignment: .top, spacing: 8) {
                        if canEdit {
                            TextField("地点名称", text: $draft.locationName, axis: .vertical)
                                .lineLimit(1...3)
                                .accessibilityLabel("地点名称")
                                .accessibilityIdentifier("task.location")
                            Image(systemName: "pencil").font(.subheadline).foregroundStyle(Theme.secondary)
                                .accessibilityHidden(true)
                        } else {
                            Text(draft.locationName).fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("task.location")
                        }
                    }.frame(minHeight: 44).disabled(!canEdit)
                    Button { selectingLocation = true } label: { Label("更换地点", systemImage: "magnifyingglass") }.disabled(!canEdit)
                    if !locationConfirmed {
                        Text("Choose a place, or confirm the default location in San Francisco shown below.").font(.footnote).foregroundStyle(.secondary)
                        Button("Use San Francisco default location") { locationConfirmed = true; draft.locationName = String(localized: "San Francisco (default location)") }.accessibilityIdentifier("task.location.confirm").disabled(!canEdit)
                    }
                    Text(String(format: "%.5f, %.5f", draft.latitude, draft.longitude)).font(.caption).foregroundStyle(.secondary)
                    Picker("出行方式", selection: $travelMode) { ForEach(TravelMode.allCases) { Text($0.title).tag($0) } }
                    Button { navigate() } label: { Label("开始导航", systemImage: "arrow.triangle.turn.up.right.diamond") }.disabled(!locationConfirmed)
                }
                Section("时间") {
                    DatePicker(LocalizedStringKey(draft.isFlexible ? "最早开始" : "开始时间"), selection: $draft.scheduledAt)
                        .environment(\.timeZone, TimeZone(identifier: draft.timeZoneIdentifier) ?? .current).accessibilityIdentifier("task.start")
                    Stepper("时长 \(draft.durationMinutes) 分钟", value: $draft.durationMinutes, in: 5...720, step: 5).accessibilityIdentifier("task.duration")
                    Toggle("可灵活安排", isOn: $draft.isFlexible).tint(Theme.toggleOn).accessibilityIdentifier("task.flexible")
                    if draft.isFlexible { DatePicker("最晚结束", selection: $draft.flexibilityEnd, in: draft.scheduledAt...).environment(\.timeZone, TimeZone(identifier: draft.timeZoneIdentifier) ?? .current) }
                    Button { selectingTimeZone = true } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("时间显示时区")
                            Text(draft.timeZoneIdentifier).font(.caption).foregroundStyle(.secondary)
                        }
                    }.accessibilityIdentifier("task.timezone")
                    if let timeZoneNotice { Text(LocalizedStringKey(timeZoneNotice)).font(.footnote).foregroundStyle(.secondary) }

                }.disabled(!canEdit)
                Section("提醒") {
                    if !reminders.isEnabled {
                        Text("全局事项提醒已关闭，保存事项不会安排通知。").font(.footnote).foregroundStyle(.secondary)
                    } else if reminders.authorizationStatus == .notDetermined || reminders.authorizationStatus == .denied {
                        Text("通知权限尚未开启，保存事项不会安排通知。请在提醒设置中启用。").font(.footnote).foregroundStyle(.secondary)
                    }
                    NavigationLink("提醒设置") { ReminderSettingsView() }.accessibilityIdentifier("task.reminders.settings")

                    Picker("提前提醒", selection: $draft.reminderMinutes) {
                        Text("关闭").tag(-1)
                        Text("准时").tag(0)
                        ForEach([5, 15, 30, 60], id: \.self) { Text("提前 \($0) 分钟").tag($0) }
                    }.disabled(!canEdit)
                    Picker("提醒方式", selection: $draft.reminderMode) { ForEach(ReminderMode.allCases) { Text($0.title).tag($0) } }.disabled(!canEdit)
                }
                Section("地点天气") {
                    if locationConfirmed { WeatherCardView(latitude: draft.latitude, longitude: draft.longitude, date: draft.scheduledAt).environment(\.timeZone, TimeZone(identifier: draft.timeZoneIdentifier) ?? .current) }
                    else { Text("选择地点查看天气").foregroundStyle(.secondary) }
                }
                if let error { Section { Text(LocalizedStringKey(error)).foregroundStyle(.red).accessibilityLabel(Text(LocalizedStringKey(error))) } }
                if exists { Section { Button("删除事项", role: .destructive) { confirmDelete = true }.accessibilityIdentifier("task.delete") } }
            }
            .navigationTitle(LocalizedStringKey(exists ? "事项详情" : "新建事项"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { if hasUnsavedChanges { confirmDiscard = true } else { dismiss() } }.accessibilityIdentifier("task.cancel") }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).fontWeight(.semibold).accessibilityIdentifier("task.save").disabled(!canEdit) }
            }
            .confirmationDialog("Discard changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }.accessibilityIdentifier("task.discard")
                Button("Keep editing", role: .cancel) { }.accessibilityIdentifier("task.keepEditing")
            }
            .confirmationDialog("删除后无法恢复", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("删除事项", role: .destructive) { store.remove(draft.id)
                    if let message = store.errorMessage { error = message } else { dismiss() } }
            }
            .sheet(isPresented: $selectingLocation) {
                LocationPickerView { item in
                    guard canEdit else { return }
                    locationConfirmed = true
                    draft.latitude = item.placemark.coordinate.latitude
                    draft.longitude = item.placemark.coordinate.longitude
                    draft.locationName = item.name ?? String(localized: "所选地点")
                    if let zone = item.placemark.timeZone {
                        draft.timeZoneIdentifier = zone.identifier
                        timeZoneNotice = nil
                    } else {
                        draft.timeZoneIdentifier = TimeZone.current.identifier
                        timeZoneNotice = "未能确定地点时区，当前使用设备时区；请在时间设置中确认或更换。"
                    }
                }
            }
        }
        .sheet(isPresented: $selectingTimeZone) {
            TimeZonePickerView(selection: draft.timeZoneIdentifier) { identifier in
                guard canEdit else { return }
                draft.timeZoneIdentifier = identifier
                timeZoneNotice = nil
            }
        }
        .sheet(isPresented: $showingSubscription) { SubscriptionView() }
        .interactiveDismissDisabled(hasUnsavedChanges)
        .tint(Theme.ink)
        .task { await reminders.refreshAuthorization() }
        .onChange(of: canEdit) { _, allowed in
            if !allowed { selectingLocation = false; selectingTimeZone = false }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await reminders.refreshAuthorization() } }
        }
    }
    private func save() {
        guard AccessPolicy.canWrite else { showingSubscription = true; return }
        guard locationConfirmed else { error = "请先选择地点或明确确认默认位置"; return }
        error = TaskEditValidation.error(title: draft.title, latitude: draft.latitude, longitude: draft.longitude, start: draft.scheduledAt, flexible: draft.isFlexible, latest: draft.flexibilityEnd, duration: draft.durationMinutes)
        guard error == nil else { return }
        draft.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.locationName = draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.locationName.isEmpty { draft.locationName = String(localized: "地图选点") }
        store.upsert(draft)
        if let message = store.errorMessage { error = message; return }
        dismiss()
    }
    private func navigate() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: draft.coordinate))
        item.name = draft.locationName
        let mode: String
        switch travelMode { case .walking: mode = MKLaunchOptionsDirectionsModeWalking; case .driving: mode = MKLaunchOptionsDirectionsModeDriving; case .transit: mode = MKLaunchOptionsDirectionsModeTransit }
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: mode])
    }
}

private struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (MKMapItem) -> Void
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var error: String?
    @State private var searching = false
    @State private var searchTask: Task<Void, Never>?
    var body: some View {
        NavigationStack {
            List {
                if searching { ProgressView("搜索地点…") }
                if let error { Text(LocalizedStringKey(error)).foregroundStyle(.secondary) }
                ForEach(Array(results.enumerated()), id: \.offset) { _, item in
                    Button { onSelect(item); dismiss() } label: {
                        VStack(alignment: .leading) { Text(item.name ?? String(localized: "地点")); Text(item.placemark.title ?? "").font(.caption).foregroundStyle(.secondary) }
                    }.accessibilityIdentifier("search.result")
                }
            }
            .searchable(text: $query, prompt: "搜索新地点")
            .onSubmit(of: .search) { search() }
            .navigationTitle("更换地点")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
            .onDisappear { searchTask?.cancel() }
        }
    }
    private func search() {
        searchTask?.cancel()
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        searching = true; error = nil
        searchTask = Task {
            do {
                let request = MKLocalSearch.Request(); request.naturalLanguageQuery = query
                let response = try await MKLocalSearch(request: request).start()
                guard !Task.isCancelled else { return }
                results = response.mapItems; searching = false
                if results.isEmpty { error = "没有找到地点" }
            } catch {
                guard !Task.isCancelled else { return }
                searching = false; self.error = "搜索暂不可用，请稍后重试"
            }
        }
    }
}

private struct TimeZonePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selection: String
    let onSelect: (String) -> Void
    @State private var query = ""
    private var zones: [String] {
        TimeZone.knownTimeZoneIdentifiers.sorted().filter {
            query.isEmpty || $0.localizedCaseInsensitiveContains(query)
        }
    }
    var body: some View {
        NavigationStack {
            List(zones, id: \.self) { identifier in
                Button {
                    onSelect(identifier)
                    dismiss()
                } label: {
                    HStack {
                        Text(identifier).foregroundStyle(.primary)
                        Spacer()
                        if identifier == selection { Image(systemName: "checkmark") }
                    }
                }
            }
            .searchable(text: $query, prompt: "搜索城市或时区")
            .navigationTitle("选择时区")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
        }
    }
}
