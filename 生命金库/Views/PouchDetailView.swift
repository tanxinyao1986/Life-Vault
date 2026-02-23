import SwiftUI
import SwiftData

/// 锦囊详情 – 时间轴账本
/// 像翻阅账本一样回顾过去的成功日记
struct PouchDetailView: View {
    let pouchType: PouchType
    @Query private var entries: [SuccessEntry]

    @Environment(\.dismiss)       private var dismiss
    @Environment(\.modelContext)  private var modelContext
    @AppStorage("pouchName_career") private var careerName  = String(localized: "事业·财富")
    @AppStorage("pouchName_love")   private var loveName    = String(localized: "爱·关系")
    @AppStorage("pouchName_growth") private var growthName  = String(localized: "成长·智慧")
    @AppStorage("isPro") private var isPro = false

    @State private var editContext: EntryEditContext? = nil

    private var level: PouchLevel { PouchLevel.level(for: entries.count, isPro: isPro) }

    private var groupedEntries: [(key: String, value: [SuccessEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry -> String in
            let date = entry.timestamp
            if calendar.isDateInToday(date)     { return "财富时间轴" }
            if calendar.isDateInYesterday(date) { return "昨天" }
            let formatter = DateFormatter()
            formatter.dateFormat = String(localized: "M月d日")
            return formatter.string(from: date)
        }
        return grouped.sorted { a, b in
            let order = ["财富时间轴", "昨天"]
            let ai = order.firstIndex(of: a.key)
            let bi = order.firstIndex(of: b.key)
            if let ai, let bi { return ai < bi }
            if ai != nil { return true }
            if bi != nil { return false }
            return a.key > b.key
        }
    }

    init(pouchType: PouchType) {
        self.pouchType = pouchType
        let typeRawValue = pouchType.rawValue
        _entries = Query(
            filter: #Predicate<SuccessEntry> { $0.pouchType == typeRawValue },
            sort: \SuccessEntry.timestamp,
            order: .reverse
        )
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                // 顶栏
                topBar
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                // 锦囊大图 + 等级
                pouchHero
                    .padding(.top, 4)

                // 时间轴
                if entries.isEmpty {
                    emptyState
                } else {
                    timelineList
                }
            }
        }
        .presentationCornerRadius(28)
        .sheet(item: $editContext) { ctx in
            EntryEditSheet(context: ctx) { newContent, newType in
                ctx.entry.content = newContent
                ctx.entry.pouchType = newType.rawValue
            }
        }
    }

    // MARK: - Sub-views

    private var background: some View {
        ZStack {
            AppBackground()
            RadialGradient(
                colors: [pouchType.glowColor.opacity(0.12), .clear],
                center: UnitPoint(x: 0.5, y: 0.2),
                startRadius: 0, endRadius: 280
            )
            .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.offWhite)
                }
            }

            Spacer()

            Text(currentPouchName)
                .font(.custom("Songti SC", size: 17))
                .fontWeight(.medium)
                .foregroundColor(.offWhite)

            Spacer()

            // 占位
            Circle()
                .fill(.clear)
                .frame(width: 36, height: 36)
        }
    }

    private var pouchHero: some View {
        VStack(spacing: 8) {
            Image(level.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 96)

            HStack(spacing: 16) {
                heroStat(value: String(entries.count), label: "枚金币")
                divider
                heroStat(value: String.loc("Lv%lld", level.rawValue), label: "财富等级")
                if let next = level.nextThreshold {
                    divider
                    heroStat(value: String(next - entries.count), label: "枚升级")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(pouchType.glowColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 28)
    }

    private var timelineList: some View {
        List {
            ForEach(groupedEntries, id: \.key) { group in
                Section {
                    ForEach(group.value) { entry in
                        TimelineEntryCard(entry: entry, type: pouchType) {
                            editContext = EntryEditContext(entry: entry)
                        } onDelete: {
                            modelContext.delete(entry)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 10, trailing: 20))
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(LinearGradient.goldSheen)
                            .frame(height: 1)
                        Text(group.key)
                            .font(.custom("Songti SC", size: 12))
                            .foregroundColor(.mutedGold)
                            .padding(.horizontal, 4)
                            .fixedSize()
                        Rectangle()
                            .fill(LinearGradient.goldSheen)
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 12)
                }
            }

            Color.clear
                .frame(height: 80)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.mutedGold)
            Text("这个锦囊还是空的")
                .font(.custom("Songti SC", size: 16))
                .foregroundColor(.mutedGold)
            Text("回到首页，点击金币，开始记录你的第一枚成功")
                .font(.custom("Songti SC", size: 13))
                .foregroundColor(.mutedGold)
                .multilineTextAlignment(.center)
                .tracking(0.5)
                .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.custom("New York", size: 18))
                .fontWeight(.bold)
                .foregroundStyle(LinearGradient.goldSheen)
            Text(label)
                .font(.custom("Songti SC", size: 11))
                .foregroundColor(.mutedGold)
        }
        .frame(maxWidth: .infinity)
    }

    private var currentPouchName: String {
        switch pouchType {
        case .career: careerName
        case .love: loveName
        case .growth: growthName
        }
    }
}

