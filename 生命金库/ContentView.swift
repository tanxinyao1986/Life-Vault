import SwiftUI
import SwiftData

/// 主容器 – 自定义黄金风格 Tab Bar
struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── 页面切换 ──────────────────────────────────────────
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: VaultView()
                case 2: CommunityView()
                case 3: SettingsView()
                default: HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)

            // ── 自定义 Tab Bar ────────────────────────────────────
            GoldenTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        // 强制 Dark Appearance：让 .ultraThinMaterial 等 material 呈现深色磨砂玻璃效果
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - GoldenTabBar

struct GoldenTabBar: View {
    @Binding var selectedTab: Int

    private struct TabItem {
        let icon: String
        let activeIcon: String
        let label: String
    }

    private let items: [TabItem] = [
        TabItem(icon: "circle",           activeIcon: "circle.fill",         label: "每日铸币"),
        TabItem(icon: "archivebox",       activeIcon: "archivebox.fill",      label: "财富宝库"),
        TabItem(icon: "person.2",         activeIcon: "person.2.fill",        label: "能量广场"),
        TabItem(icon: "gearshape",        activeIcon: "gearshape.fill",       label: "设置"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                tabButton(index: i, item: items[i])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 28)  // safe area 预留
        .background(
            ZStack {
                // 磨砂底
                Rectangle()
                    .fill(.ultraThinMaterial)

                // 顶部金线
                Rectangle()
                    .fill(LinearGradient.goldSheen)
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .top)

                // 中心金光渐变（激活中央按钮的光晕）
                RadialGradient(
                    colors: [Color.liquidGold.opacity(0.08), .clear],
                    center: .top, startRadius: 0, endRadius: 120
                )
            }
        )
    }

    private func tabButton(index: Int, item: TabItem) -> some View {
        let isActive = selectedTab == index

        return Button {
            if selectedTab != index {
                UISelectionFeedbackGenerator().selectionChanged()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = index
                }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // 激活态背景光晕
                    if isActive {
                        Circle()
                            .fill(Color.liquidGold.opacity(0.15))
                            .frame(width: 42, height: 42)
                            .blur(radius: 6)
                    }

                    Image(systemName: isActive ? item.activeIcon : item.icon)
                        .font(.system(size: 22, weight: isActive ? .semibold : .regular))
                        .foregroundStyle(
                            isActive
                                ? LinearGradient(
                                    colors: [.liquidGold, .liquidGoldDark],
                                    startPoint: .top, endPoint: .bottom)
                                : LinearGradient(
                                    colors: [Color.offWhite.opacity(0.45)],
                                    startPoint: .top, endPoint: .bottom)
                        )
                        .scaleEffect(isActive ? 1.1 : 1.0)
                }
                .frame(width: 44, height: 32)

                Text(item.label)
                    .font(.custom("Songti SC", size: 10))
                    .foregroundColor(isActive ? .liquidGold : .offWhite.opacity(0.45))
                    .fontWeight(isActive ? .medium : .regular)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SuccessEntry.self, inMemory: true)
}
