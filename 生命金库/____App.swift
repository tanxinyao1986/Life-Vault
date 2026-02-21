import SwiftUI
import SwiftData

@main
struct LifeVaultApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SuccessEntry.self])
        // 使用具名 store（"LifeVaultV2"）避免与旧版 Item schema 冲突
        let config = ModelConfiguration("LifeVaultV2", schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // 如果具名 store 本身也损坏，删除后重建
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            if let dir = appSupport {
                let candidates = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
                for file in candidates where file.lastPathComponent.hasPrefix("LifeVaultV2") {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(sharedModelContainer)
    }
}
