import SwiftUI
import SwiftData

@main
struct LifeVaultApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SuccessEntry.self])
        let config = ModelConfiguration(
            "LifeVaultV2",
            schema: schema,
            cloudKitDatabase: .automatic   // 启用 CloudKit 多设备同步
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        seedDemoDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .task {
                    // App 启动时完成 Supabase 匿名登录（用户无感知）
                    await SupabaseManager.shared.signInIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - 演示数据（仅首次安装写入一次）
    // 三个组别对应不同等级，直观展示钱袋子样式
    //   事业·财富  3  条 → Lv1 萌芽  (01.png)
    //   爱·关系   55 条 → Lv2 积累  (02.png)
    //   成长·智慧 110条 → Lv3 丰盛  (03.png)

    private func seedDemoDataIfNeeded() {
        let key = "com.lifevault.demoDataSeeded.v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let ctx = sharedModelContainer.mainContext

        let careerSamples = ["完成了季度报告", "主动提出了新方案", "拿到了客户好评"]
        for text in careerSamples {
            ctx.insert(SuccessEntry(content: text, pouchType: "career"))
        }

        let loveSamples  = ["今天主动联系了老朋友", "给家人做了一顿饭", "真诚地表达了感谢",
                            "化解了一次小摩擦", "陪伴了需要我的人"]
        for base in loveSamples {
            for j in 0..<11 {
                ctx.insert(SuccessEntry(content: j == 0 ? base : "\(base)（\(j)）", pouchType: "love"))
            }
        }

        let growthSamples = ["读完了一章书", "坚持晨间冥想", "学会了新技能",
                             "接受了一次失败并复盘", "准时起床没有赖床"]
        for base in growthSamples {
            for j in 0..<22 {
                ctx.insert(SuccessEntry(content: j == 0 ? base : "\(base)（\(j)）", pouchType: "growth"))
            }
        }

        UserDefaults.standard.set(true, forKey: key)
    }
}
