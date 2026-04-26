# 时间银行 · 全版本 UseCase 总览

> Version: 1.0 | Date: 2026-04-26
>
> 这是一份 **high-level UC 索引**，覆盖 V1 / V1.1 / V1.5 / V2+ 全部规划。详细交互 spec 见 `Use-Cases-详尽交互.md`（V1 已实现部分）和 `PRD-时间银行-V1.md`（roadmap）。
>
> 用途：
> - 任意时刻看清产品总图（功能漏点 / 优先级 / 版本归属）
> - 给新协作者快速建立 mental map
> - **Codex 审核漏洞**时的单一来源
>
> 维护规则：每条 UC 一行说明 + 状态图标。详细交互不放这里，避免重复。

---

## 状态图标

| 图标 | 含义 |
|---|---|
| ✅ | V1 已实现（M1-M3 完成）|
| 🔄 | V1 实施中 |
| 📋 | V1 已规划但未做（M4-M6）|
| 🌱 | V1.1 候补（上线后 1-2 月）|
| 🌿 | V1.5 候补（上线后 3 月）|
| 💭 | V2+ 探索 |
| ❌ | 明确不做（永远不在 roadmap）|

---

## V1 · P0（必须有 · 总 24 项）

### 一、数据层 + 工具（M1 ✅）

| ID | 名称 | 状态 | 说明 |
|---|---|---|---|
| D-1 | SwiftData @Model 全套 | ✅ | UserProfile / Dimension / Moment / MediaItem / Settings · §7.6 schema |
| D-2 | MomentStore 强原子事务 | ✅ | save / update / delete / undoDelete / commitPendingDeletes 全套接口 |
| D-3 | FileStore 沙盒读写 + 缩略图 | ✅ | HEIC/MP4 原格式 · CGImageSource / AVAssetImageGenerator |
| D-4 | 孤儿文件清理 | ✅ | 启动时扫描 `Documents/TimeBank/moments/` 无 DB 记录的文件夹 |
| D-5 | Formatter Matrix 全 13 接口 | ✅ | hoursCompact / hoursReadable / hoursWithMinutes / occurrenceCount / momentsCount / relativeTime / absoluteDate / weeklyHours / dailyHoursWith / percentOfAwake / lifespanSubtitle / hoursInDays + 各 helper |
| D-6 | DimensionCompute 6 账户消耗逻辑 | ✅ | 父母 / 孩子 / 伴侣 / 运动 / 创造 / 自由 + lifespan 周数 |
| D-7 | 延迟删除 5s + Undo 协议 | ✅ | pendingDelete 状态 + 5s Timer + 启动 commit |
| D-8 | 聚合排除 pendingDelete | ✅ | storedHours / storedMomentCount 自动过滤 |
| D-9 | 主页 totalAccount vs 账户 Tab accountTabAggregate | ✅ | 主页不含 other / 账户 Tab 含 other |

---

### 二、引导 + 主页（M2 ✅）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-0.1 | 5 步 Onboarding | ✅ | Welcome / 生日 / 关系 chip / 条件化详情 / 完成 · 默认勾 solo · 总耗时 ≤ 60s |
| UC-2.1 | 主页时间账户卡片 | ✅ | 6 内置卡（按 onboarding 勾选过滤）· 双数字 · 副文案按 §22.3.1 |
| P0-21 | lifespan 顶部时间账户 | ✅ | systemTop kind · 主页双层卡上半 |
| P0-22 | 主页双层 lifespan + 已存入卡 | ✅ | 上半 lifespan / 下半 totalAccount · 高度 ≤ 240pt |
| P0-23 | 3 Tab 底部导航 | ✅ | 主页 / 账户 / 我 + 中央 FAB |
| P0-24 | 主页一屏容纳 | ✅ | iPhone 16 Pro 852pt 屏首屏可见双层卡 + ≥4 张卡 |

---

### 三、详情 + 参数 + 个人信息 + 下沉（M3 A 段 ✅）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-2.2 | 时间账户详情页（只读）| ✅ | 头部双数字 + 计算方式卡 + 时间线 |
| UC-2.3 | 修改计算参数 | ✅ | 6 账户参数滑块 / 警告文案 / 恢复默认 / 弃改 Alert |
| UC-1.1 | 查看个人信息 | ✅ | "我" Tab → 个人信息 |
| UC-1.2 | 修改个人信息 | ✅ | 生日 / 性别 / 预期寿命 / 关系信息 |
| UC-0.2 | 补充/修改 Onboarding 跳过的关系信息 | ✅ | 个人信息页添加父母/孩子/伴侣 |
| UC-1.3 | 移除关系（下沉协议）| ✅ | UserProfile.X = nil · Dimension.status = .hidden · Moment 迁 other + originDimensionId |
| UC-1.3.5 | 重新添加关系（恢复路径）| ✅ | 检测 other 下 originDimensionId 匹配 → Alert 询问"收回 N 个瞬间吗？" |

