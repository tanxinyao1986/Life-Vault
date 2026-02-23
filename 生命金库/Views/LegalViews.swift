import SwiftUI

// MARK: - Shared Shell

private struct LegalPageShell<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppBackground()
            GoldRainView().opacity(0.35)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.09)).frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.offWhite)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        content
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
        }
        .presentationCornerRadius(28)
    }
}

// MARK: - Shared Building Blocks

private struct LegalHeader: View {
    let emoji: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Text(emoji).font(.system(size: 46))
            Text(title)
                .font(.custom("Songti SC", size: 26))
                .fontWeight(.semibold)
                .foregroundStyle(LinearGradient.goldSheen)
            Text(subtitle)
                .font(.custom("New York", size: 10))
                .tracking(4)
                .foregroundColor(.mutedGold)
            Text("最后更新：2026年2月")
                .font(.custom("Songti SC", size: 12))
                .foregroundColor(.mutedGold.opacity(0.65))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

private struct LegalSectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient.goldSheen)
                    .frame(width: 3, height: 15)
                Text(title)
                    .font(.custom("Songti SC", size: 15))
                    .fontWeight(.semibold)
                    .foregroundStyle(LinearGradient.goldSheen)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.045))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.liquidGold.opacity(0.15), lineWidth: 1))
        )
    }
}

private struct LegalSubHeading: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.custom("Songti SC", size: 13))
            .fontWeight(.semibold)
            .foregroundColor(.liquidGold.opacity(0.9))
            .padding(.top, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LegalBody: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.custom("Songti SC", size: 14))
            .foregroundColor(.offWhite.opacity(0.82))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LegalBullet: View {
    private let attributed: AttributedString

    init(_ markdown: String) {
        self.attributed = (try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(markdown)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.liquidGold.opacity(0.65))
                .frame(width: 4, height: 4)
                .padding(.top, 8)
            Text(attributed)
                .font(.custom("Songti SC", size: 14))
                .foregroundColor(.offWhite.opacity(0.82))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct LegalTipBox: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.liquidGold)
                .padding(.top, 2)
            Text(text)
                .font(.custom("Songti SC", size: 13))
                .foregroundColor(.offWhite.opacity(0.8))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.liquidGold.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.liquidGold.opacity(0.28), lineWidth: 1))
        )
    }
}

private struct LegalStorageCard: View {
    let emoji: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji).font(.system(size: 20)).padding(.top, 2)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.custom("Songti SC", size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(.offWhite)
                Text(detail)
                    .font(.custom("Songti SC", size: 13))
                    .foregroundColor(.offWhite.opacity(0.72))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
        )
    }
}

private struct LegalContactBox: View {
    var replyNote: String = "我们将在 5 个工作日内回复"

    var body: some View {
        VStack(spacing: 8) {
            Text("bhzbtxy@163.com")
                .font(.custom("New York", size: 15))
                .fontWeight(.medium)
                .foregroundStyle(LinearGradient.goldSheen)
                .textSelection(.enabled)
            Text(replyNote)
                .font(.custom("Songti SC", size: 12))
                .foregroundColor(.mutedGold.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.liquidGold.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.liquidGold.opacity(0.28), lineWidth: 1))
        )
    }
}

private struct FAQItem: View {
    let question: String
    let answer: String
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Text(question)
                        .font(.custom("Songti SC", size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.offWhite)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.mutedGold)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(.vertical, 13)
                .padding(.horizontal, 14)
            }
            .buttonStyle(.plain)

            if expanded {
                Text(answer)
                    .font(.custom("Songti SC", size: 13))
                    .foregroundColor(.offWhite.opacity(0.75))
                    .lineSpacing(5)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        expanded ? Color.liquidGold.opacity(0.25) : Color.white.opacity(0.07),
                        lineWidth: 1
                    ))
        )
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: expanded)
    }
}

// MARK: - PrivacyView

