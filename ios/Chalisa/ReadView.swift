import SwiftUI

/// The whole Chalisa on one calm page, top to bottom.
struct ReadView: View {
    @EnvironmentObject private var store: LearningStore
    let practise: () -> Void

    private static let recording = URL(string: "https://music.youtube.com/watch?v=MeCHQb9nKhg")!

    var body: some View {
        List {
            Section {
                Link(destination: Self.recording) {
                    HStack(spacing: 14) {
                        Image(systemName: "play.circle.fill")
                            .font(.title)
                            .foregroundStyle(.saffronGlow)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Listen").font(.caption.weight(.semibold)).textCase(.uppercase).tracking(1.2)
                                .foregroundStyle(.secondary)
                            Text("Hanuman Chalisa (Lofi)").font(.headline).foregroundStyle(.primary)
                            Text("Rasraj Ji Maharaj").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 6).frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens in YouTube Music")
                .accessibilityIdentifier("listenLink")
            } footer: {
                Text("Opens in YouTube Music. The recording is not stored in this app.")
            }

            ForEach(["Opening dohas", "Chalisa", "Closing doha"], id: \.self) { section in
                let group = store.passages.filter { section == "Opening dohas" ? $0.id < 2 : section == "Chalisa" ? (2..<42).contains($0.id) : $0.id == 42 }
                Section(section) {
                    ForEach(group) { passage in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Passage.shortName(passage.id))
                                .font(.caption.weight(.semibold)).textCase(.uppercase).tracking(1.2)
                                .foregroundStyle(Color("AccentColor"))
                                .accessibilityLabel(passage.title)
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(passage.lines, id: \.self) { line in
                                    Text(line)
                                }
                            }
                            .font(.system(.title3, design: .serif))
                            .lineSpacing(6)
                            .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("read\(passage.id)")
                        .contextMenu {
                            Button {
                                store.select(passage.id)
                                practise()
                            } label: {
                                Label("Practise this passage", systemImage: "sparkles")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Read")
    }
}
