import Foundation

struct Passage: Codable, Identifiable {
    let id: Int
    let title: String
    let lines: [String]

    static func load(bundle: Bundle = .main) throws -> [Passage] {
        guard let url = bundle.url(forResource: "verses", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let passages = try JSONDecoder().decode([Passage].self, from: Data(contentsOf: url))
        guard passages.count == 43,
              passages.enumerated().allSatisfy({ $0.offset == $0.element.id && $0.element.lines.count == 2 }) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return passages
    }
}

struct ReviewRecord: Codable {
    var stage = 0
    var due: Date
    var lastSuccess: Date?
    var recalled = false

    func assessed(success: Bool, now: Date, calendar: Calendar = .current) -> Self {
        let today = calendar.startOfDay(for: now)
        let alreadySucceeded = lastSuccess.map { calendar.isDate($0, inSameDayAs: now) } ?? false
        let nextStage = success ? min(4, max(0, stage) + (alreadySucceeded ? 0 : 1)) : 0
        let interval = success ? [1, 1, 3, 7, 14][nextStage] : 0
        return Self(stage: nextStage,
                    due: calendar.date(byAdding: .day, value: interval, to: today) ?? today,
                    lastSuccess: success ? today : lastSuccess,
                    recalled: recalled || success)
    }
}

struct LearningState: Codable {
    var current = 0
    var speed: Float = 1
    var records: [Int: ReviewRecord] = [:]

    mutating func normalize(count: Int) {
        current = min(max(0, current), max(0, count - 1))
        if ![Float(0.75), 1, 1.15].contains(speed) { speed = 1 }
        records = records.filter { (0..<count).contains($0.key) }
        for id in Array(records.keys) {
            let stage = min(4, max(0, records[id]!.stage))
            records[id]?.stage = stage
        }
    }

    func dueIDs(now: Date = Date(), calendar: Calendar = .current) -> [Int] {
        let today = calendar.startOfDay(for: now)
        return records.filter { calendar.startOfDay(for: $0.value.due) <= today }.keys.sorted()
    }
}

enum Streak {
    static func key(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    /// Consecutive practice days ending today, or yesterday if today is still open.
    static func length(days: Set<String>, now: Date = Date(), calendar: Calendar = .current) -> Int {
        var day = calendar.startOfDay(for: now)
        if !days.contains(key(day, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var count = 0
        while days.contains(key(day, calendar: calendar)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}
