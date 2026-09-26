import SwiftUI

@MainActor
final class LearningStore: ObservableObject {
    @Published private(set) var state: LearningState
    /// Days with at least one self-assessment, kept apart from `state` so older saves still decode.
    @Published private(set) var practiceDays: Set<String>
    /// Bumped on every save, so reminders can be rescheduled with fresh review counts.
    @Published private(set) var revision = 0
    let passages: [Passage]
    let loadError: String?
    private let defaults: UserDefaults
    private let key = "chalisa.learning.v1"
    private let daysKey = "chalisa.days.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        do {
            passages = try Passage.load()
            loadError = nil
        } catch {
            passages = []
            loadError = "The passages could not be opened. Please reinstall the app from Xcode."
        }
        var saved = defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(LearningState.self, from: $0) } ?? LearningState()
        saved.normalize(count: passages.count)
        state = saved
        practiceDays = Set(defaults.stringArray(forKey: daysKey) ?? [])
    }

    var current: Passage? { passages.indices.contains(state.current) ? passages[state.current] : nil }
    var recalledCount: Int { state.records.values.filter(\.recalled).count }
    var dueIDs: [Int] { state.dueIDs() }
    var streak: Int { Streak.length(days: practiceDays) }
    var practisedToday: Bool { practiceDays.contains(Streak.key(Date())) }

    func refreshReviews() { objectWillChange.send() }

    func select(_ id: Int) {
        guard passages.indices.contains(id) else { return }
        state.current = id
        save()
    }

    func setSpeed(_ speed: Float) { state.speed = speed; save() }

    func assess(success: Bool, now: Date = Date()) {
        let id = state.current
        state.records[id] = (state.records[id] ?? ReviewRecord(due: now)).assessed(success: success, now: now)
        practiceDays.insert(Streak.key(now))
        defaults.set(Array(practiceDays).sorted(), forKey: daysKey)
        save()
    }

    func reset() {
        state = LearningState()
        practiceDays = []
        defaults.removeObject(forKey: daysKey)
        save()
    }

    private func save() {
        revision += 1
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: key) }
    }
}
