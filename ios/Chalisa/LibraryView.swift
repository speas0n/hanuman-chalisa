import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: LearningStore
    @State private var search = ""
    let practise: () -> Void
    private var filtered: [Passage] {
        store.passages.filter { search.isEmpty || ($0.title + " " + $0.lines.joined(separator: " ")).localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            Section {
                Text("Two opening dohas, 40 verses, and a closing doha. Choose any passage to practise.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(["Opening dohas", "Chalisa", "Closing doha"], id: \.self) { section in
                let group = filtered.filter { section == "Opening dohas" ? $0.id < 2 : section == "Chalisa" ? (2..<42).contains($0.id) : $0.id == 42 }
                if !group.isEmpty {
                    Section(section) {
                        ForEach(group) { passage in
                            Button {
                                store.select(passage.id)
                                practise()
                            } label: {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(passage.title).font(.headline).foregroundStyle(.primary)
                                        Text(passage.lines[0]).font(.subheadline).foregroundStyle(.secondary)
                                            .lineLimit(2)
                                        if store.dueIDs.contains(passage.id) {
                                            Text("Ready to review").font(.caption).foregroundStyle(Color("AccentColor"))
                                        }
                                    }
                                    Spacer(minLength: 0)
                                    if store.state.records[passage.id]?.recalled == true {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color("AccentColor"))
                                            .accessibilityLabel("Recalled before")
                                    }
                                    Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                                }.padding(.vertical, 6).frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("passage\(passage.id)")
                        }
                    }
                }
            }
        }
        .overlay {
            if filtered.isEmpty { ContentUnavailableView.search(text: search) }
        }
        .searchable(text: $search, prompt: "Find a verse or word")
        .navigationTitle("Library")
    }
}

struct ProgressViewScreen: View {
    @EnvironmentObject private var store: LearningStore
    @State private var showAbout = false
    @State private var confirmReset = false
    let practise: () -> Void

    var body: some View {
        List {
            Section {
                VStack(spacing: 18) {
                    HStack(spacing: 22) {
                        ZStack {
                            ProgressRing(value: Double(store.recalledCount) / 43)
                            VStack(spacing: 0) {
                                Text("\(store.recalledCount)")
                                    .font(.system(size: 40, weight: .bold, design: .serif)).monospacedDigit()
                                    .contentTransition(.numericText())
                                Text("of 43 recalled").font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 132, height: 132)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Passages recalled").accessibilityValue("\(store.recalledCount) of 43")
                        VStack(alignment: .leading, spacing: 14) {
                            statRow(symbol: "flame.fill", value: "\(store.streak)", label: "day streak")
                            statRow(symbol: "clock.arrow.circlepath", value: "\(store.dueIDs.count)", label: "to review")
                            statRow(symbol: "book.pages", value: "\(store.state.records.count)", label: "tried")
                        }
                    }
                    Text(store.practisedToday ? "You’ve practised today. Beautiful." : "Each passage you remember is a step forward. Regular reviews help it stay with you.")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.padding(.vertical, 10)
            }
            Section {
                MasteryGrid(practise: practise).padding(.vertical, 6)
            } header: {
                Text("All 43 passages")
            } footer: {
                Text("Brighter tiles are held longer in memory. An outlined tile is ready to review. Tap any tile to practise it.")
            }
            ReminderSection()
            if let next = store.state.records.values.map(\.due).filter({ $0 > Date() }).min(), store.dueIDs.isEmpty {
                Section { LabeledContent("Next review", value: next.formatted(date: .abbreviated, time: .omitted)) }
            }
            Section("Ready to review") {
                if store.dueIDs.isEmpty {
                    Label(store.state.records.isEmpty ? "Your reviews will appear here" : "You're up to date", systemImage: store.state.records.isEmpty ? "calendar" : "checkmark.circle")
                    Text(store.state.records.isEmpty ? "Try recalling a passage and choose how it went to start your review list." : "Keep learning, or come back for your next review.")
                        .font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(store.dueIDs, id: \.self) { id in
                        Button {
                            store.select(id)
                            practise()
                        } label: {
                            HStack {
                                Text(store.passages[id].title)
                                Spacer()
                                Image(systemName: "arrow.right")
                            }.frame(minHeight: 44)
                        }
                    }
                }
            }
            Section {
                Button("Continue practising") { practise() }.frame(minHeight: 44)
            } footer: {
                Text("Progress is saved only on this iPhone. Website progress is separate.")
            }
        }
        .navigationTitle("Progress")
        .animation(.snappy, value: store.revision)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAbout = true } label: { Image(systemName: "gearshape") }
                    .accessibilityLabel("Settings and about")
            }
        }
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                List {
                    Section("Learning") {
                        Text("Read aloud, try with hints, then recall both lines. Reveal the words and choose how it went.")
                        Text("Successful recalls on different days space your reviews 1, 3, 7, then 14 days apart. A difficult passage returns to today's list.")
                    }
                    Section("Pronunciation") {
                        Text("All 86 recordings work offline. These are synthetic Hindi reading guides, not a traditional sung recitation. Some pronunciations may differ from a fluent reciter.")
                        Text("Audio uses Kokoro-82M v1.0 (Apache 2.0), voice hm_omega. Headphones can help you hear each word clearly.")
                    }
                    Section("Text and privacy") {
                        Text("Traditional Hanuman Chalisa by Tulsidas, in simple English letters. The devotional illustration was generated with AI.")
                        Text("No sign-in, tracking, or internet connection is required. Removing the app also removes its saved progress.")
                        Link("Text reference", destination: URL(string: "https://www.indiapress.org/salasar/Chalisa.pdf")!)
                        Link("Audio model and license", destination: URL(string: "https://huggingface.co/hexgrad/Kokoro-82M")!)
                    }
                    Section {
                        Button("Reset all progress", role: .destructive) { confirmReset = true }
                    }
                }
                .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showAbout = false } } }
                .confirmationDialog("Reset all learning progress?", isPresented: $confirmReset, titleVisibility: .visible) {
                    Button("Reset progress", role: .destructive) { store.reset() }
                } message: { Text("Your saved recalls and review dates will be erased. This cannot be undone.") }
            }
        }
    }

    private func statRow(symbol: String, value: String, label: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.body.weight(.semibold)).foregroundStyle(.saffronGlow).frame(width: 24)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.system(.title3, design: .rounded).bold()).monospacedDigit().contentTransition(.numericText())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
