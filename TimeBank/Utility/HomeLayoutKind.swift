// TimeBank/Utility/HomeLayoutKind.swift

import Foundation

/// 首页布局样式（@AppStorage 持久化 rawValue；未知/残留值经 `?? .classic` 回落）。
enum HomeLayoutKind: String, CaseIterable, Identifiable {
    static let storageKey = "timeBank.homeLayout"
    case classic        // 首页A：现有布局改造（维度卡内嵌小图横滑带）
    case bigPhoto       // 首页C：全新大图为主首页（单图）
    case bigPhotoMulti  // 大图·多图：每维度横向多张照片
    case bigPhotoText   // 大图·带文字：大封面叠加记录的标题

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic:        return "经典"
        case .bigPhoto:       return "大图·单图"
        case .bigPhotoMulti:  return "大图·多图"
        case .bigPhotoText:   return "大图·带文字"
        }
    }

    var subtitle: String {
        switch self {
        case .classic:        return "维度卡保留数字，内嵌可横滑小图"
        case .bigPhoto:       return "每维度一张大封面"
        case .bigPhotoMulti:  return "每维度横向多张照片"
        case .bigPhotoText:   return "大封面叠加记录的标题"
        }
    }

    /// Settings 选择行用的 SF Symbol 图标名（穷举，避免非穷举 switch 编译报错）。
    var iconName: String {
        switch self {
        case .classic:        return "rectangle.on.rectangle"
        case .bigPhoto:       return "photo.on.rectangle"
        case .bigPhotoMulti:  return "photo.stack"
        case .bigPhotoText:   return "text.below.photo"
        }
    }
}
