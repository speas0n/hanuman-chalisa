import XCTest
import AVFoundation
@testable import Chalisa

final class LearningTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return calendar
    }
    private func date(_ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    func testReviewIntervalsAndSameDayProtection() {
        let now = date(9, 26)
        let first = ReviewRecord(due: now).assessed(success: true, now: now, calendar: calendar)
        XCTAssertEqual(first.stage, 1)
        XCTAssertTrue(calendar.isDate(first.due, inSameDayAs: date(9, 27)))
        let repeated = first.assessed(success: true, now: now, calendar: calendar)
        XCTAssertEqual(repeated.stage, 1)
        let second = repeated.assessed(success: true, now: date(9, 27), calendar: calendar)
        XCTAssertEqual(second.stage, 2)
        XCTAssertTrue(calendar.isDate(second.due, inSameDayAs: date(9, 30)))
        let third = second.assessed(success: true, now: date(9, 30), calendar: calendar)
        XCTAssertEqual(third.stage, 3)
        XCTAssertTrue(calendar.isDate(third.due, inSameDayAs: date(10, 7)))
        let fourth = third.assessed(success: true, now: date(10, 7), calendar: calendar)
        XCTAssertEqual(fourth.stage, 4)
        XCTAssertTrue(calendar.isDate(fourth.due, inSameDayAs: date(10, 21)))
    }

    func testFailureIsDueTodayAndRetainsRecallHistory() {
        let now = date(9, 26)
        let record = ReviewRecord(stage: 4, due: date(10, 10), lastSuccess: date(9, 20), recalled: true)
            .assessed(success: false, now: now, calendar: calendar)
        XCTAssertEqual(record.stage, 0)
        XCTAssertTrue(record.recalled)
        let state = LearningState(records: [3: record, 1: ReviewRecord(due: date(9, 25)), 2: ReviewRecord(due: date(9, 27))])
        XCTAssertEqual(state.dueIDs(now: now, calendar: calendar), [1, 3])
    }

    func testReviewUsesCalendarDaysAcrossDaylightSaving() {
        let first = ReviewRecord(due: date(3, 7)).assessed(success: true, now: date(3, 7), calendar: calendar)
        let second = first.assessed(success: true, now: date(3, 8), calendar: calendar)
        XCTAssertTrue(calendar.isDate(second.due, inSameDayAs: date(3, 11)))
        XCTAssertEqual(calendar.component(.hour, from: second.due), 0)
    }

    func testStateRestoresAndNormalizes() throws {
        var state = LearningState(current: 100, speed: 100, records: [-1: ReviewRecord(due: Date()), 0: ReviewRecord(stage: 99, due: Date()), 43: ReviewRecord(due: Date())])
        state.normalize(count: 43)
        let restored = try JSONDecoder().decode(LearningState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.current, 42)
        XCTAssertEqual(restored.speed, 1)
        XCTAssertEqual(restored.records.count, 1)
        XCTAssertEqual(restored.records[0]?.stage, 4)
    }

    func testEveryPassageHasTwoDecodableOfflineClips() throws {
        let passages = try Passage.load()
        XCTAssertEqual(passages.count, 43)
        for passage in passages {
            for line in passage.lines.indices {
                let name = String(format: "%02d-%d", passage.id, line)
                let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "audio"))
                let player = try AVAudioPlayer(contentsOf: url)
                XCTAssertGreaterThan(player.duration, 0.3, name)
                XCTAssertTrue(player.prepareToPlay(), name)
            }
        }
    }

    @MainActor func testProgressPersistsAndResetClearsIt() throws {
        let name = "ChalisaTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = LearningStore(defaults: defaults)
        store.select(7)
        store.setSpeed(0.75)
        store.assess(success: true)
        let restored = LearningStore(defaults: defaults)
        XCTAssertEqual(restored.state.current, 7)
        XCTAssertEqual(restored.state.speed, 0.75)
        XCTAssertEqual(restored.recalledCount, 1)
        restored.reset()
        XCTAssertEqual(LearningStore(defaults: defaults).state.records.count, 0)
    }

    func testStreakCountsConsecutiveDaysAndAllowsTodayToBeOpen() {
        let days: Set<String> = ["2026-09-23", "2026-09-24", "2026-09-25"]
        XCTAssertEqual(Streak.length(days: days, now: date(9, 25), calendar: calendar), 3)
        XCTAssertEqual(Streak.length(days: days, now: date(9, 26), calendar: calendar), 3)
        XCTAssertEqual(Streak.length(days: days, now: date(9, 27), calendar: calendar), 0)
        XCTAssertEqual(Streak.length(days: days.union(["2026-09-26"]), now: date(9, 26), calendar: calendar), 4)
    }

    func testRemindersSkipPractisedTodayAndCountReviewsPerDay() throws {
        let passages = try Passage.load()
        let morning = calendar.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 8))!
        let state = LearningState(current: 4, records: [3: ReviewRecord(stage: 1, due: date(9, 28), recalled: true),
                                                        9: ReviewRecord(stage: 2, due: date(9, 28), recalled: true)])
        let plan = ReminderPlan.plan(state: state, passages: passages, practisedToday: false,
                                     hour: 19, minute: 30, now: morning, calendar: calendar, days: 3)
        XCTAssertEqual(plan.map(\.id), ["chalisa.daily.0", "chalisa.daily.1", "chalisa.daily.2"])
        XCTAssertEqual(plan[0].date.hour, 19)
        XCTAssertEqual(plan[0].date.minute, 30)
        XCTAssertTrue(plan[0].body.contains(passages[4].title))
        XCTAssertEqual(plan[2].body, "2 passages are ready to review. A few minutes is enough.")
        let practised = ReminderPlan.plan(state: state, passages: passages, practisedToday: true,
                                          hour: 19, minute: 30, now: morning, calendar: calendar, days: 3)
        XCTAssertEqual(practised.first?.id, "chalisa.daily.1")
        let evening = calendar.date(from: DateComponents(year: 2026, month: 9, day: 26, hour: 21))!
        XCTAssertEqual(ReminderPlan.plan(state: state, passages: passages, practisedToday: false,
                                         hour: 19, minute: 30, now: evening, calendar: calendar, days: 2).map(\.id), ["chalisa.daily.1"])
    }

    @MainActor func testPracticeDaysPersistWithoutChangingSavedProgressFormat() throws {
        let name = "ChalisaTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = LearningStore(defaults: defaults)
        store.assess(success: false)
        XCTAssertTrue(store.practisedToday)
        XCTAssertEqual(LearningStore(defaults: defaults).streak, 1)
        store.reset()
        XCTAssertEqual(LearningStore(defaults: defaults).streak, 0)
    }

    func testWidgetVerseOfTheDayWalksThroughAllPassagesInOrder() {
        let newYear = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 23))!
        XCTAssertEqual(DailyPassage.id(on: newYear, count: 43, calendar: calendar), 0)
        let ids = (0..<44).map { DailyPassage.id(on: calendar.date(byAdding: .day, value: $0, to: newYear)!, count: 43, calendar: calendar) }
        XCTAssertEqual(Array(ids.prefix(43)), Array(0..<43))
        XCTAssertEqual(ids[43], 0)
        let before = calendar.date(byAdding: .day, value: -1, to: newYear)!
        XCTAssertEqual(DailyPassage.id(on: before, count: 43, calendar: calendar), 42)
        // Same passage all day, across a daylight-saving change.
        XCTAssertEqual(DailyPassage.id(on: date(3, 8), count: 43, calendar: calendar),
                       DailyPassage.id(on: calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1))!, count: 43, calendar: calendar))
    }

    func testWidgetLinkOpensItsPassage() {
        XCTAssertEqual(DeepLink.passageID(from: DeepLink.url(passage: 17)), 17)
        XCTAssertNil(DeepLink.passageID(from: URL(string: "https://example.com/passage/3")!))
        XCTAssertNil(DeepLink.passageID(from: URL(string: "chalisa://settings/3")!))
        XCTAssertEqual(Passage.shortName(0), "D1")
        XCTAssertEqual(Passage.shortName(2), "1")
        XCTAssertEqual(Passage.shortName(42), "D3")
    }
}
