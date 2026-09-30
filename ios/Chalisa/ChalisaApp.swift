import SwiftUI

@main
struct ChalisaApp: App {
    @StateObject private var store = LearningStore()
    @StateObject private var audio = PronunciationPlayer()
    // Created with the app, not lazily with the first view, so the notification
    // delegate is in place before iOS delivers a tap that launched the app.
    @ObservedObject private var reminders = ReminderScheduler.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let serif = { (style: UIFont.TextStyle) -> UIFont in
            let base = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
            let descriptor = base.withDesign(.serif)?.withSymbolicTraits(.traitBold) ?? base
            return UIFont(descriptor: descriptor, size: 0)
        }
        UINavigationBar.appearance().largeTitleTextAttributes = [.font: serif(.largeTitle)]
        UINavigationBar.appearance().titleTextAttributes = [.font: serif(.headline)]
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(audio)
                .environmentObject(reminders)
                .tint(Color("AccentColor"))
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { audio.stop() }
                    else {
                        store.refreshReviews()
                        Task { await reminders.reschedule(store: store) }
                    }
                }
                .onChange(of: store.revision) { _, _ in Task { await reminders.reschedule(store: store) } }
        }
    }
}

enum AppTab: Hashable { case practice, read, library, progress }

struct RootView: View {
    @EnvironmentObject private var store: LearningStore
    @EnvironmentObject private var audio: PronunciationPlayer
    @EnvironmentObject private var reminders: ReminderScheduler
    @State private var tab = AppTab.practice

    var body: some View {
        if let error = store.loadError {
            ContentUnavailableView("Unable to open Chalisa", systemImage: "book.closed", description: Text(error))
        } else {
            TabView(selection: $tab) {
                NavigationStack { PracticeView() }
                    .tabItem { Label("Practice", systemImage: "sparkles") }.tag(AppTab.practice)
                NavigationStack { ReadView { tab = .practice } }
                    .tabItem { Label("Read", systemImage: "book") }.tag(AppTab.read)
                NavigationStack { LibraryView { tab = .practice } }
                    .tabItem { Label("Library", systemImage: "books.vertical") }.tag(AppTab.library)
                NavigationStack { ProgressViewScreen { tab = .practice } }
                    .tabItem { Label("Progress", systemImage: "flame") }.tag(AppTab.progress)
            }
            .onChange(of: tab) { _, _ in audio.stop() }
            .onChange(of: reminders.openedAt) { _, _ in
                // Opening a reminder goes straight to the first passage waiting for review.
                if let first = store.dueIDs.first { store.select(first) }
                tab = .practice
            }
            .onOpenURL { url in
                // Tapping the widget opens the passage it is showing.
                guard let id = DeepLink.passageID(from: url) else { return }
                store.select(id)
                tab = .practice
            }
            .onChange(of: store.state.current) { _, _ in audio.stop() }
            .alert("Audio unavailable", isPresented: Binding(get: { audio.error != nil }, set: { if !$0 { audio.error = nil } })) {
                Button("OK", role: .cancel) { audio.error = nil }
            } message: { Text(audio.error ?? "") }
        }
    }
}
