// TimeBank/TimeBankTests/DisposableTimeTests.swift

import Foundation
import XCTest

@testable import TimeBank

final class DisposableTimeTests: XCTestCase {
    /// 固定历法（公历 + 当前时区），与生产 .current 同语义；用固定日构造各 now。
    private let calendar = Calendar(identifier: .gregorian)
    private let routine = DailyRoutineParams.default

    /// 在 2026-06-15 这一天构造 now（hour:minute:second，距 0 点）。
    private func now(h: Int, m: Int = 0, s: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 15
        components.hour = h
        components.minute = m
        components.second = s
        return calendar.date(from: components)!
    }

    private func seconds(_ date: Date) -> Double {
        DisposableTime.remainingSeconds(now: date, routine: routine, calendar: calendar)
    }

    private func hours(_ date: Date) -> Double {
        seconds(date) / 3600.0
    }

    // now=10:00 → 自由段，按 default routine 实算 = 9.5h（窗口780min − 损耗并集210min = 570min）。
    func testTenAMIsAroundTenHours() {
        let value = hours(now(h: 10))
        XCTAssertEqual(value, 9.5, accuracy: 0.01)
        XCTAssertTrue(value > 8 && value < 11, "10:00 可支配应在 ~10h 量级，实得 \(value)")
    }

    // now=12:10（午餐段 12:00–12:30 内）与 now=12:30 连续：差值 ≈ 流逝的 20min，不跳变。
    func testLunchSegmentIsContinuous() {
        let at1210 = seconds(now(h: 12, m: 10))
        let at1230 = seconds(now(h: 12, m: 30))
        // 12:10 处于午餐损耗段：数字"暂停"，余额不因损耗段内分钟流逝而额外掉，
        // 与 12:30（午餐刚结束）差值约等于这 20min 的窗口收缩（1200s）。
        let delta = at1210 - at1230
        XCTAssertEqual(delta, 20 * 60, accuracy: 90, "午餐段内外应连续，差值≈流逝时间，实得 \(delta)")
    }

    // 损耗段边界整点（12:00:00 / 12:30:00）结果连续、无突变。
    func testSegmentBoundaryContinuous() {
        let just = seconds(now(h: 11, m: 59, s: 59))
        let at1200 = seconds(now(h: 12, m: 0, s: 0))
        let at1230 = seconds(now(h: 12, m: 30, s: 0))
        XCTAssertEqual(just - at1200, 1, accuracy: 120, "12:00 边界应连续")
        XCTAssertGreaterThanOrEqual(at1200, at1230 - 1, "进入午餐段后余额不应反增")
    }

    // 就寝点 23:00 ±1s：22:59:59 给极小正值、23:00:01 给 0。
    func testBedtimeBoundary() {
        let before = seconds(now(h: 22, m: 59, s: 59))
        let after = seconds(now(h: 23, m: 0, s: 1))
        XCTAssertGreaterThan(before, 0, "就寝前 1s 应为极小正值")
        XCTAssertLessThan(before, 10, "就寝前 1s 应是极小正值（<10s）")
        XCTAssertEqual(after, 0, "就寝后应为 0")
    }

    // 跨午夜 now=00:10：[00:10,07:00) 睡眠 + 后续三餐+杂项全扣 → 余额为正且显著大于 0，
    // 验证午夜重算为预期值（非负数/非异常）。
    func testPastMidnightRecomputesToValidValue() {
        let value = hours(now(h: 0, m: 10))
        XCTAssertGreaterThan(value, 0, "凌晨可支配应为正")
        XCTAssertLessThan(value, 24, "不应超过一天")
        // 凌晨醒着，到 23:00 窗口很长，扣掉凌晨睡眠+三餐+杂项后仍应 > 10h。
        XCTAssertGreaterThan(value, 10, "凌晨可支配应显著大于 10h，实得 \(value)")
    }

    // remainingText 格式化：整数不带小数、半小时带 1 位小数、均带"约"前缀、无 emoji。
    func testRemainingTextFormat() {
        let text = DisposableTime.remainingText(now: now(h: 10), routine: routine)
        XCTAssertTrue(text.hasPrefix("约 "), "应带『约』前缀，实得 \(text)")
        XCTAssertTrue(text.hasSuffix(" 小时"), "应以『小时』结尾，实得 \(text)")
        // 10:00 = 9.5h，应保留 1 位小数。
        XCTAssertEqual(text, "约 9.5 小时")
    }
}