struct PrivacyView: View {
    var body: some View {
        LegalPageShell {
            LegalHeader(emoji: "🔒", title: "隐私政策", subtitle: "PRIVACY POLICY")

            LegalTipBox(text: "本应用遵循「最小必要原则」：仅收集提供核心服务所必需的数据，不收集广告追踪信息，不出售您的任何数据。")

            LegalBody(text: "欢迎使用生命金库（Life Vault）。我们非常重视您的隐私，并致力于以透明、负责任的方式处理您的数据。")

            LegalSectionCard("一、我们收集的信息") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalSubHeading(text: "1.1 您主动提供的信息")
                    LegalBullet("**日记内容**：您在各金库中记录的成功日记文字内容（最多30字/条）")
                    LegalBullet("**昵称**：您在设置中自定义的用户名（默认为「生命金库用户」）")
                    LegalBullet("**头像**：您从相册中选择的个人头像图片")
                    LegalBullet("**社区分享内容**：您选择公开投射到能量广场的日记条目")

                    LegalSubHeading(text: "1.2 自动收集的信息")
                    LegalBullet("**匿名用户标识**：App 首次启动时自动生成一个匿名 UUID，用于识别设备和关联社区互动记录（点赞、收藏等）。此 ID 不与您的 Apple ID 或任何个人身份挂钩。")
                    LegalBullet("**互动记录**：您在能量广场的点赞、收藏操作，仅用于防止重复操作。")

                    LegalSubHeading(text: "1.3 我们不收集的信息")
                    LegalBullet("姓名、电话、电子邮件等个人身份信息")
                    LegalBullet("设备位置信息 / 广告标识符（IDFA）")
                    LegalBullet("第三方平台账号信息")
                    LegalBullet("浏览行为、崩溃日志（暂未接入第三方统计 SDK）")
                }
            }

            LegalSectionCard("二、信息的存储与同步") {
                VStack(spacing: 10) {
                    LegalStorageCard(emoji: "📱", title: "本地存储",
                        detail: "头像图片、金库自定义配置、本地收藏列表存储于您设备的本地沙盒中，不上传至任何服务器。")
                    LegalStorageCard(emoji: "☁️", title: "Apple CloudKit（iCloud 同步）",
                        detail: "您的私人日记条目通过 Apple CloudKit 在您本人的 iCloud 账户中加密存储与同步，仅您自己可访问。我们无法读取您的 iCloud 数据。")
                    LegalStorageCard(emoji: "🌐", title: "Supabase（能量广场云端服务）",
                        detail: "您选择公开投射的日记内容、昵称及匿名用户 ID 存储于 Supabase 托管的数据库中，用于实现能量广场的社区功能。Supabase 服务器位于美国。")
                }
            }

            LegalSectionCard("三、信息的使用目的") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalBullet("提供日记记录、金库管理等核心功能")
                    LegalBullet("实现多设备数据同步（通过 iCloud）")
                    LegalBullet("展示能量广场社区内容及统计信息")
                    LegalBullet("防止重复点赞 / 收藏等异常操作")
                    LegalBody(text: "我们不会将您的数据用于广告推送、用户画像分析或任何商业化目的。")
                }
            }

            LegalSectionCard("四、社区内容须知") {
                LegalBody(text: "当您将日记内容「投射」到能量广场时，该内容将以您的昵称公开展示给所有用户。请勿在公开内容中包含个人敏感信息（如姓名、电话、地址等）。一旦投射，内容将保存于云端服务器，删除请通过应用内操作或联系我们。")
            }

            LegalSectionCard("五、数据保留与删除") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalBullet("**私人日记**：存储于您的 iCloud，随时可在应用内删除，亦可从「iPhone 设置 → Apple ID → iCloud → 管理账户存储」中删除。")
                    LegalBullet("**社区帖子**：可在「能量广场」界面删除，或联系我们代为删除。")
                    LegalBullet("**本地数据**：卸载 App 即可清除所有本地数据。")
                    LegalBullet("**匿名账户**：如需删除匿名账户及关联社区数据，请联系我们，我们将在 30 个工作日内处理。")
                }
            }

            LegalSectionCard("六、儿童隐私") {
                LegalBody(text: "本应用适合13岁及以上用户使用。我们不会主动收集13岁以下儿童的个人信息。如果您是家长或监护人，发现您的子女在未经授权的情况下使用本应用，请联系我们，我们将立即采取措施。")
            }

            LegalSectionCard("七、政策更新") {
                LegalBody(text: "我们可能因产品功能更新或法律要求而修订本政策。重大变更将通过应用内通知告知用户。继续使用本应用即表示您同意修订后的政策。")
            }

            LegalSectionCard("八、联系我们") {
                VStack(spacing: 12) {
                    LegalBody(text: "如您对本隐私政策有任何疑问，或希望行使数据访问、更正、删除等权利，请通过以下方式联系：")
                    LegalContactBox()
                }
            }
        }
    }
}

