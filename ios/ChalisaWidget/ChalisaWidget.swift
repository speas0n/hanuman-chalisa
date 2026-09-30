import SwiftUI
import WidgetKit

@main
struct ChalisaWidgetBundle: WidgetBundle {
    var body: some Widget { VerseOfTheDayWidget() }
}

struct VerseOfTheDayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VerseOfTheDay", provider: VerseProvider()) { entry in
            VerseWidgetView(entry: entry)
        }
        .configurationDisplayName("Verse of the Day")
        .description("One passage of the Hanuman Chalisa each day, in order. Tap to practise it.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge,
                            .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

// MARK: - Timeline

struct VerseEntry: TimelineEntry {
    let date: Date
    let passage: Passage
    let total: Int
}

struct VerseProvider: TimelineProvider {
    static let sample = Passage(id: 2, title: "Verse 1", lines: ["Jai Hanuman gyaan gun saagar", "Jai Kapees tihun lok ujaagar"])
    private let passages = (try? Passage.load()) ?? []

    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: Date(), passage: Self.sample, total: 43)
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(entry(for: Date()))
    }

    /// A week of entries, one per midnight. WidgetKit asks for more after the last one.
    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        completion(Timeline(entries: days.map(entry(for:)), policy: .atEnd))
    }

    func entry(for date: Date) -> VerseEntry {
        guard !passages.isEmpty else { return VerseEntry(date: date, passage: Self.sample, total: 43) }
        return VerseEntry(date: date, passage: passages[DailyPassage.id(on: date, count: passages.count)], total: passages.count)
    }
}

// MARK: - Views

struct VerseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VerseEntry

    var body: some View {
        VerseWidgetContent(family: family, passage: entry.passage, total: entry.total)
            .containerBackground(for: .widget) {
                switch family {
                case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge: VerseBackdrop(family: family)
                case .accessoryCircular: AccessoryWidgetBackground()
                default: Color.clear
                }
            }
            .widgetURL(DeepLink.url(passage: entry.passage.id))
    }
}

/// Everything in front of the backdrop. Takes the family as a value so it can be rendered outside WidgetKit.
struct VerseWidgetContent: View {
    let family: WidgetFamily
    let passage: Passage
    let total: Int

    var body: some View {
        switch family {
        case .accessoryInline: inline
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .systemSmall: small
        case .systemLarge: large
        default: medium
        }
    }

    // MARK: Home Screen

