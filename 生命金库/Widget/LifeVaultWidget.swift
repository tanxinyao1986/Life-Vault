import WidgetKit
import SwiftUI

struct LifeVaultWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct LifeVaultWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LifeVaultWidgetEntry {
        LifeVaultWidgetEntry(date: Date(), data: placeholderData())
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeVaultWidgetEntry) -> Void) {
        completion(LifeVaultWidgetEntry(date: Date(), data: loadData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeVaultWidgetEntry>) -> Void) {
        let entry = LifeVaultWidgetEntry(date: Date(), data: loadData())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func loadData() -> WidgetData {
        WidgetDataStore.read() ?? placeholderData()
    }

    private func placeholderData() -> WidgetData {
        WidgetData(
            updatedAt: Date(),
            todayCount: 1,
            streakDays: 7,
            totalCount: 172,
            lastFavorite: String(localized: "宇宙看见了你的努力"),
            pouchCounts: ["career": 6, "love": 60, "growth": 111]
        )
    }
}

struct LifeVaultWidgetView: View {
    let entry: LifeVaultWidgetEntry
    @Environment(\.widgetFamily) private var family

    private var hour: Int { Calendar.current.component(.hour, from: entry.date) }
    private var isFresh: Bool { entry.date.timeIntervalSince(entry.data.updatedAt) < 12 * 60 }

    var body: some View {
        ZStack {
            widgetBackground

            switch family {
            case .systemSmall:
                smallContent
            case .systemMedium:
                mediumContent
            case .systemLarge:
                largeContent
            default:
                smallContent
            }
        }
        .padding(14)
    }

    private var widgetBackground: some View {
        let colors = timeGradientColors
        return RadialGradient(
            colors: colors,
            center: .top,
            startRadius: 10,
            endRadius: 200
        )
        .overlay(
            RadialGradient(
                colors: [Color.white.opacity(0.04), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 160
            )
        )
        .ignoresSafeArea()
    }

    private var coinView: some View {
        let phase = CGFloat(entry.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6)) / 6.0
        let glow = 0.18 + 0.10 * abs(sin(phase * .pi * 2))
        return ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(hex: "FFFDE7"), Color(hex: "FFD700"), Color(hex: "F9A825")],
                    center: UnitPoint(x: 0.35, y: 0.30),
                    startRadius: 1,
                    endRadius: 36
                ))
            Circle()
                .strokeBorder(Color(hex: "DAA520").opacity(0.6), lineWidth: 1)
            Diamond()
                .fill(Color(hex: "D4AF37").opacity(0.8))
                .frame(width: 16, height: 16)
        }
        .frame(width: 72, height: 72)
        .shadow(color: Color.liquidGold.opacity(glow), radius: 18, x: 0, y: 6)
        .overlay(
            Circle()
                .stroke(Color.liquidGold.opacity(glow + 0.08), lineWidth: 1)
                .blur(radius: 4)
                .frame(width: 92, height: 92)
        )
    }

    private var headlineBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String.loc("今日 %lld 枚", entry.data.todayCount))
                .font(.custom("Songti SC", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.offWhite)
            Text(String.loc("连续%lld天", entry.data.streakDays))
                .font(.custom("Songti SC", size: 12))
                .foregroundColor(.mutedGold)
            Text(String(localized: "宇宙看见了你的努力"))
                .font(.custom("Songti SC", size: 11))
                .foregroundColor(.mutedGold.opacity(0.9))
        }
    }

    private var smallContent: some View {
        VStack(spacing: 10) {
            coinView
            headlineBlock
        }
    }

    private var mediumContent: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                coinView
                headlineBlock
            }
            Spacer()
            favoriteBlock
                .frame(maxWidth: 160)
        }
    }

    private var largeContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                coinView
                headlineBlock
                Spacer()
            }
            favoriteBlock
            pouchRow
        }
    }

    private var favoriteBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "最近收藏"))
                .font(.custom("Songti SC", size: 11))
                .foregroundColor(.mutedGold)
            Text(entry.data.lastFavorite ?? String(localized: "还没有收藏"))
                .font(.custom("Songti SC", size: 12))
                .foregroundColor(.offWhite)
                .lineLimit(3)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.liquidGold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var pouchRow: some View {
        HStack(spacing: 10) {
            pouchChip(title: String(localized: "事业·财富"), count: entry.data.pouchCounts["career"] ?? 0, color: .cinnabarRed)
            pouchChip(title: String(localized: "爱·关系"), count: entry.data.pouchCounts["love"] ?? 0, color: .roseGold)
            pouchChip(title: String(localized: "成长·智慧"), count: entry.data.pouchCounts["growth"] ?? 0, color: .sapphireBlue)
        }
    }

    private func pouchChip(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "bag.fill")
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(title)
                .font(.custom("Songti SC", size: 11))
                .foregroundColor(.offWhite)
                .lineLimit(1)
            Text(String.loc("%lld 枚", count))
                .font(.custom("New York", size: 11))
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(color.opacity(isFresh ? 0.75 : 0.4), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(isFresh ? 0.35 : 0.12), radius: isFresh ? 6 : 2, x: 0, y: 2)
    }

    private var timeGradientColors: [Color] {
        switch hour {
        case 5..<9:
            return [Color(hex: "F8F2E6"), Color(hex: "C9A96D").opacity(0.35)]
        case 9..<17:
            return [Color(hex: "D9B887").opacity(0.5), Color(hex: "6D4C41").opacity(0.25)]
        case 17..<21:
            return [Color(hex: "8B4A3A").opacity(0.6), Color(hex: "2F2621").opacity(0.35)]
        default:
            return [Color(hex: "2A1A12"), Color(hex: "0D0906")]
        }
    }
}

// NOTE: This widget must be added to a Widget Extension target.
struct LifeVaultWidget: Widget {
    let kind: String = "LifeVaultWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifeVaultWidgetProvider()) { entry in
            LifeVaultWidgetView(entry: entry)
        }
        .configurationDisplayName("Life Vault")
        .description("今日铸币、连击与收藏一目了然")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
