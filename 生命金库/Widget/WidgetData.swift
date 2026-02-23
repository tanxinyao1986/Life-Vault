import Foundation
import SwiftData

struct WidgetData: Codable {
    var updatedAt: Date
    var todayCount: Int
    var streakDays: Int
    var totalCount: Int
    var lastFavorite: String?
    var pouchCounts: [String: Int]
}

enum WidgetDataStore {
    private static let suiteName = "group.com.xinyao.----"
    private static let key = "lifevault.widget.data.v1"

    static func read() -> WidgetData? {
        guard let ud = UserDefaults(suiteName: suiteName),
              let data = ud.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetData.self, from: data)
    }

    static func write(_ value: WidgetData) {
        guard let ud = UserDefaults(suiteName: suiteName),
              let data = try? JSONEncoder().encode(value) else { return }
        ud.set(data, forKey: key)
    }

    static func updateFromEntries(_ entries: [SuccessEntry]) {
        let cal = Calendar.current
        let today = Date()
        let todayCount = entries.filter { cal.isDateInToday($0.timestamp) }.count
        let totalCount = entries.count

        let uniqueDays = Set(entries.map { cal.startOfDay(for: $0.timestamp) })
        var streak = 0
        var cursor = cal.startOfDay(for: today)
        while uniqueDays.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }

        let pouchCounts: [String: Int] = entries.reduce(into: [:]) { acc, e in
            acc[e.pouchType, default: 0] += 1
        }

        let current = read()
        let payload = WidgetData(
            updatedAt: Date(),
            todayCount: todayCount,
            streakDays: streak,
            totalCount: totalCount,
            lastFavorite: current?.lastFavorite,
            pouchCounts: pouchCounts
        )
        write(payload)
    }

    static func updateLastFavorite(_ text: String?) {
        let current = read() ?? WidgetData(
            updatedAt: Date(),
            todayCount: 0,
            streakDays: 0,
            totalCount: 0,
            lastFavorite: nil,
            pouchCounts: [:]
        )
        let payload = WidgetData(
            updatedAt: Date(),
            todayCount: current.todayCount,
            streakDays: current.streakDays,
            totalCount: current.totalCount,
            lastFavorite: text,
            pouchCounts: current.pouchCounts
        )
        write(payload)
    }
}
