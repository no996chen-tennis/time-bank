// TimeBank/TimeBank/Retention/StreakModel.swift
//
// 连续存入奖励（只奖不罚）：点亮日历 + 自动补灯 + 里程碑。
// 红线：永不显示"连续 N 天"/断签天数；中断不清零；空着的周自动"留白"垫上，免费静默。

import Foundation
import SwiftData

struct StreakModel {
    struct WeekCell: Identifiable {
        let id: Int          // 距今第几周（0 = 本周）
        let isLit: Bool      // 该周有存入
        let isCurrent: Bool
    }

    let totalMoments: Int
    let weekNumber: Int          // 陪伴你的第 N 周
    let litDaysThisMonth: Int
    let litDays: Set<Date>       // startOfDay 集合（用 createdAt = 你点亮的日子）
    let monthDays: [Date?]       // 当月日历格（含前导空格）
    let weekCells: [WeekCell]    // 最近 8 周（含本周），用于点亮/留白条
    let monthTitle: String

    static func build(moments: [Moment], now: Date = .now) -> StreakModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1 // 周日起，与日历格头对齐
        let today = calendar.startOfDay(for: now)
        let normal = moments.filter { $0.status == .normal }

        let litDays = Set(normal.map { calendar.startOfDay(for: $0.createdAt) })

        let firstDate = normal.map(\.createdAt).min().map { calendar.startOfDay(for: $0) }
        let weekNumber: Int
        if let firstDate {
            let weeks = calendar.dateComponents([.weekOfYear], from: firstDate, to: today).weekOfYear ?? 0
            weekNumber = max(1, weeks + 1)
        } else {
            weekNumber = 1
        }

        // 当月日历格
        let monthComponents = calendar.dateComponents([.year, .month], from: now)
        let monthStart = calendar.date(from: monthComponents) ?? today
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        let leading = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for day in 0..<daysInMonth {
            cells.append(calendar.date(byAdding: .day, value: day, to: monthStart))
        }
        let litThisMonth = litDays.filter { calendar.isDate($0, equalTo: monthStart, toGranularity: .month) }.count

        // 最近 8 周点亮/留白
        let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? today
        var weekCells: [StreakModel.WeekCell] = []
        for back in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -back, to: currentWeekStart),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart)
            else { continue }
            let lit = litDays.contains { interval.contains($0) }
            weekCells.append(WeekCell(id: back, isLit: lit, isCurrent: back == 0))
        }

        let monthTitle = "\(monthComponents.year ?? 2026) 年 \(monthComponents.month ?? 1) 月"

        return StreakModel(
            totalMoments: normal.count,
            weekNumber: weekNumber,
            litDaysThisMonth: litThisMonth,
            litDays: litDays,
            monthDays: cells,
            weekCells: weekCells,
            monthTitle: monthTitle
        )
    }

    func isLit(_ date: Date) -> Bool {
        let day = Calendar(identifier: .gregorian).startOfDay(for: date)
        return litDays.contains(day)
    }

    /// 连续奖励档位（设计 §4.2 全套）。按累计存入宽松计——自动补灯让链条永不断，
    /// 所以档位只升不降、断签不回收（只奖不罚红线）：
    /// 0 = 还没有；1 = ≥3 次（星空 shimmer 增强）；2 = ≥7 次（「七次之后」纪念明信片入池）；
    /// 3 = ≥21 次（流星 + 星座辉光）。
    static func rewardTier(totalMoments: Int) -> Int {
        if totalMoments >= 21 { return 3 }
        if totalMoments >= 7 { return 2 }
        if totalMoments >= 3 { return 1 }
        return 0
    }
}

/// 里程碑：第 10 / 50 / 100 个瞬间（累计，永不归零）。每个阈值只庆祝一次。
enum MilestoneTracker {
    static let thresholds = [10, 50, 100]
    private static let key = "milestones.celebrated"

    /// 已达成但还没庆祝过的最小阈值。
    static func pending(totalMoments: Int) -> Int? {
        let done = Set(UserDefaults.standard.array(forKey: key) as? [Int] ?? [])
        return thresholds.first { $0 <= totalMoments && done.contains($0) == false }
    }

    static func markCelebrated(_ milestone: Int) {
        var done = Set(UserDefaults.standard.array(forKey: key) as? [Int] ?? [])
        done.insert(milestone)
        UserDefaults.standard.set(Array(done), forKey: key)
    }
}