// MARK: - TermsView

struct TermsView: View {
    var body: some View {
        LegalPageShell {
            LegalHeader(emoji: "📋", title: "用户协议", subtitle: "TERMS OF SERVICE")

            LegalTipBox(text: "本协议适用于生命金库（Life Vault）iOS 应用的所有功能，包括日记记录、财富宝库、能量广场及相关云服务。")

            LegalBody(text: "欢迎使用生命金库（Life Vault）。下载、安装或使用本应用即表示您已阅读并同意本协议的全部条款。")

            LegalSectionCard("一、服务说明") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalBullet("**每日铸币**：记录让自己感到自豪的每日成就，以「金币」的形式积累")
                    LegalBullet("**财富宝库**：按事业·财富、爱·关系、成长·智慧等维度分类管理记录")
                    LegalBullet("**能量广场**：可选择将记录公开分享，与全球用户互相鼓励")
                    LegalBullet("**多设备同步**：通过 iCloud 在您登录同一 Apple ID 的设备间同步数据")
                }
            }

            LegalSectionCard("二、账户与身份") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalBody(text: "本应用采用匿名登录机制，您无需注册账号、提供邮箱或密码即可使用全部功能。系统将自动为您的设备分配一个唯一的匿名身份标识，用于能量广场的社区互动。")
                    LegalBody(text: "您可在设置中自定义昵称，昵称将在能量广场公开显示。请勿使用包含他人真实姓名、虚假宣传、攻击性词语等内容作为昵称。")
                }
            }

            LegalSectionCard("三、用户行为规范") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalSubHeading(text: "✅ 鼓励的内容")
                    LegalBullet("真实记录自身的积极经历与成就感")
                    LegalBullet("传递正向、温暖、励志的生活态度")
                    LegalBullet("尊重其他用户的分享内容")

                    LegalSubHeading(text: "❌ 明确禁止的行为")
                    LegalBullet("发布虚假、误导、欺诈性内容")
                    LegalBullet("包含仇恨言论、歧视、骚扰、人身攻击")
                    LegalBullet("发布他人的私人信息（隐私侵犯）")
                    LegalBullet("色情、暴力或其他违法内容")
                    LegalBullet("广告推广、营销信息或垃圾内容")
                    LegalBullet("侵犯任何第三方知识产权的内容")
                    LegalBullet("任何违反中华人民共和国、美国或您所在国家法律法规的内容")

                    LegalBody(text: "我们保留对违规内容进行删除并暂停相关账户使用社区功能的权利，情节严重者将配合相关执法机构处理。")
                }
            }

            LegalSectionCard("四、内容所有权") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalBody(text: "您的私人日记归您个人所有，我们无权访问您存储在 iCloud 中的私人内容。")
                    LegalBody(text: "社区公开内容：当您将内容投射至能量广场时，您授予我们在全球范围内、免版税的非独家许可，用于在本应用内展示该内容。此授权不影响您对内容的所有权，您可随时删除已公开的内容。")
                }
            }

            LegalSectionCard("五、订阅服务（Pro 会员）") {
                VStack(alignment: .leading, spacing: 10) {
                    LegalSubHeading(text: "免费版")
                    LegalBullet("3个金库完整记录功能及社区功能")
                    LegalBullet("能量广场收藏上限 **8 条**")
                    LegalBullet("锦囊等级最高至 **LV3（丰盛）**")

                    LegalSubHeading(text: "Pro 版")
                    LegalBullet("🏆 **锦囊晋级至传奇 LV4**：200枚以上解锁最高财富等级")
                    LegalBullet("⭐ **无限收藏心动日记**：突破8条限制，永久珍藏每一份感动")
                    LegalBullet("📄 **一键导出 PDF 生命账本**：精美排版，掌控并分享你的人生记录")
                    LegalBullet("👑 **能量广场专属金色徽章**：彰显你在社区中坚持的力量")
                    LegalBullet("➕ **无限自定义金库**：按你的人生维度，自由创建更多金库")
                    LegalBullet("🔲 **桌面小组件**（即将推出）：每天一眼，看见自己的财富增长")

                    LegalSubHeading(text: "订阅价格")
                    LegalBullet("月度订阅：**¥8 / 月**")
                    LegalBullet("年度订阅：**¥48 / 年**（约每日 ¥0.13，较月度省约50%），含 **7天免费试用**")

                    LegalTipBox(text: "订阅将在到期前24小时自动续费。可随时在 iPhone 设置 → Apple ID → 订阅中取消，取消后当前周期结束前仍可使用 Pro 功能。订阅通过 Apple App Store 内购完成，退款请求须向 Apple 提出。")
                }
            }

            LegalSectionCard("六、服务变更与中断") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalBody(text: "我们保留随时修改、暂停或终止本应用全部或部分服务的权利。重大变更将提前通知用户。")
                    LegalBody(text: "能量广场社区功能依赖第三方云服务（Supabase），可能因网络问题、服务维护或不可抗力导致短暂中断，届时应用将以本地缓存内容展示，不影响私人日记功能。")
                }
            }

            LegalSectionCard("七、免责声明") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalBody(text: "本应用按「现状」提供服务，不提供任何明示或默示的保证，包括但不限于服务的可用性、准确性或适用于特定目的。")
                    LegalBody(text: "生命金库旨在帮助用户发现和记录生活中的积极体验，不构成任何形式的心理咨询、医疗建议或专业治疗服务。如您正在经历心理健康问题，请寻求专业医疗帮助。")
                }
            }

            LegalSectionCard("八、适用法律与协议修订") {
                VStack(alignment: .leading, spacing: 8) {
                    LegalBody(text: "本协议受中华人民共和国相关法律管辖。如本协议的中文版本与其他语言版本存在冲突，以中文版本为准。")
                    LegalBody(text: "我们可能因产品功能调整、法律变化等原因更新本协议。更新后将在本页面公布，并在应用内通知用户。继续使用本应用即表示您接受修订后的协议。")
                }
            }

            LegalSectionCard("九、联系我们") {
                VStack(spacing: 12) {
                    LegalBody(text: "如您对本协议有任何疑问或意见，请联系：")
                    LegalContactBox()
                }
            }
        }
    }
}