// MARK: - TimelineEntryCard

struct TimelineEntryCard: View {
    let entry: SuccessEntry
    let type: PouchType
    var onEdit: () -> Void
    var onDelete: () -> Void

    @State private var isExpanded = false

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = String(localized: "M月d日")
        return formatter.string(from: entry.timestamp)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间轴节点
            VStack(spacing: 0) {
                GoldCoinChip(diameter: 18)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.liquidGold.opacity(0.4), .clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 1.5)
            }
            .frame(width: 18)

            // 内容卡片
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.content)
                    .font(.custom("Songti SC", size: 14))
                    .foregroundColor(.offWhite)
                    .lineSpacing(4)
                    .lineLimit(isExpanded ? nil : 1)

                HStack {
                    Text(dateLabel)
                        .font(.custom("New York", size: 11))
                        .foregroundColor(.mutedGold)

                    if entry.isSharedToCommunity {
                        HStack(spacing: 3) {
                            Image(systemName: "globe")
                                .font(.system(size: 9))
                            Text("全球公开")
                                .font(.custom("Songti SC", size: 10))
                        }
                        .foregroundColor(Color.roseGold.opacity(0.85))
                    }

                    Spacer()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(type.glowColor.opacity(0.2), lineWidth: 1)
                    )
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("修改", action: onEdit)
                    .tint(.liquidGold)
                Button(role: .destructive, action: onDelete) {
                    Text("删除")
                }
            }
        }
    }
}

// MARK: - EntryEdit

private struct EntryEditContext: Identifiable {
    var id: UUID = UUID()
    let entry: SuccessEntry
}

private struct EntryEditSheet: View {
    let context: EntryEditContext
    let onSave: (String, PouchType) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var content: String
    @State private var pouchType: PouchType

    @AppStorage("pouchName_career") private var careerName  = String(localized: "事业·财富")
    @AppStorage("pouchName_love")   private var loveName    = String(localized: "爱·关系")
    @AppStorage("pouchName_growth") private var growthName  = String(localized: "成长·智慧")

    private let maxChars = 30

    init(context: EntryEditContext, onSave: @escaping (String, PouchType) -> Void) {
        self.context = context
        self.onSave = onSave
        _content = State(initialValue: context.entry.content)
        _pouchType = State(initialValue: PouchType(rawValue: context.entry.pouchType) ?? .career)
    }

    var body: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.35)

            VStack(spacing: 16) {
                HStack {
                    Text("修改记录")
                        .font(.custom("Songti SC", size: 18))
                        .fontWeight(.semibold)
                        .foregroundStyle(LinearGradient.goldSheen)
                    Spacer()
                    Button("完成") {
                        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, pouchType)
                        dismiss()
                    }
                    .font(.custom("Songti SC", size: 14))
                    .foregroundColor(.liquidGold)
                }

                TextEditor(text: $content)
                    .font(.custom("Songti SC", size: 15))
                    .foregroundColor(.offWhite)
                    .lineSpacing(4)
                    .frame(minHeight: 110)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.liquidGold.opacity(0.35), lineWidth: 1)
                            )
                    )
                    .onChange(of: content) { _, newValue in
                        if newValue.count > maxChars {
                            content = String(newValue.prefix(maxChars))
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        }
                    }

                HStack {
                    Text(String.loc("%lld/%lld", content.count, maxChars))
                        .font(.custom("New York", size: 11))
                        .foregroundColor(.mutedGold)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("归属锦囊")
                        .font(.custom("Songti SC", size: 13))
                        .foregroundColor(.mutedGold)
                    Picker("归属锦囊", selection: $pouchType) {
                        Text(careerName).tag(PouchType.career)
                        Text(loveName).tag(PouchType.love)
                        Text(growthName).tag(PouchType.growth)
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()
            }
            .padding(20)
        }
        .presentationCornerRadius(24)
    }
}

#Preview {
    PouchDetailView(pouchType: .career)
}
