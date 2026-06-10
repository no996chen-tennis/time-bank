// TimeBank/Features/Onboarding/Step4DoneView.swift

import ImageIO
import PhotosUI
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications

struct Step4DoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var draft: OnboardingDraft
    @State private var isFinishing = false
    @State private var prefillItems: [PhotosPickerItem] = []
    @State private var prefillPhotos: [PrefillPhoto] = []

    let onNext: () -> Void
    let onBack: () -> Void

    /// 开户首存的待存照片（禀赋进度：从一段已经存在的回忆开始，不从零开始）。
    private struct PrefillPhoto {
        let data: Data
        let fileExtension: String
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TBSpace.s6) {
            Spacer()

            completionCopy
            notificationCopy
            prefillCopy

            Spacer()

            VStack(spacing: TBSpace.s3) {
                Button("好，开启提醒") {
                    Task {
                        await finish(requestNotifications: true)
                    }
                }
                .buttonStyle(OnboardingNavigationButtonStyle())
                .disabled(isFinishing)
                .opacity(isFinishing ? 0.5 : 1)

                Button("以后再说") {
                    Task {
                        await finish(requestNotifications: false)
                    }
                }
                .buttonStyle(OnboardingSecondaryButtonStyle())
                .disabled(isFinishing)
                .opacity(isFinishing ? 0.5 : 1)
            }
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var completionCopy: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("做好了。")
                .font(.tbHeadM)
                .foregroundStyle(Color.tbInk)

            Text("一切就绪。开始吧。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var notificationCopy: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("每天早上轻轻提醒一次。不催。")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            Text("只是帮你记得：今天也有一些片段，值得被留下。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(TBSpace.s5)
        .background(Color.tbBg2)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
    }

    private var prefillCopy: some View {
        VStack(alignment: .leading, spacing: TBSpace.s3) {
            Text("如果你愿意，先存一笔")
                .font(.tbHeadS)
                .foregroundStyle(Color.tbInk)

            Text("选一两张和重要的人的旧照片。每个账户，都可以从一段已经存在的回忆开始。")
                .font(.tbBody)
                .foregroundStyle(Color.tbInk2)
                .fixedSize(horizontal: false, vertical: true)

            PhotosPicker(
                selection: $prefillItems,
                maxSelectionCount: 3,
                matching: .images
            ) {
                Label(
                    prefillPhotos.isEmpty ? "从相册选 1-3 张" : "已选 \(prefillPhotos.count) 张 · 重新选",
                    systemImage: prefillPhotos.isEmpty ? "photo.on.rectangle" : "checkmark.circle"
                )
                .font(.tbBodySm)
                .foregroundStyle(Color.tbPrimary)
            }

            if prefillPhotos.isEmpty == false {
                Text("完成后，它们会成为你的第一笔存入。")
                    .font(.tbLabel)
                    .foregroundStyle(Color.tbInk3)
            }
        }
        .padding(TBSpace.s5)
        .background(Color.tbBg2)
        .clipShape(RoundedRectangle(cornerRadius: TBRadius.lg))
        .onChange(of: prefillItems) { _, newItems in
            Task { await loadPrefillPhotos(from: newItems) }
        }
    }

    @MainActor
    private func loadPrefillPhotos(from items: [PhotosPickerItem]) async {
        var loaded: [PrefillPhoto] = []
        for item in items.prefix(3) {
            guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
            let fileExtension = item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
            loaded.append(PrefillPhoto(data: data, fileExtension: fileExtension))
        }
        prefillPhotos = loaded
    }

    @MainActor
    private func finish(requestNotifications: Bool) async {
        guard isFinishing == false else { return }
        isFinishing = true
        defer { isFinishing = false }

        if requestNotifications {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        }

        guard (try? draft.finalize(in: modelContext)) != nil else {
            return
        }

        await savePrefillMoments()

        onNext()
    }

    /// 开户首存：把选中的旧照存成第一批瞬间。拍摄日期从 EXIF 读（读不到就用现在），
    /// 失败静默跳过——首存是礼物，不能挡住 onboarding 完成。
    @MainActor
    private func savePrefillMoments() async {
        guard prefillPhotos.isEmpty == false,
              let dimensionID = prefillDimensionID()
        else {
            return
        }

        let store = MomentStore(modelContext: modelContext)
        for photo in prefillPhotos {
            let request = MomentStore.SaveRequest(
                dimensionId: dimensionID,
                title: "一段旧时光",
                happenedAt: Self.exifDate(from: photo.data) ?? .now,
                media: [.image(data: photo.data, fileExtension: photo.fileExtension)]
            )
            _ = try? await store.save(moment: request)
        }
    }

    private func prefillDimensionID() -> String? {
        guard let dimensions = try? modelContext.fetch(FetchDescriptor<Dimension>()) else { return nil }
        let visible = dimensions.filter { $0.status == .visible && $0.mode == .normal }

        let priority = [
            DimensionReservedID.parents.rawValue,
            DimensionReservedID.partner.rawValue,
            DimensionReservedID.kids.rawValue,
            DimensionReservedID.free.rawValue
        ]
        for id in priority where visible.contains(where: { $0.id == id }) {
            return id
        }
        return visible.first?.id
    }

    private static func exifDate(from data: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
              let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String
        else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateString)
    }
}

struct OnboardingNavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBody)
            .foregroundStyle(Color.tbSurface)
            .padding(.horizontal, TBSpace.s6)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbPrimary.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(Capsule())
    }
}

struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.tbBody)
            .foregroundStyle(Color.tbInk2)
            .padding(.horizontal, TBSpace.s6)
            .padding(.vertical, TBSpace.s3)
            .background(Color.tbBg2.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(Capsule())
    }
}
