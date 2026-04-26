// TimeBank/Features/DimensionDetail/DimensionDetailCopy.swift

import Foundation

enum DimensionDetailCopy {
    static let calculationTitle = "计算方式"
    static let firstDepositCTA = "存入第一个"
    static let timelineEnd = "到这里就是最早的了"
    static let depositAccessibilityLabel = "存入一个时刻"

    static func iconSystemName(for dimension: Dimension) -> String {
        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            return "heart.fill"
        case DimensionReservedID.kids.rawValue:
            return "figure.2.and.child.holdinghands"
        case DimensionReservedID.partner.rawValue:
            return "heart.circle.fill"
        case DimensionReservedID.sport.rawValue:
            return "figure.run"
        case DimensionReservedID.create.rawValue:
            return "paintbrush.fill"
        case DimensionReservedID.free.rawValue:
            return "sun.max.fill"
        default:
            return dimension.iconKey
        }
    }

    static func headerSubtitleLines(
        for dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension]
    ) -> [String] {
        let consumeHours = DimensionCompute.consumeHours(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID
        )
        let subtitle = DimensionCompute.subtitleData(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID
        )

        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            guard let parents = profile.parents else { return [] }
            let meetings = occurrenceCount(from: subtitle)
            return [
                "约还能一起度过 · 合 \(meetings) 次见面",
                "每次 \(Formatter.hoursCompact(parents.hoursPerVisit))"
            ]

        case DimensionReservedID.kids.rawValue:
            let weeklyHours = weeklyHours(from: subtitle)
            let weeks = weeks(from: consumeHours, weeklyHours: weeklyHours)
            return [
                "约还能陪伴 · 共 \(weeks) 周",
                Formatter.weeklyHours(weeklyHours)
            ]

        case DimensionReservedID.partner.rawValue:
            guard let partner = profile.partner else { return [] }
            return [Formatter.dailyHoursWith(partner.hoursPerDay, action: "共处")]

        case DimensionReservedID.sport.rawValue:
            let sessionHours = sportSessionHours(for: dimension)
            let sessions = Int((consumeHours / sessionHours).rounded())
            return [
                "约还能运动 · 合 \(max(0, sessions)) 次",
                "每次 \(Formatter.hoursReadable(sessionHours))"
            ]

        case DimensionReservedID.create.rawValue:
            let weeklyHours = weeklyHours(from: subtitle)
            let weeks = weeks(from: consumeHours, weeklyHours: weeklyHours)
            return [
                "约还能创造 · 共 \(weeks) 周",
                Formatter.weeklyHours(weeklyHours)
            ]

        case DimensionReservedID.free.rawValue:
            let params = dimension.decodeParams(FreeDimensionParams.self, default: FreeDimensionParams())
            return [
                percentText(from: subtitle),
                "每天约 \(Formatter.hoursReadable(params.awakeHoursPerDay))清醒"
            ]

        default:
            return []
        }
    }

    static func insight(for dimension: Dimension, profile: UserProfile) -> String? {
        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            return parentsInsight(profile: profile)
        case DimensionReservedID.kids.rawValue:
            return kidsInsight(profile: profile)
        case DimensionReservedID.partner.rawValue:
            return partnerInsight(profile: profile)
        case DimensionReservedID.sport.rawValue:
            return sportInsight(profile: profile)
        case DimensionReservedID.create.rawValue:
            return createInsight(profile: profile)
        case DimensionReservedID.free.rawValue:
            return "一天 14 小时清醒，减去所有承诺，剩下的才是你真正的时间。"
        default:
            return nil
        }
    }

    static func calculationSummary(
        for dimension: Dimension,
        profile: UserProfile,
        dimensionsByID: [String: Dimension]
    ) -> String {
        let subtitle = DimensionCompute.subtitleData(
            for: dimension,
            profile: profile,
            dimensionsByID: dimensionsByID
        )

        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            guard let parents = profile.parents else { return "" }
            let fatherAge = ageText(for: parents.father, fallbackAge: 60)
            let motherAge = ageText(for: parents.mother, fallbackAge: 58)
            return "父母 \(fatherAge)/\(motherAge) · 每年 \(max(0, parents.visitsPerYear)) 次 · 每次 \(Formatter.hoursCompact(parents.hoursPerVisit))\n预期寿命 \(parents.expectedLifespan)"

        case DimensionReservedID.kids.rawValue:
            let youngestAge = profile.children
                .filter { $0.deceased == false }
                .map { age(fromBirthYear: $0.birthYear) }
                .min() ?? 0
            let weekly = weeklyHours(from: subtitle)
            return "孩子 \(youngestAge) 岁 · 每周 \(Formatter.hoursReadable(weekly))陪伴"

        case DimensionReservedID.partner.rawValue:
            guard let partner = profile.partner else { return "" }
            let age = age(fromBirthYear: partner.birthYear)
            return "伴侣 \(age) 岁 · 每天 \(Formatter.hoursReadable(partner.hoursPerDay))共处"

        case DimensionReservedID.sport.rawValue:
            let weekly = weeklyHours(from: subtitle)
            let sessionHours = sportSessionHours(for: dimension)
            let weeklySessions = Int((weekly / sessionHours).rounded())
            return "每周 \(max(1, weeklySessions)) 次 · 每次 \(Formatter.hoursReadable(sessionHours))"

        case DimensionReservedID.create.rawValue:
            let params = dimension.decodeParams(CreateDimensionParams.self, default: CreateDimensionParams())
            let weekly = weeklyHours(from: subtitle)
            return "创造期至 \(params.focusedPhaseEndAge) 岁 · 每周 \(Formatter.hoursReadable(weekly))"

        case DimensionReservedID.free.rawValue:
            let params = dimension.decodeParams(FreeDimensionParams.self, default: FreeDimensionParams())
            return "每天清醒 \(Formatter.hoursReadable(params.awakeHoursPerDay)) · 减去其他承诺"

        default:
            return ""
        }
    }

    static func timelineEmptyText(for dimensionID: String) -> String {
        switch dimensionID {
        case DimensionReservedID.parents.rawValue:
            return "还没有陪父母的瞬间被存下来。下次回家，可以带一点回来。"
        case DimensionReservedID.kids.rawValue:
            return "还没有陪孩子的瞬间被存下来。那些不起眼的时刻，可能就是他/她未来记得最久的。"
        case DimensionReservedID.partner.rawValue:
            return "还没有和伴侣的瞬间被存下来。一顿饭、一段散步，都值得留下。"
        case DimensionReservedID.sport.rawValue:
            return "还没有运动的瞬间被存下来。一次轻微出汗也算一次。"
        case DimensionReservedID.create.rawValue:
            return "还没有创造的瞬间被存下来。哪怕只是写完一段、画完一笔，也存下来吧。"
        case DimensionReservedID.free.rawValue:
            return "还没有自由时间的瞬间被存下来。发呆、走神、听一首歌，都是真实的时间。"
        default:
            return "你的时间银行还是空的。"
        }
    }

    static func timelineTitle(for moment: Moment) -> String {
        let title = (moment.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            return Formatter.absoluteDate(moment.happenedAt)
        }
        return truncated(title, maxCount: 24)
    }

    static func timelineNote(for moment: Moment) -> String? {
        let note = moment.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard note.isEmpty == false else { return nil }
        return truncated(note, maxCount: 36)
    }

    static func mediaCountText(_ count: Int) -> String? {
        guard count > 0 else { return nil }
        return "\(count) 个媒体"
    }

    static func depositedSectionHeader(momentCount: Int, storedHours: Double) -> String {
        let shortCount = Formatter.momentsCount(momentCount)
            .replacingOccurrences(of: "瞬间", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return "已存入瞬间 · \(shortCount) · \(Formatter.storedDuration(storedHours))"
    }

    private static func occurrenceCount(from subtitle: DimensionCompute.DimensionSubtitle) -> Int {
        guard case .occurrence(let count, _) = subtitle else { return 0 }
        return max(0, count)
    }

    private static func sportSessionHours(for dimension: Dimension) -> Double {
        let params = dimension.decodeParams(SportDimensionParams.self, default: SportDimensionParams())
        return max(0.25, params.hoursPerSession)
    }

    private static func weeklyHours(from subtitle: DimensionCompute.DimensionSubtitle) -> Double {
        guard case .weeklyHours(let hours) = subtitle else { return 0 }
        return max(0, hours)
    }

    private static func percentText(from subtitle: DimensionCompute.DimensionSubtitle) -> String {
        guard case .percentOfAwake(let percent) = subtitle else {
            return Formatter.percentOfAwake(0)
        }
        return Formatter.percentOfAwake(percent)
    }

    private static func weeks(from hours: Double, weeklyHours: Double) -> Int {
        guard weeklyHours > 0 else { return 0 }
        return max(0, Int((hours / weeklyHours).rounded()))
    }

    private static func parentsInsight(profile: UserProfile) -> String? {
        let ages = [profile.parents?.father, profile.parents?.mother]
            .compactMap { member -> Int? in
                guard let member, member.deceased == false else { return nil }
                return age(fromBirthYear: member.birthYear)
            }

        let representativeAge = ages.isEmpty
            ? 60
            : Int((Double(ages.reduce(0, +)) / Double(ages.count)).rounded())

        switch representativeAge {
        case ..<60:
            return "每一次回家都更重要一点。"
        case 60..<70:
            return "他们正在经历一生中最自由的一段时间。"
        default:
            return "多一次见面，都是赚的。"
        }
    }

    private static func kidsInsight(profile: UserProfile) -> String? {
        guard let youngestAge = profile.children
            .filter({ $0.deceased == false })
            .map({ age(fromBirthYear: $0.birthYear) })
            .min()
        else {
            return nil
        }

        switch youngestAge {
        case ..<6:
            return "他/她长得很快，过两年你就找不回现在的他/她了。"
        case 6..<13:
            return "这是你们最默契的一段时光。"
        case 13..<18:
            return "他/她开始有自己的世界了。接下来几年，你会怀念吵架的次数。"
        default:
            return nil
        }
    }

    private static func partnerInsight(profile: UserProfile) -> String? {
        guard let partner = profile.partner else { return nil }
        if partner.hoursPerDay >= 2 {
            return "每天 \(Formatter.hoursReadable(partner.hoursPerDay))，不止是量，还是彼此的空气。"
        }
        return "距离让每一次相见都更重。"
    }

    private static func sportInsight(profile: UserProfile) -> String? {
        let age = Int(DimensionCompute.ageYears(birthday: profile.birthday).rounded())
        switch age {
        case ..<30:
            return "身体的黄金期，多动一动会换来后面三十年的差别。"
        case 30..<45:
            return "保持动起来，比训练强度更重要。"
        case 45..<60:
            return "每周三次让心跳加快几十分钟，比偶尔猛练有用得多。"
        default:
            return "走得比昨天稳，就是赢了。"
        }
    }

    private static func createInsight(profile: UserProfile) -> String? {
        let age = Int(DimensionCompute.ageYears(birthday: profile.birthday).rounded())
        switch age {
        case 25..<35:
            return "你人生中最有精力的 10 年，正在发生。"
        case 35..<45:
            return "最成熟的 10 年，也是产出最好作品的 10 年。"
        case 45..<55:
            return "还有时间做那件你一直想做的事。"
        default:
            return nil
        }
    }

    private static func ageText(for member: FamilyMember?, fallbackAge: Int) -> String {
        guard let member, member.deceased == false else { return "\(fallbackAge)" }
        return "\(age(fromBirthYear: member.birthYear))"
    }

    private static func age(fromBirthYear birthYear: Int) -> Int {
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: .now)
        return max(0, currentYear - birthYear)
    }

    private static func truncated(_ string: String, maxCount: Int) -> String {
        guard string.count > maxCount else { return string }
        return "\(string.prefix(maxCount))…"
    }
}
