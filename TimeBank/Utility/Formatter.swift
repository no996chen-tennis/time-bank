// TimeBank/Utility/Formatter.swift

import Foundation

enum Formatter {
    private static let decimalGroupingFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    private static let readableHoursFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static func hoursCompact(_ h: Double) -> String {
        let roundedHours = max(0, h.rounded())

        switch roundedHours {
        case ..<1_000:
            return "\(Int(roundedHours))h"

        case 1_000..<10_000:
            let number = decimalGroupingFormatter.string(from: NSNumber(value: Int(roundedHours))) ?? "\(Int(roundedHours))"
            return "\(number)h"

        case 10_000..<100_000:
            let compact = (roundedHours / 1_000).rounded(toPlaces: 1)
            return "\(trimmedDecimalString(compact, fractionDigits: 1))Kh"

        default:
            let compact = Int((roundedHours / 1_000).rounded())
            return "\(compact)Kh"
        }
    }

    static func hoursReadable(_ h: Double) -> String {
        let value = max(0, h)
        let rendered = readableHoursFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(rendered) 小时"
    }

    static func hoursWithMinutes(_ seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)
        let roundedMinutes = Int((Double(clampedSeconds) / 60.0).rounded())
        let hours = roundedMinutes / 60
        let minutes = roundedMinutes % 60

        switch (hours, minutes) {
        case (0, _):
            return "\(minutes)m"

        case (_, 0):
            return "\(hours)h"

        default:
            return "\(hours)h \(minutes)m"
        }
    }

    static func occurrenceCount(_ n: Int, noun: String) -> String {
        "约 \(max(0, n)) 次\(noun)"
    }

    static func momentsCount(_ n: Int) -> String {
        "\(max(0, n)) 个瞬间"
    }

    // MARK: - 副文案接口（V1.3.2 新增 · 时间账户卡片消耗层副文案）

    /// 每周约 N 小时（kids / sport / create 卡副文案）
    /// 例：weeklyHours(30) → "每周约 30 小时"
    static func weeklyHours(_ h: Double) -> String {
        let rounded = max(0, Int(h.rounded()))
        return "每周约 \(rounded) 小时"
    }

    /// 每天约 N 小时<action>（partner 卡副文案）
    /// 例：dailyHoursWith(4, action: "共处") → "每天约 4 小时共处"
    /// 例：dailyHoursWith(3.5, action: "共处") → "每天约 3.5 小时共处"
    static func dailyHoursWith(_ h: Double, action: String) -> String {
        let value = max(0, h)
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return "每天约 \(Int(rounded)) 小时\(action)"
        }
        let formatted = String(format: "%.1f", rounded)
        return "每天约 \(formatted) 小时\(action)"
    }

    /// 占清醒时间约 N%（free 卡副文案）
    /// 例：percentOfAwake(56) → "占清醒时间约 56%"
    static func percentOfAwake(_ pct: Double) -> String {
        let clamped = max(0, min(100, Int(pct.rounded())))
        return "占清醒时间约 \(clamped)%"
    }

    /// lifespan 顶部卡副文案：N 年 · N Kh
    /// 例：lifespanSubtitle(years: 45, hoursK: 473) → "45 年 · 473 Kh"
    static func lifespanSubtitle(years: Double, hoursK: Double) -> String {
        let y = max(0, Int(years.rounded()))
        let k = max(0, Int(hoursK.rounded()))
        return "\(y) 年 · \(k) Kh"
    }

    static func relativeTime(_ date: Date, relativeTo now: Date = .now) -> String {
        let referenceNow = max(now, date)
        let calendar = Calendar(identifier: .gregorian)
        let seconds = max(0, referenceNow.timeIntervalSince(date))

        if seconds < 24 * 60 * 60 {
            let hours = max(0, Int(seconds / 3600))
            return "发生在 \(hours) 小时前"
        }

        let days = calendar.dateComponents([.day], from: date, to: referenceNow).day ?? 0
        if days < 30 {
            return "\(max(1, days)) 天前"
        }

        let months = calendar.dateComponents([.month], from: date, to: referenceNow).month ?? 0
        if months < 12 {
            return "\(max(1, months)) 个月前"
        }

        let years = calendar.dateComponents([.year], from: date, to: referenceNow).year ?? 0
        let sameMonth = calendar.component(.month, from: date) == calendar.component(.month, from: referenceNow)
        let sameDay = calendar.component(.day, from: date) == calendar.component(.day, from: referenceNow)

        if sameMonth && sameDay {
            return "\(max(1, years)) 年前的今天"
        }

        return "\(max(1, years)) 年前"
    }

    static func absoluteDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func trimmedDecimalString(_ value: Double, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fractionDigits
        formatter.minimumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        guard places > 0 else { return rounded() }
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
