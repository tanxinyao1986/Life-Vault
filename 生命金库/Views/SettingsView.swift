import SwiftUI
import PhotosUI

// MARK: - Data Model

struct ExtraVault: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var iconName: String
}

// MARK: - Edit Context

struct VaultEditContext: Identifiable {
    enum Target {
        case career, love, growth
        case extra(UUID)
        case new
    }
    var id: UUID = UUID()
    var target: Target
    var initialName: String
    var initialIcon: String
}

// MARK: - SettingsView

struct SettingsView: View {

    // 用户信息
    @AppStorage("username")         private var username    = "生命金库用户"
    @AppStorage("isPro")            private var isPro       = false

    // 默认金库名称
    @AppStorage("pouchName_career") private var careerName  = "事业·财富"
    @AppStorage("pouchName_love")   private var loveName    = "爱·关系"
    @AppStorage("pouchName_growth") private var growthName  = "成长·智慧"

    // 默认金库图标
    @AppStorage("pouchIcon_career") private var careerIcon  = "briefcase.fill"
    @AppStorage("pouchIcon_love")   private var loveIcon    = "heart.fill"
    @AppStorage("pouchIcon_growth") private var growthIcon  = "leaf.fill"

    // 头像
    @State private var photoItem:    PhotosPickerItem? = nil
    @State private var avatarImage:  UIImage?          = nil

    // 昵称编辑
    @State private var editingUsername = false
    @State private var draftUsername   = ""

    // 金库编辑
    @State private var editContext:  VaultEditContext? = nil
    @State private var extraVaults:  [ExtraVault]     = []

    // MARK: - Body

