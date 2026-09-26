import SwiftUI

extension Color {
    /// The deep navy behind the Hanuman artwork.
    static let night = Color(red: 0.055, green: 0.090, blue: 0.170)
    static let saffron = Color(red: 0.96, green: 0.52, blue: 0.16)
    static let marigold = Color(red: 1.0, green: 0.76, blue: 0.30)
    /// Deep enough for white text in both appearances.
    static let ember = Color(red: 0.72, green: 0.22, blue: 0.07)
}

extension ShapeStyle where Self == LinearGradient {
    static var saffronGlow: LinearGradient {
        LinearGradient(colors: [.marigold, .saffron, Color("AccentColor")], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    static var emberGlow: LinearGradient {
        LinearGradient(colors: [Color(red: 0.90, green: 0.40, blue: 0.10), .ember], startPoint: .leading, endPoint: .trailing)
    }
}

/// Artwork on navy, with the day's streak and overall progress.
struct HeroCard: View {
    let streak: Int
    let recalled: Int
    let total: Int

    var body: some View {
        ZStack(alignment: .leading) {
            Color.night
            RadialGradient(colors: [Color.saffron.opacity(0.35), .clear], center: .init(x: 0.85, y: 0.55), startRadius: 4, endRadius: 170)
            HStack {
                Spacer()
                Image("Hanuman").resizable().scaledToFit()
                    .frame(height: 180)
                    .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.35)], startPoint: .leading, endPoint: .trailing))
                    .offset(x: 26)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("श्री हनुमान चालीसा")
                    .font(.caption.weight(.semibold)).foregroundStyle(Color.marigold)
                    .accessibilityHidden(true)
                Text("Hanuman\nChalisa")
                    .font(.system(.title, design: .serif).bold()).foregroundStyle(.white)
                    .lineSpacing(-4).shadow(color: .night, radius: 8)
                HStack(spacing: 8) {
                    StatPill(symbol: "flame.fill", text: streak == 1 ? "1 day" : "\(streak) days", active: streak > 0)
                        .accessibilityLabel("Streak, \(streak) days")
                    StatPill(symbol: "checkmark.seal.fill", text: "\(recalled)/\(total)", active: recalled > 0)
                        .accessibilityLabel("\(recalled) of \(total) passages recalled")
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Color.marigold.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.night.opacity(0.35), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }
}

struct StatPill: View {
    let symbol: String
    let text: String
    let active: Bool

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .foregroundStyle(active ? AnyShapeStyle(.saffronGlow) : AnyShapeStyle(Color.white.opacity(0.5)))
                .symbolEffect(.bounce, value: text)
            Text(text).monospacedDigit().contentTransition(.numericText())
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(.white.opacity(0.12), in: Capsule())
    }
}

struct GlowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(.emberGlow, in: Capsule())
            .shadow(color: Color.saffron.opacity(configuration.isPressed ? 0.2 : 0.45), radius: configuration.isPressed ? 6 : 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct ProgressRing: View {
    let value: Double
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle().stroke(Color.saffron.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, value)))
                .stroke(AngularGradient(colors: [Color("AccentColor"), .saffron, .marigold], center: .center, startAngle: .degrees(0), endAngle: .degrees(360 * max(0.001, value))),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.saffron.opacity(0.5), radius: 6)
        }
        .animation(.spring(duration: 0.9), value: value)
    }
}

/// Every passage as a tile, brighter the longer you have held it in memory.
struct MasteryGrid: View {
    @EnvironmentObject private var store: LearningStore
    let practise: () -> Void

    static func shortName(_ id: Int) -> String {
        id < 2 ? "D\(id + 1)" : id == 42 ? "D3" : "\(id - 1)"
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
            ForEach(store.passages) { passage in
                let record = store.state.records[passage.id]
                let level = record.map { $0.recalled ? Double($0.stage + 1) / 5 : 0.12 } ?? 0
                Button {
                    store.select(passage.id)
                    practise()
                } label: {
                    Text(Self.shortName(passage.id))
                        .font(.caption2.weight(.bold)).monospacedDigit()
                        .lineLimit(1).minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .foregroundStyle(level > 0.5 ? .white : .secondary)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(level == 0 ? AnyShapeStyle(Color.secondary.opacity(0.12)) : AnyShapeStyle(.saffronGlow.opacity(0.25 + level * 0.75)))
                        }
                        .overlay {
                            if store.dueIDs.contains(passage.id) {
                                RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color("AccentColor"), lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(passage.title), \(record == nil ? "not started" : record!.recalled ? "recalled, level \(record!.stage) of 4" : "practising")\(store.dueIDs.contains(passage.id) ? ", ready to review" : "")")
            }
        }
    }
}

/// A short burst of marigold sparks for a successful recall.
struct CelebrationBurst: View {
    @State private var fired = false
    private let sparks = (0..<18).map { index in
        (angle: Double(index) / 18 * 2 * .pi + Double.random(in: -0.15...0.15),
         distance: CGFloat.random(in: 50...95),
         size: CGFloat.random(in: 5...9),
         color: [Color.marigold, .saffron, Color("AccentColor")][index % 3])
    }

    var body: some View {
        ZStack {
            ForEach(sparks.indices, id: \.self) { index in
                let spark = sparks[index]
                Capsule()
                    .fill(spark.color)
                    .frame(width: spark.size, height: spark.size * 2.2)
                    .rotationEffect(.radians(spark.angle + .pi / 2))
                    .offset(x: fired ? cos(spark.angle) * spark.distance : 0,
                            y: fired ? sin(spark.angle) * spark.distance : 0)
                    .opacity(fired ? 0 : 1)
                    .scaleEffect(fired ? 0.4 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { withAnimation(.easeOut(duration: 0.9)) { fired = true } }
    }
}
