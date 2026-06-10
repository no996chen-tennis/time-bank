// TimeBank/TimeBank/Retention/TodayMemory.swift
//
// 盲盒选片：以"当天日期为种子"做稳定随机——同一天多次打开是同一条，次日才换。
// 优先级：那年今日（同月同日）> 比今天更早的任意一条 > 全部（含今天）。
// 闭环角色：④ 不可预测的回流 / 多变奖励。空记忆时返回 nil，由卡片走冷启动邀请态。

import Foundation
import SwiftData

enum TodayMemory {
    struct Selection: Equatable {
        let momentID: UUID
        let title: String
        let label: String              // "一年前的今天" / "N 天前" / "今天"
        let colorKey: String
        let firstMediaRelativePath: String?
        let isPostcard: Bool           // createdAt 落在 2-4 天前 = 刚"冲洗好"
    }

    static func pick(
        from moments: [Moment],
        dimensionsByID: [String: Dimension],
        now: Date = .now
    ) -> Selection? {
        let normal = moments.filter { $0.status == .normal }
        guard normal.isEmpty == false else { return nil }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let todayMD = calendar.dateComponents([.month, .day], from: now)

        func daysAgo(_ moment: Moment) -> Int {
            max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: moment.happenedAt), to: today).day ?? 0)
        }
        func isSameMonthDay(_ moment: Moment) -> Bool {
            let md = calendar.dateComponents([.month, .day], from: moment.happenedAt)
            return md.month == todayMD.month && md.day == todayMD.day
        }

        let anniversary = normal.filter { daysAgo($0) > 0 && isSameMonthDay($0) }
        let older = normal.filter { daysAgo($0) > 0 }
        let bucket = anniversary.isEmpty == false ? anniversary : (older.isEmpty == false ? older : normal)

        // 日期种子：同一天稳定，次日才换。
        let year = calendar.component(.year, from: now)
        let seed = year &* 10_000 &+ (todayMD.month ?? 1) &* 100 &+ (todayMD.day ?? 1)
        let ordered = bucket.sorted { $0.id.uuidString < $1.id.uuidString }
        let chosen = ordered[abs(seed) % ordered.count]

        let days = daysAgo(chosen)
        let label: String
        if days > 0 && isSameMonthDay(chosen) {
            let years = max(1, calendar.dateComponents([.year], from: chosen.happenedAt, to: now).year ?? 1)
            label = years == 1 ? "一年前的今天" : "\(years) 年前的今天"
        } else if days == 0 {
            label = "今天"
        } else if days == 1 {
            label = "昨天"
        } else {
            label = "\(days) 天前"
        }

        let createdDaysAgo = calendar.dateComponents([.day], from: calendar.startOfDay(for: chosen.createdAt), to: today).day ?? 0
        let firstMedia = chosen.mediaItems
            .sorted { $0.sortIndex < $1.sortIndex }
            .first?
            .relativePath

        return Selection(
            momentID: chosen.id,
            title: DimensionDetailCopy.timelineTitle(for: chosen),
            label: label,
            colorKey: dimensionsByID[chosen.dimensionId]?.colorKey ?? "rose",
            firstMediaRelativePath: firstMedia,
            isPostcard: chosen.postcardSeenAt == nil && (2...4).contains(createdDaysAgo)
        )
    }
}
