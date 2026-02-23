import SwiftUI
import SwiftData

/// 每日铸币输入卡片
struct EntryInputView: View {
    @Environment(\.modelContext)  private var modelContext
    @Environment(\.dismiss)       private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass

    @Query(sort: \SuccessEntry.timestamp, order: .reverse)
    private var allEntries: [SuccessEntry]

    @State private var content      = ""
    @State private var selectedType = PouchType.career
    @State private var saving       = false
    @State private var showSuccess  = false
    @State private var shareToCommunity = false
    @FocusState private var focused: Bool

    private let maxChars = 30

    var body: some View {
        ZStack {
            // 背景
            AppBackground()
                .contentShape(Rectangle())
                .onTapGesture { focused = false }
            RadialGradient(
                colors: [Color.liquidGold.opacity(0.08), .clear],
                center: .top, startRadius: 0, endRadius: 280
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                dragHandle

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        textInputSection
                        pouchSelector
                        shareOptionSection
                        submitButton
                    }
                    .padding(.horizontal, 22)
                    .frame(maxWidth: sizeClass == .regular ? 560 : .infinity)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }

            if showSuccess { successOverlay }
        }
        .presentationDetents([.fraction(0.82)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .onAppear { focused = true }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") { focused = false }
            }
        }
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

    // MARK: - 记事本风格书写框

    private var textInputSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ZStack(alignment: .topLeading) {
                // ── 底板：磨砂 + 暖纸色调 ───────────────────────
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)

                // ── 描边：聚焦时金色，否则微弱白色 ──────────────
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        focused
                            ? LinearGradient(
                                colors: [.liquidGold, .liquidGoldDark],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(
                                colors: [Color.white.opacity(0.10)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: focused ? 1.5 : 1
                    )
                    .animation(.easeInOut(duration: 0.2), value: focused)

                // ── 占位符 ────────────────────────────────────
                if content.isEmpty {
                    Text("比如：今天我按时完成了计划……")
                        .font(.custom("Songti SC", size: 15))
                        .foregroundColor(.mutedGold.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                // ── 输入框 ────────────────────────────────────
                TextField("", text: $content, axis: .vertical)
                    .font(.custom("Songti SC", size: 15))
                    .foregroundColor(.offWhite)
                    .lineSpacing(5)
                    .focused($focused)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .onChange(of: content) { _, newValue in
                        if newValue.count > maxChars {
                            content = String(newValue.prefix(maxChars))
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        }
                    }
            }
            .overlay(alignment: .topTrailing) {
            coinCornerDecoration
                .offset(x: 8, y: -14)
        }
        .frame(minHeight: 118)

            // ── 字数计数 ──────────────────────────────────────
            HStack(spacing: 3) {
                Text("\(content.count)")
                    .foregroundColor(content.count >= maxChars ? .cinnabarRed : .liquidGold)
                Text("/ \(maxChars)")
                    .foregroundColor(.mutedGold.opacity(0.6))
            }
            .font(.custom("New York", size: 12))
            .animation(.easeInOut(duration: 0.15), value: content.count)
        }
    }

    // MARK: - 锦囊选择器（可横向滑动）

    private var pouchSelector: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ── 区块标题 ──────────────────────────────────────
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient.goldSheen)
                    .frame(width: 3, height: 15)
                Text("存入锦囊")
                    .font(.custom("Songti SC", size: 14))
                    .fontWeight(.medium)
                    .foregroundColor(.offWhite.opacity(0.88))
                    .tracking(0.5)
            }

            // ── 可横向滑动的锦囊列表 ──────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
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

                    // ── 订阅解锁更多锦囊（占位入口）────────────
                    ProPouchPlaceholder()
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 提交按钮

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
                        ProgressView().tint(.white).scaleEffect(0.8)
                    } else {
                        Image(systemName: "bag.badge.plus")
                            .font(.system(size: 18))
                        Text("纳入囊中")
                            .font(.custom("Songti SC", size: 18))
                            .fontWeight(.semibold)
                            .tracking(2)
                    }
                }
                .foregroundColor(content.isEmpty ? .mutedGold : .white)
            }
            .frame(height: 56)
        }
        .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty || saving)
        .animation(.easeInOut(duration: 0.2), value: content.isEmpty)
    }

    // MARK: - 是否公开

    private var shareOptionSection: some View {
        Button {
            shareToCommunity.toggle()
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            shareToCommunity
                                ? LinearGradient(colors: [.liquidGold, .liquidGoldDark],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.15)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Image(systemName: shareToCommunity ? "globe.asia.australia.fill" : "lock.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(shareToCommunity ? .white : .mutedGold)
                }
                .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text("可见范围")
                        .font(.custom("Songti SC", size: 15))
                        .foregroundColor(.offWhite)
                    Text(shareToCommunity ? "公开到能量广场" : "仅自己可见")
                        .font(.custom("Songti SC", size: 12))
                        .foregroundColor(shareToCommunity ? .liquidGold : .mutedGold.opacity(0.8))
                }

                Spacer()

                Image(systemName: shareToCommunity ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(shareToCommunity ? .liquidGold : .white.opacity(0.25))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                shareToCommunity ? Color.liquidGold.opacity(0.6)
                                                 : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("公开到能量广场")
        .accessibilityValue(shareToCommunity ? "已开启" : "已关闭")
    }

    // MARK: - 成功覆盖层

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.18).ignoresSafeArea()

            // 粒子爆炸
            CoinBurstEffect { }

            VStack(spacing: 16) {
                // 旋转金币 GIF（无福字）
                ZStack {
                    RadialGradient(
                        colors: [Color.liquidGold.opacity(0.40), .clear],
                        center: .center, startRadius: 0, endRadius: 70
                    )
                    .frame(width: 150, height: 150)
                    .blur(radius: 20)

                    AnimatedGIFView(name: "coin_spin")
                        .frame(width: 86, height: 127)
                }

                // +1 枚金币
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("+1")
                            .font(.custom("New York", size: 44))
                            .fontWeight(.black)
                        Text("枚金币")
                            .font(.custom("Songti SC", size: 18))
                            .fontWeight(.semibold)
                            .offset(y: 3)
                    }
                    .foregroundStyle(LinearGradient(
                        colors: [.liquidGold, Color(hex: "F9A825")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))

                    HStack(spacing: 5) {
                        Image(systemName: selectedType.iconName)
                            .font(.system(size: 11))
                        Text("已入 · \(selectedType.displayName)")
                            .font(.custom("Songti SC", size: 13))
                            .tracking(1.5)
                    }
                    .foregroundColor(.mutedGold)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 26)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26)
                            .strokeBorder(Color.liquidGold.opacity(0.38), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 44)
        }
        .transition(.scale(scale: 0.78).combined(with: .opacity))
    }

    // MARK: - 右上角金币装饰

    private var coinCornerDecoration: some View {
        HStack(spacing: -5) {
            ForEach([11.0, 15.0, 10.0], id: \.self) { d in
                ZStack {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color(hex: "FFFDE7"), Color(hex: "FFD700"), Color(hex: "F9A825")],
                            center: UnitPoint(x: 0.35, y: 0.30),
                            startRadius: 1, endRadius: d * 0.6
                        ))
                    Circle()
                        .strokeBorder(Color(hex: "DAA520").opacity(0.55), lineWidth: 0.8)
                }
                .frame(width: d, height: d)
                .shadow(color: Color.liquidGold.opacity(0.45), radius: 2, x: 0, y: 1)
            }
        }
        .rotationEffect(.degrees(-12))
    }

    // MARK: - Actions

    private func save() {
        let text = content.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        focused = false
        saving = true

        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            impact.impactOccurred(intensity: 1.0)
            let entry = SuccessEntry(content: text, pouchType: selectedType.rawValue)
            entry.isSharedToCommunity = shareToCommunity
            modelContext.insert(entry)

            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                saving = false; showSuccess = true
            }
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