    var body: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.50)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    pageTitle
                    profileSection
                    vaultCustomSection
                    aboutSection
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(item: $editContext) { ctx in
            VaultEditorSheet(context: ctx) { name, icon in
                commitEdit(target: ctx.target, name: name, icon: icon)
            }
        }
        .onAppear(perform: loadData)
    }

    // MARK: - Page Title

    private var pageTitle: some View {
        HStack {
            Text("设置")
                .font(.custom("Songti SC", size: 26))
                .fontWeight(.semibold)
                .foregroundStyle(LinearGradient.goldSheen)
            Spacer()
        }
        .padding(.top, 64)
    }

    // MARK: - Profile

    private var profileSection: some View {
        SettingsCard {
            VStack(spacing: 16) {
                // 头像
                PhotosPicker(selection: $photoItem, matching: .images) {
                    avatarCircle
                }
                .onChange(of: photoItem) { _, item in
                    loadAvatar(from: item)
                }

                // 昵称
                if editingUsername {
                    HStack(spacing: 10) {
                        TextField("请输入昵称", text: $draftUsername)
                            .font(.custom("Songti SC", size: 15))
                            .foregroundColor(.offWhite)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                        Button("完成") {
                            if !draftUsername.trimmingCharacters(in: .whitespaces).isEmpty {
                                username = draftUsername
                            }
                            editingUsername = false
                        }
                        .font(.custom("Songti SC", size: 14))
                        .foregroundColor(.liquidGold)
                    }
                    .padding(.horizontal, 20)
                } else {
                    Button {
                        draftUsername = username
                        editingUsername = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(username)
                                .font(.custom("Songti SC", size: 17))
                                .fontWeight(.medium)
                                .foregroundColor(.offWhite)
                            Image(systemName: "pencil")
                                .font(.system(size: 12))
                                .foregroundColor(.mutedGold)
                        }
                    }
                }

                memberBadge
                    .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var avatarCircle: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [.liquidGold.opacity(0.25), .liquidGoldDark.opacity(0.15)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 80, height: 80)
                .overlay(Circle().strokeBorder(LinearGradient.goldSheen, lineWidth: 1.5))

            if let img = avatarImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.liquidGold)
            }

            // 相机角标
            Circle()
                .fill(Color(hex: "2A2010"))
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.liquidGold)
                )
                .offset(x: 26, y: 26)
        }
        .padding(.top, 4)
    }

    private var memberBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: isPro ? "crown.fill" : "person.crop.circle")
                .font(.system(size: 13))
                .foregroundColor(isPro ? .liquidGold : .mutedGold)
            Text(isPro ? "订阅会员" : "免费版")
                .font(.custom("Songti SC", size: 13))
                .foregroundColor(isPro ? .liquidGold : .mutedGold)
            Spacer()
            if !isPro {
                Text("升级会员 →")
                    .font(.custom("Songti SC", size: 12))
                    .foregroundColor(.liquidGold)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(
                        Capsule().fill(Color.liquidGold.opacity(0.12))
                            .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.45), lineWidth: 1))
                    )
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isPro ? Color.liquidGold.opacity(0.08) : Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isPro ? Color.liquidGold.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1))
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Vault Custom Section

    private var vaultCustomSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("金库自定义")
            SettingsCard {
                VStack(spacing: 0) {
                    // 三个默认金库
                    vaultRow(
                        icon: careerIcon, name: careerName,
                        color: PouchType.career.primaryColor,
                        glowColor: PouchType.career.glowColor
                    ) {
                        editContext = VaultEditContext(
                            target: .career, initialName: careerName, initialIcon: careerIcon)
                    }
                    rowDivider
                    vaultRow(
                        icon: loveIcon, name: loveName,
                        color: PouchType.love.primaryColor,
                        glowColor: PouchType.love.glowColor
                    ) {
                        editContext = VaultEditContext(
                            target: .love, initialName: loveName, initialIcon: loveIcon)
                    }
                    rowDivider
                    vaultRow(
                        icon: growthIcon, name: growthName,
                        color: PouchType.growth.primaryColor,
                        glowColor: PouchType.growth.glowColor
                    ) {
                        editContext = VaultEditContext(
                            target: .growth, initialName: growthName, initialIcon: growthIcon)
                    }

                    // 付费用户的额外金库
                    ForEach(extraVaults) { vault in
                        rowDivider
                        vaultRow(
                            icon: vault.iconName, name: vault.name,
                            color: .liquidGold, glowColor: .liquidGoldDark
                        ) {
                            editContext = VaultEditContext(
                                target: .extra(vault.id),
                                initialName: vault.name,
                                initialIcon: vault.iconName)
                        }
                    }

                    // 添加金库按钮
                    rowDivider
                    addVaultButton
                }
            }
        }
    }

    private func vaultRow(icon: String, name: String, color: Color, glowColor: Color, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(glowColor.opacity(0.18))
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(glowColor.opacity(0.3), lineWidth: 1)
                        )
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                Text(name)
                    .font(.custom("Songti SC", size: 15))
                    .foregroundColor(.offWhite)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.mutedGold.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    private var addVaultButton: some View {
        Button {
            if isPro {
                editContext = VaultEditContext(target: .new, initialName: "", initialIcon: "star.fill")
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(isPro ? 0.08 : 0.04))
                        .frame(width: 42, height: 42)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    isPro ? Color.liquidGold.opacity(0.4) : Color.white.opacity(0.1),
                                    lineWidth: 1
                                )
                        )
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isPro ? .liquidGold : .mutedGold.opacity(0.4))
                }
                Text("添加金库")
                    .font(.custom("Songti SC", size: 15))
                    .foregroundColor(isPro ? .offWhite : .mutedGold.opacity(0.4))
                Spacer()
                if !isPro {
                    Text("Pro")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.liquidGold)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(
                            Capsule().fill(Color.liquidGold.opacity(0.15))
                                .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.4), lineWidth: 1))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("关于")
            SettingsCard {
                VStack(spacing: 0) {
                    linkRow(icon: "shield.lefthalf.filled",   title: "隐私政策", color: Color(hex: "5B9BD5"))
                    rowDivider
                    linkRow(icon: "questionmark.circle.fill", title: "技术支持", color: Color(hex: "FF6B35"))
                    rowDivider
                    linkRow(icon: "doc.text.fill",            title: "用户协议", color: .mutedGold)
                    rowDivider
                    versionRow
                }
            }
        }
    }

    private func linkRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color).frame(width: 28)
            Text(title).font(.custom("Songti SC", size: 15)).foregroundColor(.offWhite)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mutedGold.opacity(0.45))
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var versionRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 18)).foregroundColor(.mutedGold.opacity(0.55)).frame(width: 28)
            Text("当前版本").font(.custom("Songti SC", size: 15)).foregroundColor(.offWhite)
            Spacer()
            Text("1.0.0").font(.custom("New York", size: 13)).foregroundColor(.mutedGold)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    // MARK: - Helpers

    private var rowDivider: some View {
        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1).padding(.leading, 72)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("Songti SC", size: 12)).foregroundColor(.mutedGold)
            .tracking(1.5).padding(.leading, 4)
    }

    // MARK: - Data

    private func loadData() {
        // 加载头像
        let url = avatarURL()
        if let data = try? Data(contentsOf: url) {
            avatarImage = UIImage(data: data)
        }
        // 加载额外金库
        if let data = UserDefaults.standard.data(forKey: "extraVaults"),
           let vaults = try? JSONDecoder().decode([ExtraVault].self, from: data) {
            extraVaults = vaults
        }
    }

    private func loadAvatar(from item: PhotosPickerItem?) {
        guard let item else { return }
        item.loadTransferable(type: Data.self) { result in
            DispatchQueue.main.async {
                if case .success(let data) = result, let data, let img = UIImage(data: data) {
                    avatarImage = img
                    try? data.write(to: avatarURL())
                }
            }
        }
    }

    private func avatarURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar.jpg")
    }

    private func commitEdit(target: VaultEditContext.Target, name: String, icon: String) {
        switch target {
        case .career:      careerName = name; careerIcon = icon
        case .love:        loveName   = name; loveIcon   = icon
        case .growth:      growthName = name; growthIcon = icon
        case .extra(let id):
            if let idx = extraVaults.firstIndex(where: { $0.id == id }) {
                extraVaults[idx].name     = name
                extraVaults[idx].iconName = icon
            }
            saveExtraVaults()
        case .new:
            let vault = ExtraVault(name: name.isEmpty ? "新金库" : name, iconName: icon)
            extraVaults.append(vault)
            saveExtraVaults()
        }
    }

    private func saveExtraVaults() {
        if let data = try? JSONEncoder().encode(extraVaults) {
            UserDefaults.standard.set(data, forKey: "extraVaults")
        }
    }
}