    private var small: some View {
        VStack(alignment: .leading, spacing: 3) {
            Spacer(minLength: 0)
            eyebrow
            title(.system(.title3, design: .serif).bold())
            Text(passage.lines[0])
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(3).minimumScaleFactor(0.85)
            ProgressLine(value: Double(passage.id + 1) / Double(total)).padding(.top, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 4) {
            eyebrow
            title(.system(.title2, design: .serif).bold())
            lines(.system(.footnote, design: .serif), spacing: 3)
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                ProgressLine(value: Double(passage.id + 1) / Double(total))
                counter
            }
        }
        .frame(maxWidth: 206, maxHeight: .infinity, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                eyebrow
                Spacer()
                Text("VERSE OF THE DAY")
                    .font(.caption2.weight(.bold)).tracking(1.2)
                    .foregroundStyle(.white.opacity(0.55))
            }
            Spacer(minLength: 0)
            title(.system(.title, design: .serif).bold())
            lines(.system(.callout, design: .serif), spacing: 5)
            ChalisaTrack(current: passage.id, total: total).padding(.top, 6)
            HStack {
                counter
                Spacer()
                Label("Practise", systemImage: "sparkles")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.emberGlow, in: Capsule())
                    .shadow(color: Color.saffron.opacity(0.45), radius: 8, y: 3)
            }
        }
    }

    private var eyebrow: some View {
        Text("श्री हनुमान चालीसा")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color.marigold)
            .widgetAccentable()
            .accessibilityHidden(true)
    }

    private func title(_ font: Font) -> some View {
        Text(passage.title)
            .font(font)
            .foregroundStyle(.white)
            .lineLimit(1).minimumScaleFactor(0.7)
            .shadow(color: .night, radius: 6)
            .widgetAccentable()
    }

    private func lines(_ font: Font, spacing: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(passage.lines, id: \.self) { line in
                Text(line)
                    .font(font)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(2).minimumScaleFactor(0.75)
            }
        }
        .shadow(color: .night, radius: 4)
    }

    private var counter: some View {
        Text("\(passage.id + 1) of \(total)")
            .font(.caption2.weight(.semibold)).monospacedDigit()
            .foregroundStyle(.white.opacity(0.6))
    }

    // MARK: Lock Screen

    private var inline: some View {
        Label("\(passage.title) · \(passage.lines[0])", systemImage: "sparkles")
    }

    private var circular: some View {
        Gauge(value: Double(passage.id + 1), in: 1...Double(total)) {
            Text("Chalisa")
        } currentValueLabel: {
            Text(Passage.shortName(passage.id))
                .font(.system(.title3, design: .serif).bold())
        }
        .gaugeStyle(.accessoryCircular)
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label(passage.title, systemImage: "sparkles")
                .font(.caption.weight(.bold))
                .widgetAccentable()
            Text(passage.lines[0])
                .font(.system(.footnote, design: .serif))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Navy with a saffron glow and the Hanuman artwork, placed differently for each size.
struct VerseBackdrop: View {
    let family: WidgetFamily

    var body: some View {
        ZStack {
            Color.night
            switch family {
            case .systemSmall:
                glow(center: glowCenter, radius: glowRadius)
                art(height: 168)
                    .mask(fade(from: .trailing, clearAt: 0.95))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .offset(x: 34)
                readability(from: 0.35)
            case .systemLarge, .systemExtraLarge:
                glow(center: glowCenter, radius: glowRadius)
                art(height: 256)
                    .mask(fade(from: .top, clearAt: 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .offset(x: 62, y: 34)
                readability(from: 0.42)
            default:
                glow(center: glowCenter, radius: glowRadius)
                art(height: 168)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .offset(x: -6)
            }
            ContainerRelativeShape()
                .strokeBorder(Color.marigold.opacity(0.22), lineWidth: 1)
        }
    }

    private var glowCenter: UnitPoint {
        switch family {
        case .systemSmall: UnitPoint(x: 0.8, y: 0.35)
        case .systemLarge, .systemExtraLarge: UnitPoint(x: 0.67, y: 0.28)
        default: UnitPoint(x: 0.82, y: 0.4)
        }
    }

    private var glowRadius: CGFloat {
        switch family {
        case .systemSmall: 120
        case .systemLarge, .systemExtraLarge: 230
        default: 170
        }
    }

    private func glow(center: UnitPoint, radius: CGFloat) -> some View {
        RadialGradient(colors: [Color.saffron.opacity(0.5), .clear], center: center, startRadius: 2, endRadius: radius)
    }

    private func art(height: CGFloat) -> some View {
        // Transparent cutout, so the glow shows through around the figure.
        Image("HanumanLeap")
            .resizable()
            .desaturatedWhenTinted()
            .scaledToFit()
            .frame(height: height)
            .shadow(color: Color.night.opacity(0.6), radius: 10)
            .accessibilityHidden(true)
    }

    /// Opaque at `edge`, fading to clear `clearAt` of the way across.
    private func fade(from edge: UnitPoint, clearAt: CGFloat) -> LinearGradient {
        let end = UnitPoint(x: 1 - edge.x, y: 1 - edge.y)
        return LinearGradient(stops: [.init(color: .black, location: 0.45 * clearAt), .init(color: .clear, location: clearAt)],
                              startPoint: edge, endPoint: end)
    }

    /// Darkens the lower part, where the text sits.
    private func readability(from start: CGFloat) -> some View {
        LinearGradient(stops: [.init(color: .night.opacity(0), location: start), .init(color: .night.opacity(0.9), location: 1)],
                       startPoint: .top, endPoint: .bottom)
    }
}

private extension Image {
    @ViewBuilder func desaturatedWhenTinted() -> some View {
        if #available(iOS 18.0, *) {
            self.widgetAccentedRenderingMode(.desaturated)
        } else {
            self
        }
    }
}

/// How far through the 43 passages today's is.
struct ProgressLine: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule().fill(.saffronGlow)
                    .frame(width: max(5, geo.size.width * min(1, value)))
                    .shadow(color: Color.saffron.opacity(0.6), radius: 4)
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}

/// One tick per passage: done ones glow saffron, today's stands tall in marigold.
struct ChalisaTrack: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AnyShapeStyle(Color.marigold)
                          : index < current ? AnyShapeStyle(Color.saffron.opacity(0.75))
                          : AnyShapeStyle(Color.white.opacity(0.16)))
                    .frame(maxWidth: .infinity)
                    .frame(height: index == current ? 16 : 8)
                    .shadow(color: index == current ? Color.marigold.opacity(0.8) : .clear, radius: 5)
            }
        }
        .frame(height: 16)
        .accessibilityHidden(true)
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) { VerseOfTheDayWidget() } timeline: {
    VerseEntry(date: .now, passage: VerseProvider.sample, total: 43)
}

#Preview("Medium", as: .systemMedium) { VerseOfTheDayWidget() } timeline: {
    VerseEntry(date: .now, passage: VerseProvider.sample, total: 43)
}

#Preview("Large", as: .systemLarge) { VerseOfTheDayWidget() } timeline: {
    VerseEntry(date: .now, passage: VerseProvider.sample, total: 43)
}

#Preview("Lock Screen", as: .accessoryRectangular) { VerseOfTheDayWidget() } timeline: {
    VerseEntry(date: .now, passage: VerseProvider.sample, total: 43)
}
