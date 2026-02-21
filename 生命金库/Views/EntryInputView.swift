import SwiftUI
import SwiftData

/// 每日铸币输入卡片
/// 限制 30 字，选择锦囊分类，点击"存入"触发金币入袋动效
struct EntryInputView: View {
    @Environment(\.modelContext)  private var modelContext
    @Environment(\.dismiss)       private var dismiss

    @Query(sort: \SuccessEntry.timestamp, order: .reverse)
    private var allEntries: [SuccessEntry]

    @State private var content      = ""
    @State private var selectedType = PouchType.career
    @State private var saving       = false
    @State private var showSuccess  = false
    @FocusState private var focused: Bool

    private let maxChars = 30

    var body: some View {
        ZStack {
            // 背景
            AppBackground()
            RadialGradient(
                colors: [Color.liquidGold.opacity(0.1), .clear],
                center: .top, startRadius: 0, endRadius: 300
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                dragHandle

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        headerSection
                        textInputSection
                        pouchSelector
                        submitButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }

            // 成功动效覆盖层
            if showSuccess {
                successOverlay
            }
        }
        .presentationDetents([.fraction(0.82)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .onAppear { focused = true }
    }

    // MARK: - Sub-views

    private var dragHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.08))
            .frame(width: 36, height: 4)
            .padding(.top, 10)
            .padding(.bottom, 8)
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("铸造今日金币")
                .font(.custom("Songti SC", size: 24))
                .fontWeight(.semibold)
                .foregroundStyle(LinearGradient(
                    colors: [.liquidGold, .liquidGoldDark],
                    startPoint: .leading, endPoint: .trailing
                ))
            Text("记录一件让你自豪的小事")
                .font(.custom("Songti SC", size: 13))
                .tracking(1)
                .foregroundColor(.mutedGold)
        }
        .padding(.top, 12)
    }

    private var textInputSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                focused
                                    ? LinearGradient(colors: [.liquidGold, .liquidGoldDark],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color.white.opacity(0.08)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: focused ? 1.5 : 1
                            )
                    )
                    .animation(.easeInOut(duration: 0.2), value: focused)

                if content.isEmpty {
                    Text("比如：今天我按时完成了计划……")
                        .font(.custom("Songti SC", size: 15))
                        .foregroundColor(.mutedGold)
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                }

                TextField("", text: $content, axis: .vertical)
                    .font(.custom("Songti SC", size: 15))
                    .foregroundColor(.offWhite)
                    .lineSpacing(4)
                    .focused($focused)
                    .padding(14)
                    .onChange(of: content) { _, newValue in
                        if newValue.count > maxChars {
                            content = String(newValue.prefix(maxChars))
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        }
                    }
            }
            .frame(minHeight: 110)

            // 字数计数
            HStack(spacing: 4) {
                Text("\(content.count)")
                    .foregroundColor(content.count >= maxChars ? .cinnabarRed : .liquidGold)
                Text("/ \(maxChars)")
                    .foregroundColor(.mutedGold)
            }
            .font(.custom("New York", size: 12))
            .animation(.easeInOut(duration: 0.15), value: content.count)
        }
    }

    private var pouchSelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("存入锦囊")
                .font(.custom("Songti SC", size: 14))
                .foregroundColor(.mutedGold)
                .tracking(1)

            HStack(spacing: 10) {
                ForEach(PouchType.allCases) { type in
                    PouchOptionButton(
                        type: type,
                        isSelected: selectedType == type,
                        count: countFor(type)
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = type
                        }
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
            }
        }
    }

    private var submitButton: some View {
        Button { save() } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        content.isEmpty
                            ? LinearGradient(colors: [Color.white.opacity(0.08)],
                                             startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [.liquidGold, .liquidGoldDark],
                                             startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(
                        color: content.isEmpty ? .clear : Color.liquidGold.opacity(0.4),
                        radius: 12, x: 0, y: 6
                    )

                HStack(spacing: 10) {
                    if saving {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 18))
                        Text("存　入")
                            .font(.custom("Songti SC", size: 18))
                            .fontWeight(.semibold)
                            .tracking(4)
                    }
                }
                .foregroundColor(content.isEmpty ? .mutedGold : .white)
            }
            .frame(height: 56)
        }
        .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty || saving)
        .animation(.easeInOut(duration: 0.2), value: content.isEmpty)
    }

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.1).ignoresSafeArea()
            VStack(spacing: 20) {
                // 金币
                GoldCoinView(size: 100)
                Text("金币已入袋！")
                    .font(.custom("Songti SC", size: 22))
                    .fontWeight(.semibold)
                    .foregroundStyle(LinearGradient.goldSheen)
                Text("你的生命资产又增值了")
                    .font(.custom("Songti SC", size: 14))
                    .foregroundColor(.mutedGold)
                    .tracking(2)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.liquidGold.opacity(0.4), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
        .transition(.scale(scale: 0.8).combined(with: .opacity))
    }

    // MARK: - Actions

    private func save() {
        let text = content.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        focused = false
        saving = true

        // 重度震动：模拟金币坠入
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impact.impactOccurred(intensity: 1.0)
            let entry = SuccessEntry(content: text, pouchType: selectedType.rawValue)
            modelContext.insert(entry)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                saving = false
                showSuccess = true
            }
            // 连续震动（能量爆发）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { impact.impactOccurred(intensity: 0.6) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { impact.impactOccurred(intensity: 0.4) }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation { dismiss() }
            }
        }
    }

    private func countFor(_ type: PouchType) -> Int {
        allEntries.filter { $0.pouchType == type.rawValue }.count
    }
}

// MARK: - PouchOptionButton

struct PouchOptionButton: View {
    let type: PouchType
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // 锦囊缩略图
                PouchCardView(
                    type: type,
                    level: PouchLevel.level(for: count),
                    count: count
                )
                .scaleEffect(0.45)
                .frame(width: 55, height: 65)
                .clipped()

                Text(type.displayName)
                    .font(.custom("Songti SC", size: 10))
                    .foregroundColor(isSelected ? type.primaryColor : .mutedGold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected
                          ? type.primaryColor.opacity(0.12)
                          : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? type.primaryColor.opacity(0.6) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EntryInputView()
        .modelContainer(for: SuccessEntry.self, inMemory: true)
}
