// TimeBank/TimeBankTests/DataLayerTests.swift

import Foundation
import SwiftData
import UIKit
import XCTest

@testable import TimeBank

@MainActor
final class DataLayerTests: XCTestCase {
    @MainActor
    private final class TestEnvironment {
        let rootURL: URL
        let storeURL: URL
        let documentsRootURL: URL
        let container: ModelContainer
        let context: ModelContext
        let fileStore: FileStore

        init(
            rootURL: URL? = nil,
            failureInjector: FileStore.FailureInjector? = nil
        ) throws {
            let chosenRoot = rootURL ?? FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            self.rootURL = chosenRoot
            self.storeURL = chosenRoot.appendingPathComponent("TimeBank.sqlite", isDirectory: false)
            self.documentsRootURL = chosenRoot.appendingPathComponent("Documents/TimeBank", isDirectory: true)

            try FileManager.default.createDirectory(at: chosenRoot, withIntermediateDirectories: true)

            let configuration = ModelConfiguration(
                nil,
                schema: nil,
                url: storeURL,
                allowsSave: true,
                cloudKitDatabase: .none
            )

            self.container = try ModelContainer(
                for: UserProfile.self,
                TimeBank.Dimension.self,
                Moment.self,
                MediaItem.self,
                Settings.self,
                configurations: configuration
            )

            self.context = container.mainContext
            self.fileStore = FileStore(baseURL: documentsRootURL, failureInjector: failureInjector)
            try fileStore.ensureBaseDirectories()
        }

        func makeMomentStore(deleteDelaySeconds: TimeInterval = 5.0) -> MomentStore {
            MomentStore(
                modelContext: context,
                fileStore: fileStore,
                deleteDelaySeconds: deleteDelaySeconds
            )
        }

        func cleanup() {
            try? FileManager.default.removeItem(at: rootURL)
        }
    }

    func testSaveMomentWithThreeImagesWritesDatabaseAndFiles() async throws {
        let env = try TestEnvironment()
        defer { env.cleanup() }

        let store = env.makeMomentStore()
        _ = try store.bootstrapReservedData()

        let request = MomentStore.SaveRequest(
            dimensionId: DimensionReservedID.parents.rawValue,
            title: "杭州西湖 48 小时",
            note: "一次完整旅行",
            happenedAt: Date(timeIntervalSince1970: 1_712_000_000),
            durationSeconds: 48 * 3600,
            media: [
                .image(data: makeJPEGData()),
                .image(data: makeJPEGData()),
                .image(data: makeJPEGData())
            ]
        )

        let savedMoment = try await store.save(moment: request)

        let fetchedMoments = try store.fetchAllMoments()
        XCTAssertEqual(fetchedMoments.count, 1)

        let moment = try XCTUnwrap(fetchedMoments.first)
        XCTAssertEqual(moment.id, savedMoment.id)
        XCTAssertEqual(moment.dimensionId, DimensionReservedID.parents.rawValue)
        XCTAssertEqual(moment.mediaItems.count, 3)

        for media in moment.mediaItems.sorted(by: { $0.sortIndex < $1.sortIndex }) {
            XCTAssertTrue(env.fileStore.fileExists(atRelativePath: media.relativePath))
            XCTAssertNotNil(media.thumbnailPath)
            XCTAssertTrue(env.fileStore.fileExists(atRelativePath: try XCTUnwrap(media.thumbnailPath)))
            XCTAssertGreaterThan(media.fileSize, 0)
        }
    }

    func testSaveRollbackWhenSecondImageFailsLeavesNoDatabaseRecordAndNoOrphans() async throws {
        let env = try TestEnvironment { _, index, stage in
            if index == 1 && stage == .beforeWriteOriginal {
                throw FileStore.FileStoreError.injectedFailure("Simulated failure on second image.")
            }
        }
        defer { env.cleanup() }

        let store = env.makeMomentStore()
        _ = try store.bootstrapReservedData()

        let request = MomentStore.SaveRequest(
            dimensionId: DimensionReservedID.parents.rawValue,
            media: [
                .image(data: makeJPEGData()),
                .image(data: makeJPEGData()),
                .image(data: makeJPEGData())
            ]
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await store.save(moment: request)
        }

        XCTAssertEqual(try store.fetchAllMoments().count, 0)

        let momentDirectory = env.fileStore.momentDirectory(for: request.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: momentDirectory.path))

