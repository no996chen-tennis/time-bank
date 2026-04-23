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

    func testFormatterMatrixCoversAllSevenInterfaces() {
        XCTAssertEqual(TimeBank.Formatter.hoursCompact(552), "552h")
        XCTAssertEqual(TimeBank.Formatter.hoursCompact(1_240), "1,240h")
        XCTAssertEqual(TimeBank.Formatter.hoursCompact(18_240), "18.2Kh")

        XCTAssertEqual(TimeBank.Formatter.hoursReadable(128), "128 小时")
        XCTAssertEqual(TimeBank.Formatter.hoursReadable(48.5), "48.5 小时")
        XCTAssertEqual(TimeBank.Formatter.hoursReadable(0), "0 小时")

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
