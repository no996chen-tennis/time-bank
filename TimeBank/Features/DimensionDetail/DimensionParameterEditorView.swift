// TimeBank/Features/DimensionDetail/DimensionParameterEditorView.swift

import SwiftData
import SwiftUI

struct DimensionParameterEditorView: View {
    let dimensionID: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var dimensions: [Dimension]

    @State private var parentsExpectedLifespan = 82.0
    @State private var parentsVisitsPerYear = 4.0
    @State private var parentsHoursPerVisit = 6.0
    @State private var kidsWeeklyHours = 14.0
    @State private var partnerHoursPerDay = 4.0
    @State private var sportSessionsPerWeek = 5.0
    @State private var sportHoursPerSession = 1.0
    @State private var createFocusedEndAge = 65.0
    @State private var createWeeklyHours = 40.0
    @State private var freeAwakeHoursPerDay = 16.0

    @State private var loaded = false
    @State private var snapshot = ParameterSnapshot()
    @State private var showDiscardAlert = false
    @State private var showRestoreAlert = false
    @State private var showSaveFailureAlert = false

    private var profile: UserProfile? { profiles.first }
    private var dimension: Dimension? { dimensions.first(where: { $0.id == dimensionID }) }

    var body: some View {
        Group {
            if let dimension, let profile {
                editorContent(dimension: dimension, profile: profile)
            } else {
                ProgressView()
                    .tint(Color.tbPrimary)
            }
        }
        .background(Color.tbBg)
        .navigationTitle("\(dimension?.name ?? "") · 计算方式")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    cancel()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("完成") {
                    save()
                }
                .disabled(!canSave)
            }
        }
        .onAppear(perform: loadIfNeeded)
        .alert("改的还没保存。先这样吗？", isPresented: $showDiscardAlert) {
            Button("继续编辑", role: .cancel) {}
            Button("不保存", role: .destructive) { dismiss() }
        }
        .alert("会把这个时间账户的参数恢复到系统默认。\n你自己调的数字会丢。", isPresented: $showRestoreAlert) {
            Button("取消", role: .cancel) {}
            Button("恢复", role: .destructive) { restoreDefaults() }
        }
        .alert("没保存上。再试一次？", isPresented: $showSaveFailureAlert) {
            Button("取消", role: .cancel) {}
            Button("重试") { save() }
        }
    }

    private func editorContent(dimension: Dimension, profile: UserProfile) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: TBSpace.s5) {
                parameterControls(for: dimension, profile: profile)

                previewCard(dimension: dimension, profile: profile)

                Button("恢复默认") {
                    showRestoreAlert = true
                }
                .font(.tbBodySm)
                .foregroundStyle(Color.tbInk2)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, TBSpace.s2)
            }
            .padding(.horizontal, TBSpace.s5)
            .padding(.top, TBSpace.s4)
            .padding(.bottom, TBSpace.s8)
        }
    }

    @ViewBuilder
    private func parameterControls(for dimension: Dimension, profile: UserProfile) -> some View {
        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            parameterCard {
                sliderRow(title: "父母预期寿命", valueText: "\(Int(parentsExpectedLifespan.rounded())) 岁") {
                    Slider(value: $parentsExpectedLifespan, in: 60...100, step: 1)
                        .tint(Color.tbPrimary)
                }
                warningRow(parentsLifespanWarning(profile: profile))

                sliderRow(title: "每年见面次数", valueText: "\(Int(parentsVisitsPerYear.rounded())) 次") {
                    Slider(value: $parentsVisitsPerYear, in: 0...52, step: 1)
                        .tint(Color.tbPrimary)
                }
                warningRow(parentsVisitsWarning)

                sliderRow(title: "每次见面时长", valueText: "\(formatHalfHour(parentsHoursPerVisit)) 小时") {
                    Slider(value: $parentsHoursPerVisit, in: 0.5...72, step: 0.5)
                        .tint(Color.tbPrimary)
                }
                warningRow(parentsHoursWarning)
            }

        case DimensionReservedID.kids.rawValue:
            parameterCard {
                sliderRow(title: "每周陪伴时长", valueText: "\(formatHalfHour(kidsWeeklyHours)) 小时") {
                    Slider(value: $kidsWeeklyHours, in: 0...80, step: 0.5)
                        .tint(Color.tbPrimary)
                }
                warningRow(kidsWarning)
            }

        case DimensionReservedID.partner.rawValue:
            parameterCard {
                sliderRow(title: "每天共处时长", valueText: "\(formatHalfHour(partnerHoursPerDay)) 小时") {
                    Slider(value: $partnerHoursPerDay, in: 0...16, step: 0.5)
                        .tint(Color.tbPrimary)
                }
                warningRow(partnerWarning)
            }

        case DimensionReservedID.sport.rawValue:
            parameterCard {
                sliderRow(title: "每周运动次数", valueText: "\(Int(sportSessionsPerWeek.rounded())) 次") {
                    Slider(value: $sportSessionsPerWeek, in: 0...14, step: 1)
                        .tint(Color.tbPrimary)
                }
                warningRow(sportSessionsWarning)

                sliderRow(title: "每次运动时长", valueText: "\(formatQuarterHour(sportHoursPerSession)) 小时") {
                    Slider(value: $sportHoursPerSession, in: 0.25...3, step: 0.25)
                        .tint(Color.tbPrimary)
                }
                warningRow(sportHoursWarning)
            }

        case DimensionReservedID.create.rawValue:
            parameterCard {
                sliderRow(title: "创造期到几岁", valueText: "\(Int(createFocusedEndAge.rounded())) 岁") {
                    Slider(value: $createFocusedEndAge, in: 30...80, step: 1)
                        .tint(Color.tbPrimary)
                }
                warningRow(createEndWarning(profile: profile))

                sliderRow(title: "每周创造时长", valueText: "\(formatHalfHour(createWeeklyHours)) 小时") {
                    Slider(value: $createWeeklyHours, in: 0...80, step: 0.5)
                        .tint(Color.tbPrimary)
                }
            }

        case DimensionReservedID.free.rawValue:
            parameterCard {
                sliderRow(title: "每天清醒时长", valueText: "\(formatHalfHour(freeAwakeHoursPerDay)) 小时") {
                    Slider(value: $freeAwakeHoursPerDay, in: 8...24, step: 0.5)
                        .tint(Color.tbPrimary)
                }
                warningRow(freeAwakeWarning)
            }

        default:
            EmptyView()
        }
    }

    private func parameterCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s4) {
            content()
        }
        .padding(TBSpace.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbBg2)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
    }

    private func previewCard(dimension: Dimension, profile: UserProfile) -> some View {
        let previewDimension = previewDimension(from: dimension)
        let previewProfile = previewProfile(from: profile)
        var lookup = Dictionary(uniqueKeysWithValues: dimensions.map { ($0.id, $0) })
        lookup[dimensionID] = previewDimension
        let lines = DimensionDetailCopy.headerSubtitleLines(
            for: previewDimension,
            profile: previewProfile,
            dimensionsByID: lookup
        )

        return VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("按这些数算下来：")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk2)
                    .lineSpacing(TBSpace.s1)
            }
        }
        .padding(TBSpace.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tbSurface)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        .modifier(DimensionDetailSoftShadowModifier())
    }

    private func sliderRow<Content: View>(
        title: String,
        valueText: String,
        @ViewBuilder control: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: TBSpace.s2) {
            HStack {
                Text(title)
                    .font(.tbBody)
                    .foregroundStyle(Color.tbInk)

                Spacer()

                Text(valueText)
                    .font(.tbBodySm)
                    .foregroundStyle(Color.tbPrimary)
            }

            control()
        }
    }

    @ViewBuilder
    private func warningRow(_ warning: ParameterWarning?) -> some View {
        if let warning {
            Text(warning.text)
                .font(.tbBodySm)
                .foregroundStyle(warning.isBlocking ? Color.tbDanger : Color.tbInk3)
        }
    }

    private var canSave: Bool {
        guard let dimension, let profile else { return false }
        switch dimension.id {
        case DimensionReservedID.parents.rawValue:
            return parentsLifespanWarning(profile: profile)?.isBlocking != true
                && parentsHoursWarning?.isBlocking != true
        case DimensionReservedID.sport.rawValue:
            return sportHoursWarning?.isBlocking != true
        case DimensionReservedID.create.rawValue:
            return createEndWarning(profile: profile)?.isBlocking != true
        default:
            return true
        }
    }

    private var isDirty: Bool {
        snapshot != currentSnapshot
    }

    private var currentSnapshot: ParameterSnapshot {
        ParameterSnapshot(
            parentsExpectedLifespan: Int(parentsExpectedLifespan.rounded()),
            parentsVisitsPerYear: Int(parentsVisitsPerYear.rounded()),
            parentsHoursPerVisit: parentsHoursPerVisit,
            kidsWeeklyHours: kidsWeeklyHours,
            partnerHoursPerDay: partnerHoursPerDay,
            sportSessionsPerWeek: Int(sportSessionsPerWeek.rounded()),
            sportHoursPerSession: sportHoursPerSession,
            createFocusedEndAge: Int(createFocusedEndAge.rounded()),
            createWeeklyHours: createWeeklyHours,
            freeAwakeHoursPerDay: freeAwakeHoursPerDay
        )
    }

    private var parentsVisitsWarning: ParameterWarning? {
        Int(parentsVisitsPerYear.rounded()) == 0
            ? ParameterWarning(text: "那以后就不再见了吗？🙈", isBlocking: false)
            : nil
    }

    private var parentsHoursWarning: ParameterWarning? {
        parentsHoursPerVisit < 0.5
            ? ParameterWarning(text: "时间再短就难得算见面了", isBlocking: true)
            : nil
    }

    private var kidsWarning: ParameterWarning? {
        kidsWeeklyHours == 0
            ? ParameterWarning(text: "孩子还小的时候，多一点陪伴都是好的", isBlocking: false)
            : nil
    }

    private var partnerWarning: ParameterWarning? {
        partnerHoursPerDay == 0
            ? ParameterWarning(text: "每天 0 小时？那也是一种状态", isBlocking: false)
            : nil
    }

    private var sportSessionsWarning: ParameterWarning? {
        Int(sportSessionsPerWeek.rounded()) == 0
            ? ParameterWarning(text: "不动也行。但身体会替你记得。", isBlocking: false)
            : nil
    }

    private var sportHoursWarning: ParameterWarning? {
        sportHoursPerSession < 0.25
            ? ParameterWarning(text: "太短了不算一次", isBlocking: true)
            : nil
    }

    private var freeAwakeWarning: ParameterWarning? {
        if freeAwakeHoursPerDay < 8 {
            return ParameterWarning(text: "这真的够吗？", isBlocking: false)
        }
        if freeAwakeHoursPerDay > 18 {
            return ParameterWarning(text: "要不要也给自己留点睡眠？", isBlocking: false)
        }
        return nil
    }

    private func parentsLifespanWarning(profile: UserProfile) -> ParameterWarning? {
        let parentAges = [profile.parents?.father, profile.parents?.mother]
            .compactMap { member -> Int? in
                guard let member else { return nil }
                return age(fromBirthYear: member.birthYear)
            }
        guard let maxParentAge = parentAges.max() else { return nil }
        return Int(parentsExpectedLifespan.rounded()) < maxParentAge
            ? ParameterWarning(text: "这好像不太对", isBlocking: true)
            : nil
    }

    private func createEndWarning(profile: UserProfile) -> ParameterWarning? {
        let currentAge = Int(DimensionCompute.ageYears(birthday: profile.birthday).rounded())
        return Int(createFocusedEndAge.rounded()) < currentAge
            ? ParameterWarning(text: "这好像不太对", isBlocking: true)
            : nil
    }

    private func loadIfNeeded() {
        guard loaded == false, let dimension, let profile else { return }
        loaded = true

        let parents = profile.parents ?? ParentsInfo()
        parentsExpectedLifespan = Double(parents.expectedLifespan)
        parentsVisitsPerYear = Double(parents.visitsPerYear)
        parentsHoursPerVisit = parents.hoursPerVisit

        let kidsParams = dimension.decodeParams(KidsDimensionParams.self, default: KidsDimensionParams())
        kidsWeeklyHours = kidsParams.weeklyHoursOverride ?? currentKidsWeeklyHours(dimension: dimension, profile: profile)

        partnerHoursPerDay = profile.partner?.hoursPerDay ?? 4

        let sport = dimension.decodeParams(SportDimensionParams.self, default: SportDimensionParams())
        sportSessionsPerWeek = Double(sport.sessionsPerWeek)
        sportHoursPerSession = sport.hoursPerSession

        let create = dimension.decodeParams(CreateDimensionParams.self, default: CreateDimensionParams())
        createFocusedEndAge = Double(create.focusedPhaseEndAge)
        createWeeklyHours = currentCreateWeeklyHours(dimension: dimension, profile: profile)

        let free = dimension.decodeParams(FreeDimensionParams.self, default: FreeDimensionParams())
        freeAwakeHoursPerDay = free.awakeHoursPerDay

        snapshot = currentSnapshot
    }

    private func cancel() {
        if isDirty {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }

    private func restoreDefaults() {
        switch dimensionID {
        case DimensionReservedID.parents.rawValue:
            parentsExpectedLifespan = 82
            parentsVisitsPerYear = 4
            parentsHoursPerVisit = 6
        case DimensionReservedID.kids.rawValue:
            kidsWeeklyHours = 14
        case DimensionReservedID.partner.rawValue:
            partnerHoursPerDay = 4
        case DimensionReservedID.sport.rawValue:
            sportSessionsPerWeek = 5
            sportHoursPerSession = 1
        case DimensionReservedID.create.rawValue:
            createFocusedEndAge = 65
            createWeeklyHours = 40
        case DimensionReservedID.free.rawValue:
            freeAwakeHoursPerDay = 16
        default:
            break
        }
    }

    private func save() {
        guard let dimension, let profile else { return }

        do {
            switch dimension.id {
            case DimensionReservedID.parents.rawValue:
                var parents = profile.parents ?? ParentsInfo()
                parents.expectedLifespan = Int(parentsExpectedLifespan.rounded())
                parents.visitsPerYear = Int(parentsVisitsPerYear.rounded())
                parents.hoursPerVisit = parentsHoursPerVisit
                profile.parents = parents

            case DimensionReservedID.kids.rawValue:
                dimension.setParams(KidsDimensionParams(weeklyHoursOverride: kidsWeeklyHours))

            case DimensionReservedID.partner.rawValue:
                var partner = profile.partner ?? PartnerInfo()
                partner.hoursPerDay = partnerHoursPerDay
                profile.partner = partner

            case DimensionReservedID.sport.rawValue:
                var params = dimension.decodeParams(SportDimensionParams.self, default: SportDimensionParams())
                params.sessionsPerWeek = Int(sportSessionsPerWeek.rounded())
                params.hoursPerSession = sportHoursPerSession

                // A2 contract: DimensionCompute reads hoursPerWeekBefore50/50To80/After80.
                // The editor exposes sessions x hours only as derived UI state, so saving syncs
                // just the current age band and leaves the other age-band fields untouched.
                let currentWeeklyHours = Double(params.sessionsPerWeek) * params.hoursPerSession
                switch DimensionCompute.ageYears(birthday: profile.birthday) {
                case ..<50:
                    params.hoursPerWeekBefore50 = currentWeeklyHours
                case 50..<80:
                    params.hoursPerWeek50To80 = currentWeeklyHours
                default:
                    params.hoursPerWeekAfter80 = currentWeeklyHours
                }
                dimension.setParams(params)

            case DimensionReservedID.create.rawValue:
                var params = dimension.decodeParams(CreateDimensionParams.self, default: CreateDimensionParams())
                params.focusedPhaseEndAge = Int(createFocusedEndAge.rounded())
                if DimensionCompute.ageYears(birthday: profile.birthday) < Double(params.focusedPhaseEndAge) {
                    params.focusedPhaseHoursPerWeek = createWeeklyHours
                } else {
                    params.freePhaseHoursPerWeek = createWeeklyHours
                }
                dimension.setParams(params)

            case DimensionReservedID.free.rawValue:
                dimension.setParams(FreeDimensionParams(awakeHoursPerDay: freeAwakeHoursPerDay))

            default:
                break
            }

            profile.updatedAt = .now
            dimension.updatedAt = .now
            try modelContext.save()
            snapshot = currentSnapshot
            dismiss()
        } catch {
            showSaveFailureAlert = true
        }
    }

    private func previewProfile(from profile: UserProfile) -> UserProfile {
        var parents = profile.parents
        var partner = profile.partner

        if dimensionID == DimensionReservedID.parents.rawValue {
            var updated = parents ?? ParentsInfo()
            updated.expectedLifespan = Int(parentsExpectedLifespan.rounded())
            updated.visitsPerYear = Int(parentsVisitsPerYear.rounded())
            updated.hoursPerVisit = parentsHoursPerVisit
            parents = updated
        }

        if dimensionID == DimensionReservedID.partner.rawValue {
            var updated = partner ?? PartnerInfo()
            updated.hoursPerDay = partnerHoursPerDay
            partner = updated
        }

        return UserProfile(
            id: UUID(),
            birthday: profile.birthday,
            gender: profile.gender,
            expectedLifespanYears: profile.expectedLifespanYears,
            parents: parents,
            children: profile.children,
            partner: partner,
            soloEmphasis: profile.soloEmphasis,
            extras: profile.extras,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )
    }

    private func previewDimension(from dimension: Dimension) -> Dimension {
        let copy = Dimension(
            id: dimension.id,
            name: dimension.name,
            kind: dimension.kind,
            status: dimension.status,
            mode: dimension.mode,
            iconKey: dimension.iconKey,
            colorKey: dimension.colorKey,
            sortIndex: dimension.sortIndex,
            params: dimension.params,
            createdAt: dimension.createdAt,
            updatedAt: dimension.updatedAt
        )

        switch dimension.id {
        case DimensionReservedID.kids.rawValue:
            copy.setParams(KidsDimensionParams(weeklyHoursOverride: kidsWeeklyHours))
        case DimensionReservedID.sport.rawValue:
            var params = dimension.decodeParams(SportDimensionParams.self, default: SportDimensionParams())
            params.sessionsPerWeek = Int(sportSessionsPerWeek.rounded())
            params.hoursPerSession = sportHoursPerSession
            let weekly = Double(params.sessionsPerWeek) * params.hoursPerSession
            params.hoursPerWeekBefore50 = weekly
            params.hoursPerWeek50To80 = weekly
            params.hoursPerWeekAfter80 = weekly
            copy.setParams(params)
        case DimensionReservedID.create.rawValue:
            var params = dimension.decodeParams(CreateDimensionParams.self, default: CreateDimensionParams())
            params.focusedPhaseEndAge = Int(createFocusedEndAge.rounded())
            params.focusedPhaseHoursPerWeek = createWeeklyHours
            params.freePhaseHoursPerWeek = createWeeklyHours
            copy.setParams(params)
        case DimensionReservedID.free.rawValue:
            copy.setParams(FreeDimensionParams(awakeHoursPerDay: freeAwakeHoursPerDay))
        default:
            break
        }

        return copy
    }

    private func currentKidsWeeklyHours(dimension: Dimension, profile: UserProfile) -> Double {
        let subtitle = DimensionCompute.subtitleData(for: dimension, profile: profile)
        guard case .weeklyHours(let hours) = subtitle else { return 14 }
        return max(0, hours)
    }

    private func currentCreateWeeklyHours(dimension: Dimension, profile: UserProfile) -> Double {
        let subtitle = DimensionCompute.subtitleData(for: dimension, profile: profile)
        guard case .weeklyHours(let hours) = subtitle else { return 40 }
        return max(0, hours)
    }

    private func age(fromBirthYear birthYear: Int) -> Int {
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: .now)
        return max(0, currentYear - birthYear)
    }

    private func formatHalfHour(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }

    private func formatQuarterHour(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        let formatted = String(format: "%.2f", value)
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
        return formatted.replacingOccurrences(of: #"\.$"#, with: "", options: .regularExpression)
    }
}

private struct ParameterWarning {
    let text: String
    let isBlocking: Bool
}

private struct ParameterSnapshot: Equatable {
    var parentsExpectedLifespan: Int = 82
    var parentsVisitsPerYear: Int = 4
    var parentsHoursPerVisit: Double = 6
    var kidsWeeklyHours: Double = 14
    var partnerHoursPerDay: Double = 4
    var sportSessionsPerWeek: Int = 5
    var sportHoursPerSession: Double = 1
    var createFocusedEndAge: Int = 65
    var createWeeklyHours: Double = 40
    var freeAwakeHoursPerDay: Double = 16
}
