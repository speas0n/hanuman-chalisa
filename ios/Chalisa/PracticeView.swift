import SwiftUI

private enum PracticeMode: String, CaseIterable {
    case read = "Read", hints = "Hints", recall = "Recall"
    var instruction: String {
        switch self {
        case .read: "Listen, then say each line out loud."
        case .hints: "Fill in the missing words. Tap a gap for help."
        case .recall: "Say both lines from memory, then check."
        }
    }
}

struct PracticeView: View {
    @EnvironmentObject private var store: LearningStore
    @EnvironmentObject private var audio: PronunciationPlayer
    @State private var mode = PracticeMode.read
    @State private var revealed = Set<String>()
    @State private var showAnswer = false
    @State private var repeatThree = false
    @State private var result: Bool?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            if let passage = store.current {
                VStack(alignment: .leading, spacing: 24) {
                    if !typeSize.isAccessibilitySize {
                        HeroCard(streak: store.streak, recalled: store.recalledCount, total: store.passages.count)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        let titleLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8)) : AnyLayout(HStackLayout(alignment: .firstTextBaseline))
                        titleLayout {
                            Text(passage.title).font(.system(.title2, design: .serif).bold()).accessibilityIdentifier("passageTitle")
                            if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
                            Text("\(passage.id + 1) of \(store.passages.count)")
                                .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary).fixedSize()
                        }
                        if typeSize.isAccessibilitySize {
                            Picker("Practice mode", selection: $mode) {
                                ForEach(PracticeMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.menu).font(.headline).frame(minHeight: 44)
                            .accessibilityIdentifier("accessibleMode")
                        } else { Picker("Practice mode", selection: $mode) {
                            ForEach(PracticeMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented) }
                        Text(mode.instruction).font(.subheadline).foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        ForEach(passage.lines.indices, id: \.self) { line in
                            let playing = audio.isPlaying && audio.activeLine == line
                            if line > 0 { Divider().padding(.horizontal, 20) }
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("LINE \(line + 1)").font(.caption.weight(.semibold)).tracking(1.2)
                                        .foregroundStyle(playing ? Color("AccentColor") : .secondary)
                                        .accessibilityLabel("Line \(line + 1)")
                                    Spacer()
                                    Button {
                                        if audio.isPlaying && audio.activeLine == line { audio.stop() }
                                        else { audio.play(passage: passage, line: line, speed: store.state.speed, repeatThree: repeatThree) }
                                    } label: {
                                        Image(systemName: playing ? "speaker.wave.3.fill" : "speaker.wave.2")
                                            .font(.title3).frame(width: 44, height: 44)
                                            .symbolEffect(.variableColor.iterative, isActive: playing)
                                            .background(Color("AccentColor").opacity(playing ? 0.14 : 0.08), in: Circle())
                                    }
                                    .accessibilityLabel(audio.isPlaying && audio.activeLine == line ? "Stop audio" : "Listen to line \(line + 1)")
                                    .accessibilityIdentifier("listenLine\(line)")
                                }
                                if mode == .read || showAnswer {
                                    Text(passage.lines[line])
                                        .font(.system(.title2, design: .serif)).lineSpacing(6)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .accessibilityIdentifier("lineText\(line)")
                                } else {
                                    WordFlow(spacing: 6) {
                                        let words = passage.lines[line].split(separator: " ").map(String.init)
                                        ForEach(words.indices, id: \.self) { index in
                                            let key = "\(line)-\(index)"
                                            let visible = (mode == .hints && index.isMultiple(of: 2)) || revealed.contains(key)
                                            if visible {
                                                Text(words[index])
                                                    .font(.system(.title3, design: .serif))
                                                    .foregroundStyle(revealed.contains(key) ? Color("AccentColor") : .primary)
                                                    .frame(minWidth: 44, minHeight: 44)
                                                    .transition(.scale(scale: 0.6).combined(with: .opacity))
                                            } else {
                                                Button { withAnimation(.bouncy) { _ = revealed.insert(key) } } label: {
                                                    Text("•••")
                                                        .font(.system(.title3, design: .serif))
                                                        .foregroundStyle(Color("AccentColor"))
                                                        .padding(.horizontal, 10)
                                                        .frame(minWidth: 44, minHeight: 44)
                                                        .background(Color("AccentColor").opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                                                }
                                                .buttonStyle(.plain)
                                                .accessibilityLabel("Hidden word \(index + 1), line \(line + 1)")
                                                .accessibilityHint("Double-tap to reveal")
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20).padding(.bottom, 22).padding(.top, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(playing ? Color("AccentColor").opacity(0.07) : .clear)
                            .overlay(alignment: .leading) {
                                if playing {
                                    Capsule().fill(.saffronGlow).frame(width: 4).padding(.vertical, 14)
                                        .transition(.opacity)
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: playing)
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 12, y: 4)

                    VStack(spacing: 12) {
                        Button {
                            if audio.isPlaying { audio.stop() }
                            else { audio.play(passage: passage, speed: store.state.speed, repeatThree: repeatThree) }
                        } label: {
                            Label(audio.isPlaying ? "Stop listening" : "Listen to passage", systemImage: audio.isPlaying ? "stop.fill" : "play.fill")
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(GlowButtonStyle())
                        .accessibilityIdentifier("playPassage")
                        HStack {
                            Menu {
                                Picker("Playback speed", selection: Binding(get: { store.state.speed }, set: { store.setSpeed($0); audio.stop() })) {
                                    Text("Slow · 0.75×").tag(Float(0.75))
                                    Text("Normal · 1×").tag(Float(1))
                                    Text("Faster · 1.15×").tag(Float(1.15))
                                }
                            } label: {
                                Label("\(store.state.speed.formatted())×", systemImage: "speedometer").frame(minHeight: 44)
                            }
                            .accessibilityLabel("Playback speed, \(store.state.speed.formatted()) times")
                            Spacer()
                            Button { repeatThree.toggle(); audio.stop() } label: {
                                Label(repeatThree ? "Repeat 3× on" : "Repeat 3×", systemImage: "repeat")
                                    .frame(minHeight: 44)
                            }
                            .accessibilityValue(repeatThree ? "On" : "Off")
                            .tint(repeatThree ? Color("AccentColor") : .secondary)
                        }
                        .font(.subheadline)
                    }

                    assessment(passage)

                    HStack {
                        Button { store.select(passage.id - 1) } label: {
                            Label("Previous", systemImage: "chevron.left").frame(minHeight: 44)
                        }.disabled(passage.id == 0)
                        Spacer()
                        Button { store.select(passage.id + 1) } label: {
                            HStack { Text("Next"); Image(systemName: "chevron.right") }.frame(minHeight: 44)
                        }.disabled(passage.id == store.passages.count - 1)
                        .accessibilityIdentifier("nextPassage")
                    }.font(.subheadline)
                }
                .padding(20)
                .id(passage.id)
            }
        }
        .id(store.state.current)
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Practice")
        .onChange(of: store.state.current) { _, _ in resetPractice() }
        .onChange(of: mode) { _, _ in revealed = []; showAnswer = false; result = nil; audio.stop() }
    }

    @ViewBuilder private func assessment(_ passage: Passage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let result {
                HStack(spacing: 12) {
                    Image(systemName: result ? "checkmark.seal.fill" : "arrow.clockwise.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(result ? AnyShapeStyle(.saffronGlow) : AnyShapeStyle(Color.secondary))
                        .symbolEffect(.bounce, value: result)
                        .overlay { if result { CelebrationBurst() } }
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result ? "Remembered" : "Saved for more practice")
                            .font(.system(.title3, design: .serif).bold()).accessibilityIdentifier("assessmentResult")
                        if result, store.streak > 0 {
                            Text(store.streak == 1 ? "Streak started. See you tomorrow." : "\(store.streak)-day streak. Jai Hanuman!")
                                .font(.subheadline).foregroundStyle(Color("AccentColor"))
                        }
                    }
                }
                if let record = store.state.records[passage.id] {
                    Text(result ? "Review again \(record.due.formatted(date: .abbreviated, time: .omitted))." : "This passage is in your review list for today.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Button("Practise again") { resetPractice() }.frame(minHeight: 44)
            } else if mode == .recall && showAnswer {
                Text("How did you do?").font(.headline)
                Text("Be honest about how much you remembered before you saw the words.").font(.subheadline).foregroundStyle(.secondary)
                Button("I remembered it") { withAnimation(.snappy) { store.assess(success: true); result = true }; audio.stop() }
                    .buttonStyle(GlowButtonStyle())
                    .accessibilityIdentifier("remembered")
                Button("Need more practice") { withAnimation(.snappy) { store.assess(success: false); result = false }; audio.stop() }
                    .buttonStyle(.bordered).controlSize(.large)
                    .accessibilityIdentifier("needsPractice")
            } else {
                Button {
                    switch mode {
                    case .read: mode = .hints
                    case .hints: mode = .recall
                    case .recall: showAnswer = true
                    }
                } label: {
                    HStack {
                        Text(mode == .read ? "Try with hints" : mode == .hints ? "Try from memory" : "Reveal both lines")
                        Spacer()
                        Image(systemName: mode == .recall ? "eye" : "arrow.right")
                    }.frame(minHeight: 44)
                }
                .accessibilityIdentifier("practiceStep")
            }
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .sensoryFeedback(trigger: result) { _, new in new == true ? .success : new == false ? .warning : nil }
    }

    private func resetPractice() {
        mode = .read
        revealed = []
        showAnswer = false
        result = nil
        audio.stop()
    }
}

// Wrap words naturally while letting each hidden word remain an accessible control.
private struct WordFlow: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width ?? 300).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let layout = arrange(subviews, width: bounds.width)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + layout.points[index].x, y: bounds.minY + layout.points[index].y),
                          proposal: ProposedViewSize(width: min(subview.sizeThatFits(.unspecified).width, bounds.width), height: nil))
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (size: CGSize, points: [CGPoint]) {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var points: [CGPoint] = []
        for subview in subviews {
            let ideal = subview.sizeThatFits(.unspecified)
            let size = subview.sizeThatFits(ProposedViewSize(width: min(ideal.width, width), height: nil))
            if x > 0 && x + size.width > width { x = 0; y += rowHeight + spacing; rowHeight = 0 }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: y + rowHeight), points)
    }
}