// MARK: - SupportView

struct SupportView: View {
    var body: some View {
        LegalPageShell {
            LegalHeader(emoji: "💬", title: "技术支持", subtitle: "TECHNICAL SUPPORT")

            LegalSectionCard("联系我们") {
                VStack(spacing: 12) {
                    LegalBody(text: "遇到问题、有功能建议，或需要数据删除帮助？请发邮件联系我们。")
                    LegalContactBox(replyNote: "通常在 3 个工作日内回复")
                    LegalTipBox(text: "请在邮件中注明您的 iOS 系统版本及设备型号，有助于我们更快定位问题。")
                }
            }

            LegalSectionCard("版本信息") {
                HStack(spacing: 8) {
                    versionBadge("版本 1.0.0")
                    versionBadge("iOS 18.0+")
                    versionBadge("iPhone & iPad")
                    Spacer()
                }
            }

            LegalSectionCard("常见问题 FAQ") {
                VStack(spacing: 8) {
                    FAQItem(
                        question: "📱 更换手机后，数据会丢失吗？",
                        answer: "不会。您的私人日记通过 iCloud 同步，只需在新设备登录相同的 Apple ID，打开应用后数据会自动恢复。请确认「设置 → Apple ID → iCloud → 生命金库」已开启。"
                    )
                    FAQItem(
                        question: "☁️ 如何确认 iCloud 同步是否开启？",
                        answer: "前往系统「设置 → 您的名字（Apple ID）→ iCloud → 显示全部 App」，找到「生命金库」并确认开关已打开。同步需要网络连接，初次同步可能需要几分钟。"
                    )
                    FAQItem(
                        question: "🌐 能量广场加载失败怎么办？",
                        answer: "请检查网络连接是否正常。能量广场需要连接互联网才能加载社区内容。若网络正常仍无法加载，应用会显示示例内容，请稍后重试或联系我们。"
                    )
                    FAQItem(
                        question: "🗑️ 如何删除已投射到能量广场的内容？",
                        answer: "在「财富宝库」中打开对应金库详情页，长按需要删除的日记条目，点击删除图标即可删除本地记录。如需同时撤回社区公开内容，请发邮件至 bhzbtxy@163.com 并提供内容文字，我们将在 3 个工作日内处理。"
                    )
                    FAQItem(
                        question: "🔒 我的日记内容安全吗？别人能看到吗？",
                        answer: "您的私人日记仅存储在您个人的 iCloud 账户中，采用 Apple 的端对端加密，我们无法访问。只有您选择「投射」到能量广场的内容才会公开，投射前系统会明确提示确认。"
                    )
                    FAQItem(
                        question: "👤 如何修改在能量广场显示的昵称？",
                        answer: "进入 App 底部「设置」页面，点击头像下方的昵称文字（铅笔图标），即可编辑并保存新昵称。"
                    )
                    FAQItem(
                        question: "🖼️ 如何更换头像？",
                        answer: "在「设置」页面点击头像圆圈，系统将请求访问相册权限，选择任意图片即可设置为头像。头像仅保存在本地，不上传到服务器。"
                    )
                    FAQItem(
                        question: "💎 Pro 会员包含哪些功能？如何升级？",
                        answer: "Pro 会员包含六大专属权益：① 锦囊晋级至传奇LV4（200枚以上解锁）② 无限收藏心动日记（免费版上限8条）③ 一键导出PDF生命账本 ④ 能量广场专属金色徽章 ⑤ 无限自定义金库 ⑥ 桌面小组件（即将推出）。\n\n订阅价格：月度 ¥8/月，年度 ¥48/年（含7天免费试用，约省50%）。\n\n升级入口：「设置」页面点击「升级会员」，或财富宝库中点击LV4锁定提示。订阅将在到期前24小时自动续费，可随时在 iPhone 设置 → Apple ID → 订阅中取消。"
                    )
                    FAQItem(
                        question: "🗂️ 如何彻底删除我的所有数据？",
                        answer: "① 删除本地数据：卸载应用即可；② 删除 iCloud 数据：「设置 → Apple ID → iCloud → 管理账户存储 → 生命金库 → 删除数据」；③ 删除社区数据：发邮件至 bhzbtxy@163.com 申请，我们将在 30 个工作日内处理。"
                    )
                    FAQItem(
                        question: "🌏 应用支持哪些语言？",
                        answer: "当前版本支持简体中文、繁体中文及英文三种语言，将根据您的设备系统语言自动切换，无需手动设置。如需修改，请前往 iPhone 设置 → 通用 → 语言与地区 → 首选语言进行调整。"
                    )
                    FAQItem(
                        question: "📊 能量广场的「昨日金币」和「金币共振」数据怎么来的？",
                        answer: "这两项数据为基于日期算法生成的全球参考数值，每日固定且随日期变化，用于展示社区整体积极能量的趋势，不代表实时精确统计。「我的金库收藏」是您在能量广场收藏的帖子数量。"
                    )
                }
            }

            LegalSectionCard("功能建议") {
                VStack(spacing: 12) {
                    LegalBody(text: "我们非常重视用户的声音。如果您有功能改进建议或新功能想法，欢迎发送邮件告诉我们。您的反馈将直接影响产品的迭代方向。")
                    LegalContactBox(replyNote: "主题请注明「功能建议」")
                }
            }

            LegalSectionCard("报告违规内容") {
                VStack(spacing: 10) {
                    LegalBody(text: "如果您在能量广场发现违规、有害或令人不适的内容，请通过邮件告知我们帖子内容文字，我们将在 48 小时内审核处理。")
                    LegalTipBox(text: "举报邮件主题请注明「内容举报」，并提供违规内容的具体文字，以便我们快速定位。")
                }
            }
        }
    }

    private func versionBadge(_ text: String) -> some View {
        Text(text)
            .font(.custom("Songti SC", size: 11))
            .foregroundColor(.liquidGold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.liquidGold.opacity(0.10))
                    .overlay(Capsule().strokeBorder(Color.liquidGold.opacity(0.3), lineWidth: 1))
            )
    }
}
