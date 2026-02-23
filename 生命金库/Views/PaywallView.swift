import SwiftUI
import StoreKit

struct PaywallView: View {

    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: Plan = .annual
    @State private var glowPulse = false
    @State private var showPrivacy = false
    @State private var showTerms = false
    @State private var showSupport = false

    enum Plan { case monthly, annual }

    private let features: [(icon: String, title: String, sub: String)] = [
        ("bag.fill",             "锦囊晋级至传奇 LV4",   "解锁第四阶段，见证生命资产的最高形态"),
        ("heart.fill",           "无限收藏心动日记",      "突破8条限制，永久珍藏每一份感动"),
        ("doc.richtext.fill",    "一键导出 PDF 生命账本", "精美排版，掌控并分享你的人生记录"),
        ("crown.fill",           "能量广场专属金色徽章",  "彰显你在社区中坚持的力量"),
        ("plus.circle.fill",     "无限自定义金库",        "按你的人生维度，自由创建更多金库"),
        ("square.grid.2x2.fill", "桌面小组件（即将推出）","每天一眼，看见自己的财富增长"),
    ]

    var body: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.40)

            VStack(spacing: 0) {
                closeButton
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection.padding(.top, 4)
                        featureList.padding(.top, 28)
                        planSelector.padding(.top, 24)
                        ctaSection.padding(.top, 20)
                        legalFooter.padding(.top, 14).padding(.bottom, 44)
                    }
                    .padding(.horizontal, 22)
                }
            }
        }
        .presentationCornerRadius(28)
        .sheet(isPresented: $showPrivacy) { PrivacyView() }
        .sheet(isPresented: $showTerms)   { TermsView() }
        .sheet(isPresented: $showSupport) { SupportView() }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
        .alert("购买失败", isPresented: Binding(
            get: { store.purchaseError != nil },
            set: { if !$0 { store.purchaseError = nil } }
        )) {
            Button("好") { store.purchaseError = nil }
        } message: {
            Text(store.purchaseError ?? "")
        }
    }

    // MARK: - Close

    private var closeButton: some View {
        HStack {
            Spacer()
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(Color.white.opacity(0.09)).frame(width: 32, height: 32)
                    Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundColor(.offWhite)
                }
            }
        }
        .padding(.horizontal, 20).padding(.top, 16)
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color.liquidGold.opacity(glowPulse ? 0.40 : 0.16), .clear],
                        center: .center, startRadius: 0, endRadius: 65
                    ))
                    .frame(width: 130, height: 130)
                    .blur(radius: 22)

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(LinearGradient(
                            colors: [Color.liquidGold.opacity(0.28), Color.liquidGoldDark.opacity(0.14)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 84, height: 84)
                        .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(LinearGradient.goldSheen, lineWidth: 1.5))
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(LinearGradient.goldSheen)
                }
            }

            VStack(spacing: 8) {
                Text("开启你的无限丰盛模式")
                    .font(.custom("Songti SC", size: 22))
                    .fontWeight(.bold)
                    .foregroundStyle(LinearGradient(
                        colors: [.liquidGold, Color(hex: "F9A825")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .multilineTextAlignment(.center)

                Text("打破边界，让你的生命资产不再受限。")
                    .font(.custom("Songti SC", size: 14))
                    .foregroundColor(.offWhite.opacity(0.72))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: 10) {
            ForEach(features, id: \.title) { f in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.liquidGold.opacity(0.12))
                            .frame(width: 36, height: 36)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(Color.liquidGold.opacity(0.28), lineWidth: 1))
                        Image(systemName: f.icon)
                            .font(.system(size: 14))
                            .foregroundStyle(LinearGradient.goldSheen)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.title)
                            .font(.custom("Songti SC", size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.offWhite)
                        Text(f.sub)
                            .font(.custom("Songti SC", size: 12))
                            .foregroundColor(.mutedGold.opacity(0.8))
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.liquidGold.opacity(0.15), lineWidth: 1))
        )
    }

    // MARK: - Plan Selector

    private var planSelector: some View {
        HStack(spacing: 12) {
            planCard(plan: .monthly, title: "月度", price: "¥8",  period: "/月", badge: nil,    note: "灵活订阅，随时取消")
            planCard(plan: .annual,  title: "年度", price: "¥48", period: "/年", badge: "省50%", note: "每日仅需 ¥0.13")
        }
    }

    private func planCard(plan: Plan, title: String, price: String, period: String, badge: String?, note: String) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) { selectedPlan = plan }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 6) {
                    Text(title)
                        .font(.custom("Songti SC", size: 13))
                        .foregroundColor(isSelected ? .liquidGold : .mutedGold)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(price)
                            .font(.custom("New York", size: 22)).fontWeight(.bold)
                            .foregroundStyle(isSelected
                                ? LinearGradient.goldSheen
                                : LinearGradient(colors: [.mutedGold], startPoint: .leading, endPoint: .trailing))
                        Text(period)
                            .font(.custom("Songti SC", size: 11))
                            .foregroundColor(isSelected ? .liquidGold.opacity(0.8) : .mutedGold.opacity(0.6))
                    }

                    Text(note)
                        .font(.custom("Songti SC", size: 11))
                        .foregroundColor(isSelected ? .liquidGold.opacity(0.8) : .mutedGold.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.liquidGold.opacity(0.10) : Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color.liquidGold.opacity(0.70) : Color.white.opacity(0.10),
                                lineWidth: isSelected ? 1.5 : 1
                            ))
                )

                if let badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(hex: "0e0c08"))
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(LinearGradient(
                            colors: [.liquidGold, .liquidGoldDark],
                            startPoint: .leading, endPoint: .trailing
                        )))
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    let product = selectedPlan == .annual ? store.annualProduct : store.monthlyProduct
                    guard let product else { return }
                    await store.purchase(product)
                    if store.isPro { dismiss() }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: [.liquidGold, .liquidGoldDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .shadow(color: Color.liquidGold.opacity(0.45), radius: 14, x: 0, y: 6)

                    if store.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text(selectedPlan == .annual ? "开始 7 天免费体验" : "立即开启 Pro")
                            .font(.custom("Songti SC", size: 17))
                            .fontWeight(.bold)
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "0e0c08"))
                    }
                }
                .frame(height: 54)
            }
            .disabled(store.isLoading)

            Button {
                Task { await store.restorePurchases() }
            } label: {
                Text("已有订阅？恢复购买")
                    .font(.custom("Songti SC", size: 13))
                    .foregroundColor(.mutedGold)
                    .underline(color: .mutedGold.opacity(0.5))
            }
        }
    }

    // MARK: - Legal Footer

    private var legalFooter: some View {
        VStack(spacing: 6) {
            Text(selectedPlan == .annual
                 ? "7天免费体验结束后，将自动按¥48/年续订。随时可在iPhone设置中取消。"
                 : "订阅将按¥8/月自动续订。随时可在iPhone设置中取消。")
                .font(.custom("Songti SC", size: 11))
                .foregroundColor(.mutedGold.opacity(0.5))
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Text("隐私政策").onTapGesture { showPrivacy = true }
                Text("·").foregroundColor(.mutedGold.opacity(0.3))
                Text("用户协议").onTapGesture { showTerms = true }
                Text("·").foregroundColor(.mutedGold.opacity(0.3))
                Text("订阅条款").onTapGesture { showSupport = true }
            }
            .font(.custom("Songti SC", size: 11))
            .foregroundColor(.mutedGold.opacity(0.45))
        }
    }
}
