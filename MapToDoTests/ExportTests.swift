import XCTest
@testable import MapToDo

final class ExportTests: XCTestCase {
    func testEndDayIncludesLateTaskAndExcludesNextMidnightAcrossDST() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let day = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8))!
        let late = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 23, minute: 59))!
        let next = calendar.date(from: DateComponents(year: 2026, month: 3, day: 9))!
        let tasks = [TaskItem(title: "今天", scheduledAt: late), TaskItem(title: "明天", scheduledAt: next)]
        XCTAssertEqual(ExportFormatter.filtered(tasks, from: day, through: day, calendar: calendar).map(\.title), ["今天"])
        XCTAssertEqual(next.timeIntervalSince(day), 23 * 3600)
    }

    func testICSEscapesTextAndUsesUTC() {
        let task = TaskItem(title: "a,b;c\\d\ne", notes: "第一行\r\n第二行", scheduledAt: Date(timeIntervalSince1970: 0), timeZoneIdentifier: "Asia/Shanghai")
        let result = ExportFormatter.render([task], format: .ics, generatedAt: Date(timeIntervalSince1970: 0))
        XCTAssertTrue(result.contains("SUMMARY:a\\,b\\;c\\\\d\\ne\r\n"))
        XCTAssertTrue(result.contains("DESCRIPTION:第一行\\n第二行\r\n"))
        XCTAssertTrue(result.contains("DTSTART:19700101T000000Z\r\n"))
        XCTAssertTrue(result.contains("DTEND:19700101T003000Z\r\n"))
    }

    func testUTF8FoldingPreservesContentAndLimitsEveryPhysicalLine() {
        let title = String(repeating: "地点🌿", count: 40)
        let result = ExportFormatter.render([TaskItem(title: title)], format: .ics)
        for line in result.components(separatedBy: "\r\n") { XCTAssertLessThanOrEqual(line.utf8.count, 75) }
        XCTAssertTrue(result.replacingOccurrences(of: "\r\n ", with: "").contains("SUMMARY:" + title))
    }

    func testTextShowsTaskLocalTimeAndAllDetails() {
        let task = TaskItem(title: "买花", notes: "白色", locationName: "花店", scheduledAt: Date(timeIntervalSince1970: 0), timeZoneIdentifier: "Asia/Shanghai")
        let result = ExportFormatter.render([task], format: .text)
        XCTAssertTrue(result.contains("08:00"))
        XCTAssertTrue(result.contains("Asia/Shanghai"))
        XCTAssertTrue(result.contains("花店"))
        XCTAssertTrue(result.contains("白色"))
    }
}