        let orphans = try env.fileStore.orphanMomentDirectories(referencedMomentIDs: [])
        XCTAssertTrue(orphans.isEmpty)
    }

    func testDeleteThenUndoWithinWindowRestoresMoment() async throws {
        let env = try TestEnvironment()
        defer { env.cleanup() }

        let store = env.makeMomentStore(deleteDelaySeconds: 0.4)
        _ = try store.bootstrapReservedData()

        let request = MomentStore.SaveRequest(
            dimensionId: DimensionReservedID.parents.rawValue,
            durationSeconds: 3600,
            media: [.image(data: makeJPEGData())]
        )

        let savedMoment = try await store.save(moment: request)
        try store.delete(moment: savedMoment)

        XCTAssertEqual(savedMoment.status, .pendingDelete)
        XCTAssertNotNil(savedMoment.pendingDeleteAt)

        try await Task.sleep(nanoseconds: 150_000_000)
        try store.undoDelete(moment: savedMoment)

        let restored = try XCTUnwrap(try store.fetchMoment(id: savedMoment.id))
        XCTAssertEqual(restored.status, .normal)
        XCTAssertNil(restored.pendingDeleteAt)
        XCTAssertTrue(FileManager.default.fileExists(atPath: env.fileStore.momentDirectory(for: restored.id).path))
    }

    func testDeleteAfterDelayRemovesDatabaseRecordAndFiles() async throws {
        let env = try TestEnvironment()
        defer { env.cleanup() }

        let store = env.makeMomentStore(deleteDelaySeconds: 0.15)
        _ = try store.bootstrapReservedData()

        let request = MomentStore.SaveRequest(
            dimensionId: DimensionReservedID.parents.rawValue,
            durationSeconds: 3600,
            media: [.image(data: makeJPEGData())]
        )

        let savedMoment = try await store.save(moment: request)
        let momentDirectory = env.fileStore.momentDirectory(for: savedMoment.id)

        try store.delete(moment: savedMoment)
        try await Task.sleep(nanoseconds: 350_000_000)

        XCTAssertNil(try store.fetchMoment(id: savedMoment.id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: momentDirectory.path))
    }

    func testCommitPendingDeletesOnRestartImmediatelyPurgesData() async throws {
        let rootURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        var firstStore: MomentStore?

        do {
            let env = try TestEnvironment(rootURL: rootURL)
            let store = env.makeMomentStore(deleteDelaySeconds: 60)
            firstStore = store

            _ = try store.bootstrapReservedData()

            let request = MomentStore.SaveRequest(
                dimensionId: DimensionReservedID.parents.rawValue,
                durationSeconds: 7200,
                media: [.image(data: makeJPEGData())]
            )

            let moment = try await store.save(moment: request)
            try store.delete(moment: moment)

            XCTAssertEqual(moment.status, .pendingDelete)
        }

        _ = firstStore // 让 compiler 知道这个变量不是 dead store，其生命周期是刻意延长到这一行
        firstStore = nil

        do {
            let restartedEnv = try TestEnvironment(rootURL: rootURL)
            defer { restartedEnv.cleanup() }

            let restartedStore = restartedEnv.makeMomentStore(deleteDelaySeconds: 60)
            let deletedCount = try await restartedStore.commitPendingDeletes()

            XCTAssertEqual(deletedCount, 1)
            XCTAssertTrue(try restartedStore.fetchAllMoments().isEmpty)

            let orphanDirectories = try restartedEnv.fileStore.orphanMomentDirectories(referencedMomentIDs: [])
            XCTAssertTrue(orphanDirectories.isEmpty)
        }
    }

    func testAggregationExcludesPendingDeleteAndNilDurationStillCountsMoment() throws {
        let env = try TestEnvironment()
        defer { env.cleanup() }

        try TimeBank.Dimension.seedReservedDimensionsIfNeeded(in: env.context)

        let sportDimension = try XCTUnwrap(TimeBank.Dimension.fetch(by: DimensionReservedID.sport.rawValue, in: env.context))
        let lifespanDimension = try XCTUnwrap(TimeBank.Dimension.fetch(by: DimensionReservedID.lifespan.rawValue, in: env.context))

        let customDimension = TimeBank.Dimension(
            id: UUID().uuidString,
            name: "阅读",
            kind: .custom,
            status: .visible,
            mode: .normal,
            iconKey: "book",
            colorKey: "sky",
            sortIndex: 100,
            params: TimeBank.Dimension.encodedParams(EmptyDimensionParams())
        )
        env.context.insert(customDimension)

        let activeSportMoment = Moment(
            dimensionId: sportDimension.id,
            durationSeconds: 3600,
            status: .normal
        )

        let pendingSportMoment = Moment(
            dimensionId: sportDimension.id,
            durationSeconds: 7200,
            status: .pendingDelete,
            pendingDeleteAt: .now
        )

        let nilDurationSportMoment = Moment(
            dimensionId: sportDimension.id,
            durationSeconds: nil,
            status: .normal
        )

        let customMoment = Moment(
            dimensionId: customDimension.id,
            durationSeconds: 1800,
            status: .normal
        )

        let lifespanMoment = Moment(
            dimensionId: lifespanDimension.id,
            durationSeconds: 10_800,
            status: .normal
        )

        env.context.insert(activeSportMoment)
        env.context.insert(pendingSportMoment)
        env.context.insert(nilDurationSportMoment)
        env.context.insert(customMoment)
        env.context.insert(lifespanMoment)
        try env.context.save()

        let allMoments = try env.context.fetch(FetchDescriptor<Moment>())
        let allDimensions = try env.context.fetch(FetchDescriptor<TimeBank.Dimension>())

        XCTAssertEqual(
            DimensionCompute.storedHours(for: sportDimension.id, moments: allMoments),
            1.0,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            DimensionCompute.storedMomentCount(for: sportDimension.id, moments: allMoments),
            2
        )

        let totalAccount = DimensionCompute.totalAccount(dimensions: allDimensions, moments: allMoments)
        XCTAssertEqual(totalAccount.hours, 1.5, accuracy: 0.0001)
        XCTAssertEqual(totalAccount.moments, 3)
        XCTAssertEqual(totalAccount.dimensionCount, 2)
    }

    func testFormatterMatrixCoversAllInterfaces() {
        // 既有 7 接口
        XCTAssertEqual(TimeBank.Formatter.hoursCompact(552), "552h")
        XCTAssertEqual(TimeBank.Formatter.hoursCompact(1_240), "1,240h")
        XCTAssertEqual(TimeBank.Formatter.hoursCompact(18_240), "18.2Kh")

        XCTAssertEqual(TimeBank.Formatter.hoursReadable(128), "128 小时")
        XCTAssertEqual(TimeBank.Formatter.hoursReadable(48.5), "48.5 小时")
        XCTAssertEqual(TimeBank.Formatter.hoursReadable(0), "0 小时")

        XCTAssertEqual(TimeBank.Formatter.hoursInDays(0), "≈ 0 天")
        XCTAssertEqual(TimeBank.Formatter.hoursInDays(23), "≈ 0 天")
        XCTAssertEqual(TimeBank.Formatter.hoursInDays(24), "≈ 1 天")
        XCTAssertEqual(TimeBank.Formatter.hoursInDays(25), "≈ 1 天")
        XCTAssertEqual(TimeBank.Formatter.hoursInDays(240), "≈ 10 天")
        XCTAssertEqual(TimeBank.Formatter.hoursInDays(2_400), "≈ 100 天")

        XCTAssertEqual(TimeBank.Formatter.hoursWithMinutes(30 * 60), "30m")
        XCTAssertEqual(TimeBank.Formatter.hoursWithMinutes(2 * 3600), "2h")
        XCTAssertEqual(TimeBank.Formatter.hoursWithMinutes(2 * 3600 + 30 * 60), "2h 30m")

        XCTAssertEqual(TimeBank.Formatter.occurrenceCount(92, noun: "见面"), "约 92 次见面")
        XCTAssertEqual(TimeBank.Formatter.occurrenceCount(40, noun: "通话"), "约 40 次通话")
        XCTAssertEqual(TimeBank.Formatter.occurrenceCount(5, noun: "散步"), "约 5 次散步")

        XCTAssertEqual(TimeBank.Formatter.momentsCount(12), "12 个瞬间")
        XCTAssertEqual(TimeBank.Formatter.momentsCount(1), "1 个瞬间")
        XCTAssertEqual(TimeBank.Formatter.momentsCount(0), "0 个瞬间")

        let now = Date(timeIntervalSince1970: 1_720_000_000)
        let calendar = Calendar(identifier: .gregorian)
        XCTAssertEqual(TimeBank.Formatter.relativeTime(now.addingTimeInterval(-3 * 3600), relativeTo: now), "发生在 3 小时前")
        XCTAssertEqual(TimeBank.Formatter.relativeTime(now.addingTimeInterval(-3 * 24 * 3600), relativeTo: now), "3 天前")
        XCTAssertEqual(TimeBank.Formatter.relativeTime(calendar.date(byAdding: .month, value: -2, to: now)!, relativeTo: now), "2 个月前")
        XCTAssertEqual(TimeBank.Formatter.relativeTime(calendar.date(byAdding: .year, value: -1, to: now)!, relativeTo: now), "1 年前的今天")

        let localCalendar = Calendar(identifier: .gregorian)
        let localKnownDate = localCalendar.date(from: DateComponents(year: 2026, month: 3, day: 22, hour: 12)) ?? now
        XCTAssertEqual(TimeBank.Formatter.absoluteDate(localKnownDate), "2026-03-22")
        XCTAssertEqual(TimeBank.Formatter.absoluteDate(Date(timeIntervalSince1970: 1_700_000_000)).count, 10)
        XCTAssertTrue(TimeBank.Formatter.absoluteDate(now).contains("-"))

        // V1.3.2 新增 4 接口（PRD §21 + §22.3.1）
        XCTAssertEqual(TimeBank.Formatter.weeklyHours(30), "每周约 30 小时")
        XCTAssertEqual(TimeBank.Formatter.weeklyHours(5), "每周约 5 小时")
        XCTAssertEqual(TimeBank.Formatter.weeklyHours(40), "每周约 40 小时")
        XCTAssertEqual(TimeBank.Formatter.weeklyHours(0), "每周约 0 小时")
        XCTAssertEqual(TimeBank.Formatter.weeklyHours(29.6), "每周约 30 小时") // round to int

        XCTAssertEqual(TimeBank.Formatter.dailyHoursWith(4, action: "共处"), "每天约 4 小时共处")
        XCTAssertEqual(TimeBank.Formatter.dailyHoursWith(3.5, action: "共处"), "每天约 3.5 小时共处")
        XCTAssertEqual(TimeBank.Formatter.dailyHoursWith(2, action: "陪伴"), "每天约 2 小时陪伴")
        XCTAssertEqual(TimeBank.Formatter.dailyHoursWith(0, action: "共处"), "每天约 0 小时共处")

        XCTAssertEqual(TimeBank.Formatter.percentOfAwake(56), "占清醒时间约 56%")
        XCTAssertEqual(TimeBank.Formatter.percentOfAwake(0), "占清醒时间约 0%")
        XCTAssertEqual(TimeBank.Formatter.percentOfAwake(100), "占清醒时间约 100%")
        XCTAssertEqual(TimeBank.Formatter.percentOfAwake(150), "占清醒时间约 100%") // clamped
        XCTAssertEqual(TimeBank.Formatter.percentOfAwake(-10), "占清醒时间约 0%") // clamped

        XCTAssertEqual(TimeBank.Formatter.lifespanSubtitle(years: 45, hoursK: 473), "45 年 · 473 Kh")
        XCTAssertEqual(TimeBank.Formatter.lifespanSubtitle(years: 0, hoursK: 0), "0 年 · 0 Kh")
        XCTAssertEqual(TimeBank.Formatter.lifespanSubtitle(years: 44.6, hoursK: 472.7), "45 年 · 473 Kh") // round

        // 负数 input clamp（Codex review 二轮加固，PRD §21 4 个新接口的边界契约）
        XCTAssertEqual(TimeBank.Formatter.weeklyHours(-5), "每周约 0 小时")
        XCTAssertEqual(TimeBank.Formatter.dailyHoursWith(-3, action: "共处"), "每天约 0 小时共处")
        XCTAssertEqual(TimeBank.Formatter.lifespanSubtitle(years: -10, hoursK: -100), "0 年 · 0 Kh")
    }

    func testBuiltinComputeFunctionsProduceStableNonNegativeValues() throws {
        let calendar = Calendar(identifier: .gregorian)
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 4, day: 1)) ?? .now

        let profile = UserProfile(
            birthday: birthday,
            gender: .undisclosed,
            expectedLifespanYears: 85,
            parents: ParentsInfo(
                father: FamilyMember(birthYear: 1958, deceased: false, deceasedAt: nil),
                mother: FamilyMember(birthYear: 1960, deceased: false, deceasedAt: nil),
                visitsPerYear: 4,
                hoursPerVisit: 6,
                expectedLifespan: 82
            ),
            children: [
                ChildInfo(birthYear: 2018, gender: .undisclosed, deceased: false, deceasedAt: nil)
            ],
            partner: PartnerInfo(
                birthYear: 1991,
                hoursPerDay: 4,
                deceased: false,
                deceasedAt: nil
            ),
            soloEmphasis: false,
            extras: []
        )

        let parents = TimeBank.Dimension(
            id: DimensionReservedID.parents.rawValue,
            name: "陪父母",
            kind: .builtin,
            status: .visible,
            mode: .normal,
            iconKey: "heart",
            colorKey: "rose",
            sortIndex: 1,
            params: TimeBank.Dimension.encodedParams(EmptyDimensionParams())
        )
        let kids = TimeBank.Dimension(
            id: DimensionReservedID.kids.rawValue,
            name: "陪孩子",
            kind: .builtin,
            status: .visible,
            mode: .normal,
            iconKey: "figure.2.and.child.holdinghands",
            colorKey: "warm",
            sortIndex: 2,
            params: TimeBank.Dimension.encodedParams(EmptyDimensionParams())
        )
        let partner = TimeBank.Dimension(
            id: DimensionReservedID.partner.rawValue,
            name: "陪伴侣",
            kind: .builtin,
            status: .visible,
            mode: .normal,
            iconKey: "sparkles.heart",
            colorKey: "lavender",
            sortIndex: 3,
            params: TimeBank.Dimension.encodedParams(EmptyDimensionParams())
        )
        let sport = TimeBank.Dimension(
            id: DimensionReservedID.sport.rawValue,
            name: "运动",
            kind: .builtin,
            status: .visible,
            mode: .normal,
            iconKey: "figure.run",
            colorKey: "sage",
            sortIndex: 4,
            params: TimeBank.Dimension.encodedParams(SportDimensionParams())
        )
        let create = TimeBank.Dimension(
            id: DimensionReservedID.create.rawValue,
            name: "创造",
            kind: .builtin,
            status: .visible,
            mode: .normal,
            iconKey: "paintbrush",
            colorKey: "sky",
            sortIndex: 5,
            params: TimeBank.Dimension.encodedParams(CreateDimensionParams())
        )
        let free = TimeBank.Dimension(
            id: DimensionReservedID.free.rawValue,
            name: "自由",
            kind: .builtin,
            status: .visible,
            mode: .normal,
            iconKey: "sun.max",
            colorKey: "peach",
            sortIndex: 6,
            params: TimeBank.Dimension.encodedParams(FreeDimensionParams())
        )

        let lookup = Dictionary(uniqueKeysWithValues: [parents, kids, partner, sport, create, free].map { ($0.id, $0) })

        XCTAssertGreaterThanOrEqual(DimensionCompute.Lifespan.remainingWeeks(profile: profile), 0)
        XCTAssertGreaterThanOrEqual(DimensionCompute.Lifespan.remainingYears(profile: profile), 0)
        XCTAssertGreaterThanOrEqual(DimensionCompute.Lifespan.remainingHoursK(profile: profile), 0)

        XCTAssertGreaterThanOrEqual(DimensionCompute.consumeHours(for: parents, profile: profile, dimensionsByID: lookup), 0)
        XCTAssertGreaterThanOrEqual(DimensionCompute.consumeHours(for: kids, profile: profile, dimensionsByID: lookup), 0)
        XCTAssertGreaterThanOrEqual(DimensionCompute.consumeHours(for: partner, profile: profile, dimensionsByID: lookup), 0)
        XCTAssertGreaterThanOrEqual(DimensionCompute.consumeHours(for: sport, profile: profile, dimensionsByID: lookup), 0)
        XCTAssertGreaterThanOrEqual(DimensionCompute.consumeHours(for: create, profile: profile, dimensionsByID: lookup), 0)
        XCTAssertGreaterThanOrEqual(DimensionCompute.consumeHours(for: free, profile: profile, dimensionsByID: lookup), 0)
    }

    // MARK: - V1.3.2 新增测试（Codex review 后补充）

    /// PRD §7.6 保留 ID seed 默认值 invariant：
    /// - daily.name 必须是 "__daily" 占位（V1 不暴露 V1.1+ 功能名）
    /// - 关系型（parents/kids/partner）seed 默认 .hidden（等 Onboarding 勾选后转 visible）
    /// - 通用型（sport/create/free）seed 默认 .visible（人人都适用）
    /// - lifespan 默认 .visible 且 kind = .systemTop
    func testReservedDimensionSeedInvariants() throws {
        let env = try TestEnvironment()
        defer { env.cleanup() }

        try TimeBank.Dimension.seedReservedDimensionsIfNeeded(in: env.context)

        let daily = try XCTUnwrap(TimeBank.Dimension.fetch(by: DimensionReservedID.daily.rawValue, in: env.context))
        XCTAssertEqual(daily.name, "__daily", "daily 占位名必须是 __daily（V1 不能暴露 V1.1 功能名 '今日此刻'）")
        XCTAssertEqual(daily.kind, .systemHidden)
        XCTAssertEqual(daily.status, .hidden)

        for relationalId in [DimensionReservedID.parents, .kids, .partner] {
            let dim = try XCTUnwrap(TimeBank.Dimension.fetch(by: relationalId.rawValue, in: env.context))
            XCTAssertEqual(dim.kind, .builtin)
            XCTAssertEqual(dim.status, .hidden, "关系型 \(relationalId.rawValue) seed 默认必须 .hidden")
        }

        for genericId in [DimensionReservedID.sport, .create, .free] {
            let dim = try XCTUnwrap(TimeBank.Dimension.fetch(by: genericId.rawValue, in: env.context))
            XCTAssertEqual(dim.kind, .builtin)
            XCTAssertEqual(dim.status, .visible, "通用型 \(genericId.rawValue) seed 默认必须 .visible")
        }

        let lifespan = try XCTUnwrap(TimeBank.Dimension.fetch(by: DimensionReservedID.lifespan.rawValue, in: env.context))
        XCTAssertEqual(lifespan.kind, .systemTop)
        XCTAssertEqual(lifespan.status, .visible)
        XCTAssertEqual(lifespan.name, "时间余额")

        let other = try XCTUnwrap(TimeBank.Dimension.fetch(by: DimensionReservedID.other.rawValue, in: env.context))
        XCTAssertEqual(other.kind, .systemHidden)
        XCTAssertEqual(other.status, .hidden)
    }

    /// MomentStore.save 必须按 Dimension.kind 白名单校验：
    /// 只允许 .builtin / .custom；拒绝 .systemTop / .systemHidden / .systemVirtual；
    /// dimensionId 不存在时抛 .dimensionNotFound。
    /// 依据：PRD §7.6「systemTop / systemHidden 无存储层」+ V1.3.2 Codex review 二轮加固。
    func testSaveRejectsSystemDimensionsAndAcceptsValidKinds() async throws {
        let env = try TestEnvironment()
        defer { env.cleanup() }

        let store = env.makeMomentStore()
        _ = try store.bootstrapReservedData()

        // (1) 系统账户（lifespan = systemTop；daily / other = systemHidden）→ invalidDimensionForMoment
        for forbiddenId in [DimensionReservedID.lifespan, .daily, .other] {
            let request = MomentStore.SaveRequest(
                dimensionId: forbiddenId.rawValue,
                durationSeconds: 3600,
                media: []
            )
            do {
                _ = try await store.save(moment: request)
                XCTFail("save 应该拒绝 \(forbiddenId.rawValue)，但没抛错")
            } catch let error as MomentStore.MomentStoreError {
                guard case .invalidDimensionForMoment(let id) = error else {
                    XCTFail("期望 .invalidDimensionForMoment，实际 \(error)")
                    return
                }
                XCTAssertEqual(id, forbiddenId.rawValue)
            } catch {
                XCTFail("期望 MomentStoreError.invalidDimensionForMoment，实际 \(error)")
            }
        }

        // (2) systemVirtual 也应被拒（虚构一个保存到 DB 的 systemVirtual dimension）
        let virtualId = "test-virtual-dim"
        let virtualDim = TimeBank.Dimension(
            id: virtualId,
            name: "test virtual",
            kind: .systemVirtual,
            status: .hidden,
            mode: .normal,
            iconKey: "circle",
            colorKey: "rose",
            sortIndex: 999,
            params: TimeBank.Dimension.encodedParams(EmptyDimensionParams())
        )
        env.context.insert(virtualDim)
        try env.context.save()

        do {
            _ = try await store.save(moment: MomentStore.SaveRequest(
                dimensionId: virtualId,
                durationSeconds: 3600,
                media: []
            ))
            XCTFail("save 应该拒绝 systemVirtual dimension")
        } catch MomentStore.MomentStoreError.invalidDimensionForMoment(let id) {
            XCTAssertEqual(id, virtualId)
        } catch {
            XCTFail("期望 .invalidDimensionForMoment，实际 \(error)")
        }

        // (3) dimensionId 不存在 → dimensionNotFound
        let unknownId = "non-existent-\(UUID().uuidString)"
        do {
            _ = try await store.save(moment: MomentStore.SaveRequest(
                dimensionId: unknownId,
                durationSeconds: 3600,
                media: []
            ))
            XCTFail("save 应该拒绝不存在的 dimensionId")
        } catch MomentStore.MomentStoreError.dimensionNotFound(let id) {
            XCTAssertEqual(id, unknownId)
        } catch {
            XCTFail("期望 .dimensionNotFound，实际 \(error)")
        }

        // (4) builtin (parents) 应该接受 — 即使 status 是 .hidden
        let parentsId = DimensionReservedID.parents.rawValue
        let savedFromBuiltin = try await store.save(moment: MomentStore.SaveRequest(
            dimensionId: parentsId,
            durationSeconds: 3600,
            media: []
        ))
        XCTAssertEqual(savedFromBuiltin.dimensionId, parentsId)

        // (5) custom 应该接受
        let customId = UUID().uuidString
        let customDim = TimeBank.Dimension(
            id: customId,
            name: "阅读",
            kind: .custom,
            status: .visible,
            mode: .normal,
            iconKey: "book",
            colorKey: "sky",
            sortIndex: 100,
            params: TimeBank.Dimension.encodedParams(EmptyDimensionParams())
        )
        env.context.insert(customDim)
        try env.context.save()

        let savedFromCustom = try await store.save(moment: MomentStore.SaveRequest(
            dimensionId: customId,
            durationSeconds: 1800,
            media: []
        ))
        XCTAssertEqual(savedFromCustom.dimensionId, customId)

        XCTAssertEqual(try store.fetchAllMoments().count, 2, "2 个有效 save 应该都留下了 DB 记录")
    }

    /// PRD §22.3.1 6 内置时间账户的副文案数据契约。
    func testDimensionSubtitleDataForBuiltins() throws {
        let env = try TestEnvironment()
        defer { env.cleanup() }

        try TimeBank.Dimension.seedReservedDimensionsIfNeeded(in: env.context)

        let calendar = Calendar(identifier: .gregorian)
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 4, day: 1)) ?? .now
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)) ?? .now

        let profile = UserProfile(
            birthday: birthday,
            gender: .undisclosed,
            expectedLifespanYears: 85,
            parents: ParentsInfo(
                father: FamilyMember(birthYear: 1958, deceased: false, deceasedAt: nil),
                mother: FamilyMember(birthYear: 1960, deceased: false, deceasedAt: nil),
                visitsPerYear: 4,
                hoursPerVisit: 6,
                expectedLifespan: 82
            ),
            children: [ChildInfo(birthYear: 2018, gender: .undisclosed, deceased: false, deceasedAt: nil)],
            partner: PartnerInfo(birthYear: 1991, hoursPerDay: 4, deceased: false, deceasedAt: nil),
            soloEmphasis: false,
            extras: []
        )

        let allDims = try env.context.fetch(FetchDescriptor<TimeBank.Dimension>())
        let dimsByID = Dictionary(uniqueKeysWithValues: allDims.map { ($0.id, $0) })

        // lifespan
        let lifespanDim = try XCTUnwrap(dimsByID[DimensionReservedID.lifespan.rawValue])
        let lifespanSubtitle = DimensionCompute.subtitleData(for: lifespanDim, profile: profile, dimensionsByID: dimsByID, now: now)
        guard case .lifespan(let years, let hoursK) = lifespanSubtitle else {
            XCTFail("lifespan 应返回 .lifespan case，实际 \(lifespanSubtitle)")
            return
        }
        XCTAssertGreaterThan(years, 0)
        XCTAssertGreaterThan(hoursK, 0)

        // parents → .occurrence
        let parentsDim = try XCTUnwrap(dimsByID[DimensionReservedID.parents.rawValue])
        let parentsSubtitle = DimensionCompute.subtitleData(for: parentsDim, profile: profile, dimensionsByID: dimsByID, now: now)
        guard case .occurrence(let count, let noun) = parentsSubtitle else {
            XCTFail("parents 应返回 .occurrence case，实际 \(parentsSubtitle)")
            return
        }
        XCTAssertGreaterThan(count, 0)
        XCTAssertEqual(noun, "见面")

        // kids → .weeklyHours，孩子 2018 年生 → 2026 = 8 岁，落 6-13 段 = 20 小时/周
        let kidsDim = try XCTUnwrap(dimsByID[DimensionReservedID.kids.rawValue])
        let kidsSubtitle = DimensionCompute.subtitleData(for: kidsDim, profile: profile, dimensionsByID: dimsByID, now: now)
        guard case .weeklyHours(let kidsHpw) = kidsSubtitle else {
            XCTFail("kids 应返回 .weeklyHours case，实际 \(kidsSubtitle)")
            return
        }
        XCTAssertEqual(kidsHpw, 20, accuracy: 0.001, "8 岁孩子应落 6-13 段 = 20h/周")

        // partner → .dailyHoursWith
        let partnerDim = try XCTUnwrap(dimsByID[DimensionReservedID.partner.rawValue])
        let partnerSubtitle = DimensionCompute.subtitleData(for: partnerDim, profile: profile, dimensionsByID: dimsByID, now: now)
        guard case .dailyHoursWith(let pHours, let action) = partnerSubtitle else {
            XCTFail("partner 应返回 .dailyHoursWith case，实际 \(partnerSubtitle)")
            return
        }
        XCTAssertEqual(pHours, 4, accuracy: 0.001)
        XCTAssertEqual(action, "共处")

        // sport → .weeklyHours，36 岁落 < 50 段 = 5h/周
        let sportDim = try XCTUnwrap(dimsByID[DimensionReservedID.sport.rawValue])
        let sportSubtitle = DimensionCompute.subtitleData(for: sportDim, profile: profile, dimensionsByID: dimsByID, now: now)
        guard case .weeklyHours(let sportHpw) = sportSubtitle else {
            XCTFail("sport 应返回 .weeklyHours case")
            return
        }
        XCTAssertEqual(sportHpw, 5, accuracy: 0.001, "36 岁应落 < 50 段 = 5h/周")

        // create → .weeklyHours，36 岁 < 65（focusedPhaseEndAge 默认）= 40h/周
        let createDim = try XCTUnwrap(dimsByID[DimensionReservedID.create.rawValue])
        let createSubtitle = DimensionCompute.subtitleData(for: createDim, profile: profile, dimensionsByID: dimsByID, now: now)
        guard case .weeklyHours(let createHpw) = createSubtitle else {
            XCTFail("create 应返回 .weeklyHours case")
            return
        }
        XCTAssertEqual(createHpw, 40, accuracy: 0.001, "36 岁 < 65 应取 focused 段 = 40h/周")

        // free → .percentOfAwake，应在 0~100 之间
        let freeDim = try XCTUnwrap(dimsByID[DimensionReservedID.free.rawValue])
        let freeSubtitle = DimensionCompute.subtitleData(for: freeDim, profile: profile, dimensionsByID: dimsByID, now: now)
        guard case .percentOfAwake(let pct) = freeSubtitle else {
            XCTFail("free 应返回 .percentOfAwake case")
            return
        }
        XCTAssertGreaterThanOrEqual(pct, 0)
        XCTAssertLessThanOrEqual(pct, 100)

        // memorial mode 应返回 .none
        let memorialDim = try XCTUnwrap(dimsByID[DimensionReservedID.parents.rawValue])
        memorialDim.mode = .memorial
        let memorialSubtitle = DimensionCompute.subtitleData(for: memorialDim, profile: profile, dimensionsByID: dimsByID, now: now)
        XCTAssertEqual(memorialSubtitle, .none, "memorial mode 应返回 .none")
    }

    /// childQualityHours 必须包含 18+ 尾段（V1.3.2 Codex review 发现的对称性 bug）。
    /// 公式：0-6 岁 30h/周、6-13 岁 20h/周、13-18 岁 10h/周、18+ 2h/周。
    func testKidsHoursIncludesAdultBand() throws {
        let calendar = Calendar(identifier: .gregorian)
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 4, day: 1)) ?? .now
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1)) ?? .now // self 36 岁

        // 用单个 5 岁孩子构造 profile，self 寿命 85 → 还有 49 年
        let profile = UserProfile(
            birthday: birthday,
            gender: .undisclosed,
            expectedLifespanYears: 85,
            parents: nil,
            children: [ChildInfo(birthYear: 2021, gender: nil, deceased: false, deceasedAt: nil)],
            partner: nil,
            soloEmphasis: false,
            extras: []
        )

        let kidsDim = TimeBank.Dimension(
            id: DimensionReservedID.kids.rawValue,
            name: "陪孩子",
            kind: .builtin,
            status: .visible,
            mode: .normal,
            iconKey: "figure.2.and.child.holdinghands",
            colorKey: "warm",
            sortIndex: 2,
            params: TimeBank.Dimension.encodedParams(EmptyDimensionParams())
        )

        let kidsHours = DimensionCompute.consumeHours(for: kidsDim, profile: profile, dimensionsByID: [:], now: now)

        // 5 岁孩子，剩余 49 年（self 寿命 85 - age 36）
        // 0-6 段：1 年 × 52.1429 × 30 ≈ 1564.29
        // 6-13 段：7 年 × 52.1429 × 20 ≈ 7300.01
        // 13-18 段：5 年 × 52.1429 × 10 ≈ 2607.15
        // 18+ 段：49 - 13 = 36 年 × 52.1429 × 2 ≈ 3754.29
        // 总：约 15225.74
        XCTAssertGreaterThan(kidsHours, 15000, "kidsHours 必须包含 18+ 尾段，应 > 15000h（旧实现漏算约 3754h）")
        XCTAssertLessThan(kidsHours, 16000)

        // 孩子已成年（25 岁）case
        let adultProfile = UserProfile(
            birthday: birthday,
            gender: .undisclosed,
            expectedLifespanYears: 85,
            parents: nil,
            children: [ChildInfo(birthYear: 2001, gender: nil, deceased: false, deceasedAt: nil)],
            partner: nil,
            soloEmphasis: false,
            extras: []
        )
        let adultKidsHours = DimensionCompute.consumeHours(for: kidsDim, profile: adultProfile, dimensionsByID: [:], now: now)
        // 25 岁 ≥ 18，全程 49 年 × 52.1429 × 2 ≈ 5110.0
        XCTAssertGreaterThan(adultKidsHours, 5000)
        XCTAssertLessThan(adultKidsHours, 5200)

        // 边界 1：0 岁孩子（今年生），完整覆盖 0-6 / 6-13 / 13-18 / 18+ 四段
        let infantProfile = UserProfile(
            birthday: birthday,
            gender: .undisclosed,
            expectedLifespanYears: 85,
            parents: nil,
            children: [ChildInfo(birthYear: 2026, gender: nil, deceased: false, deceasedAt: nil)],
            partner: nil,
            soloEmphasis: false,
            extras: []
        )
        let infantKidsHours = DimensionCompute.consumeHours(for: kidsDim, profile: infantProfile, dimensionsByID: [:], now: now)
        // 0-6: 6×52.1429×30 ≈ 9385.72; 6-13: 7×52.1429×20 ≈ 7300.01;
        // 13-18: 5×52.1429×10 ≈ 2607.15; 18+: 31×52.1429×2 ≈ 3232.86
        // 总：约 22525.74
        XCTAssertGreaterThan(infantKidsHours, 22000, "0 岁孩子应覆盖全 4 段")
        XCTAssertLessThan(infantKidsHours, 23000)

        // 边界 2：self 剩余 0 年（expectedLifespan = 当前 age）
        let dyingProfile = UserProfile(
            birthday: birthday,
            gender: .undisclosed,
            expectedLifespanYears: 36, // self 当前 36 岁，剩余 0
            parents: nil,
            children: [ChildInfo(birthYear: 2021, gender: nil, deceased: false, deceasedAt: nil)],
            partner: nil,
            soloEmphasis: false,
            extras: []
        )
        let dyingKidsHours = DimensionCompute.consumeHours(for: kidsDim, profile: dyingProfile, dimensionsByID: [:], now: now)
        XCTAssertEqual(dyingKidsHours, 0, accuracy: 0.001, "self 剩余 0 年时应返回 0（cap 生效）")

        // 边界 3：所有孩子已故
        let bereavedProfile = UserProfile(
            birthday: birthday,
            gender: .undisclosed,
            expectedLifespanYears: 85,
            parents: nil,
            children: [ChildInfo(birthYear: 2018, gender: nil, deceased: true, deceasedAt: now)],
            partner: nil,
            soloEmphasis: false,
            extras: []
        )
        let bereavedKidsHours = DimensionCompute.consumeHours(for: kidsDim, profile: bereavedProfile, dimensionsByID: [:], now: now)
        XCTAssertEqual(bereavedKidsHours, 0, accuracy: 0.001, "所有孩子已故应返回 0")
    }

    private func makeJPEGData(size: CGSize = CGSize(width: 40, height: 40), color: UIColor = .systemOrange) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        guard let data = image.jpegData(compressionQuality: 0.92) else {
            XCTFail("Failed to create test JPEG data.")
            return Data()
        }

        return data
    }

    private func XCTAssertThrowsErrorAsync(
        _ expression: @escaping () async throws -> Void,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await expression()
            XCTFail(message().isEmpty ? "Expected error to be thrown." : message(), file: file, line: line)
        } catch {
            // expected
        }
    }
}
