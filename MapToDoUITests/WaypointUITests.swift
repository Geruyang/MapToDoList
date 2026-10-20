import XCTest

/// Runs against an isolated UI-test store on a designated test device.
/// Demo access is explicitly restricted by the App to DEBUG + --uitesting.
final class WaypointUITests: XCTestCase {
    private var app: XCUIApplication!
    private var uiLanguage = "zh-Hans"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        uiLanguage = "zh-Hans"
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        if let app, app.state != .notRunning { app.terminate() }
        app = nil
    }

    func testFirstLaunchShowsNavigationWithoutRequestingNotificationPermission() throws {
        launch(reset: true, demoAccess: false)
        for id in ["tab.map", "tab.today", "tab.planning", "tab.settings"] {
            XCTAssertTrue(element(id).waitForExistence(timeout: 10), "Missing navigation: \(id)")
        }
        XCTAssertEqual(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.count, 0,
                       "First launch must not ask for notification permission.")
        capture("MAP_EMPTY_light")
        tap("tab.today")
        capture("TODAY_EMPTY_light")
    }

    func testNativeMapKitOnlyAttributionDiagnostic() throws {
        // Both DEBUG-only gates are required. No demo entitlement, fixture
        // tasks, user location, or provider API request is needed by this map.
        app.launchArguments = ["--uitesting", "--native-map-attribution-probe",
                               "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        let map = element("map.nativeAttributionProbe")
        XCTAssertTrue(map.waitForExistence(timeout: 15))
        XCTAssertGreaterThan(map.frame.width, 0)
        XCTAssertGreaterThan(map.frame.height, 0)
        for id in ["map.search", "map.selection.card", "map.selection.pin", "map.surface", "task.title"] {
            XCTAssertFalse(element(id).exists, "The MapKit-only probe unexpectedly contains custom UI: \(id)")
        }
        XCTAssertEqual(app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "map.task.")).count, 0)
        XCTAssertEqual(app.tabBars.count, 0, "The diagnostic must contain only the standalone native map.")
        capture("NATIVE_MAPKIT_ONLY_SHANGHAI_INITIAL")
        // MapKit exposes no tile-completion accessibility signal. Give its
        // public Shanghai map a bounded rendering window, then retain the
        // actual pixels for attribution review; this is not a tile/logo pass.
        let renderingWindow = XCTestExpectation(description: "Bounded native MapKit rendering window")
        renderingWindow.isInverted = true
        _ = XCTWaiter.wait(for: [renderingWindow], timeout: 8)
        XCTAssertTrue(map.exists)
        attachMapHierarchy("NATIVE_MAPKIT_ONLY_SHANGHAI_ATTRIBUTION")
    }

    func testCreateEditPersistAndDeleteTask() throws {
        launch(reset: true)
        tap("tab.today")
        tap("task.add")
        // Confirm the visible default before entering multiline notes. A whole
        // screen swipe with the keyboard open can drag inside the keyboard.
        tap("task.location.confirm")
        replaceText("task.title", with: "UI 持久化事项")
        replaceText("task.notes", with: "中文备注，第一行\n第二行；emoji 🧭")
        capture("TASK_EDITOR_light")
        tap("task.save")
        XCTAssertTrue(taskElement("UI 持久化事项").waitForExistence(timeout: 10))

        app.terminate()
        launch(reset: false)
        tap("tab.today")
        let persisted = taskElement("UI 持久化事项")
        XCTAssertTrue(persisted.waitForExistence(timeout: 10), "Saved task did not survive relaunch.")
        capture("TASK_PERSISTED_light")
        persisted.tap()
        XCTAssertTrue(element("task.notes").waitForExistence(timeout: 5))
        XCTAssertTrue((element("task.notes").value as? String)?.contains("第二行") == true)
        replaceText("task.title", with: "UI 已编辑事项")
        tap("task.save")
        XCTAssertTrue(taskElement("UI 已编辑事项").waitForExistence(timeout: 10))
        XCTAssertFalse(taskElement("UI 持久化事项").exists)

        taskElement("UI 已编辑事项").tap()
        tap("task.delete")
        confirmDeletionIfPresented()
        XCTAssertTrue(waitUntilAbsent(taskElement("UI 已编辑事项")))

        app.terminate()
        launch(reset: false)
        tap("tab.today")
        XCTAssertFalse(taskElement("UI 已编辑事项").exists, "Deleted task returned after relaunch.")
    }

    /// Requires a real existing verified subscription. Test data is disposable;
    /// no local StoreKit session, purchase, restore sync, or demo-access bypass.
    func testRealSubscriptionUnlocksCreateEditPersistAndDeleteWithoutDemoAccess() throws {
        launch(reset: true, demoAccess: false)
        tap("tab.settings")
        tap("settings.subscription")
        let active = app.staticTexts["订阅有效"].firstMatch
        XCTAssertTrue(active.waitForExistence(timeout: 40),
                      "Real subscription is not active in this candidate (or has expired). Never replace it with demo access.")
        guard active.exists else { return }
        XCTAssertFalse(app.staticTexts["StoreKit 本地测试权益，不代表真实购买。"].exists,
                       "A local StoreKit fixture must not count as the real subscribed-user precondition.")
        capture("REAL_SUBSCRIPTION_ACTIVE_WITHOUT_DEMO_ACCESS")
        tap("subscription.close")
        tap("tab.today")
        tap("task.add")
        XCTAssertTrue(element("task.title").waitForExistence(timeout: 10),
                      "A real subscriber could not open the new-task editor.")
        XCTAssertFalse(element("task.readonly").exists, "A real subscriber was incorrectly placed in read-only mode.")
        let editableTitle = app.textFields.matching(identifier: "task.title").firstMatch.exists
            ? app.textFields.matching(identifier: "task.title").firstMatch
            : app.textViews.matching(identifier: "task.title").firstMatch
        XCTAssertTrue(editableTitle.exists && editableTitle.isEnabled,
                      "The title must be an enabled text input, not a read-only StaticText.")
        XCTAssertTrue(element("task.save").isEnabled, "Verified active subscription did not enable Save.")
        tap("task.location.confirm")
        let token = UUID().uuidString.prefix(8)
        let createdTitle = "UI disposable subscribed task \(token)"
        let editedTitle = "UI disposable subscribed edited \(token)"
        guard replaceTaskTitleExactly(createdTitle) else { return }
        XCTAssertEqual(element("task.title").value as? String, createdTitle, "Creation input must be exact before Save.")
        tap("task.save")
        let created = taskElement(createdTitle)
        XCTAssertTrue(created.waitForExistence(timeout: 10), "Subscribed task creation did not persist.")
        created.tap()
        XCTAssertTrue(element("task.title").waitForExistence(timeout: 10))
        XCTAssertFalse(element("task.readonly").exists, "Editing an existing subscribed task is still read-only.")
        XCTAssertTrue(element("task.title").isEnabled)
        guard replaceTaskTitleExactly(editedTitle) else { return }
        XCTAssertEqual(element("task.title").value as? String, editedTitle, "Edit input must replace the old title before Save.")
        XCTAssertTrue(element("task.save").isEnabled)
        tap("task.save")
        XCTAssertTrue(taskElement(editedTitle).waitForExistence(timeout: 10))
        XCTAssertFalse(taskElement(createdTitle).exists)

        app.terminate()
        launch(reset: false, demoAccess: false)
        tap("tab.settings")
        tap("settings.subscription")
        XCTAssertTrue(app.staticTexts["订阅有效"].firstMatch.waitForExistence(timeout: 40),
                      "Relaunch did not reconcile the existing real subscription, or it expired during this test.")
        tap("subscription.close")
        tap("tab.today")
        let persisted = taskElement(editedTitle)
        XCTAssertTrue(persisted.waitForExistence(timeout: 10), "Saved subscribed edits did not survive relaunch.")
        persisted.tap()
        XCTAssertTrue(element("task.title").waitForExistence(timeout: 10))
        XCTAssertEqual(element("task.title").value as? String, editedTitle)
        XCTAssertFalse(element("task.readonly").exists, "Relaunched task lost real subscription write access.")
        XCTAssertTrue(element("task.save").isEnabled)
        capture("REAL_SUBSCRIPTION_EDITABLE_AFTER_RELAUNCH")
        tap("task.delete")
        confirmDeletionIfPresented()
        XCTAssertTrue(waitUntilAbsent(taskElement(editedTitle)))
        app.terminate()
        launch(reset: false, demoAccess: false)
        tap("tab.today")
        XCTAssertFalse(taskElement(editedTitle).exists, "Deleted disposable subscribed task returned after relaunch.")
    }

    func testCancelCreationDoesNotPersistTask() throws {
        launch(reset: true)
        tap("tab.today")
        tap("task.add")
        replaceText("task.title", with: "UI 取消事项")
        cancelEditor(discardChanges: true)
        XCTAssertFalse(taskElement("UI 取消事项").exists)
        app.terminate()
        launch(reset: false)
        tap("tab.today")
        XCTAssertFalse(taskElement("UI 取消事项").exists)
    }

    func testBlankTitleCannotBeSaved() throws {
        launch(reset: true)
        tap("tab.today")
        tap("task.add")
        replaceText("task.title", with: "   ")
        let save = element("task.save")
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        if save.isEnabled { save.tap() }
        XCTAssertTrue(element("task.title").exists, "Whitespace title was accepted and editor dismissed.")
        capture("TASK_INVALID_TITLE_light")
    }

    func testMapSearchFieldAcceptsAndRetainsQuery() throws {
        launch(reset: true)
        tap("tab.map")
        replaceText("map.search", with: "上海人民广场")
        XCTAssertEqual(element("map.search").value as? String, "上海人民广场")
        capture("MAP_SEARCH_QUERY_light")
        // A result/service success is deliberately not inferred from accepting text.
    }

    func testMapPointOpensEditorAndPersistsChosenLocation() throws {
        launch(reset: true)
        let surface = element("map.surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10))
        surface.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.55)).tap()
        let previewCoordinates = try assertMapSelectionBeforeEditing()
        capture("MAP_POINT_SELECTED_BEFORE_CONFIRM")
        tap("map.selection.confirm")
        XCTAssertTrue(element("task.title").waitForExistence(timeout: 10))
        let chosenLocation = try XCTUnwrap(element("task.location").value as? String)
        XCTAssertFalse(chosenLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        let chosenCoordinates = try editorCoordinateText()
        XCTAssertEqual(chosenCoordinates, previewCoordinates, "Editor must use the point that the user confirmed.")
        replaceText("task.title", with: "UI 地图选点事项")
        capture("MAP_POINT_EDITOR_light")
        tap("task.save")
        tap("tab.today")
        XCTAssertTrue(taskElement("UI 地图选点事项").waitForExistence(timeout: 10))
        app.terminate()
        launch(reset: false)
        tap("tab.today")
        taskElement("UI 地图选点事项").tap()
        XCTAssertTrue(element("task.location").waitForExistence(timeout: 10))
        XCTAssertEqual(element("task.location").value as? String, chosenLocation)
        XCTAssertEqual(try editorCoordinateText(), chosenCoordinates,
                       "The selected map coordinates did not survive relaunch.")
    }

    func testLiveMapSearchSelectsResult() throws {
        launch(reset: true)
        replaceText("map.search", with: "上海人民广场\n")
        let result = element("search.result")
        if !result.waitForExistence(timeout: 30) {
            if app.staticTexts["搜索暂不可用，请重试或点击地图选点"].exists ||
                app.staticTexts["没有找到地点，请尝试更具体的名称"].exists {
                capture("MAP_SEARCH_SERVICE_UNAVAILABLE_light")
                throw XCTSkip("MapKit search did not provide a live result; service-unavailable UI was observed.")
            }
            XCTFail("Search neither returned a result nor reported an unavailable state.")
            return
        }
        capture("MAP_SEARCH_RESULTS_light")
        result.tap()
        let previewCoordinates = try assertMapSelectionBeforeEditing()
        capture("MAP_SEARCH_SELECTED_BEFORE_CONFIRM")
        tap("map.selection.confirm")
        XCTAssertTrue(element("task.location").waitForExistence(timeout: 10))
        XCTAssertEqual(try editorCoordinateText(), previewCoordinates)
        XCTAssertFalse((element("task.location").value as? String ?? "").isEmpty)
        replaceText("task.title", with: "UI 搜索选点事项")
        tap("task.save")
        tap("tab.today")
        XCTAssertTrue(taskElement("UI 搜索选点事项").waitForExistence(timeout: 10))
    }

    func testMapPreviewRenameAndEditorRenamePersistWithoutChangingCoordinates() throws {
        launch(reset: true)
        visibleMapCoordinate(xFraction: 0.3).tap()
        let coordinates = try assertMapSelectionBeforeEditing()
        let previewName = "UI 自定义地点：河畔咖啡"
        guard replaceLocationExactly("map.selection.locationName", with: previewName) else { return }
        submitPreviewLocationName(expected: previewName)
        XCTAssertEqual(element("map.selection.coordinates").label, coordinates)
        capture("MAP_CUSTOM_NAME_BEFORE_CONFIRM")
        tap("map.selection.confirm")
        XCTAssertTrue(element("task.location").waitForExistence(timeout: 10))
        XCTAssertEqual(element("task.location").value as? String, previewName)
        XCTAssertEqual(try editorCoordinateText(), coordinates)
        let title = "UI 地点名称持久化事项"
        guard replaceTaskTitleExactly(title) else { return }
        tap("task.save")
        app.terminate()
        launch(reset: false)
        tap("tab.today")
        tapTask(title)
        XCTAssertTrue(scrollToElement("task.location", upward: false))
        XCTAssertEqual(element("task.location").value as? String, previewName)
        XCTAssertEqual(try editorCoordinateText(), coordinates)
        let editedName = "UI 第二次修改地点：南门"
        guard replaceLocationExactly("task.location", with: "  \(editedName)  ") else { return }
        tap("task.save")
        app.terminate()
        launch(reset: false)
        tap("tab.today")
        tapTask(title)
        XCTAssertTrue(scrollToElement("task.location", upward: false))
        XCTAssertEqual(element("task.location").value as? String, editedName,
                       "Saving a manually edited location must trim surrounding whitespace and preserve its full name.")
        XCTAssertEqual(try editorCoordinateText(), coordinates,
                       "Renaming a place must never move the saved coordinate.")
        capture("MAP_CUSTOM_NAME_REOPENED_AFTER_SECOND_EDIT")
        cancelEditor()
    }

    func testMapPreviewBlankNameDisablesConfirmationAndCancelCreatesNothing() throws {
        launch(reset: true, language: "en")
        visibleMapCoordinate(xFraction: 0.3).tap()
        let coordinates = try assertMapSelectionBeforeEditing()
        guard replaceLocationExactly("map.selection.locationName", with: "   ") else { return }
        submitPreviewLocationName(expected: "   ")
        XCTAssertFalse(element("map.selection.confirm").isEnabled,
                       "Whitespace-only place names must not be confirmed or silently replaced by lookup metadata.")
        XCTAssertEqual(element("map.selection.coordinates").label, coordinates)
        XCTAssertFalse(element("task.title").exists)
        capture("MAP_BLANK_PLACE_NAME_CONFIRM_DISABLED")
        tap("map.selection.cancel")
        XCTAssertTrue(waitUntilAbsent(element("map.selection.card")))
        app.terminate()
        launch(reset: false, language: "en")
        tap("tab.today")
        XCTAssertTrue(app.staticTexts["Start with one small task"].waitForExistence(timeout: 5))
    }

    func testMapLongPlaceNamesChineseAndEnglishSubmitAndConfirmWithoutCoordinateChanges() throws {
        let samples = [
            ("zh-Hans", "UI 超长地点名称：旧金山渡轮大厦北侧蓝瓶咖啡靠海露台入口，请从市场街方向进入并在临海长椅旁集合"),
            ("en", "UI long place name: Blue Bottle Coffee near the Ferry Building waterfront terrace, enter from Market Street and meet beside the long bench facing the bay")
        ]
        for (language, name) in samples {
            launch(reset: true, language: language)
            visibleMapCoordinate(xFraction: 0.3).tap()
            let coordinates = try assertMapSelectionBeforeEditing()
            guard replaceLocationExactly("map.selection.locationName", with: name) else { return }
            capture("\(language)_MAP_LONG_PLACE_NAME_KEYBOARD")
            submitPreviewLocationName(expected: name)
            XCTAssertEqual(element("map.selection.coordinates").label, coordinates)
            XCTAssertTrue(element("map.selection.confirm").isEnabled)
            XCTAssertTrue(element("map.selection.confirm").isHittable)
            capture("\(language)_MAP_LONG_PLACE_NAME_READY_TO_CONFIRM")
            tap("map.selection.confirm")
            XCTAssertTrue(element("task.location").waitForExistence(timeout: 10))
            XCTAssertEqual(element("task.location").value as? String, name,
                           "The full long place name must reach the editor without truncating stored text.")
            XCTAssertEqual(try editorCoordinateText(), coordinates)
            let title = "UI \(language) long place name"
            guard replaceTaskTitleExactly(title) else { return }
            tap("task.save")
            app.terminate()
            launch(reset: false, language: language)
            tap("tab.today")
            tapTask(title)
            XCTAssertTrue(scrollToElement("task.location", upward: false))
            XCTAssertEqual(element("task.location").value as? String, name)
            XCTAssertEqual(try editorCoordinateText(), coordinates)
            capture("\(language)_MAP_LONG_PLACE_NAME_PERSISTED")
            cancelEditor()
            app.terminate()
        }
    }

    func testLiveNativeShanghaiCommercialPlazaMarkedPlaceSelection() throws {
        try exerciseLiveNativeMarkedPlace(query: "上海 雅居乐国际广场",
                                          expectedName: "雅居乐国际广场", category: "SHANGHAI_COMMERCIAL_PLAZA")
    }

    func testLiveNativeShanghaiPublicParkMarkedPlaceSelection() throws {
        try exerciseLiveNativeMarkedPlace(query: "上海 人民公园",
                                          expectedName: "人民公园", category: "SHANGHAI_PUBLIC_PARK")
    }

    func testLiveNativeShanghaiPublicOfficeLandmarkSelection() throws {
        try exerciseLiveNativeMarkedPlace(query: "上海 中财中心大厦",
                                          expectedName: "中财中心大厦", category: "SHANGHAI_PUBLIC_OFFICE_LANDMARK")
    }

    private func exerciseLiveNativeMarkedPlace(query: String, expectedName: String, category: String) throws {
        // These labels were observed in R42's actual public Shanghai native
        // MapKit AX tree. A translated/business-name match alone is not enough:
        // both search and native selection must also be geographically Shanghai.
        launch(reset: true, language: "zh-Hans", additionalLaunchArguments: ["--map-selection-diagnostics"])
        replaceText("map.search", with: query + "\n")
        let results = app.buttons.matching(identifier: "search.result")
        guard results.firstMatch.waitForExistence(timeout: 30) else {
            attachMapHierarchy("\(category)_LIVE_SEARCH_UNAVAILABLE")
            XCTFail("\(category): no real public Shanghai search result; native selection remains unverified.")
            return
        }
        guard let result = results.allElementsBoundByIndex.first(where: {
            $0.label.localizedCaseInsensitiveContains(expectedName) && $0.isHittable
        }) else {
            attachMapHierarchy("\(category)_EXPECTED_PUBLIC_RESULT_UNAVAILABLE")
            XCTFail("\(category): no matching public Shanghai landmark; no fake registry fixture is substituted.")
            return
        }
        result.tap()
        let searchCoordinates = try assertMapSelectionBeforeEditing()
        try assertPublicShanghaiCoordinates(searchCoordinates)
        XCTAssertTrue((element("map.selection.locationName").value as? String ?? "")
            .localizedCaseInsensitiveContains(expectedName))
        tap("map.selection.cancel")
        XCTAssertTrue(waitUntilAbsent(element("map.selection.card")))
        XCTAssertFalse(element("search.result").exists)
        let surface = element("map.surface")
        func nativePlace() -> XCUIElement? {
            let frame = surface.frame
            return surface.descendants(matching: .any)
                .matching(identifier: "VKPointFeature")
                .matching(NSPredicate(format: "label CONTAINS[c] %@", expectedName))
                .allElementsBoundByIndex.first { candidate in
                    !candidate.identifier.hasPrefix("map.") && candidate.identifier != "search.result" &&
                    candidate.isHittable && candidate.frame.width > 0 && candidate.frame.height > 0 &&
                    candidate.frame != frame && frame.contains(CGPoint(x: candidate.frame.midX, y: candidate.frame.midY))
                }
        }
        let available = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in nativePlace() != nil }, object: surface)
        let waitResult = XCTWaiter.wait(for: [available], timeout: 15)
        attachMapHierarchy("\(category)_BEFORE_NATIVE_FEATURE_TAP")
        guard waitResult == .completed, let native = nativePlace() else {
            XCTFail("\(category): actual public Shanghai VKPointFeature is not hittable; no substitute coordinate tap was performed.")
            return
        }
        let clickedLabel = native.label
        let evidence = XCTAttachment(string: "Public landmark scenario: \(category)\nNative label: \(clickedLabel)\nidentifier: \(native.identifier)\nframe: \(native.frame)\nNo MapKit category metadata is inferred from this label.")
        evidence.name = "WAYPOINT_\(category)_ACTUAL_NATIVE_FEATURE"
        evidence.lifetime = .keepAlways
        add(evidence)
        native.tap()
        // Once an actual feature is tappable, a missing/wrong selection is a
        // functional failure, never converted to a provider-availability skip.
        let coordinates = try assertMapSelectionBeforeEditing()
        try assertPublicShanghaiCoordinates(coordinates)
        let selectedName = try XCTUnwrap(element("map.selection.locationName").value as? String)
        XCTAssertTrue(clickedLabel.localizedCaseInsensitiveContains(expectedName))
        XCTAssertTrue(selectedName.localizedCaseInsensitiveContains(expectedName),
                      "A native marked-place tap must select the clicked public landmark.")
        capture("\(category)_NATIVE_SELECTION_BEFORE_CONFIRM")
        // Native selection must survive both the 500ms generic arbitration
        // delay and the bounded 4s nearby lookup. Do not open the editor early
        // and accidentally conceal a late fallback that swaps the chosen POI.
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let name = self.element("map.selection.locationName")
            let point = self.element("map.selection.coordinates")
            return !name.exists || !point.exists || (name.value as? String) != selectedName || point.label != coordinates
        }, object: app)
        changed.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5.5), .completed,
                       "The clicked native place name and coordinate must not be replaced by a delayed generic tap/lookup.")
        XCTAssertEqual(element("map.selection.locationName").value as? String, selectedName)
        XCTAssertEqual(element("map.selection.coordinates").label, coordinates)
        XCTAssertTrue(element("map.selection.confirm").isEnabled && element("map.selection.confirm").isHittable)
        attachMapHierarchy("\(category)_NATIVE_SELECTION_AFTER_LATE_RESULT_WINDOW")
        tap("map.selection.confirm")
        XCTAssertTrue(element("task.location").waitForExistence(timeout: 10))
        XCTAssertEqual(element("task.location").value as? String, selectedName)
        XCTAssertEqual(try editorCoordinateText(), coordinates)
        cancelEditor()
    }

    private func attachMapHierarchy(_ name: String) {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = "WAYPOINT_\(name)_FULL_HIERARCHY"
        attachment.lifetime = .keepAlways
        add(attachment)
        capture(name)
    }

    private func assertPublicShanghaiCoordinates(_ text: String) throws {
        let parts = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        XCTAssertEqual(parts.count, 2)
        guard parts.count == 2 else { return }
        let latitude = try XCTUnwrap(Double(parts[0]))
        let longitude = try XCTUnwrap(Double(parts[1]))
        XCTAssertTrue((31.0...31.6).contains(latitude) && (120.8...122.0).contains(longitude),
                      "The public Shanghai name resolved outside Shanghai; a same-name result in Hong Kong/SF is not accepted.")
    }

    private func submitPreviewLocationName(expected: String) {
        let field = element("map.selection.locationName")
        XCTAssertTrue(field.exists && field.isEnabled)
        XCTAssertEqual(field.value as? String, expected)
        attachMapHierarchy("PLACE_NAME_BEFORE_SUBMIT")
        // Multiline Return inserts text, and third-party keyboards need not
        // expose standard Keyboard AX. The app's explicit Done action must
        // work with any keyboard without changing the name or keyboard choice.
        let done = element("map.selection.nameDone")
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Focused location name must expose the app's Done action.")
        XCTAssertTrue(done.isEnabled && done.isHittable, "The app's location-name Done action must be reachable.")
        done.tap()
        XCTAssertTrue(waitUntilAbsent(done), "Done must end location-name editing and remove the focus-only action.")
        let unchanged = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (field.value as? String) == expected
        }, object: field)
        XCTAssertEqual(XCTWaiter.wait(for: [unchanged], timeout: 3), .completed,
                       "Submitting must preserve the complete place name without adding a newline.")
        let cancel = element("map.selection.cancel")
        XCTAssertTrue(cancel.exists && cancel.isHittable, "Cancel must remain usable after name submission.")
        let confirm = element("map.selection.confirm")
        XCTAssertTrue(confirm.exists)
        if expected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            XCTAssertFalse(confirm.isEnabled)
        } else {
            XCTAssertTrue(confirm.isEnabled && confirm.isHittable,
                          "The submitted valid name must leave confirmation usable.")
        }
        attachMapHierarchy("PLACE_NAME_AFTER_SUBMIT")
    }

    @discardableResult
    private func replaceLocationExactly(_ id: String, with text: String) -> Bool {
        guard scrollToElement(id, upward: id != "task.location") else {
            XCTFail("Editable location name is unreachable: \(id)")
            return false
        }
        let field = element(id)
        XCTAssertTrue(field.isEnabled)
        field.tap()
        if let value = field.value as? String, !value.isEmpty, value != field.placeholderValue {
            field.press(forDuration: 1.1)
            let predicate = NSPredicate(format: "label IN %@", ["Select All", "全选"])
            let menu = app.menuItems.matching(predicate).firstMatch
            let button = app.buttons.matching(predicate).firstMatch
            let selectAll = menu.exists ? menu : button
            guard selectAll.waitForExistence(timeout: 5), selectAll.isHittable else {
                attachMapHierarchy("LOCATION_NATIVE_SELECT_ALL_MISSING")
                XCTFail("Native whole-field selection is unavailable; refusing to append to the old location name.")
                return false
            }
            selectAll.tap()
            field.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        let empty = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let value = field.value as? String else { return false }
            return value.isEmpty || value == field.placeholderValue
        }, object: field)
        guard XCTWaiter.wait(for: [empty], timeout: 3) == .completed else {
            XCTFail("Location input did not clear before replacement.")
            return false
        }
        field.typeText(text)
        let exact = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in (field.value as? String) == text }, object: field)
        guard XCTWaiter.wait(for: [exact], timeout: 3) == .completed else {
            XCTFail("Location input differs from the complete replacement before confirmation or Save.")
            return false
        }
        return true
    }

    func testMapSelectionCanBeReplacedAndCancelledWithoutCreatingTask() throws {
        for largest in [false, true] {
            launch(reset: true, language: "en", largestType: largest)
            let surface = element("map.surface")
            visibleMapCoordinate(xFraction: 0.3).tap()
            let firstCoordinates = try assertMapSelectionBeforeEditing()
            assertLocateButtonDoesNotOverlapSelectionControls()
            visibleMapCoordinate(xFraction: 0.7).tap()
            let secondCoordinates = try assertMapSelectionBeforeEditing()
            assertLocateButtonDoesNotOverlapSelectionControls()
            XCTAssertNotEqual(firstCoordinates, secondCoordinates, "Choosing a different point must update the preview.")
            capture("MAP_SELECTION_REPLACED_\(largest ? "AXXXL" : "NORMAL")")
            tap("map.selection.cancel")
            XCTAssertTrue(waitUntilAbsent(element("map.selection.card")))
            XCTAssertFalse(element("map.selection.pin").exists)
            XCTAssertFalse(element("task.title").exists, "Cancel must not open the editor.")
            app.terminate()
            launch(reset: false, language: "en", largestType: largest)
            XCTAssertFalse(element("map.selection.card").exists)
            tap("tab.today")
            XCTAssertTrue(app.staticTexts["Start with one small task"].waitForExistence(timeout: 5),
                          "Unconfirmed map selections must not persist as tasks.")
            app.terminate()
        }
    }

    private func assertLocateButtonDoesNotOverlapSelectionControls() {
        let locate = element("location.fill")
        XCTAssertTrue(locate.waitForExistence(timeout: 5), "Map search must retain the location action.")
        XCTAssertTrue(locate.isEnabled && locate.isHittable, "Location action must remain reachable with a pending selection.")
        let frame = locate.frame
        // AX can serialize an exact 44pt frame as 43.99999999999997.
        // This tolerance covers floating-point rounding, not visual undersizing.
        let roundingTolerance: CGFloat = 1e-6
        XCTAssertGreaterThanOrEqual(frame.width, 44 - roundingTolerance, "Location action needs a full 44pt touch width.")
        XCTAssertGreaterThanOrEqual(frame.height, 44 - roundingTolerance, "Location action needs a full 44pt touch height.")
        XCTAssertTrue(app.frame.contains(frame), "Location action must remain fully within the app window.")
        for id in ["map.selection.locationName", "map.selection.confirm", "map.selection.cancel"] {
            let control = element(id)
            XCTAssertTrue(control.exists, "Selection control is missing during location overlap review: \(id)")
            let controlFrame = control.frame
            XCTAssertFalse(controlFrame.isEmpty, "Selection control has no visible frame: \(id)")
            if !frame.isEmpty && !controlFrame.isEmpty {
                XCTAssertFalse(frame.intersects(controlFrame), "Location action overlaps the selection control: \(id)")
            }
        }
        attachMapHierarchy("MAP_LOCATION_ACTION_NO_SELECTION_OVERLAP")
    }

    private func assertMapSelectionBeforeEditing() throws -> String {
        XCTAssertTrue(element("map.selection.card").waitForExistence(timeout: 10))
        let confirm = element("map.selection.confirm")
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            confirm.exists && confirm.isEnabled && confirm.isHittable
        }, object: confirm)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed,
                       "Confirm must become enabled after the bounded nearby-place lookup before reading final coordinates.")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "WAYPOINT_MAP_SELECTION_PRE_ASSERT_FULL_HIERARCHY"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        capture("MAP_SELECTION_PRE_ASSERT")
        XCTAssertTrue(element("map.selection.pin").exists, "Selected location must have a distinct map marker.")
        XCTAssertFalse(element("task.title").exists, "Selecting a point must not open the editor before confirmation.")
        XCTAssertTrue(element("map.selection.confirm").isHittable)
        XCTAssertTrue(element("map.selection.cancel").isHittable)
        let coordinates = element("map.selection.coordinates")
        XCTAssertTrue(coordinates.exists)
        return coordinates.label
    }

    private func visibleMapCoordinate(xFraction: CGFloat) -> XCUICoordinate {
        let surface = element("map.surface")
        let frame = surface.frame
        let top = max(frame.minY + 16, element("map.search").frame.maxY + 16)
        let card = element("map.selection.card")
        let bottom = card.exists ? min(frame.maxY - 16, card.frame.minY - 24) : frame.minY + frame.height * 0.60
        XCTAssertGreaterThan(bottom, top, "No uncovered map band is available for the selection gesture.")
        let point = CGPoint(x: frame.minX + frame.width * xFraction, y: (top + bottom) / 2)
        XCTAssertTrue(frame.contains(point))
        return surface.coordinate(withNormalizedOffset: CGVector(dx: (point.x - frame.minX) / frame.width,
                                                                 dy: (point.y - frame.minY) / frame.height))
    }

    func testMapPanPinchAndLongPressPreserveExplicitSelectionIntent() throws {
        launch(reset: true)
        let surface = element("map.surface")
        XCTAssertTrue(surface.waitForExistence(timeout: 10))
        let start = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.32))
        let end = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.32))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertFalse(element("map.selection.card").exists, "Panning must not select a place.")
        surface.pinch(withScale: 1.5, velocity: 1)
        XCTAssertFalse(element("map.selection.card").exists, "Pinching must not select a place.")
        surface.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.42)).press(forDuration: 0.8)
        let coordinates = try assertMapSelectionBeforeEditing()
        capture("MAP_LONG_PRESS_SELECTED")
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertEqual(element("map.selection.coordinates").label, coordinates,
                       "Panning must preserve the pending selection rather than synthesize a new tap.")
        surface.pinch(withScale: 1.3, velocity: 1)
        XCTAssertEqual(element("map.selection.coordinates").label, coordinates,
                       "Zooming must preserve the pending selected coordinate.")
        XCTAssertFalse(element("task.title").exists)
        capture("MAP_PENDING_SELECTION_AFTER_PAN_AND_PINCH")
        tap("map.selection.confirm")
        XCTAssertTrue(element("task.title").waitForExistence(timeout: 10))
        XCTAssertEqual(try editorCoordinateText(), coordinates)
        cancelEditor()
    }

    func testExistingMapTaskRequiresPreviewConfirmationBeforeEditing() throws {
        launch(reset: true, seeded: true)
        let savedPin = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "map.task.")).firstMatch
        XCTAssertTrue(savedPin.waitForExistence(timeout: 10))
        savedPin.tap()
        let coordinates = try assertMapSelectionBeforeEditing()
        let selectedTitle = element("map.selection.name").label
        XCTAssertFalse(selectedTitle.isEmpty)
        capture("MAP_EXISTING_TASK_SELECTED")
        tap("map.selection.confirm")
        XCTAssertTrue(element("task.title").waitForExistence(timeout: 10))
        XCTAssertEqual(element("task.title").value as? String, selectedTitle)
        XCTAssertEqual(try editorCoordinateText(), coordinates)
        cancelEditor()
    }

    func testCompletionSurvivesRelaunch() throws {
        launch(reset: true, seeded: true)
        tap("tab.today")
        let title = "街角咖啡，慢慢开始"
        let incomplete = app.buttons.matching(NSPredicate(format: "label == %@ AND value == %@", "完成事项", title)).firstMatch
        XCTAssertTrue(incomplete.waitForExistence(timeout: 10))
        incomplete.tap()
        let completed = app.buttons.matching(NSPredicate(format: "label == %@ AND value == %@", "标记为未完成", title)).firstMatch
        XCTAssertTrue(completed.waitForExistence(timeout: 5))
        app.terminate()
        launch(reset: false)
        tap("tab.today")
        XCTAssertTrue(completed.waitForExistence(timeout: 10), "Completion state was lost after relaunch.")
        capture("TASK_COMPLETED_PERSISTED_light")
    }

    func testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess() throws {
        launch(reset: true, seeded: true, demoAccess: false)
        tap("tab.today")
        let existing = taskElement("街角咖啡，慢慢开始")
        XCTAssertTrue(existing.waitForExistence(timeout: 10))
        existing.tap()
        XCTAssertTrue(element("task.readonly").waitForExistence(timeout: 10),
                      "Existing tasks must remain readable without subscription access.")
        assertReadableTitle("街角咖啡，慢慢开始", readOnly: true)
        XCTAssertFalse(element("task.save").isEnabled, "Read-only task must not permit saving edits.")
        capture("EXISTING_TASK_READONLY_NO_ACCESS_light")
        cancelEditor()
        tap("export.open")
        XCTAssertTrue(app.staticTexts["导出日期范围"].waitForExistence(timeout: 10))
        tap("export.format")
        for label in ["纯文本", "Markdown", "日历 ICS"] {
            XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 5), "Missing export menu option: \(label)")
        }
        app.buttons["纯文本"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "街角咖啡，慢慢开始")).firstMatch.exists)
        capture("EXPORT_RANGE_TEXT_light")
        tap("export.copy")
        XCTAssertTrue(element("export.copy").label.contains("已复制"))

        selectExportFormat("Markdown")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "- [ ]")).firstMatch.waitForExistence(timeout: 5))
        capture("EXPORT_MARKDOWN_light")
        selectExportFormat("日历 ICS")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "BEGIN:VCALENDAR")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "BEGIN:VEVENT")).firstMatch.exists)
        capture("EXPORT_ICS_light")
        // File bytes, share handoff and calendar import are separate acceptance items.
    }

    func testEmptyExportDisablesCopy() throws {
        launch(reset: true, demoAccess: false)
        tap("tab.today")
        tap("export.open")
        XCTAssertTrue(app.staticTexts["此范围没有事项"].waitForExistence(timeout: 5))
        XCTAssertFalse(element("export.copy").isEnabled)
        capture("EXPORT_EMPTY_light")
    }

    func testReminderSettingsDoNotRequestPermissionOnEntry() throws {
        launch(reset: true, demoAccess: false)
        tap("tab.settings")
        app.buttons["提醒与通知"].firstMatch.tap()
        XCTAssertTrue(element("reminders.enabled").waitForExistence(timeout: 10))
        XCTAssertEqual(XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.count, 0)
        capture("REMINDER_SETTINGS_light")
    }

    func testSubscriptionShowsRestoreAndManagementWithoutClaimingPurchase() throws {
        launch(reset: true, demoAccess: false)
        tap("tab.settings")
        tap("settings.subscription")
        XCTAssertTrue(app.staticTexts["行迹年度订阅"].waitForExistence(timeout: 10))
        // Resetting test data does not revoke an existing verified Apple purchase.
        let hadAccess = app.staticTexts["订阅有效"].exists
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        guard !springboard.alerts.firstMatch.exists else {
            throw XCTSkip("A system account prompt requires the user's action; this test does not enter credentials.")
        }
        tap("subscription.restore")
        let stop = element("subscription.stopWaiting")
        let isRestoreResult: (String) -> Bool = { text in
            text == "已恢复有效订阅。" || text == "没有找到有效订阅。" || text.hasPrefix("恢复失败：") ||
            text == "等待 Apple 同步超时，尚未确认恢复。请完成系统账户验证后重试。" ||
            text == "核对购买权益超时，尚未确认恢复，请重试。"
        }
        let observableState = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            springboard.alerts.firstMatch.exists || stop.exists ||
            (self.element("subscription.message").exists && isRestoreResult(self.element("subscription.message").label))
        }, object: nil)
        // The sync budget is 120s, followed by a separate 15s entitlement budget.
        XCTAssertEqual(XCTWaiter.wait(for: [observableState], timeout: 145), .completed,
                       "Restore exposed neither its Stop waiting control nor its actual bounded result.")
        guard !springboard.alerts.firstMatch.exists else {
            throw XCTSkip("Apple account verification is blocking the app; restore interaction is NOT_RUN until the user completes it.")
        }
        var stoppedWaiting = false
        if stop.exists {
            XCTAssertTrue(scrollToElement("subscription.close", upward: false), "Done must remain reachable while restoring.")
            XCTAssertTrue(element("subscription.close").isEnabled)
            // A real sync can finish while we verify Done; then inspect its result.
            if stop.exists {
                let stopReachable = scrollToElement("subscription.stopWaiting")
                if stop.exists {
                    XCTAssertTrue(stopReachable, "Stop waiting must remain reachable during sync.")
                    XCTAssertTrue(stop.isEnabled)
                    stop.tap()
                    stoppedWaiting = true
                    XCTAssertTrue(waitUntilAbsent(stop), "Stopping the local wait must remove the busy state.")
                }
            }
        }
        XCTAssertTrue(element("subscription.message").waitForExistence(timeout: 145))
        let message = element("subscription.message").label
        if stoppedWaiting {
            XCTAssertEqual(message, "已停止等待，尚未确认恢复。此操作不会取消 Apple 购买或订阅。",
                           "Stopping the app waiter must not claim cancellation of an Apple transaction.")
        } else {
            XCTAssertTrue(isRestoreResult(message), "Restore must report its actual result: \(message)")
        }
        XCTAssertTrue(element("subscription.restore").isEnabled, "Restore must allow retry after its bounded result.")
        if !hadAccess && (stoppedWaiting || message.contains("超时") || message.hasPrefix("恢复失败：")) {
            XCTAssertFalse(app.staticTexts["订阅有效"].exists, "An unconfirmed restore must not grant unverified access.")
        }
        if message == "已恢复有效订阅。" {
            XCTAssertTrue(app.staticTexts["订阅有效"].exists, "A restored-access result must match the actual entitlement UI.")
        }
        capture(stoppedWaiting ? "SUB_RESTORE_STOPPED_WITHOUT_CANCELLING_APPLE_light" : "SUB_RESTORE_ACTUAL_RESULT_light")
        XCTAssertTrue(scrollToElement("subscription.restore"), "Restore retry must be reachable.")
        XCTAssertTrue(element("subscription.restore").isHittable, "Retry is inspected without starting a second Apple sync.")
        XCTAssertTrue(scrollToElement("subscription.manage"))
        XCTAssertTrue(scrollToElement("subscription.close", upward: false), "Paywall exit must remain reachable.")
        element("subscription.close").tap()
        XCTAssertTrue(waitUntilAbsent(element("subscription.restore")), "Paywall did not close after restore finished.")
        // Real transactions and StoreKit-local lifecycle testing run separately.
    }

    func testLocalPlanningProducesPreviewWithoutChangingSavedTasks() throws {
        launch(reset: true, seeded: true)
        tap("tab.today")
        taskElement("去书店寻找新灵感").tap()
        XCTAssertTrue(element("task.start").waitForExistence(timeout: 10))
        let originalFlexibleStart = element("task.start").value as? String
        XCTAssertNotNil(originalFlexibleStart, "Task start date must be observable to compare persisted scheduling.")
        cancelEditor()
        taskElement("街角咖啡，慢慢开始").tap()
        XCTAssertTrue(element("task.start").waitForExistence(timeout: 10))
        let originalFixedStart = element("task.start").value as? String
        XCTAssertNotNil(originalFixedStart)
        cancelEditor()
        tap("tab.planning")
        tap("planning.generate")
        let finished = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            self.element("planning.generate").isEnabled
        }, object: element("planning.generate"))
        XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 60), .completed,
                       "Local planning remained busy beyond its bounded service timeouts.")
        XCTAssertTrue(scrollToElement("planning.apply"), "Local planning did not finish with a preview.")
        capture("PLAN_FIXED_FLEX_PREVIEW_light")
        app.terminate()
        launch(reset: false)
        tap("tab.today")
        taskElement("去书店寻找新灵感").tap()
        XCTAssertTrue(element("task.flexible").waitForExistence(timeout: 10))
        XCTAssertEqual(element("task.flexible").value as? String, "1")
        XCTAssertEqual(element("task.start").value as? String, originalFlexibleStart,
                       "Preview changed the flexible task before explicit Apply.")
        cancelEditor()
        taskElement("街角咖啡，慢慢开始").tap()
        XCTAssertTrue(element("task.start").waitForExistence(timeout: 10))
        XCTAssertEqual(element("task.start").value as? String, originalFixedStart,
                       "Preview changed a fixed task's saved time.")
    }

    func testScreenshotGalleryOfPrimaryScreens() throws {
        launch(reset: true, seeded: true)
        capturePrimaryGallery(prefix: "GALLERY")
    }

    func testRealSubscriptionScreenshotGalleryChineseAndEnglishWithoutDemoBanner() throws {
        for language in ["zh-Hans", "en"] {
            launch(reset: true, seeded: true, demoAccess: false, language: language)
            XCTAssertFalse(element("demo.banner").exists, "Release screenshots must not display a debug/demo banner.")
            tap("tab.settings")
            tap("settings.subscription")
            let active = app.staticTexts[language == "en" ? "Subscription active" : "订阅有效"].firstMatch
            XCTAssertTrue(active.waitForExistence(timeout: 40), "Real subscription is unavailable or expired; never use demo access for release screenshots.")
            guard active.exists else { return }
            tap("subscription.close")
            tap("tab.map")
            let prefix = language == "en" ? "RELEASE_REAL_EN" : "RELEASE_REAL_ZH"
            capturePrimaryGallery(prefix: prefix, requireRealAccess: true)
            tap("export.open")
            XCTAssertTrue(element("export.start").waitForExistence(timeout: 10))
            XCTAssertTrue(element("export.end").exists)
            capture("\(prefix)_EXPORT")
            app.terminate()
        }
    }

    /// Real accessible screens with seeded disposable records; no entitlement
    /// bypass, purchase, restore, writable-editor claim, or AI send action.
    func testReleaseReadOnlyGalleryChineseAndEnglishWithoutDemoBanner() throws {
        for language in ["zh-Hans", "en"] {
            launch(reset: true, seeded: true, demoAccess: false, language: language)
            let prefix = language == "en" ? "RELEASE_READONLY_EN" : "RELEASE_READONLY_ZH"
            XCTAssertFalse(element("demo.banner").exists)
            XCTAssertTrue(element("map.search").waitForExistence(timeout: 10))
            XCTAssertTrue(element("map.surface").exists)
            capture("\(prefix)_MAP")
            tap("tab.today")
            XCTAssertTrue(taskElement("街角咖啡，慢慢开始").waitForExistence(timeout: 10))
            XCTAssertFalse(element("demo.banner").exists)
            capture("\(prefix)_TODAY")
            // Do not open TaskEditor or assert write access with an expired plan.
            tap("tab.planning")
            XCTAssertTrue(element("planning.start").waitForExistence(timeout: 10))
            XCTAssertTrue(element("planning.end").exists)
            XCTAssertTrue(element("planning.generate").exists)
            capture("\(prefix)_PLANNING")
            tap("tab.settings")
            XCTAssertTrue(element("settings.ai").waitForExistence(timeout: 10))
            capture("\(prefix)_SETTINGS")
            tap("settings.ai")
            XCTAssertTrue(element("ai.analysis.exportHelp").waitForExistence(timeout: 10))
            XCTAssertTrue(element("ai.analysis.apiHelp").exists)
            XCTAssertFalse(element("demo.banner").exists)
            capture("\(prefix)_AI")
            tap("tab.today")
            tap("export.open")
            XCTAssertTrue(element("export.start").waitForExistence(timeout: 10))
            XCTAssertTrue(element("export.end").exists)
            XCTAssertTrue(element("export.format").exists)
            capture("\(prefix)_EXPORT")
            // No local/AI generation button, model refresh, or send confirmation
            // was tapped. Maps/region/StoreKit may perform normal service reads.
            app.terminate()
        }
    }

    func testSimplifiedAISettingsAndPlanningConsentCancelInChineseAndEnglish() throws {
        for language in ["zh-Hans", "en"] {
            launch(reset: true, seeded: true, language: language)
            tap("tab.today")
            tapTask("街角咖啡，慢慢开始")
            XCTAssertTrue(element("task.start").waitForExistence(timeout: 10))
            let originalStart = element("task.start").value as? String
            XCTAssertNotNil(originalStart)
            cancelEditor()
            tap("tab.settings")
            XCTAssertFalse(element("settings.contact").exists)
            XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["联系开发者", "Contact developer", "支持与联系", "Support & contact"])).firstMatch.exists)
            XCTAssertTrue(scrollToElement("settings.support"))
            XCTAssertTrue(element("settings.privacy").exists)
            capture("SIMPLIFIED_\(language)_SETTINGS")
            tap("settings.ai")
            assertAnalysisChoicesAndExportNavigation()
            XCTAssertFalse(element("ai.region.check").exists)
            XCTAssertFalse(element("ai.region.status").exists)
            XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label IN %@", ["OpenAI 地区可用性", "OpenAI regional availability"])).firstMatch.exists)
            XCTAssertTrue(scrollToElement("ai.provider"))
            let providerText = element("ai.provider").label + " " + (element("ai.provider").value as? String ?? "")
            let provider = try XCTUnwrap(["GLM", "Qwen", "DeepSeek", "OpenAI"].first { providerText.contains($0) })
            capture("SIMPLIFIED_\(language)_AI_SETTINGS")
            tap("tab.planning")
            let taskLabel = language == "en" ? "Select task to send: 街角咖啡，慢慢开始" : "选择发送事项 街角咖啡，慢慢开始"
            let choice = app.buttons[taskLabel].firstMatch
            for _ in 0..<8 where !choice.exists || !choice.isHittable { scrollContent(upward: true) }
            XCTAssertTrue(choice.exists && choice.isHittable)
            choice.tap()
            XCTAssertTrue(element("planning.ai.generate").isEnabled)
            capture("SIMPLIFIED_\(language)_PLANNING")
            tap("planning.ai.generate")
            let send = element("planning.ai.confirm")
            XCTAssertTrue(send.waitForExistence(timeout: 10), "Generate must require explicit consent before any AI request.")
            XCTAssertTrue(element("planning.ai.policy").exists)
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ AND label MATCHES %@", provider, ".*[?？]$")).firstMatch.exists,
                          "Consent must name the actual selected provider.")
            capture("SIMPLIFIED_\(language)_AI_CONFIRMATION_NO_SEND")
            // Never tap planning.ai.confirm: paid generation is not authorized.
            dismissConfirmation(cancelIdentifier: "planning.ai.cancel")
            XCTAssertTrue(waitUntilAbsent(send))
            XCTAssertTrue(element("planning.ai.generate").isEnabled)
            XCTAssertFalse(element("planning.apply").exists)
            XCTAssertEqual(app.progressIndicators.count, 0, "Cancel must not start AI work.")
            tap("tab.today")
            tapTask("街角咖啡，慢慢开始")
            XCTAssertTrue(element("task.start").waitForExistence(timeout: 10))
            XCTAssertEqual(element("task.start").value as? String, originalStart)
            cancelEditor()
            app.terminate()
        }
    }

    func testShowCompletedToggleFiltersTasksInLightAndDark() throws {
        let previousAppearance = XCUIDevice.shared.appearance
        // R38's actual start screenshots were Dark. The coordinator authorized
        // this explicit Dark fallback when XCTest reports an unusable 0 value;
        // never pass .unspecified back to the setter or guess a Light preference.
        let restoreAppearance = previousAppearance == .unspecified ? .dark : previousAppearance
        defer { XCUIDevice.shared.appearance = restoreAppearance }
        for dark in [false, true] {
            XCUIDevice.shared.appearance = dark ? .dark : .light
            XCTAssertEqual(XCUIDevice.shared.appearance, dark ? .dark : .light)
            launch(reset: true, seeded: true)
            tap("tab.today")
            let toggle = app.switches.matching(identifier: "today.showCompleted").firstMatch
            XCTAssertTrue(toggle.waitForExistence(timeout: 10))
            if toggle.value as? String != "1" { toggle.tap() }
            let complete = app.buttons.matching(NSPredicate(format: "label == %@ AND value == %@", "完成事项", "街角咖啡，慢慢开始")).firstMatch
            XCTAssertTrue(complete.waitForExistence(timeout: 10))
            complete.tap()
            XCTAssertEqual(toggle.value as? String, "1")
            XCTAssertTrue(taskElement("街角咖啡，慢慢开始").exists)
            capture("SHOW_COMPLETED_\(dark ? "DARK" : "LIGHT")_ON")
            toggle.tap()
            XCTAssertEqual(toggle.value as? String, "0")
            XCTAssertFalse(taskElement("街角咖啡，慢慢开始").exists)
            capture("SHOW_COMPLETED_\(dark ? "DARK" : "LIGHT")_OFF")
            toggle.tap()
            XCTAssertEqual(toggle.value as? String, "1")
            XCTAssertTrue(taskElement("街角咖啡，慢慢开始").exists)
            app.terminate()
        }
    }

    func testNormalAppNotificationSettingsDiagnosticWithoutResetOrDemoAccess() throws {
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        XCTAssertFalse(element("demo.banner").exists)
        let settings = app.tabBars.buttons.matching(NSPredicate(format: "label IN %@", ["设置", "Settings"])).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        let reminders = app.buttons.matching(NSPredicate(format: "label IN %@", ["提醒与通知", "Reminders & notifications"])).firstMatch
        XCTAssertTrue(reminders.waitForExistence(timeout: 10))
        reminders.tap()
        XCTAssertTrue(element("reminders.enabled").waitForExistence(timeout: 10))
        let before = XCTAttachment(string: app.debugDescription)
        before.name = "WAYPOINT_NORMAL_NOTIFICATION_SETTINGS_BEFORE"
        before.lifetime = .keepAlways
        add(before)
        capture("NORMAL_NOTIFICATION_SETTINGS_BEFORE")
        let authorize = element("reminders.authorize")
        if authorize.exists && authorize.isHittable {
            authorize.tap() // Only shown for notDetermined; user authorized Allow.
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allow = springboard.buttons.matching(NSPredicate(format: "label IN %@", ["允许", "Allow"])).firstMatch
            if allow.waitForExistence(timeout: 10) {
                let alert = springboard.alerts.firstMatch
                let text = alert.label + " " + alert.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " ")
                guard text.contains("通知") || text.localizedCaseInsensitiveContains("notification") else {
                    XCTFail("The system prompt is not identifiable as notification permission; no account or other approval was touched.")
                    return
                }
                XCTAssertTrue(allow.isHittable)
                allow.tap()
                XCTAssertTrue(waitUntilAbsent(allow, timeout: 10))
            }
        }
        // A denied grant is evidence, not permission to change system settings.
        let after = XCTAttachment(string: app.debugDescription)
        after.name = "WAYPOINT_NORMAL_NOTIFICATION_SETTINGS_AFTER"
        after.lifetime = .keepAlways
        add(after)
        capture("NORMAL_NOTIFICATION_SETTINGS_AFTER")
        XCTAssertTrue(element("reminders.enabled").exists)
    }

    func testAuthorizePreviouslyApprovedNotificationSettings() throws {
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        XCTAssertFalse(element("demo.banner").exists)
        let settings = app.tabBars.buttons.matching(NSPredicate(format: "label IN %@", ["设置", "Settings"])).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        settings.tap()
        let reminders = app.buttons.matching(NSPredicate(format: "label IN %@", ["提醒与通知", "Reminders & notifications"])).firstMatch
        XCTAssertTrue(reminders.waitForExistence(timeout: 10))
        reminders.tap()
        XCTAssertTrue(element("reminders.enabled").waitForExistence(timeout: 10))
        let allowedLabel = NSPredicate(format: "(label BEGINSWITH %@ AND label CONTAINS %@) OR (label BEGINSWITH %@ AND label CONTAINS %@)",
                                       "通知权限", "已允许", "Notification permission", "Allowed")
        let allowed = app.staticTexts.matching(allowedLabel).firstMatch
        let openSettings = app.buttons.matching(NSPredicate(format: "label IN %@", ["打开系统设置", "Open system settings"])).firstMatch
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in allowed.exists || openSettings.exists }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 15), .completed)
        capture("NOTIFICATION_REAUTHORIZE_APP_BEFORE")
        if allowed.exists { return } // Already authorized: never invert a grant.
        guard openSettings.exists && openSettings.isHittable else {
            XCTFail("No denied-notification settings route is visible; refusing to explore other permissions.")
            return
        }
        openSettings.tap()
        let preferences = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        XCTAssertTrue(preferences.wait(for: .runningForeground, timeout: 10))
        let appNames = ["行迹", "Waypoint", "MapToDo"]
        let ownAppPage = preferences.navigationBars.matching(NSPredicate(format: "identifier IN %@ OR label IN %@", appNames, appNames)).firstMatch
        guard ownAppPage.waitForExistence(timeout: 10) else {
            XCTFail("System settings does not identify the expected Waypoint app; no other setting was touched.")
            return
        }
        let pageBefore = XCTAttachment(string: preferences.debugDescription)
        pageBefore.name = "WAYPOINT_SYSTEM_OWN_APP_SETTINGS_BEFORE"
        pageBefore.lifetime = .keepAlways
        add(pageBefore)
        let notificationEntry = preferences.descendants(matching: .any).matching(NSPredicate(format: "label IN %@", ["通知", "Notifications"])).firstMatch
        guard notificationEntry.waitForExistence(timeout: 10), notificationEntry.isHittable else {
            XCTFail("The expected app has no reachable Notifications entry; no other settings were explored.")
            return
        }
        notificationEntry.tap()
        let notificationTitles = appNames + ["通知", "Notifications"]
        let notificationPage = preferences.navigationBars.matching(NSPredicate(format: "identifier IN %@ OR label IN %@", notificationTitles, notificationTitles)).firstMatch
        guard notificationPage.waitForExistence(timeout: 10) else {
            XCTFail("The expected Notifications page was not opened; no switch was changed.")
            return
        }
        let allow = preferences.switches.matching(NSPredicate(format: "label IN %@", ["允许通知", "Allow Notifications"])).firstMatch
        guard allow.waitForExistence(timeout: 10), allow.isHittable else {
            XCTFail("The exact Allow Notifications switch is unavailable; no other switch was changed.")
            return
        }
        for (name, action) in [("BEFORE", false), ("AFTER", true)] {
            if action {
                let value = allow.value as? String
                guard value == "0" || value == "1" else {
                    XCTFail("Unknown Allow Notifications state; refusing to toggle blindly.")
                    return
                }
                if value == "0" {
                    let row = allow.frame
                    guard row.width >= 44, row.height > 0, preferences.frame.contains(row), allow.isHittable else {
                        XCTFail("Allow Notifications row is outside the expected visible window; no setting was changed.")
                        return
                    }
                    // R39 exposes the entire label row as the Switch. Its center
                    // hits empty text; the actual native switch is at the right.
                    allow.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
                }
                let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '1'"), object: allow)
                XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 10), .completed)
            }
            let hierarchy = XCTAttachment(string: preferences.debugDescription)
            hierarchy.name = "WAYPOINT_SYSTEM_NOTIFICATION_\(name)_HIERARCHY"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            let screenshot = XCTAttachment(screenshot: preferences.screenshot())
            screenshot.name = "WAYPOINT_SYSTEM_NOTIFICATION_\(name)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(allowed.waitForExistence(timeout: 15), "The app did not report notification permission Allowed after returning.")
        capture("NOTIFICATION_REAUTHORIZE_APP_ALLOWED")
    }

    func testEnglishScreenshotGalleryOfPrimaryScreens() throws {
        launch(reset: true, seeded: true, language: "en")
        capturePrimaryGallery(prefix: "GALLERY_EN")
    }

    func testLargestAccessibilityTypeScreenshotGalleryOfPrimaryScreens() throws {
        launch(reset: true, seeded: true)
        tap("tab.today")
        let normalHeading = app.staticTexts["把今天，走成行迹"].firstMatch
        XCTAssertTrue(normalHeading.waitForExistence(timeout: 10))
        let normalHeight = normalHeading.frame.height
        app.terminate()
        launch(reset: true, seeded: true, largestType: true)
        tap("tab.today")
        let largestHeading = app.staticTexts["把今天，走成行迹"].firstMatch
        XCTAssertTrue(largestHeading.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(largestHeading.frame.height, normalHeight * 1.4,
                             "Largest accessibility launch preference did not measurably enlarge Dynamic Type.")
        tap("tab.map")
        // Retain hierarchy as well as pixels to review wrapping and reachable
        // controls. This launch preference does not alter device Settings.
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "WAYPOINT_AXXXL_MAP_HIERARCHY"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        capturePrimaryGallery(prefix: "GALLERY_AXXXL")
    }

    func testLongEditableTitleWrapsAndSurvivesSaveAndRelaunch() throws {
        try exerciseLongTitle(readOnlyAfterRelaunch: false)
    }

    func testLongReadonlyTitleWrapsAndRemainsWholeWithoutAccess() throws {
        try exerciseLongTitle(readOnlyAfterRelaunch: true)
    }

    private func exerciseLongTitle(readOnlyAfterRelaunch: Bool) throws {
        let longTitle = "UI 长标题 " + String(repeating: "这条事项标题需要完整换行并保留每一个字符，", count: 3) + "末尾完整标记"
        for largest in [false, true] {
            launch(reset: true, largestType: largest)
            tap("tab.today")
            tap("task.add")
            tap("task.location.confirm")
            XCTAssertTrue(scrollToElement("task.title", upward: false),
                          "Return to the title after confirming a location lower in the form.")
            let title = element("task.title")
            XCTAssertTrue(title.waitForExistence(timeout: 10))
            let oneLineHeight = title.frame.height
            replaceText("task.title", with: longTitle)
            assertReadableTitle(longTitle, readOnly: false)
            XCTAssertGreaterThan(title.frame.height, oneLineHeight * 2.5,
                                 "Long editable title still occupies a truncated single-line field.")
            capture("LONG_TITLE_EDITABLE_\(largest ? "AXXXL" : "NORMAL")")
            tap("task.save")
            app.terminate()
            launch(reset: false, demoAccess: !readOnlyAfterRelaunch, largestType: largest)
            tap("tab.today")
            tapTask(longTitle)
            assertReadableTitle(longTitle, readOnly: readOnlyAfterRelaunch)
            XCTAssertGreaterThan(element("task.title").frame.height, oneLineHeight * 2.5,
                                 "Saved title does not visibly wrap when reopened.")
            if readOnlyAfterRelaunch {
                XCTAssertTrue(element("task.readonly").exists)
                XCTAssertFalse(element("task.save").isEnabled)
            }
            capture("LONG_TITLE_\(readOnlyAfterRelaunch ? "READONLY" : "REOPENED")_\(largest ? "AXXXL" : "NORMAL")")
            cancelEditor()
            app.terminate()
        }
    }

    private func assertReadableTitle(_ expected: String, readOnly: Bool) {
        let title = element("task.title")
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        let actual = readOnly ? title.label : (title.value as? String)
        XCTAssertEqual(actual, expected, "Every title character, including its final marker, must remain readable.")
        XCTAssertGreaterThan(title.frame.width, 0)
        XCTAssertLessThanOrEqual(title.frame.maxX, app.frame.maxX,
                                 "Title must wrap within the screen rather than overflow horizontally.")
        if readOnly {
            XCTAssertTrue(app.staticTexts.matching(identifier: "task.title").firstMatch.exists)
            XCTAssertFalse(app.textFields.matching(identifier: "task.title").firstMatch.exists)
            XCTAssertFalse(app.textViews.matching(identifier: "task.title").firstMatch.exists,
                           "Read-only title must expose readable text rather than an editable field.")
        }
    }

    private func capturePrimaryGallery(prefix: String, requireRealAccess: Bool = false) {
        if requireRealAccess { XCTAssertFalse(element("demo.banner").exists) }
        capture("\(prefix)_MAP")
        tap("tab.today")
        capture("\(prefix)_TODAY")
        tapTask("街角咖啡，慢慢开始")
        XCTAssertTrue(element("task.title").waitForExistence(timeout: 10))
        XCTAssertEqual(element("task.title").value as? String, "街角咖啡，慢慢开始",
                       "Gallery must show the selected saved task, not an empty new draft.")
        if requireRealAccess {
            XCTAssertFalse(element("task.readonly").exists)
            XCTAssertTrue(element("task.save").isEnabled)
        }
        capture("\(prefix)_TASK_EDITOR")
        cancelEditor()
        tap("tab.planning")
        capture("\(prefix)_PLANNING")
        tap("tab.settings")
        capture("\(prefix)_SETTINGS")
        tap("settings.ai")
        capture("\(prefix)_AI")
        tap("tab.today")
        XCTAssertTrue(scrollToElement("task.add"), "Today add action must remain reachable at the end of scrolling.")
        let add = element("task.add")
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        for _ in 0..<4 where add.frame.maxY > tabBar.frame.minY { scrollContent(upward: true) }
        XCTAssertLessThanOrEqual(add.frame.maxY, tabBar.frame.minY,
                                 "Entire Today add action must be above the floating tab bar, not merely partly hittable.")
        XCTAssertGreaterThanOrEqual(add.frame.minY, app.frame.minY)
        capture("\(prefix)_TODAY_SCROLL_END")
    }

    func testTodayScreenAccessibilityAudit() throws {
        launch(reset: true, seeded: true)
        tap("tab.today")
        capture("ACCESSIBILITY_TODAY")
        if #available(iOS 17.0, *) {
            try app.performAccessibilityAudit(for: [.contrast, .hitRegion, .textClipped])
        }
    }

    func testAvailableAIProvidersUseSecureInputAndHideUnverifiedOpenAIAndGemini() throws {
        launch(reset: true)
        tap("tab.settings")
        tap("settings.ai")
        assertAnalysisChoicesAndExportNavigation()
        for provider in ["GLM", "Qwen", "DeepSeek"] {
            tap("ai.provider")
            XCTAssertFalse(app.buttons["Gemini"].exists, "Gemini must not be selectable in the first release.")
            XCTAssertFalse(app.buttons["OpenAI"].exists, "OpenAI must remain hidden before both region checks pass.")
            let choice = app.buttons[provider].firstMatch
            XCTAssertTrue(choice.waitForExistence(timeout: 5), "Missing AI provider: \(provider)")
            choice.tap()
            let key = app.secureTextFields.matching(identifier: "ai.key").firstMatch
            XCTAssertTrue(scrollToElement("ai.key"), "Secure input is not reachable for \(provider).")
            XCTAssertTrue(key.exists, "API key input must be a SecureField.")
            let saveKey = app.buttons.matching(identifier: "ai.key.save").firstMatch
            XCTAssertFalse(saveKey.isEnabled, "Empty input must not enable saving a new key.")
            let sentinel = "UITEST_INVALID_KEY_\(provider)_ONLY"
            key.tap()
            key.typeText(sentinel)
            XCTAssertNotEqual(key.value as? String, sentinel, "Secure input exposed the raw key.")
            XCTAssertFalse((key.value as? String ?? "").isEmpty, "Typing did not populate the secure input.")
            XCTAssertNotEqual(key.value as? String, key.placeholderValue, "Input still contains only its placeholder.")
            tap("ai.key.done")
            XCTAssertTrue(waitUntilAbsent(app.keyboards.firstMatch), "Keyboard Done did not dismiss the keyboard.")
            XCTAssertTrue(saveKey.isEnabled, "Nonempty input did not enable Save; this is distinct from keyboard/scroll occlusion.")
            tap("ai.key.save")
            XCTAssertTrue(scrollToElement("ai.status"), "Key-save result must be reachable and visible.")
            XCTAssertEqual(element("ai.status").label, "已保存到此设备钥匙串。")
            XCTAssertEqual(element("ai.key.saved").label, "此设备已保存 API Key")
            XCTAssertFalse(app.staticTexts[sentinel].exists)
            tap("ai.key.delete")
            let confirmDelete = element("ai.key.delete.confirm")
            XCTAssertTrue(confirmDelete.waitForExistence(timeout: 5),
                          "Key deletion must require an explicit confirmation for \(provider).")
            dismissConfirmation(cancelIdentifier: nil)
            XCTAssertTrue(waitUntilAbsent(confirmDelete), "Deletion confirmation did not dismiss.")
            XCTAssertEqual(element("ai.status").label, "已保存到此设备钥匙串。",
                           "Cancelling confirmation must not delete the saved key.")
            XCTAssertEqual(element("ai.key.saved").label, "此设备已保存 API Key")
            tap("ai.key.delete")
            XCTAssertTrue(confirmDelete.waitForExistence(timeout: 5))
            confirmDelete.tap()
            XCTAssertEqual(element("ai.status").label, "此服务密钥已删除。")
            XCTAssertEqual(element("ai.key.saved").label, "此设备尚未保存 API Key")
            XCTAssertFalse(element("ai.key.delete").isEnabled, "Deleting an absent provider key must be disabled.")
            XCTAssertTrue(scrollToElement("ai.provider", upward: false), "Provider picker is not reachable after deleting \(provider).")
        }
        capture("AI_THREE_PROVIDERS_KEYS_DELETED_REGION_UNVERIFIED")
        app.terminate()
        launch(reset: false)
        tap("tab.settings")
        tap("settings.ai")
        XCTAssertTrue(scrollToElement("ai.provider"), "Provider picker must be reachable after relaunch before reading its value.")
        let savedProvider = element("ai.provider")
        XCTAssertTrue(savedProvider.isHittable, "Persisted provider picker must be interactive after relaunch.")
        XCTAssertTrue(savedProvider.label.contains("DeepSeek") || (savedProvider.value as? String)?.contains("DeepSeek") == true,
                      "AI provider selection did not persist.")
        tap("ai.provider")
        XCTAssertFalse(app.buttons["Gemini"].exists, "Gemini became selectable after relaunch.")
        XCTAssertFalse(app.buttons["OpenAI"].exists, "Unverified region access must not survive relaunch.")
        XCTAssertTrue(app.buttons["DeepSeek"].waitForExistence(timeout: 5))
        app.buttons["DeepSeek"].tap()
        XCTAssertTrue(scrollToElement("ai.key"), "Secure input must remain reachable after relaunch.")
        XCTAssertTrue(app.secureTextFields.matching(identifier: "ai.key").firstMatch.exists)
        XCTAssertTrue(app.secureTextFields.matching(identifier: "ai.key").firstMatch.isHittable)
        capture("AI_SECURE_INPUT_AFTER_RELAUNCH")
    }

    func testNotificationDenialKeepsAppUsable() throws {
        launch(reset: true, demoAccess: false)
        tap("tab.settings")
        app.buttons["提醒与通知"].firstMatch.tap()
        let authorize = element("reminders.authorize")
        if !authorize.waitForExistence(timeout: 3) {
            throw XCTSkip("Notification permission was already determined; a fresh install is needed for the denial scenario.")
        }
        authorize.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let deny = springboard.buttons.matching(NSPredicate(format: "label IN %@", ["Don’t Allow", "Don't Allow", "不允许"])).firstMatch
        XCTAssertTrue(deny.waitForExistence(timeout: 10), "Explicit authorization did not show the system notification prompt.")
        deny.tap()
        XCTAssertTrue(app.staticTexts["通知权限已关闭，事项仍会保存。请在系统设置中允许通知后返回。"].waitForExistence(timeout: 10))
        capture("REM_DENIED_light")
        XCTAssertTrue(element("reminders.enabled").exists)
    }

    func testEnglishMarketSmokeShowsEnglishNavigationExportAndPaywall() throws {
        launch(reset: true, seeded: true, demoAccess: false, language: "en")
        for label in ["Map", "Today", "Plan", "Settings"] {
            XCTAssertTrue(app.tabBars.buttons[label].waitForExistence(timeout: 10), "Missing English tab: \(label)")
        }
        capture("EN_MAP")
        tap("tab.today")
        tap("export.open")
        XCTAssertTrue(app.staticTexts["Export date range"].waitForExistence(timeout: 10))
        XCTAssertTrue(element("export.start").exists)
        XCTAssertTrue(element("export.end").exists)
        XCTAssertTrue(element("export.format").exists)
        tap("export.format")
        XCTAssertTrue(app.buttons["Plain text"].waitForExistence(timeout: 5))
        app.buttons["Plain text"].tap()
        capture("EN_EXPORT")
        app.buttons["Done"].firstMatch.tap()
        tap("tab.planning")
        XCTAssertTrue(element("planning.generate").exists)
        capture("EN_PLAN")
        tap("tab.settings")
        tap("settings.ai")
        assertAnalysisChoicesAndExportNavigation()
        let settingsBack = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(settingsBack.isHittable)
        settingsBack.tap()
        tap("settings.subscription")
        XCTAssertTrue(app.staticTexts["Waypoint annual subscription"].waitForExistence(timeout: 10))
        XCTAssertEqual(element("subscription.restore").label, "Restore purchases")
        XCTAssertTrue(element("subscription.manage").exists)
        capture("EN_PAYWALL")
        let purchase = element("subscription.purchase")
        XCTAssertTrue(purchase.waitForExistence(timeout: 25),
                      "Live product must load before the purchase-button contrast can be assessed.")
        XCTAssertTrue(scrollToElement("subscription.purchase"))
        XCTAssertTrue(purchase.isEnabled, "Loaded purchase action must be available without being tapped.")
        XCTAssertTrue(["Start 7-day free trial", "Subscribe for one year"].contains(purchase.label),
                      "Purchase label must reflect the actual account eligibility in English.")
        if purchase.label == "Start 7-day free trial" {
            XCTAssertTrue(app.staticTexts["Eligible: 7 days free, then auto-renews at the annual price shown above."].exists)
        } else {
            XCTAssertTrue(app.staticTexts["This account is not currently eligible for the 7-day trial. The annual price above applies upon purchase."].exists)
        }
        capture("EN_PAYWALL_LOADED_PURCHASE_NO_TRANSACTION")
        let purchaseScreenshot = XCTAttachment(screenshot: purchase.screenshot())
        purchaseScreenshot.name = "WAYPOINT_EN_PAYWALL_PURCHASE_CONTRAST"
        purchaseScreenshot.lifetime = .keepAlways
        add(purchaseScreenshot)
        if #available(iOS 17.0, *) {
            try app.performAccessibilityAudit(for: [.contrast])
        }
        XCTAssertFalse(app.tabBars.firstMatch.isHittable,
                       "Subscription controls must not sit beneath the floating tab bar.")
        XCTAssertTrue(scrollToElement("subscription.manage"))
        XCTAssertTrue(element("subscription.manage").isHittable)
        XCTAssertTrue(scrollToElement("subscription.terms"))
        XCTAssertTrue(element("subscription.privacy").isHittable)
        XCTAssertTrue(element("subscription.terms").isHittable)
        capture("EN_PAYWALL_MANAGEMENT_AND_LEGAL")
        XCTAssertTrue(scrollToElement("subscription.close", upward: false))
        element("subscription.close").tap()
        for id in ["tab.map", "tab.today", "tab.planning", "tab.settings"] {
            XCTAssertTrue(element(id).waitForExistence(timeout: 5))
            XCTAssertTrue(element(id).isHittable, "Paywall dismissal must restore tab navigation: \(id)")
        }
        tap("tab.today")
        tap("task.add")
        XCTAssertTrue(element("subscription.close").waitForExistence(timeout: 5),
                      "Without access, creating a task must present the subscription sheet.")
        element("subscription.close").tap()
        XCTAssertTrue(waitUntilAbsent(element("subscription.close")))
        tap("tab.map")
        XCTAssertTrue(element("map.search").waitForExistence(timeout: 5),
                      "Closing the subscription sheet must preserve usable tab navigation.")
    }

    private func assertAnalysisChoicesAndExportNavigation() {
        let exportHelp = element("ai.analysis.exportHelp")
        let apiHelp = element("ai.analysis.apiHelp")
        XCTAssertTrue(exportHelp.waitForExistence(timeout: 10))
        XCTAssertTrue(apiHelp.exists)
        if uiLanguage == "en" {
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label ==[c] %@", "Choose how to analyze")).firstMatch.exists)
            XCTAssertEqual(exportHelp.label, "Export a date range, then paste or upload the records to your chosen AI service yourself. No API key is needed in this app.")
            XCTAssertEqual(apiHelp.label, "Or add your provider’s API key below and analyze in the Plan tab. API usage is billed by your provider.")
        } else {
            XCTAssertTrue(app.staticTexts["选择分析方式"].exists)
            XCTAssertEqual(exportHelp.label, "按日期导出记录，再自行粘贴或上传到服务商的模型中分析；无需在本 App 配置 API Key。")
            XCTAssertEqual(apiHelp.label, "也可以在下方配置服务商的 API Key，再到“规划”页在 App 内分析。API 用量按服务商规则计费。")
        }
        capture("\(uiLanguage)_AI_ANALYSIS_CHOICES")
        tap("ai.analysis.export")
        XCTAssertTrue(element("export.start").waitForExistence(timeout: 10))
        XCTAssertTrue(element("export.end").exists)
        capture("\(uiLanguage)_AI_ANALYSIS_EXPORT")
        let back = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(back.isHittable, "Export must retain a working return path to AI settings.")
        back.tap()
        XCTAssertTrue(exportHelp.waitForExistence(timeout: 10), "Returning from export must restore AI analysis choices.")
        XCTAssertTrue(apiHelp.exists)
    }

    private func launch(reset: Bool, seeded: Bool = false, demoAccess: Bool = true, language: String = "zh-Hans", largestType: Bool = false, interfaceStyle: String? = nil, additionalLaunchArguments: [String] = []) {
        uiLanguage = language
        app.launchArguments = ["--uitesting"]
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "en" ? "en_US" : "zh_CN"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", largestType
            ? "UICTContentSizeCategoryAccessibilityXXXL" : "UICTContentSizeCategoryL"]
        if reset { app.launchArguments.append("--reset-data") }
        if seeded { app.launchArguments.append("--seed-demo") }
        if demoAccess { app.launchArguments.append("--demo-access") }
        if let interfaceStyle { app.launchArguments += ["-AppleInterfaceStyle", interfaceStyle] }
        app.launchArguments += additionalLaunchArguments
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
        XCTAssertTrue(element("tab.map").waitForExistence(timeout: 10))
        element("tab.map").tap()
        XCTAssertTrue(element("tab.map").isSelected, "Launch must begin on the Map tab.")
    }

    private func element(_ id: String) -> XCUIElement {
        let tabs = uiLanguage == "en"
            ? ["tab.map": "Map", "tab.today": "Today", "tab.planning": "Plan", "tab.settings": "Settings"]
            : ["tab.map": "地图", "tab.today": "今日", "tab.planning": "规划", "tab.settings": "设置"]
        if let label = tabs[id] { return app.tabBars.buttons[label].firstMatch }
        return app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func taskElement(_ title: String) -> XCUIElement {
        let button = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
        return button.exists ? button : app.staticTexts[title].firstMatch
    }

    private func tapTask(_ title: String) {
        for _ in 0..<12 {
            let target = taskElement(title)
            if target.exists && target.isHittable { target.tap(); return }
            scrollContent(upward: true)
        }
        XCTFail("Saved task is not reachable: \(title)")
    }

    private func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = element(id)
        XCTAssertTrue(scrollToElement(id), "Missing or unreachable \(id)", file: file, line: line)
        XCTAssertTrue(target.isHittable, "Not hittable: \(id)", file: file, line: line)
        target.tap()
    }

    /// Native whole-field selection avoids assuming that a tap leaves the caret
    /// at the end of a multiline title. Used only for the real-subscription case.
    @discardableResult
    private func replaceTaskTitleExactly(_ text: String,
                                         file: StaticString = #filePath, line: UInt = #line) -> Bool {
        guard scrollToElement("task.title", upward: false) else {
            XCTFail("Editable title is unreachable.", file: file, line: line)
            return false
        }
        let field = element("task.title")
        XCTAssertTrue(field.isEnabled, file: file, line: line)
        field.tap()
        if let current = field.value as? String, !current.isEmpty, current != field.placeholderValue {
            field.press(forDuration: 1.1)
            let labels = NSPredicate(format: "label IN %@", ["Select All", "全选"])
            let menuItem = app.menuItems.matching(labels).firstMatch
            let button = app.buttons.matching(labels).firstMatch
            let selectAll = menuItem.exists ? menuItem : button
            guard selectAll.waitForExistence(timeout: 5), selectAll.isHittable else {
                let hierarchy = XCTAttachment(string: app.debugDescription)
                hierarchy.name = "WAYPOINT_TASK_TITLE_NATIVE_SELECT_ALL_MISSING"
                hierarchy.lifetime = .keepAlways
                add(hierarchy)
                capture("TASK_TITLE_NATIVE_EDIT_MENU")
                XCTFail("Native Select All is unavailable; refusing to append to the existing title.", file: file, line: line)
                return false
            }
            selectAll.tap()
            field.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        let cleared = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let value = field.value as? String else { return false }
            return value.isEmpty || value == field.placeholderValue
        }, object: field)
        guard XCTWaiter.wait(for: [cleared], timeout: 3) == .completed else {
            XCTFail("Title was not empty after whole-field deletion; refusing to type new text.", file: file, line: line)
            return false
        }
        field.typeText(text)
        let exact = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (field.value as? String) == text
        }, object: field)
        guard XCTWaiter.wait(for: [exact], timeout: 3) == .completed else {
            XCTFail("Title input does not equal the full replacement before Save.", file: file, line: line)
            return false
        }
        return true
    }

    private func replaceText(_ id: String, with text: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        let field = element(id)
        XCTAssertTrue(field.waitForExistence(timeout: 10), "Missing \(id)", file: file, line: line)
        field.tap()
        if let value = field.value as? String, !value.isEmpty, value != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        field.typeText(text)
    }

    private func cancelEditor(discardChanges: Bool = false) {
        tap("task.cancel")
        if discardChanges {
            XCTAssertTrue(element("task.discard").waitForExistence(timeout: 5),
                          "Dirty cancellation must offer an explicit discard confirmation.")
            let title = element("task.title").value as? String
            dismissConfirmation(cancelIdentifier: "task.keepEditing")
            XCTAssertTrue(waitUntilAbsent(element("task.discard")))
            XCTAssertEqual(element("task.title").value as? String, title,
                           "Dismissing discard confirmation must preserve the unsaved draft.")
            tap("task.cancel")
            tap("task.discard")
        } else {
            XCTAssertFalse(element("task.discard").exists,
                           "Opening an unchanged task must not require discarding changes.")
        }
        XCTAssertTrue(waitUntilAbsent(element("task.title")), "Task editor did not close after cancellation.")
    }

    private func dismissConfirmation(cancelIdentifier: String?) {
        if let cancelIdentifier, element(cancelIdentifier).exists {
            element(cancelIdentifier).tap()
            return
        }
        let cancelLabel = uiLanguage == "en" ? "Cancel" : "取消"
        if app.buttons[cancelLabel].exists && app.buttons[cancelLabel].isHittable {
            app.buttons[cancelLabel].tap()
            return
        }
        // iOS popovers omit the role.cancel button and expose an explicit
        // dismiss region around the popover instead. Never tap the destructive
        // choice to stand in for cancellation.
        let dismiss = app.descendants(matching: .any).matching(identifier: "PopoverDismissRegion").firstMatch
        XCTAssertTrue(dismiss.waitForExistence(timeout: 5), "Native confirmation has no cancellation route.")
        dismiss.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.55)).tap()
    }

    private func selectExportFormat(_ label: String) {
        tap("export.format")
        XCTAssertTrue(app.buttons[label].waitForExistence(timeout: 5), "Missing export format: \(label)")
        app.buttons[label].tap()
    }

    private func scrollToElement(_ id: String, upward: Bool = true) -> Bool {
        let target = element(id)
        if target.waitForExistence(timeout: 2) && target.isHittable { return true }
        for _ in 0..<12 {
            scrollContent(upward: upward)
            if target.exists && target.isHittable { return true }
        }
        return target.exists && target.isHittable
    }

    private func scrollContent(upward: Bool) {
        // Start above the keyboard and below the navigation bar so the gesture
        // scrolls form/list content rather than keys or the tab bar.
        let frame = app.frame
        let keyboard = app.keyboards.firstMatch
        let startY = keyboard.exists
            ? min(frame.height * 0.70, keyboard.frame.minY - frame.minY - 24)
            : frame.height * 0.70
        let endY = max(frame.height * 0.20, startY - frame.height * 0.40)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let high = origin.withOffset(CGVector(dx: frame.width * 0.5, dy: endY))
        let low = origin.withOffset(CGVector(dx: frame.width * 0.5, dy: startY))
        (upward ? low : high).press(forDuration: 0.05, thenDragTo: upward ? high : low)
    }

    private func confirmDeletionIfPresented() {
        let confirm = app.buttons.matching(identifier: "task.delete.confirm").firstMatch
        if confirm.waitForExistence(timeout: 2) { confirm.tap(); return }
        let dialogButton = app.buttons.matching(NSPredicate(format: "label == %@", "删除事项"))
            .allElementsBoundByIndex.first { $0.isHittable }
        if let dialogButton { dialogButton.tap() }
    }

    private func waitUntilAbsent(_ target: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                    object: target)], timeout: timeout) == .completed
    }

    private func editorCoordinateText() throws -> String {
        let pattern = "^-?[0-9]{1,3}\\.[0-9]{5}, -?[0-9]{1,3}\\.[0-9]{5}$"
        let coordinateLabel = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", pattern)).firstMatch
        XCTAssertTrue(coordinateLabel.waitForExistence(timeout: 10), "Missing visible task coordinates.")
        let text = coordinateLabel.label
        let parts = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let pair = try XCTUnwrap(parts.count == 2 ? parts : nil, "Invalid coordinate format.")
        let latitude = try XCTUnwrap(Double(pair[0]))
        let longitude = try XCTUnwrap(Double(pair[1]))
        XCTAssertTrue(latitude.isFinite && (-90...90).contains(latitude))
        XCTAssertTrue(longitude.isFinite && (-180...180).contains(longitude))
        return text
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "WAYPOINT_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
