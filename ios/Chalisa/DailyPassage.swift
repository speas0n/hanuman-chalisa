import Foundation

// Shared with the widget extension, so it must not depend on app-only types.

/// The widget's "verse of the day": walks through the Chalisa in order, one passage per day.
enum DailyPassage {
    /// Day zero of the cycle. Any fixed date works; this one starts the cycle on the first doha.
    private static let epoch = DateComponents(year: 2026, month: 1, day: 1)

    static func id(on date: Date, count: Int, calendar: Calendar = .current) -> Int {
        guard count > 0, let start = calendar.date(from: epoch) else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start),
                                           to: calendar.startOfDay(for: date)).day ?? 0
        return ((days % count) + count) % count
    }
}

/// `chalisa://passage/<id>` opens the app on that passage.
enum DeepLink {
    static let scheme = "chalisa"

    static func url(passage id: Int) -> URL {
        URL(string: "\(scheme)://passage/\(id)")!
    }

    static func passageID(from url: URL) -> Int? {
        guard url.scheme == scheme, url.host == "passage" else { return nil }
        return Int(url.lastPathComponent)
    }
}