---

### 四、存时刻 CRUD + 时间线 + 详情（M3 B 段 ✅）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-3.1 | 主页 FAB 存入新时刻 | ✅ | 不预填 dimension · 用户在 sheet 内选 |
| UC-3.2 | 详情页右上 + 存入新时刻 | ✅ | 预填当前 dimension |
| UC-3.3 | 新增时刻表单通用流程 | ✅ | dimension picker / 发生在 / 持续 / 标题 / 笔记 / PhotosPicker 9 张媒体 |
| UC-3.4 | 时间账户时间线 | ✅ | 倒序 / 缩略图 / 标题 fallback / 元信息 / 笔记前 36 字 / 分页 20 + 倒数 5 触发 / 到底文案 |
| UC-3.5 | 时刻详情页 | ✅ | 全屏媒体轮播 / 视频系统 AVPlayer / chip / 笔记 / 底部三按钮（编辑/换账户/删除）|
| UC-3.6 | 编辑时刻元数据 | ✅ | 标题 / 笔记 / 时长 / 发生时间 / 媒体增删 + 长按拖拽重排 / 强原子 |
| UC-3.7 | 更换时刻所属时间账户 | ✅ | dimension picker sheet · 单事务 save · 不写 originDimensionId |
| UC-3.8 | 删除单条时刻 + 5s Undo | ✅ | 全局 UndoToastController environmentObject 共享 |
| UC-3.9 | 长按进入批量模式 | ✅ | 顶部 bar 取消/已选 N/全选 · 底部 bar 换账户/删除 |
| UC-3.10 | 批量删除 + 一次性撤销 | ✅ | N 条同 5s Timer · 单 Undo Toast 一次性恢复 |
| UC-3.11 | 批量换时间账户 | ✅ | dimension picker · 一次事务全部切换 |
| UC-4.1 | 添加媒体到时刻 | ✅ | 新增/编辑共用 PhotosPicker · 9 张上限 · 加载失败 ⚠️ 角标 |
| UC-4.2 | 查看媒体（轮播/视频）| ✅ | 详情页系统 PageStyle TabView + AVPlayerViewController |
| UC-4.3 | 调整媒体顺序 | ✅ | 编辑 sheet 长按拖拽 · 更新 sortIndex |
| UC-4.4 | 删除单个媒体 | ✅ | 编辑 sheet 右上 × 按钮 · 物理删除在 modelContext.save() 后 |

---

### 五、账户 Tab + Memorial Mode（M3 C 段 ✅）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-10.1 | 账户 Tab | ✅ | 含 other 总览 + Swift Charts 环形图 + legend + 年度回顾分组 + 0 瞬间空态 |
| UC-0.3 | 标记关系已故 → Memorial Mode | ✅ | Dimension.mode = .memorial · Moment 完全不动 |
| MM-1 | 进入 Memorial 二次 Alert + Toast | ✅ | "标记已故" / 确定标记 (.destructive) / "已标记纪念" toast |
| MM-2 | 退出 Memorial（取消纪念标记）| ✅ | "取消纪念标记" / 确定取消 (.destructive) / "已取消标记" toast |
| MM-3 | Memorial 详情页头部纪念态副文案 | ✅ | 替代消耗层数字 · 按关系映射 |
| MM-4 | Memorial 主页卡片纪念态 | ✅ | "纪念" badge · "记录这一段。" 替代消耗层 · 不变灰 |
| MM-5 | Memorial 期间禁止新增瞬间 | ✅ | 详情页 + 按钮 disabled · MomentEditor picker 排除 memorial · edit 模式保留例外 |
| MM-6 | Memorial 期间编辑/删除/换账户照常 | ✅ | 仅禁"新增"，已有 Moment 操作不受影响 |
| MM-7 | Memorial 长按 sheet 替换按钮 | ✅ | "取消纪念标记" 替换"标记已故" · 隐藏"编辑信息" · 保留"移除" |
| MM-8 | Memorial 在账户 Tab 标识 | ✅ | legend 后追加 ` · 纪念中` |

---

