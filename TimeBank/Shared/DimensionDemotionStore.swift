// TimeBank/Shared/DimensionDemotionStore.swift

import Foundation
import SwiftData

@MainActor
struct DimensionDemotionStore {
    let modelContext: ModelContext

    @discardableResult
    func demote(dimensionID: String) throws -> Int {
        let dimension = try Dimension.fetch(by: dimensionID, in: modelContext)
        let other = try ensureOtherDimension()
        let now = Date()
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        var movedCount = 0

        for moment in moments where moment.dimensionId == dimensionID && moment.status == .normal {
            moment.originDimensionId = dimensionID
            moment.dimensionId = other.id
            moment.updatedAt = now
            movedCount += 1
        }

        dimension?.status = .hidden
        dimension?.updatedAt = now
        try modelContext.save()
        return movedCount
    }

    @discardableResult
    func restore(dimensionID: String) throws -> Int {
        let otherID = DimensionReservedID.other.rawValue
        let now = Date()
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        var restoredCount = 0

        for moment in moments where moment.dimensionId == otherID && moment.originDimensionId == dimensionID && moment.status == .normal {
            moment.dimensionId = dimensionID
            moment.originDimensionId = nil
            moment.updatedAt = now
            restoredCount += 1
        }

        if let dimension = try Dimension.fetch(by: dimensionID, in: modelContext) {
            dimension.status = .visible
            dimension.updatedAt = now
        }

        try modelContext.save()
        return restoredCount
    }

    func recoverableMomentCount(for dimensionID: String) throws -> Int {
        let otherID = DimensionReservedID.other.rawValue
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        return moments.filter {
            $0.dimensionId == otherID
                && $0.originDimensionId == dimensionID
                && $0.status == .normal
        }.count
    }

    func sourceMomentCount(for dimensionID: String) throws -> Int {
        let moments = try modelContext.fetch(FetchDescriptor<Moment>())
        return moments.filter { $0.dimensionId == dimensionID && $0.status == .normal }.count
    }

    @discardableResult
    func removeParents(from profile: UserProfile) throws -> Int {
        profile.parents = nil
        profile.updatedAt = .now
        return try demote(dimensionID: DimensionReservedID.parents.rawValue)
    }

    @discardableResult
    func removePartner(from profile: UserProfile) throws -> Int {
        profile.partner = nil
        profile.updatedAt = .now
        return try demote(dimensionID: DimensionReservedID.partner.rawValue)
    }

    @discardableResult
    func removeChild(_ childID: UUID, from profile: UserProfile) throws -> Int {
        profile.children.removeAll { $0.id == childID }
        profile.updatedAt = .now

        // A2 contract: removing one child does not demote "kids" while at least one child remains.
        // Only removing the last child triggers the demotion protocol and hides the kids dimension.
        guard profile.children.isEmpty else {
            try modelContext.save()
            return 0
        }

        return try demote(dimensionID: DimensionReservedID.kids.rawValue)
    }

    func markDimensionVisible(_ dimensionID: String) throws {
        if let dimension = try Dimension.fetch(by: dimensionID, in: modelContext) {
            dimension.status = .visible
            dimension.updatedAt = .now
        }
        try modelContext.save()
    }

    private func ensureOtherDimension() throws -> Dimension {
        if let other = try Dimension.fetch(by: DimensionReservedID.other.rawValue, in: modelContext) {
            return other
        }

        try Dimension.seedReservedDimensionsIfNeeded(in: modelContext)
        if let other = try Dimension.fetch(by: DimensionReservedID.other.rawValue, in: modelContext) {
            return other
        }

        let other = Dimension(
            id: DimensionReservedID.other.rawValue,
            name: "其他",
            kind: .systemHidden,
            status: .hidden,
            mode: .normal,
            iconKey: "tray",
            colorKey: "rose",
            sortIndex: 91,
            params: Dimension.encodedParams(EmptyDimensionParams())
        )
        modelContext.insert(other)
        return other
    }
}
