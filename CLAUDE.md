# 时间银行 — 项目索引

> 2026-07-13 重写（旧版停留在 4-26 的 V1.3.2 快照，已失真）。历史 PRD/UC/设计文档全部在 `各类 md 文件/`。

## 产品定位
"时间可视化 + 时间沉淀"双层 App：消耗层看清重要时间账户的剩余（陪父母/陪孩子/运动/伴侣/创造/自由），存储层把有意义的时刻（图文视频）永久封存、只增不减。调性是**珍惜与感受当下**，不是焦虑倒计时。Widget-first、无联网无注册。

## 当前状态（2026-07-13）
- **分支 `m3-app-loop`**（已推 GitHub `no996chen-tennis/time-bank`），App 已在 Adam 真机迭代。
- **首页 4 布局并存待收敛**：经典 / 大图·单图 / 大图·多图 / 大图·带文字（`HomeLayoutKind`，设置→首页样式切换）。Adam 对现状不满意，方案讨论中；收敛后删多余（View + RootView case + enum case + pbxproj 登记一起删）。
- 「今天剩余」可支配时间条（App 秒级跳动，Widget 分钟级），基于损耗段建模（睡眠/三餐/杂项预设）。
- Widget：三尺寸 + 锁屏；回忆面缩略图已加大加清晰。
- 最新设计载体：`designs/home-widget-redesign-comparison.html`（7-10）+ `真机截图/`（7-6）。
- 里程碑分支 `main` / `m1-data-layer` / `m2-onboarding-home` / `claude/retention-p0` 各代表历史阶段，尚无统一合并计划。

## 工程铁律（都是真踩过的坑）
1. 标准 xcodeproj（**非 xcodegen**）：新 `.swift` 必须手动登记 `project.pbxproj`（仅 `TimeBank/Retention/` 与 `TimeBankTests/` 免登记）。
2. Widget target 只编译 `TimeBankWidget.swift` + `WidgetSnapshot.swift` 两个文件；要给 Widget 用的类型（含 `openAppWhenRun` 的 AppIntent）必须写进 `WidgetSnapshot.swift`，否则真机点按钮无反应。
3. Widget 图片从原图 `relativePath` 降采样（≥480px），禁止拿 200px 缩略图放大。
4. 媒体保存必须包 `withBackgroundTask`：切后台挂起会造成"文件在、数据库记录丢"→ 孤儿清理误删（已加 24h 宽限期 + os_log）。
5. 编译验证：`xcodebuild build -project TimeBank/TimeBank.xcodeproj -scheme TimeBank -destination 'generic/platform=iOS Simulator'`；实现 agent 只编译、不 boot 模拟器。
6. 真机：自动签名 team L73W528KAY；设备 iPhone 17 Pro Max（UDID 00008150-00017CE42E87801C）；`xcodebuild -allowProvisioningUpdates build` + `xcrun devicectl device install app`。

## 文档地图
| 路径 | 内容 |
|------|------|
| `各类 md 文件/` | 全部历史文档（PRD V1.3.2、Use-Cases、进度报告-2026-06-11、协作协议等，2026-07 从顶层迁入） |
| `designs/` | 设计稿仓库（最新：home-widget-redesign-comparison.html） |
| `真机截图/` | 最新真机走查截图 |
| `TimeBank/` `TimeBankWidget/` | Xcode 工程与 Widget 扩展 |