### 六、Widget（M4 📋）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-6.1 | 添加 Widget 到锁屏 | 📋 | 系统 Widget 配置流程 + 应用内引导页 |
| UC-6.2 | Widget 内容展示 | 📋 | 单一锁屏 small family · 时间账户数字或温暖文案 |
| UC-6.3 | 配置 Widget 偏好账户 | 📋 | 简化版 · 选择 1-2 个时间账户 |
| W-1 | App Group 配置 | 📋 | `group.com.adamchen.timebank` |
| W-2 | SnapshotWriter 主 App 写入 | 📋 | 关键变更后 → `snapshot.widget.json` 写入 App Group |
| W-3 | Widget Extension target | 📋 | 不直接读 SwiftData，仅读 snapshot |
| W-4 | Widget 文案轮换池 | 📋 | 已在 §3 文案系统定义 · 工程接入 |

---

### 七、导出 + 设置补完（M4 📋）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-7.1 | 查看存储占用 | 📋 | 设置页显示「数据」占多少 MB |
| UC-7.2 | 导出全部数据（Raw ZIP）| 📋 | 原图/原视频 + JSON 索引 + 人类可读 README |
| UC-7.3 | 清空所有数据 | 📋 | 双 Alert 确认 · 删 SwiftData + 沙盒文件 |
| UC-8.2 | 配置通知偏好 | 📋 | 每天温暖提醒 toggle · 时间 · 文案偏好（轻松/深沉/诗意）|
| UC-8.5 | Pre-permission 通知弹窗 | 📋 | 系统通知弹出前先用 App 内自定义 sheet 解释 |
| UC-9.1 | 通知文案池（默认 N=12）| 📋 | 已在 §4 文案系统定义 · 工程接入 |
| UC-9.2 | 通知文案池（关系型 opt-in）| 📋 | V1 默认关闭 · 用户主动 opt-in |

---

### 八、隐私 + 上架前验收（M5/M6 📋）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| P0-15 | 本地数据存储 | ✅ | SwiftData + FileManager 沙盒 · 无联网无账号 |
| P0-17 | Light Mode 完整适配 | ✅ | Release Criteria 只验收 Light |
| P0-18 | 孤儿文件清理 | ✅ | 已在 M1 实现 |
| P0-19 | 无障碍基线 | 🔄 | VoiceOver 标签 · 44pt 触控 · Dynamic Type 到 .accessibility1 · 已 partial |
| P0-20 | Privacy Manifest + 最小权限 | 📋 | M6 上架前补 · 仅 PhotosPicker（免权限）|
| M5-1 | 真机测试矩阵 | 📋 | 10 条 · iPhone SE / mini / 17 Pro / 17 Plus / 真机相册 / 后台返回 / 杀进程恢复 / 等 |
| M5-2 | TestFlight 内测 | 📋 | 上架前 1-2 周 · 至少 5 个外部测试 |
| M6-1 | App Store Connect 元数据 | 📋 | 截图（5.5"/6.5"/6.7"）/ 描述 / 关键词 / 隐私 |
| M6-2 | 30s 预览视频 | 📋 | 主页 → 存第一条 → 看时间线全流程 |
| M6-3 | 提交审核 | 📋 | Apple Review Guidelines 自检 |

---

### 九、UI 视觉系统（横跨 M2-M5）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| V-1 | DesignTokens.swift | ✅ | 色板 / 字阶 / 间距 / 圆角 / 阴影 |
| V-2 | 主页双层卡视觉 | ✅ | M2 已实现 · M5 polish 待重新设计（Adam 当前不满意）|
| V-3 | 6 时间账户卡片视觉 | ✅ | 同上 |
| V-4 | 详情页头部 + 计算方式卡 | ✅ | 同上 |
| V-5 | MomentEditor sheet | ✅ | 同上 |
| V-6 | 时刻详情媒体轮播 | ✅ | 同上 |
| V-7 | 账户 Tab 环形图 + 年度回顾 | ✅ | 同上 |
| **V-8** | **🎨 V1 UI 重设计**（M5 polish）| **🔄** | **2026-04-26 Adam 决策：当前 UI 太普通，启动 multi-tool 设计探索** |

---

## V1.1 · P1（上线后 1-2 月）

### 自定义维度 CRUD

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-2.4 | 新增自定义时间账户 | 🌱 | 主页底部"+ 添加新时间账户" · 最多 10 个 |
| UC-2.5 | 编辑自定义时间账户 | 🌱 | 改名/图标/颜色/计算方式 |
| UC-2.6 | 删除自定义时间账户 | 🌱 | 走统一下沉协议（同 UC-1.3）|
| UC-2.7 | 排序时间账户卡片 | 🌱 | 主页长按拖拽 · 更新 sortIndex |

