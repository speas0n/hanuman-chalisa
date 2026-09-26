import SwiftUI
import UserNotifications

struct PlannedReminder: Equatable {
    let id: String
    let date: DateComponents
    let body: String
}

enum ReminderPlan {
    static let prefix = "chalisa.daily."

    /// One notification per day, so each can say what is actually waiting that day.
    /// Today's reminder is skipped once you have practised.
    static func plan(state: LearningState, passages: [Passage], practisedToday: Bool,
                     hour: Int, minute: Int, now: Date = Date(),
                     calendar: Calendar = .current, days: Int = 30) -> [PlannedReminder] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).compactMap { offset in
            guard !(offset == 0 && practisedToday),
                  let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fire > now else { return nil }
            let due = state.dueIDs(now: day, calendar: calendar).count
            let body: String
            if due > 0 {
                body = due == 1 ? "1 passage is ready to review. A few minutes is enough."
                                : "\(due) passages are ready to review. A few minutes is enough."
            } else if passages.indices.contains(state.current) {
                let passage = passages[state.current]
                body = "Continue with \(passage.title): “\(passage.lines[0])…”"
            } else {
                body = "A little practice, every day."
            }
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            return PlannedReminder(id: prefix + String(offset), date: parts, body: body)
        }
    }
}

@MainActor
final class ReminderScheduler: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderScheduler()
    @Published private(set) var enabled: Bool
    @Published private(set) var time: Date
    @Published private(set) var denied = false
    /// Changes when a reminder is tapped, so the app can open the right passage.
    @Published private(set) var openedAt: Date?
    private let defaults: UserDefaults
    private let center = UNUserNotificationCenter.current()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        enabled = defaults.bool(forKey: "chalisa.reminder.enabled")
        let minutes = defaults.object(forKey: "chalisa.reminder.minutes") as? Int ?? 19 * 60
        time = Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: Date()) ?? Date()
        super.init()
        center.delegate = self
    }

    private var hourMinute: (Int, Int) {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        return (parts.hour ?? 19, parts.minute ?? 0)
    }

    func setEnabled(_ on: Bool, store: LearningStore) async {
        guard on else {
            enabled = false
            defaults.set(false, forKey: "chalisa.reminder.enabled")
            await reschedule(store: store)
            return
        }
        let settings = await center.notificationSettings()
        var allowed = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
        if settings.authorizationStatus == .notDetermined {
            allowed = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        }
        denied = !allowed
        enabled = allowed
        defaults.set(allowed, forKey: "chalisa.reminder.enabled")
        await reschedule(store: store)
    }

    func setTime(_ date: Date, store: LearningStore) async {
        time = date
        let (hour, minute) = hourMinute
        defaults.set(hour * 60 + minute, forKey: "chalisa.reminder.minutes")
        await reschedule(store: store)
    }

    /// Called on launch, on returning to the app, and after each practice.
    func reschedule(store: LearningStore) async {
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(ReminderPlan.prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        guard enabled else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus != .denied else { denied = true; return }
        denied = false
        let (hour, minute) = hourMinute
        for reminder in ReminderPlan.plan(state: store.state, passages: store.passages,
                                          practisedToday: store.practisedToday, hour: hour, minute: minute) {
            let content = UNMutableNotificationContent()
            content.title = "Hanuman Chalisa"
            content.body = reminder.body
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.date, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }

    // Completion-handler forms on purpose: the async forms finish on a background
    // thread, and UIKit aborts the app when a notification tap completes off the main thread.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        DispatchQueue.main.async {
            MainActor.assumeIsolated { self.openedAt = Date() }
            completionHandler()
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        DispatchQueue.main.async { completionHandler([.banner, .sound]) }
    }
}

struct ReminderSection: View {
    @EnvironmentObject private var store: LearningStore
    @EnvironmentObject private var reminders: ReminderScheduler
    @Environment(\.openURL) private var openURL

    var body: some View {
        Section {
            Toggle(isOn: Binding(get: { reminders.enabled }, set: { on in Task { await reminders.setEnabled(on, store: store) } })) {
                Label("Daily reminder", systemImage: "bell.badge")
            }
            .accessibilityIdentifier("reminderToggle")
            if reminders.enabled {
                DatePicker(selection: Binding(get: { reminders.time }, set: { date in Task { await reminders.setTime(date, store: store) } }),
                           displayedComponents: .hourAndMinute) {
                    Label("Time", systemImage: "clock")
                }
            }
            if reminders.denied {
                Button("Allow notifications in Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
        } header: {
            Text("Reminder")
        } footer: {
            Text(reminders.denied
                 ? "Notifications are turned off for Chalisa. Turn them on in Settings, then switch the reminder on again."
                 : "One gentle nudge a day. It tells you how many passages are ready to review, and skips a day once you’ve practised.")
        }
    }
}