// MARK: - SettingsCard

struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.liquidGold.opacity(0.18), lineWidth: 1))
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - VaultEditorSheet

struct VaultEditorSheet: View {

    let context: VaultEditContext
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var icon: String
    @FocusState private var nameFocused: Bool

    private let allIcons: [String] = [
        "briefcase.fill",           "dollarsign.circle.fill",   "chart.bar.fill",           "crown.fill",           "building.2.fill",
        "creditcard.fill",          "banknote.fill",            "chart.line.uptrend.xyaxis","medal.fill",           "rosette",
        "heart.fill",               "heart.circle.fill",        "person.2.fill",            "person.3.fill",        "hand.raised.fill",
        "hands.clap.fill",          "house.fill",               "bubble.heart.fill",        "gift.fill",            "balloon.fill",
        "leaf.fill",                "book.fill",                "lightbulb.fill",           "brain.head.profile",   "graduationcap.fill",
        "pencil.circle.fill",       "magnifyingglass.circle.fill","doc.fill",               "atom",                 "flask.fill",
        "figure.run",               "heart.text.square.fill",   "moon.stars.fill",          "sun.max.fill",         "bolt.heart.fill",
        "flame.fill",               "drop.fill",                "fork.knife",               "bicycle",              "figure.walk",
        "star.fill",                "trophy.fill",              "flag.fill",                "scope",                "camera.fill",
        "music.note",               "paintpalette.fill",        "gamecontroller.fill",      "airplane",             "globe"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    init(context: VaultEditContext, onSave: @escaping (String, String) -> Void) {
        self.context = context
        self.onSave  = onSave
        _name = State(initialValue: context.initialName)
        _icon = State(initialValue: context.initialIcon)
    }

    var body: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.50)

            VStack(spacing: 0) {
                // 顶部操作栏
                HStack {
                    Button("取消") { dismiss() }
                        .font(.custom("Songti SC", size: 15))
                        .foregroundColor(.mutedGold)

                    Spacer()

                    Text(titleText)
                        .font(.custom("Songti SC", size: 16))
                        .fontWeight(.medium)
                        .foregroundColor(.offWhite)

                    Spacer()

                    Button("完成") {
                        onSave(name.isEmpty ? context.initialName : name, icon)
                        dismiss()
                    }
                    .font(.custom("Songti SC", size: 15))
                    .fontWeight(.semibold)
                    .foregroundColor(.liquidGold)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 大图标预览
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.liquidGold.opacity(0.3), .liquidGoldDark.opacity(0.15)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 88, height: 88)
                                .overlay(Circle().strokeBorder(LinearGradient.goldSheen, lineWidth: 1.5))
                            Image(systemName: icon)
                                .font(.system(size: 38))
                                .foregroundStyle(LinearGradient.goldSheen)
                        }
                        .padding(.top, 4)

                        // 名称输入框
                        HStack {
                            TextField("金库名称", text: $name)
                                .font(.custom("Songti SC", size: 16))
                                .foregroundColor(.offWhite)
                                .focused($nameFocused)
                                .submitLabel(.done)
                            if !name.isEmpty {
                                Button { name = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.mutedGold.opacity(0.6))
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.liquidGold.opacity(0.2), lineWidth: 1))
                        )
                        .padding(.horizontal, 20)

                        // 图标网格
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(allIcons, id: \.self) { item in
                                let isSelected = icon == item
                                Button { icon = item } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isSelected
                                                  ? Color.liquidGold.opacity(0.22)
                                                  : Color.white.opacity(0.07))
                                            .frame(width: 56, height: 56)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(
                                                        isSelected ? Color.liquidGold : Color.white.opacity(0.08),
                                                        lineWidth: isSelected ? 2 : 1
                                                    )
                                            )
                                        Image(systemName: item)
                                            .font(.system(size: 22))
                                            .foregroundColor(isSelected ? .liquidGold : .offWhite.opacity(0.65))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .presentationCornerRadius(28)
        .onTapGesture { nameFocused = false }
    }

    private var titleText: String {
        switch context.target {
        case .new:    return "新建金库"
        default:      return "编辑金库"
        }
    }
}

#Preview {
    SettingsView()
}
