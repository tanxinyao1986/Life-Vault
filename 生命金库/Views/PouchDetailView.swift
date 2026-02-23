import SwiftUI
import SwiftData

/// 锦囊详情 – 时间轴账本
/// 像翻阅账本一样回顾过去的成功日记
struct PouchDetailView: View {
    let pouchType: PouchType
    let entries: [SuccessEntry]

    @Environment(\.dismiss)       private var dismiss
    @Environment(\.modelContext)  private var modelContext

    private var level: PouchLevel { PouchLevel.level(for: entries.count) }

    private var groupedEntries: [(key: String, value: [SuccessEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry -> String in
            let date = entry.timestamp
            if calendar.isDateInToday(date)     { return "财富时间轴" }
            if calendar.isDateInYesterday(date) { return "昨天" }
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
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
                    timelineScroll
                }
            }
        }
        .presentationCornerRadius(28)
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

            Text(pouchType.displayName)
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
                heroStat(value: "\(entries.count)", label: "枚金币")
                divider
                heroStat(value: "Lv\(level.rawValue)", label: "财富等级")
                if let next = level.nextThreshold {
                    divider
                    heroStat(value: "\(next - entries.count)", label: "枚升级")
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

    private var timelineScroll: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(groupedEntries, id: \.key) { group in
                    // 日期标题
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
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // 当天条目
                    ForEach(group.value) { entry in
                        TimelineEntryCard(entry: entry, type: pouchType) {
                            entry.isSharedToCommunity = true
                            // 同步投射到 Supabase 能量广场
                            Task {
                                try? await SupabaseManager.shared.sharePost(
                                    content:   entry.content,
                                    vaultName: pouchType.displayName
                                )
                            }
                        } onDelete: {
                            modelContext.delete(entry)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                }

                Color.clear.frame(height: 100)
            }
            .padding(.top, 8)
        }
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
}

// MARK: - TimelineEntryCard

struct TimelineEntryCard: View {
    let entry: SuccessEntry
    let type: PouchType
    var onShare: () -> Void
    var onDelete: () -> Void

    @State private var isExpanded = false
    @State private var showActions = false

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
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
                            Text("已投射")
                                .font(.custom("Songti SC", size: 10))
                        }
                        .foregroundColor(type.primaryColor.opacity(0.7))
                    }

                    Spacer()

                    // 长按后显示操作按钮
                    if showActions {
                        Button("投射", action: onShare)
                            .font(.custom("Songti SC", size: 11))
                            .foregroundColor(type.primaryColor)
                        Button(role: .destructive, action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.cinnabarRed.opacity(0.7))
                    }
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
            .onLongPressGesture {
                withAnimation(.spring(response: 0.3)) { showActions.toggle() }
            }
        }
    }
}

#Preview {
    PouchDetailView(pouchType: .career, entries: [])
}
