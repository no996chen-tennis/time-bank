// TimeBank/TimeBank/Retention/PostcardNotifications.swift
//
// 明信片冲洗的本地通知 + 点开路由（闭环④：延迟礼物）。
// 红线：每周总量 ≤4；今日已存入则当晚不推（顺延次日）；首次有存入后才请求通知权限；只给予不催。

import Combine
import Foundation
import SwiftUI
import UserNotifications

/// 包一层让 UUID 可用于 .sheet(item:)。
struct IdentifiableMomentID: Identifiable, Equatable {
    let id: UUID
}

/// 通知点开后的路由中枢 + UNUserNotificationCenterDelegate。
@MainActor
final class PostcardCenter: NSObject, ObservableObject {
    static let shared = PostcardCenter()

    @Published var requestedMomentID: UUID?

    func register() {
        UNUserNotificationCenter.current().delegate = self
    }

    func clear() {
        requestedMomentID = nil
    }
}

extension PostcardCenter: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let idString = userInfo["momentID"] as? String, let id = UUID(uuidString: idString) {
            Task { @MainActor in PostcardCenter.shared.requestedMomentID = id }
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}

enum PostcardNotificationScheduler {
    private static let notifiedKey = "postcard.notified.ids"
    private static let timestampKey = "postcard.scheduled.timestamps"
    private static let weeklyCap = 4
    private static let fireHour = 20

    private struct Candidate: Sendable {
        let id: UUID
    }

    /// 扫描"冲洗好"的瞬间（createdAt 落在 2-4 天前、未看过、未排过），按红线排本地通知。
    /// 只在已有存入（moments 非空且有候选）时才可能触发权限请求。
    @MainActor
    static func refresh(moments: [Moment], todayDeposited: Bool, now: Date = .now) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let candidates: [Candidate] = moments.compactMap { moment in
            guard moment.status == .normal, moment.postcardSeenAt == nil else { return nil }
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: moment.createdAt), to: today).day ?? 0
            guard (2...4).contains(days) else { return nil }
            return Candidate(id: moment.id)
        }
        guard candidates.isEmpty == false else { return }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    if granted {
                        enqueue(candidates: candidates, todayDeposited: todayDeposited, now: now, center: center)
                    }
                }
            case .authorized, .provisional, .ephemeral:
                enqueue(candidates: candidates, todayDeposited: todayDeposited, now: now, center: center)
            default:
                break
            }
        }
    }

    nonisolated private static func enqueue(
        candidates: [Candidate],
        todayDeposited: Bool,
        now: Date,
        center: UNUserNotificationCenter
    ) {
        let defaults = UserDefaults.standard
        var notified = Set(defaults.stringArray(forKey: notifiedKey) ?? [])
        var timestamps = (defaults.array(forKey: timestampKey) as? [Double]) ?? []

        // 只看最近 7 天的滚动配额。
        let weekAgo = now.addingTimeInterval(-7 * 86_400).timeIntervalSince1970
        timestamps = timestamps.filter { $0 >= weekAgo }

        let fireDate = nextFireDate(now: now, skipTonight: todayDeposited)
        let fireComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)

        for candidate in candidates {
            if notified.contains(candidate.id.uuidString) { continue }
            if timestamps.count >= weeklyCap { break }

            let content = UNMutableNotificationContent()
            content.title = "时间银行"
            content.body = "你存的那个瞬间，冲洗好了。"
            content.userInfo = ["momentID": candidate.id.uuidString]

            let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "postcard-\(candidate.id.uuidString)",
                content: content,
                trigger: trigger
            )
            center.add(request)

            notified.insert(candidate.id.uuidString)
            timestamps.append(fireDate.timeIntervalSince1970)
        }

        defaults.set(Array(notified), forKey: notifiedKey)
        defaults.set(timestamps, forKey: timestampKey)
    }

    /// 下一个晚 20:00；若今晚已存入或已过 20:00，顺延到次日（红线：今日已存入当晚不推）。
    nonisolated private static func nextFireDate(now: Date, skipTonight: Bool) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = fireHour
        components.minute = 0
        let todayFire = calendar.date(from: components) ?? now
        if skipTonight || todayFire <= now {
            return calendar.date(byAdding: .day, value: 1, to: todayFire) ?? now.addingTimeInterval(86_400)
        }
        return todayFire
    }
}