// MARK: - NotebookLinesView
// 记事本横线背景，Canvas 绘制，不影响触摸事件

private struct NotebookLinesView: View {
    var body: some View {
        Canvas { ctx, size in
            // 左侧装饰竖线（类似记事本红线）
            var marginPath = Path()
            marginPath.move(to:    CGPoint(x: 38, y: 0))
            marginPath.addLine(to: CGPoint(x: 38, y: size.height))
            ctx.stroke(marginPath,
                       with: .color(Color(hex: "FFD700").opacity(0.07)),
                       lineWidth: 0.8)

            // 横向横线，从 y=44 开始，每 26pt 一条
            var y: CGFloat = 44
            while y < size.height - 10 {
                var linePath = Path()
                linePath.move(to:    CGPoint(x: 12, y: y))
                linePath.addLine(to: CGPoint(x: size.width - 12, y: y))
                ctx.stroke(linePath,
                           with: .color(Color.white.opacity(0.06)),
                           lineWidth: 0.6)
                y += 26
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - PouchOptionButton（自定义图标 + 清晰文字 + 可滑动）

struct PouchOptionButton: View {
    let type: PouchType
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {

                // ── 图标圆圈 ──────────────────────────────────
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? type.primaryColor.opacity(0.20)
                              : Color.white.opacity(0.07))
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle().strokeBorder(
                                isSelected
                                    ? type.glowColor.opacity(0.65)
                                    : Color.white.opacity(0.10),
                                lineWidth: 1.5
                            )
                        )

                    Image(systemName: type.iconName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [type.glowColor, type.primaryColor],
                                    startPoint: .top, endPoint: .bottom))
                                : AnyShapeStyle(Color.mutedGold.opacity(0.55))
                        )
                }

                // ── 组别名称（加大加粗，清晰可读）──────────────
                Text(type.displayName)
                    .font(.custom("Songti SC", size: 12))
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .offWhite : .mutedGold.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // ── 已有金币数 ────────────────────────────────
                Text("\(count) 枚")
                    .font(.custom("New York", size: 10))
                    .foregroundColor(isSelected ? type.glowColor : .mutedGold.opacity(0.40))
            }
            .frame(width: 82)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected
                          ? type.primaryColor.opacity(0.10)
                          : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected
                                    ? type.glowColor.opacity(0.50)
                                    : Color.white.opacity(0.08),
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pro 锦囊占位（引导订阅）

private struct ProPouchPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Circle().strokeBorder(
                            Color.liquidGold.opacity(0.20),
                            style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
                        )
                    )
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(.mutedGold.opacity(0.4))
            }

            Text("更多锦囊")
                .font(.custom("Songti SC", size: 12))
                .foregroundColor(.mutedGold.opacity(0.4))

            Text("Pro")
                .font(.custom("New York", size: 10))
                .foregroundColor(.liquidGold.opacity(0.45))
        }
        .frame(width: 82)
        .padding(.vertical, 12)
    }
}

#Preview {
    EntryInputView()
        .modelContainer(for: SuccessEntry.self, inMemory: true)
}
