import SwiftUI
import MapKit

struct MapScreen: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var manuallyExpandedCard: Bool?
    @EnvironmentObject private var store: TaskStore
    @StateObject private var location = MapLocationService()
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(center: TaskItem().coordinate, span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)))
    @State private var fittedInitialTasks = false
    @State private var geocoder = CLGeocoder()
    @State private var lookupID: UUID?
    @State private var nearbySearch: MKLocalSearch?
    @State private var nativeFeature: MapFeature?
    @State private var featureRequest: MKMapItemRequest?
    @State private var deferredTap: Task<Void, Never>?
    @State private var tapArbitration = MapTapArbitration()
    @State private var suppressNativeUntil = Date.distantPast
    @State private var suppressTapUntil = Date.distantPast
    @State private var resolvingLocation = false
    @FocusState private var searchFocused: Bool
    @FocusState private var selectionNameFocused: Bool
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var searching = false
    @State private var searchError: String?
    @State private var pendingSelection: MapPendingSelection?
    @State private var editorDestination: TaskEditorDestination?
    @State private var showingSubscription = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geometry in
            let compact = dynamicTypeSize.isAccessibilitySize || geometry.size.height < 600
            mapContent
                .safeAreaInset(edge: .top) { searchPanel(maxResultHeight: max(80, min(180, geometry.size.height * 0.23)), compact: compact) }
                .safeAreaInset(edge: .bottom) {
                    if let selection = pendingSelection { selectionPanel(selection, maxDetailHeight: max(70, min(120, geometry.size.height * 0.18))) }
                    else { addPanel(compact: compact, maxRowsHeight: max(80, min(180, geometry.size.height * 0.22))) }
                }
        }
            .sheet(item: $editorDestination) { destination in
                TaskEditorView(task: destination.task, timeZoneNotice: destination.timeZoneNotice).id(destination.id)
            }
            .sheet(isPresented: $showingSubscription) { SubscriptionView() }
            .onAppear {
                guard !fittedInitialTasks else { return }
                fittedInitialTasks = true
                if !store.tasks.isEmpty { fitSavedTasks() }
            }
            .onChange(of: location.result?.id) { _, _ in
                guard let coordinate = location.result?.coordinate else { return }
                center(on: coordinate, span: 0.015)
            }
            .alert("定位提示", isPresented: Binding(get: { location.message != nil }, set: { if !$0 { location.message = nil } })) {
                Button("知道了") { location.message = nil }
            } message: { Text(LocalizedStringKey(location.message ?? "")) }
            .onDisappear { searchTask?.cancel(); cancelLookup(); location.cancelRequest() }
    }
    private var mapContent: some View {
        MapReader { proxy in
            Map(position: $position, selection: $nativeFeature) {
                UserAnnotation()
                if let selection = pendingSelection {
                    Annotation(selection.isExistingTask ? String(localized: "Selected task") : String(localized: "Selected place"), coordinate: selection.task.coordinate, anchor: .center) {
                        Image(systemName: "mappin.and.ellipse").font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.ink).frame(width: 32, height: 32)
                            .background(Theme.surface, in: Circle())
                            .overlay(Circle().stroke(Theme.accent, lineWidth: 2)).shadow(radius: 2)
                            .frame(width: 44, height: 44).contentShape(Rectangle())
                            .accessibilityLabel(Text(selection.isExistingTask ? String(localized: "Selected task") : String(localized: "Selected place")))
                            .accessibilityValue(selection.task.locationName)
                            .accessibilityIdentifier("map.selection.pin")
                    }
                }
                ForEach(store.tasks.filter { !(pendingSelection?.isExistingTask == true && pendingSelection?.task.id == $0.id) }) { task in
                    Annotation(task.title, coordinate: task.coordinate, anchor: .center) {
                        MapTaskPin(task: task) { previewExisting(task) }
                    }
                }
            }
            .accessibilityIdentifier("map.surface")
            .mapFeatureSelectionContent { _ in EmptyMapContent() }
            .onChange(of: nativeFeature) { _, feature in
                #if DEBUG
                recordMapDiagnostic("native.onChange", title: feature?.title, coordinate: feature?.coordinate, extra: ["kind": feature.map { $0.kind == .pointOfInterest ? "pointOfInterest" : ($0.kind == .territory ? "territory" : ($0.kind == .physicalFeature ? "physicalFeature" : "unknown")) } ?? "nil"])
                #endif
                guard let feature else { return }
                guard MapSelectionPolicy.acceptsNativeFeature(latitude: feature.coordinate.latitude, longitude: feature.coordinate.longitude, suppressed: Date() < suppressNativeUntil) else { nativeFeature = nil; return }
                // Accept every public feature kind; MapKit identifies the label/icon touched.
                deferredTap?.cancel()
                deferredTap = nil
                tapArbitration.cancel()
                suppressTapUntil = Date().addingTimeInterval(0.25)
                selectNativeFeature(feature)
                nativeFeature = nil
            }
            .simultaneousGesture(SpatialTapGesture().onEnded { value in
                let point = value.location
                #if DEBUG
                recordMapDiagnostic("generic.tap", coordinate: proxy.convert(point, from: .local))
                #endif
                guard Date() >= suppressTapUntil,
                      let coordinate = proxy.convert(point, from: .local) else { return }
                let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                // Snapshot the touch-time scale, conservatively using both map axes.
                // Async POI results must not project through a camera the user has since moved.
                let offsets = [CGPoint(x: point.x + MapSelectionPolicy.screenTolerance, y: point.y),
                               CGPoint(x: point.x, y: point.y + MapSelectionPolicy.screenTolerance)]
                let meters = offsets.compactMap { proxy.convert($0, from: .local) }.map {
                    origin.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))
                }.filter { $0.isFinite && $0 > 0 }.min() ?? 150
                let radius = MapSelectionPolicy.queryRadius(metersPerTolerance: meters)
                deferredTap?.cancel()
                // Do not add a card/pin or resize MapKit while its native hit resolves.
                let tapID = tapArbitration.schedule(now: ProcessInfo.processInfo.systemUptime)
                #if DEBUG
                recordMapDiagnostic("generic.scheduled", requestID: tapID, coordinate: coordinate, extra: ["radius": radius, "touchScaleMeters": meters, "fallbackDelayMilliseconds": MapTapArbitration.delayMilliseconds])
                #endif
                deferredTap = Task { @MainActor in
                    do { try await Task.sleep(for: .milliseconds(MapTapArbitration.delayMilliseconds)) } catch { return }
                    guard !Task.isCancelled, Date() >= suppressTapUntil,
                          tapArbitration.consume(tapID, now: ProcessInfo.processInfo.systemUptime) else {
                        #if DEBUG
                        recordMapDiagnostic("generic.guardRejected", requestID: tapID, coordinate: coordinate)
                        #endif
                        return
                    }
                    #if DEBUG
                    recordMapDiagnostic("generic.fired", requestID: tapID, coordinate: coordinate)
                    #endif
                    deferredTap = nil
                    selectNearbyLandmark(coordinate, radius: radius, touchScaleMeters: meters)
                }
            })
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.6, maximumDistance: 10)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                    .onChanged { value in
                        if case .second(true, _) = value { suppressMapTap(for: 0.7) }
                    }
                    .onEnded { value in
                        suppressMapTap(for: 0.7)
                        nativeFeature = nil
                        guard case .second(true, let drag?) = value,
                              hypot(drag.translation.width, drag.translation.height) <= 10,
                              let coordinate = proxy.convert(drag.startLocation, from: .local) else { return }
                        selectMapCoordinate(coordinate)
                    }
            )
            // Observe movement simultaneously; MapKit keeps ownership of pan and pinch.
            .simultaneousGesture(DragGesture(minimumDistance: 10).onChanged { _ in
                suppressMapTap(for: 0.4)
            }.onEnded { _ in suppressMapTap(for: 0.4) })
            .simultaneousGesture(MagnifyGesture().onChanged { _ in
                suppressMapTap(for: 0.4)
            }.onEnded { _ in suppressMapTap(for: 0.4) })
            .mapStyle(.standard(elevation: .flat))
        }
    }
    private func suppressMapTap(for seconds: Double) {
        suppressTapUntil = Date().addingTimeInterval(seconds)
        suppressNativeUntil = suppressTapUntil
        deferredTap?.cancel()
        deferredTap = nil
        tapArbitration.cancel()
    }
    private var todaysTasks: [TaskItem] {
        store.tasks.filter { Calendar.current.isDateInToday($0.scheduledAt) }
    }
    private func addPanel(compact: Bool, maxRowsHeight: CGFloat) -> some View {
        let expanded = manuallyExpandedCard ?? !compact
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                if compact {
                    Button { manuallyExpandedCard = !expanded } label: {
                        Label(expanded ? String(localized: "Hide today's tasks") : String(localized: "Show today's tasks"), systemImage: expanded ? "chevron.down" : "chevron.up")
                            .font(.subheadline).frame(minHeight: 44)
                    }.accessibilityIdentifier("map.card.toggle")
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("今天的行迹").font(.headline).foregroundStyle(Theme.ink)
                        Text(progressText).font(.caption).foregroundStyle(Theme.secondary)
                    }
                }
                Spacer()
                Button { openEditor(nil) } label: {
                    Image(systemName: "plus").font(.title2).frame(width: 48, height: 48)
                        .background(Theme.actionFill, in: Circle()).foregroundStyle(Theme.actionLabel)
                }.accessibilityLabel("新建事项").accessibilityIdentifier("task.add")
            }
            if !compact {
                Button { manuallyExpandedCard = !expanded } label: {
                    Label(expanded ? String(localized: "Hide today's tasks") : String(localized: "Show today's tasks"), systemImage: expanded ? "chevron.down" : "chevron.up")
                        .font(.subheadline).frame(minHeight: 44)
                }.accessibilityIdentifier("map.card.toggle")
            }
            if expanded {
                ViewThatFits(in: .vertical) {
                    summaryRows(compact: compact).fixedSize(horizontal: false, vertical: true)
                    ScrollView { summaryRows(compact: compact) }.frame(height: maxRowsHeight)
                }.frame(maxHeight: maxRowsHeight)
            }
        }.padding(20).background(Theme.surface, in: RoundedRectangle(cornerRadius: 24)).padding(.horizontal).padding(.bottom, 8)
    }
    private func summaryRows(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if todaysTasks.isEmpty {
                Text("点击地图选点，记下今天想做的事").font(.subheadline).foregroundStyle(Theme.secondary)
            } else {
                ForEach(todaysTasks.prefix(compact ? 1 : 2)) { task in
                    MapSummaryRow(task: task, complete: { complete(task) }, edit: { previewExisting(task) })
                }
            }
        }
    }
    private var progressText: String {
        let done = todaysTasks.filter(\.isCompleted).count
        return String.localizedStringWithFormat(NSLocalizedString("今天 %lld 项，已完成 %lld 项", comment: "Daily task progress"), todaysTasks.count, done)
    }
    private func complete(_ task: TaskItem) {
        guard AccessPolicy.canWrite else { showingSubscription = true; return }
        store.toggleCompletion(task.id)
    }
    private var locateButton: some View {
        Button { location.locate() } label: {
            Image(systemName: "location.fill").font(.system(size: 18, weight: .semibold))
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }.accessibilityElement(children: .ignore)
            .accessibilityLabel("定位到我的位置").accessibilityIdentifier("location.fill")
    }
    private func fitSavedTasks() {
        let points = store.tasks.map { MKMapPoint($0.coordinate) }
        guard let first = points.first else { return }
        let rect = points.dropFirst().reduce(MKMapRect(x: first.x, y: first.y, width: 1, height: 1)) {
            $0.union(MKMapRect(x: $1.x, y: $1.y, width: 1, height: 1))
        }
        position = .rect(rect.insetBy(dx: -max(rect.width * 0.3, 1200), dy: -max(rect.height * 0.3, 1200)))
    }
    private func center(on coordinate: CLLocationCoordinate2D, span: Double) {
        let destination = MapCameraPosition.region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)))
        if reduceMotion { position = destination }
        else { withAnimation(.easeInOut(duration: 0.3)) { position = destination } }
    }
    private func searchPanel(maxResultHeight: CGFloat, compact: Bool) -> some View {
        VStack(spacing: 0) {
            if !compact {
                HStack {
                    Text("行迹").font(.title3.bold()).foregroundStyle(Theme.ink)
                    Spacer()
                    Text(Date(), format: .dateTime.month().day().weekday()).font(.caption).foregroundStyle(Theme.secondary)
                }.padding(.horizontal, 16).padding(.top, 12)
            }
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.ink)
                TextField("搜索地点", text: $query).focused($searchFocused).submitLabel(.search).onSubmit(search).accessibilityIdentifier("map.search")
                if searching { ProgressView() }
                if !query.isEmpty { Button { query = ""; results = []; searchTask?.cancel(); searching = false } label: { Image(systemName: "xmark.circle.fill").frame(width: 44, height: 44).contentShape(Rectangle()) }.accessibilityLabel("清除搜索").accessibilityIdentifier("map.search.clear") }
                locateButton
            }.padding(16)
            if resolvingLocation { ProgressView("正在获取地点信息…").padding(.bottom, 12) }
            if let searchError { Text(LocalizedStringKey(searchError)).font(.caption).foregroundStyle(.secondary).padding(.bottom, 12) }
            if !results.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
            ForEach(Array(results.prefix(5).enumerated()), id: \.offset) { _, item in
                Button {
                    searchFocused = false
                    selectionNameFocused = false
                    results = []; query = ""
                    let coordinate = item.placemark.coordinate
                    center(on: coordinate, span: 0.01)
                    let task = TaskItem(locationName: item.name ?? String(localized: "所选地点"), latitude: coordinate.latitude, longitude: coordinate.longitude, timeZoneIdentifier: item.placemark.timeZone?.identifier ?? TimeZone.current.identifier)
                    cancelLookup()
                    pendingSelection = MapPendingSelection(task: task, address: item.placemark.title, isExistingTask: false, timeZoneNotice: item.placemark.timeZone == nil ? "未能确定地点时区，当前使用设备时区；请在时间设置中确认或更换。" : nil)
                } label: {
                    HStack { Image(systemName: "mappin.circle"); VStack(alignment: .leading) { Text(item.name ?? String(localized: "地点")).foregroundStyle(.primary); Text(item.placemark.title ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1) }; Spacer() }.padding(12)
                }.accessibilityIdentifier("search.result")
            }
                    }
                }.frame(maxHeight: maxResultHeight)
            }
        }.background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20)).padding(.horizontal).padding(.top, 8)
    }
    private func previewExisting(_ task: TaskItem) {
        selectionNameFocused = false
        suppressMapTap(for: 0.7)
        searchFocused = false
        cancelLookup()
        pendingSelection = MapPendingSelection(task: task, address: nil, isExistingTask: true, timeZoneNotice: nil)
        center(on: task.coordinate, span: 0.01)
    }
    private func confirmSelection() {
        guard nearbySearch == nil, featureRequest == nil, let selection = pendingSelection,
              !selection.task.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        selectionNameFocused = false
        if !selection.isExistingTask && !AccessPolicy.canWrite { showingSubscription = true; return }
        openEditor(selection.task, notice: selection.timeZoneNotice)
    }
    private func selectionPanel(_ selection: MapPendingSelection, maxDetailHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // A container identifier propagates to its buttons in SwiftUI's AX bridge.
            // Identify only the heading so each action and coordinate keeps its own ID.
            HStack {
                Text(selection.isExistingTask ? String(localized: "Selected task") : String(localized: "Selected place"))
                    .font(dynamicTypeSize.isAccessibilitySize ? .caption.weight(.semibold) : .headline)
                    .foregroundStyle(Theme.ink)
                    .accessibilityIdentifier("map.selection.card")
                Spacer()
                if selectionNameFocused {
                    Button("完成") { selectionNameFocused = false }
                        .frame(minWidth: 44, minHeight: 44).accessibilityIdentifier("map.selection.nameDone")
                }
            }
            // A single details tree keeps its accessibility identity stable.
            ScrollView { selectionDetails(selection) }
                .frame(maxHeight: maxDetailHeight)
                .accessibilityElement(children: .contain)
            // At AX sizes the shorter visual summary preserves space for the map;
            // VoiceOver and coordinate acceptance retain the full five-decimal value.
            Text(String(format: dynamicTypeSize.isAccessibilitySize ? "%.3f, %.3f" : "%.5f, %.5f", selection.task.latitude, selection.task.longitude))
                .font(dynamicTypeSize.isAccessibilitySize ? .caption2.monospacedDigit() : .caption.monospacedDigit())
                .foregroundStyle(Theme.ink)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(format: "%.5f, %.5f", selection.task.latitude, selection.task.longitude))
                .accessibilityIdentifier("map.selection.coordinates")
            let actionLayout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(spacing: 12))
            actionLayout {
                Button("取消") { selectionNameFocused = false; cancelLookup(); pendingSelection = nil }
                    .frame(minHeight: 44).accessibilityIdentifier("map.selection.cancel")
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                Button(selection.isExistingTask ? String(localized: "Open task") : String(localized: "Confirm place"), action: confirmSelection)
                    .fontWeight(.semibold).frame(minHeight: 44).disabled(nearbySearch != nil || featureRequest != nil || selection.task.locationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("map.selection.confirm")
            }
        }.padding(16).background(Theme.surface, in: RoundedRectangle(cornerRadius: 24)).padding(.horizontal).padding(.bottom, 8)
    }
    private func selectionDetails(_ selection: MapPendingSelection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if selection.isExistingTask {
                Text(selection.task.title).font(.subheadline.weight(.semibold)).accessibilityIdentifier("map.selection.name")
            } else if !AccessPolicy.canWrite {
                Text(selection.task.locationName).font(.subheadline.weight(.semibold)).accessibilityIdentifier("map.selection.name")
            }
            if !selection.isExistingTask && AccessPolicy.canWrite {
                TextField("地点名称", text: Binding(get: {
                    guard pendingSelection?.id == selection.id else { return "" }
                    return pendingSelection?.task.locationName ?? ""
                }, set: { name in
                    guard pendingSelection?.id == selection.id else { return }
                    pendingSelection?.task.locationName = name
                    pendingSelection?.userEditedName = true
                }), axis: .vertical).lineLimit(1...3).accessibilityLabel("地点名称").textFieldStyle(.roundedBorder).frame(minHeight: 44)
                    .focused($selectionNameFocused).submitLabel(.done)
                    .onSubmit { selectionNameFocused = false }
                    .accessibilityIdentifier("map.selection.locationName")
            }
            if let address = selection.address, !address.isEmpty { Text(address).font(.caption) }
            else if selection.isExistingTask { Text(selection.task.locationName).font(.caption) }
        }.foregroundStyle(Theme.ink).frame(maxWidth: .infinity, alignment: .leading)
    }
    private func cancelLookup() {
        #if DEBUG
        recordMapDiagnostic("selection.cancel", requestID: lookupID)
        #endif
        lookupID = nil
        deferredTap?.cancel()
        deferredTap = nil
        tapArbitration.cancel()
        featureRequest?.cancel()
        featureRequest = nil
        nativeFeature = nil
        resolvingLocation = false
        geocoder.cancelGeocode()
        nearbySearch?.cancel()
        nearbySearch = nil
    }
    private func openEditor(_ task: TaskItem?, notice: String? = nil) {
        cancelLookup()
        pendingSelection = nil
        editorDestination = TaskEditorDestination(task: task, timeZoneNotice: notice)
    }
    private func beginCoordinateSelection(_ coordinate: CLLocationCoordinate2D) -> UUID {
        selectionNameFocused = false
        searchFocused = false
        cancelLookup()
        let fallback = TaskItem(locationName: String(localized: "地图选点"), latitude: coordinate.latitude, longitude: coordinate.longitude)
        let selection = MapPendingSelection(task: fallback, address: nil, isExistingTask: false, timeZoneNotice: "未能确定地点时区，当前使用设备时区；请在时间设置中确认或更换。")
        pendingSelection = selection
        lookupID = selection.id
        #if DEBUG
        recordMapDiagnostic("selection.begin", requestID: selection.id, coordinate: coordinate)
        #endif
        resolvingLocation = true
        // Selecting on the map must preserve the user's camera and zoom.
        return selection.id
    }
    private func selectMapCoordinate(_ coordinate: CLLocationCoordinate2D) {
        #if DEBUG
        recordMapDiagnostic("exact.begin", coordinate: coordinate)
        #endif
        let requestID = beginCoordinateSelection(coordinate)
        resolveSelectionMetadata(requestID)
    }
    private func selectNativeFeature(_ feature: MapFeature) {
        let requestID = beginCoordinateSelection(feature.coordinate)
        #if DEBUG
        recordMapDiagnostic("native.requestStart", requestID: requestID, title: feature.title, coordinate: feature.coordinate)
        #endif
        pendingSelection?.task.locationName = MapSelectionPolicy.placeName(itemName: nil, placemarkName: nil, address: nil, featureName: feature.title, fallback: String(localized: "所选地点"))
        let request = MKMapItemRequest(feature: feature)
        featureRequest = request
        request.getMapItem { item, _ in
            Task { @MainActor in
                #if DEBUG
                recordMapDiagnostic("nativeRequest.response", requestID: requestID, title: item?.name, coordinate: item?.placemark.coordinate)
                #endif
                guard lookupID == requestID, pendingSelection?.id == requestID,
                      featureRequest === request else {
                    #if DEBUG
                    recordMapDiagnostic("nativeRequest.guardRejected", requestID: requestID)
                    #endif
                    return
                }
                featureRequest = nil
                if let item { applyPlace(item, requestID: requestID) }
                else { resolveSelectionMetadata(requestID, preservePlaceName: true) }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            guard lookupID == requestID, pendingSelection?.id == requestID,
                  featureRequest === request else { return }
            #if DEBUG
            recordMapDiagnostic("nativeRequest.timeout", requestID: requestID)
            #endif
            featureRequest = nil
            request.cancel()
            // Keep the tapped feature's own title and coordinate when lookup is unavailable.
            resolveSelectionMetadata(requestID, preservePlaceName: true)
        }
    }
    private func applyPlace(_ item: MKMapItem, requestID: UUID) {
        guard lookupID == requestID, pendingSelection?.id == requestID else {
            #if DEBUG
            recordMapDiagnostic("place.guardRejected", requestID: requestID)
            #endif
            return
        }
        #if DEBUG
        recordMapDiagnostic("place.apply", requestID: requestID, title: item.name, coordinate: item.placemark.coordinate, extra: ["placemarkName": item.placemark.name ?? "", "address": item.placemark.title ?? "", "manualNamePreserved": pendingSelection?.userEditedName == true])
        #endif
        guard let current = pendingSelection?.task else { return }
        let resolved = MapSelectionPolicy.resolvedCoordinate(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude, fallbackLatitude: current.latitude, fallbackLongitude: current.longitude)
        pendingSelection?.task.latitude = resolved.latitude
        pendingSelection?.task.longitude = resolved.longitude
        let automaticName = MapSelectionPolicy.placeName(itemName: item.name, placemarkName: item.placemark.name, address: item.placemark.title, featureName: current.locationName, fallback: String(localized: "所选地点"))
        pendingSelection?.task.locationName = MapSelectionPolicy.resolvedName(suggested: automaticName, current: current.locationName, wasEdited: pendingSelection?.userEditedName == true)
        pendingSelection?.address = item.placemark.title
        if let zone = item.placemark.timeZone {
            pendingSelection?.task.timeZoneIdentifier = zone.identifier
            pendingSelection?.timeZoneNotice = nil
            cancelLookup()
        } else { resolveSelectionMetadata(requestID, preservePlaceName: true) }
    }
    private func selectNearbyLandmark(_ coordinate: CLLocationCoordinate2D, radius: Double,
                                      touchScaleMeters: Double) {
        let requestID = beginCoordinateSelection(coordinate)
        #if DEBUG
        recordMapDiagnostic("nearby.requestStart", requestID: requestID, coordinate: coordinate, extra: ["radius": radius])
        #endif
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: radius)
        // No category restriction; service coverage still cannot enumerate every map label.
        request.pointOfInterestFilter = nil
        let search = MKLocalSearch(request: request)
        nearbySearch = search
        search.start { response, _ in
            Task { @MainActor in
                guard lookupID == requestID, pendingSelection?.id == requestID,
                      nearbySearch === search else {
                    #if DEBUG
                    recordMapDiagnostic("nearby.guardRejected", requestID: requestID)
                    #endif
                    return
                }
                #if DEBUG
                recordMapDiagnostic("nearby.response", requestID: requestID, extra: ["count": response?.mapItems.count ?? 0])
                #endif
                nearbySearch = nil
                let items = response?.mapItems ?? []
                let origin = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let candidates = items.map { item in
                    let distance = origin.distance(from: CLLocation(latitude: item.placemark.coordinate.latitude, longitude: item.placemark.coordinate.longitude))
                    return MapLandmarkCandidate(distanceMeters: distance,
                                                distancePoints: MapSelectionPolicy.screenDistance(meters: distance, touchScaleMeters: touchScaleMeters))
                }
                if let index = MapSelectionPolicy.nearestIndex(candidates, radius: radius, exact: false) {
                    #if DEBUG
                    recordMapDiagnostic("nearby.chosen", requestID: requestID, title: items[index].name, coordinate: items[index].placemark.coordinate, extra: ["distanceMeters": candidates[index].distanceMeters, "distancePoints": candidates[index].distancePoints])
                    #endif
                    applyPlace(items[index], requestID: requestID)
                } else { resolveSelectionMetadata(requestID) }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            guard lookupID == requestID, pendingSelection?.id == requestID,
                  nearbySearch === search else { return }
            nearbySearch = nil
            search.cancel()
            resolveSelectionMetadata(requestID)
        }
    }
    private func resolveSelectionMetadata(_ requestID: UUID, preservePlaceName: Bool = false) {
        guard lookupID == requestID, let selection = pendingSelection, selection.id == requestID else { return }
        let fallback = selection.task
        // Reverse geocoding supplies metadata only; it never replaces these coordinates.
        geocoder.reverseGeocodeLocation(CLLocation(latitude: fallback.latitude, longitude: fallback.longitude)) { placemarks, _ in
            Task { @MainActor in
                #if DEBUG
                recordMapDiagnostic("geocoder.response", requestID: requestID, title: placemarks?.first?.name, coordinate: placemarks?.first?.location?.coordinate, extra: ["preservePlaceName": preservePlaceName, "manualNamePreserved": pendingSelection?.userEditedName == true])
                #endif
                guard lookupID == requestID, pendingSelection?.id == requestID else {
                    #if DEBUG
                    recordMapDiagnostic("geocoder.guardRejected", requestID: requestID)
                    #endif
                    return
                }
                var task = fallback
                if let place = placemarks?.first {
                    if !preservePlaceName { task.locationName = place.name ?? place.locality ?? fallback.locationName }
                    if let zone = place.timeZone { task.timeZoneIdentifier = zone.identifier }
                }
                task.locationName = MapSelectionPolicy.resolvedName(suggested: task.locationName, current: pendingSelection?.task.locationName ?? task.locationName, wasEdited: pendingSelection?.userEditedName == true)
                pendingSelection?.task = task
                if !preservePlaceName { pendingSelection?.address = placemarks?.first?.name }
                pendingSelection?.timeZoneNotice = placemarks?.first?.timeZone == nil ? "未能确定地点时区，当前使用设备时区；请在时间设置中确认或更换。" : nil
                cancelLookup()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
            guard lookupID == requestID, pendingSelection?.id == requestID else { return }
            pendingSelection?.timeZoneNotice = "地点查询超时，当前使用设备时区；请在时间设置中确认或更换。"
            cancelLookup()
        }
    }
    #if DEBUG
    /// R44_TEST_ONLY_MAP_SELECTION_TRACE: explicit public-landmark UI probes only.
    /// No normal-user logging, manual field values, saved task titles, or account data.
    private func recordMapDiagnostic(_ phase: String, requestID: UUID? = nil,
                                     title: String? = nil, coordinate: CLLocationCoordinate2D? = nil,
                                     extra: [String: Any] = [:]) {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--uitesting"), arguments.contains("--map-selection-diagnostics") else { return }
        var record: [String: Any] = ["phase": phase, "time": Date().timeIntervalSince1970,
            "requestUUID": requestID?.uuidString ?? "nil", "currentLookupUUID": lookupID?.uuidString ?? "nil",
            "selectionUUID": pendingSelection?.id.uuidString ?? "nil",
            "activeNativeUUID": featureRequest != nil ? (lookupID?.uuidString ?? "nil") : "nil",
            "suppressTapUntil": suppressTapUntil.timeIntervalSince1970,
            "suppressNativeUntil": suppressNativeUntil.timeIntervalSince1970]
        // title is exclusively a MapKit public feature/search/geocoder response, never draft text.
        if let title { record["publicMapTitle"] = title }
        if let coordinate { record["latitude"] = coordinate.latitude; record["longitude"] = coordinate.longitude }
        record.merge(extra) { _, new in new }
        guard let encoded = try? JSONSerialization.data(withJSONObject: record, options: [.sortedKeys]),
              let line = String(data: encoded, encoding: .utf8),
              let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        print("WAYPOINT_MAP_DIAGNOSTIC " + line)
        let file = directory.appendingPathComponent("waypoint-map-selection-diagnostics.jsonl")
        var contents = (try? Data(contentsOf: file)) ?? Data()
        contents.append(encoded); contents.append(0x0A)
        let limit = 64 * 1024
        if contents.count > limit {
            contents = Data(contents.suffix(limit))
            if let newline = contents.firstIndex(of: 0x0A) { contents = Data(contents.suffix(from: contents.index(after: newline))) }
            else { contents = Data() }
        }
        try? contents.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    #endif
    private func search() {
        searchTask?.cancel()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { results = []; return }
        searching = true; searchError = nil
        searchTask = Task {
            do {
                let request = MKLocalSearch.Request(); request.naturalLanguageQuery = text
                let response = try await MKLocalSearch(request: request).start()
                guard !Task.isCancelled else { return }
                results = response.mapItems; searching = false
                if results.isEmpty { searchError = "没有找到地点，请尝试更具体的名称" }
            } catch {
                guard !Task.isCancelled else { return }
                searching = false; searchError = "搜索暂不可用，请重试或点击地图选点"
            }
        }
    }
}

private struct MapTaskPin: View {
    let task: TaskItem
    let action: () -> Void
    private var label: String {
        let state = task.isCompleted ? String(localized: "已完成") : String(localized: "未完成")
        return String(localized: "查看事项：") + task.title + "，" + task.locationName + "，" + state
    }
    var body: some View {
        Button(action: action) {
            Image(systemName: task.isCompleted ? "checkmark" : "mappin")
                .font(.system(size: 12, weight: .semibold)).foregroundStyle(Theme.actionLabel).frame(width: 28, height: 28)
                .background(Theme.actionFill, in: Circle())
                .overlay(Circle().stroke(Theme.surface, lineWidth: 2)).shadow(radius: 2)
                .frame(width: 44, height: 44).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(label).accessibilityIdentifier("map.task." + task.id.uuidString)
    }
}

private struct MapSummaryRow: View {
    let task: TaskItem
    let complete: () -> Void
    let edit: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Button(action: complete) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2).frame(width: 44, height: 44).foregroundStyle(Theme.ink)
            }.accessibilityLabel((task.isCompleted ? String(localized: "恢复事项：") : String(localized: "完成事项：")) + task.title)
                .accessibilityIdentifier("map.complete." + task.id.uuidString)
            Button(action: edit) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.ink)
                    Text(task.locationName).font(.caption).foregroundStyle(Theme.secondary)
                    Text(LocalTimeFormatter.string(task.scheduledAt, timeZoneIdentifier: task.timeZoneIdentifier))
                        .font(.caption).foregroundStyle(Theme.secondary)
                }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }.buttonStyle(.plain)
        }
    }
}