### 今日此刻

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-5.1 | 主页查看日常时刻 | 🌱 | 第 N 次洗澡 / 吃饭 / 早晨等 · 隐藏 dimension `daily` |
| UC-5.2 | 从日常时刻快速存入 | 🌱 | 主页快捷入口 · 一键打卡 |
| UC-5.3 | 隐藏/显示日常时刻项 | 🌱 | 用户配置展示哪些日常项 |

### 分享 + 桌面 Widget

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-3.5+ | 分享卡生成（V1.1 简化版）| 🌱 | 1080×1920 图片 · **仅走系统分享表** · 不申请相册写入 |
| W-V1.1-1 | 桌面 Widget 中号 | 🌱 | Home Screen Widget · 多账户 grid |
| W-V1.1-2 | 桌面 Widget 大号 | 🌱 | 同上 + 更多内容 |

### 数据 + 设置

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-7.4 | 从 ZIP 恢复数据 | 🌱 | 设置页导入 ZIP · 重建时间银行 |
| UC-8.1 | 切换叙事模式 | 🌱 | "第 N 次" ↔ "剩余 N 次" 全局切换 |
| UC-8.6 | 创造时间账户子分类 | 🌱 | 编程 / 写作 / 创业等子项 |

### 体验

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| V1.1-1 | 月度回顾（轻量版）| 🌱 | "一封温柔的信"形式 · 月底自动生成 |
| V1.1-2 | Dark Mode（候补）| 🌱 | 仅在用户社区强烈要求时考虑 |
| V1.1-3 | 关系型通知（默认关闭）| 🌱 | "你上次见爸妈是 X 天前" · opt-in |

---

## V1.5 · P1.5（上线后 3 月）

### CloudKit 同步两阶段

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-8.4 | 开启 iCloud 同步 | 🌿 | 设置页 toggle |
| C-1 | 同步阶段 A（metadata + 缩略图）| 🌿 | < 50MB/千时刻 · 跨设备秒级一致 · 不动原媒体 |
| C-2 | 同步阶段 B（原图/视频懒加载）| 🌿 | CKAsset 按需 · 失败兜底 UI |

### 媒体能力扩展

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-4.5 | App 内拍照 | 🌿 | 加 Camera 权限 · 真机链路测过 |
| UC-4.6 | App 内录视频 | 🌿 | 加 Microphone 权限 |
| UC-7.5 | 保存到相册（可选）| 🌿 | 用户可选 · 加 NSPhotoLibraryAddUsageDescription |

### 导出 + 月度

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| UC-7.6 | 多格式导出 | 🌿 | Markdown（Obsidian 友好）+ 转码压缩 ZIP |
| V1.5-1 | 月度回顾深化版 | 🌿 | 数据可视化 + 推荐瞬间 + 跨年纵向对比 |

---

## V2+ · P2（探索）

| UC | 名称 | 状态 | 说明 |
|---|---|---|---|
| V2-1 | StandBy 模式 | 💭 | iPhone 横放充电时大字时钟显示 |
| V2-2 | Apple Watch Complication | 💭 | 表盘数字 |
| V2-3 | 智能存入建议 | 💭 | 基于相册连拍 + 日历事件软提示 · **不读取**实际内容，仅元数据 |
| V2-4 | 年度回顾视频 | 💭 | 自动生成 "你的 X 年时间银行" 短视频 |
| V2-5 | 时刻关联（旅行集合）| 💭 | 父子关系 |
| V2-6 | 自定义 tag | 💭 | Moment 打 tag · 跨账户搜索 |
| V2-7 | 时间快照对比 | 💭 | 实际 vs 计划 |
| V2-8 | 多语言（V1.5 部分上线）| 💭 | i18n / 英文 / 日文 |
| V2-9 | 苹果家庭共享 | 💭 | 多账号家人之间私域分享 |

---

## 跨版本辅助 UC（基础设施 · 容易漏的）

