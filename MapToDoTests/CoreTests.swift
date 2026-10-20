import XCTest
@testable import MapToDo

@MainActor final class CoreTests: XCTestCase {
    private func file() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("tasks.json") }
    func testEditsPersistWithoutDuplicatingAndCompletionSurvivesReload() {
        let url = file()
        let store = TaskStore(fileURL: url)
        var item = TaskItem(title: "带伞去图书馆")
        store.upsert(item)
        item.title = "借书并归还雨伞"
        store.upsert(item)
        store.toggleCompletion(item.id)
        let reload = TaskStore(fileURL: url)
        XCTAssertEqual(reload.tasks.count, 1)
        XCTAssertEqual(reload.tasks.first?.title, item.title)
        XCTAssertEqual(reload.tasks.first?.isCompleted, true)
        reload.remove(item.id)
        XCTAssertTrue(TaskStore(fileURL: url).tasks.isEmpty)
    }
    func testCorruptStoreIsNeverOverwritten() throws {
        let url = file()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let original = Data("invalid json but valuable recovery data".utf8)
        try original.write(to: url)
        let store = TaskStore(fileURL: url)
        XCTAssertNotNil(store.errorMessage)
        store.upsert(TaskItem(title: "不覆盖"))
        XCTAssertEqual(try Data(contentsOf: url), original)
        XCTAssertTrue(store.tasks.isEmpty)
    }
    func testTaskDisplayUsesItsTimeZoneInsteadOfDeviceZone() {
        let date = Date(timeIntervalSince1970: 0)
        let tokyo = LocalTimeFormatter.string(date, timeZoneIdentifier: "Asia/Tokyo")
        let utc = LocalTimeFormatter.string(date, timeZoneIdentifier: "UTC")
        XCTAssertNotEqual(tokyo, utc)
        XCTAssertTrue(tokyo.contains("9") || tokyo.contains("09"))
    }
    func testInvalidDataIsRejected() {
        let store = TaskStore(fileURL: file())
        store.upsert(TaskItem(title: "   "))
        store.upsert(TaskItem(title: "异常坐标", latitude: 91))
        store.upsert(TaskItem(title: "负时长", durationMinutes: -1))
        XCTAssertTrue(store.tasks.isEmpty)
    }
    func testScheduleApplyIsAtomicAndProtectsFixedTasksAndWindows() {
        let store = TaskStore(fileURL: file())
        let start = Date(timeIntervalSince1970: 1_900_000_000)
        let fixed = TaskItem(title: "预约", scheduledAt: start)
        let flexible = TaskItem(title: "买花", scheduledAt: start, durationMinutes: 30, isFlexible: true, flexibilityEnd: start.addingTimeInterval(7200))
        store.upsert(fixed); store.upsert(flexible)
        store.replaceSchedule([fixed.id: start.addingTimeInterval(60), flexible.id: start.addingTimeInterval(1800)])
        XCTAssertEqual(store.tasks.first(where: { $0.id == fixed.id })?.scheduledAt, start)
        XCTAssertEqual(store.tasks.first(where: { $0.id == flexible.id })?.scheduledAt, start)
        store.replaceSchedule([flexible.id: start.addingTimeInterval(1800)])
        XCTAssertEqual(store.tasks.first(where: { $0.id == flexible.id })?.scheduledAt, start.addingTimeInterval(1800))
    }
}