private struct MapPendingSelection: Identifiable {
    let id = UUID()
    var task: TaskItem
    var address: String?
    let isExistingTask: Bool
    var timeZoneNotice: String?
    var userEditedName = false
}

struct MapLandmarkCandidate {
    let distanceMeters: Double
    let distancePoints: Double
}

enum MapSelectionPolicy {
    static let screenTolerance: Double = 48
    // User acceptance includes all marked place types, not only pointOfInterest.
    static func acceptsNativeFeature(latitude: Double, longitude: Double, suppressed: Bool) -> Bool {
        !suppressed && validCoordinate(latitude: latitude, longitude: longitude)
    }
    static func validCoordinate(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }
    static func resolvedCoordinate(latitude: Double, longitude: Double, fallbackLatitude: Double, fallbackLongitude: Double) -> (latitude: Double, longitude: Double) {
        validCoordinate(latitude: latitude, longitude: longitude) ? (latitude, longitude) : (fallbackLatitude, fallbackLongitude)
    }
    static func placeName(itemName: String?, placemarkName: String?, address: String?, featureName: String?, fallback: String) -> String {
        [itemName, placemarkName, address, featureName].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty } ?? fallback
    }
    static func resolvedName(suggested: String, current: String, wasEdited: Bool) -> String {
        wasEdited ? current : (suggested.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? current : suggested)
    }
    static func queryRadius(metersPerTolerance: Double) -> Double {
        min(300, max(60, metersPerTolerance.isFinite ? metersPerTolerance : 300))
    }
    static func screenDistance(meters: Double, touchScaleMeters: Double) -> Double {
        guard touchScaleMeters.isFinite, touchScaleMeters > 0 else { return .infinity }
        return meters * screenTolerance / touchScaleMeters
    }
    /// Stable first-result tie break; exact mode deliberately never snaps to a POI.
    static func nearestIndex(_ candidates: [MapLandmarkCandidate], radius: Double, exact: Bool) -> Int? {
        guard !exact else { return nil }
        let limit = min(200, max(0, radius))
        return candidates.indices.filter {
            candidates[$0].distanceMeters.isFinite && candidates[$0].distancePoints.isFinite &&
            candidates[$0].distanceMeters >= 0 && candidates[$0].distanceMeters <= limit &&
            candidates[$0].distancePoints >= 0 && candidates[$0].distancePoints <= screenTolerance
        }.min {
            let left = candidates[$0].distanceMeters, right = candidates[$1].distanceMeters
            return left == right ? $0 < $1 : left < right
        }
    }
}

/// Cancellable native-first arbitration. Scheduling never changes selection or camera.
struct MapTapArbitration {
    static let delayMilliseconds = 500
    private var pending: (id: UUID, eligibleAt: TimeInterval)?
    mutating func schedule(now: TimeInterval) -> UUID {
        let id = UUID()
        pending = (id, now + Double(Self.delayMilliseconds) / 1000)
        return id
    }
    mutating func cancel() { pending = nil }
    mutating func consume(_ id: UUID, now: TimeInterval) -> Bool {
        guard let current = pending, current.id == id, now >= current.eligibleAt else { return false }
        pending = nil
        return true
    }
}