| UC | 名称 | 优先级 | 说明 |
|---|---|---|---|
| INF-1 | 启动闪屏 / launch screen | V1 必须 | LaunchScreen.storyboard 或 SwiftUI 等价 · 需匹配第一帧 |
| INF-2 | App icon 全套尺寸 | V1 必须 | 上架前不可或缺 · 设计要重做 |
| INF-3 | 数据迁移（V1 → V1.1 schema）| V1.1 起每版必须 | SwiftData @Model 兼容字段 + Migration Plan |
| INF-4 | 错误恢复（SwiftData fetch 失败 / 数据库 corrupt）| V1 必须 | 用户感知的错误兜底 UI · 当前缺 |
| INF-5 | 反馈渠道（联系 Adam）| V1 必须 | 设置页关于页有 email · 已 ✅ |
| INF-6 | 帮助 / 教程 / FAQ | V1 可选 / V1.1 加 | 当前未规划 |
| INF-7 | 上架版本号管理 | V1 起每版 | semver / build 自动递增 |
| INF-8 | 用户隐私 / 数据请求（GDPR-style）| V1.1+ | 用户主动请求"导出全部我的数据"路径已有（UC-7.2 ZIP）/ "删除全部我的数据"已有（UC-7.3）/ 目前 V1 不对接欧盟用户单独 GDPR 流程，但 ZIP 导出 + 清空 = de facto 满足 |
| INF-9 | 性能基线（启动时间 / 主页渲染）| V1 必须 | 启动 < 1.5s / 主页 < 0.3s renders |
| INF-10 | Bug 报告日志（OSLog）| V1 起 | 不上传 · 仅本地 · TestFlight crash report 来自 Apple 自身机制 |
| INF-11 | 网络降级 | V1 N/A | App 全离线，无降级路径 |
| INF-12 | 时区切换 | V1 必须 | 用户跨时区时 happenedAt 显示如何切换？目前默认本地时区 |

---

## 已知决策记录（路线图变更点）

| 日期 | 决策 | 影响 |
|---|---|---|
| 2026-04-22 | V1 scope 收窄（V1.0 → V1.3）| 砍 5 个原 V1 项到 V1.1 / V1.5 · Memorial / 账户 Tab 升 P0 |
| 2026-04-25 | 路线图重排（M3-M7 → M3+M4）| AI 开发节奏下细颗粒 milestone 合并 |
| 2026-04-26 | UI 重设计探索启动 | M5 polish 阶段产出新视觉系统替换当前实现 |

---

## 漏洞自检清单（交给 Codex 审核时关注）

### 1. 是否有 V1 P0 漏点？
对照 PRD §6 P0 表 24 项，确认每项在本文都有对应 UC，状态准确。

### 2. 是否有 V1.1 提前到 V1 / V1 推迟到 V1.1 的合理性问题？
重点关注：分享卡 / 自定义维度 / 桌面 Widget — 是否符合"V1 克制"原则。

### 3. 是否有跨版本依赖问题？
- V1.1 自定义维度 CRUD 是否依赖 V1 已有的 schema？
- V1.5 CloudKit 同步是否要求 V1 schema 已经预留 CloudKit 兼容字段？
- V1.5 多语言是否要求 V1 文案已用 String Catalog？

### 4. 是否有产品哲学冲突？
- V1.5 拍照/录像 → 是否破坏 V1 "不索相机权限" 主张？（合规：用户主动开启 + 商店描述明示）
- V2 智能存入建议 → 是否破坏"无隐私扫描"主张？（合规边界：仅元数据 · 不读内容）

### 5. 是否有基础设施漏点？
对照"跨版本辅助 UC"12 项，确认每项要么有规划，要么明确不做。

### 6. 是否有上架卡点？
- App icon 设计在哪里？
- Privacy Manifest 模板？
- 截图视频脚本？
- App Store 元数据中文 + 英文？
- TestFlight 测试人员清单？

### 7. 是否有用户教育缺口？
- 新用户首次进 App 看到 6 张时间账户卡 + 一堆数字会不会懵？
- Memorial Mode 用户能否自行发现入口？
- 下沉协议→恢复路径用户能否自行理解？

---

## 文档关联

| 子领域 | 详细文档 |
|---|---|
| V1 详细交互 | `Use-Cases-详尽交互.md` |
| 产品 PRD + roadmap | `PRD-时间银行-V1.md` |
| 文案契约 | `文案系统.md` |
| 数据 schema | `PRD-时间银行-V1.md` §7.6 |
| 视觉规范 | `设计规范.md` + `designs/DesignTokens.swift` |
| 隐私合规 | `隐私与合规.md` |
| 媒体存储 | `技术方案-媒体存储.md` |
| M3 端到端测试 | `测试-M3端到端用例.md` |
| 协作流程 | `ChatGPT-协作协议.md` / `Claude-新窗口启动prompt.md` |
| 开发上线 | `开发上线指南.md` |
| 增长 | `增长与上线.md` |
| 用户研究 | `用户研究.md` |

---

**完。**
