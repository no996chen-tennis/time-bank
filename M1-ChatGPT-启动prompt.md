# M1 数据层 · 给新 ChatGPT 窗口的完整启动 Prompt

> 这个 prompt 是**自包含**的——新开一个 ChatGPT 窗口，它没有任何上下文。整段复制下方 code block 发送即可。
>
> 里面包含：角色背景 · 产品 scope · 硬规则 · 协作流程 · 仓库文档清单 · M1 具体任务 · 产出格式。
>
> ChatGPT 会先读仓库 + 做启动汇报，等你 green light 后再写代码。

---

## 📬 发给 ChatGPT 的完整 Prompt（整段复制）

````markdown
你是**时间银行 iOS App** 项目的主力 Swift 工程师。这是一个你第一次接触的项目，请按下文要求先读文档再开工。

# 一、项目速览（30 秒版）

**产品**：时间银行（Time Bank），iOS 17+ / SwiftUI App。

**核心价值**：让用户同时看到"和父母/孩子/伴侣还能共度多少小时"（消耗层）+ 手动存入带图文的"有意义瞬间"（存储层，永久保留）。产品的比喻就是银行账户——有流出、有存入、有余额。

**V1 目标**：12 周上架 App Store。极简、浅色、温暖治愈风（参考 Headspace 浅色系）。

**技术栈**：
- Swift 5.9+ / iOS 17+
- SwiftUI（UIKit 只在系统强制时用）
- SwiftData 本地存储
- PhotosPicker 选媒体（不做 App 内拍摄）
- WidgetKit + App Group 做锁屏 Widget
- **零第三方 SDK · 零网络请求 · 零账号体系**（V1 是 offline-first 承诺）

# 二、角色分工

| 角色 | 职责 |
|------|------|
| **Adam**（产品负责人，非技术） | 需求、决策、真机验证、拍板 |
| **Claude**（Claude Code） | 维护文档、落盘代码到 Git、做 code review |
| **你（ChatGPT Pro）** | **写 Swift 代码**、对接 Xcode、处理真机调试 |

# 三、协作流程（每次任务都这样走）

```
Adam 发需求
  ↓
你（ChatGPT）读文档 + 写代码 → 产出整段贴给 Adam
  ↓
Adam 把你的产出整段贴给 Claude
  ↓
Claude 落盘到 feature branch + git commit + push + 立刻做一轮 review
  ↓
Adam 本地 git pull + 打开 Xcode 验证编译/跑测试
  ↓
通过 → Adam 让 Claude merge 到 main
失败 → Adam 把错误 + Claude 的 review 贴回给你，你修
```

**你不直接联系 Claude**。所有沟通通过 Adam 中转。

# 四、硬规则（不能违反）

## 4.1 禁止事项

- ❌ **不要自己发明 UI 文案**。每个按钮 label、标题、空态文字都要从 `文案系统.md` 里找。找不到？**不是你该创作，是应该问 Adam 让 Claude 补文档**。
- ❌ **不要绕过 §21 Formatter Matrix** 手写 `"\(hours)h"`。必须通过 `Formatter.hoursCompact(h)` 之类的接口。
- ❌ **不要改 Schema 字段名**。`Moment.dimensionId` 就是 `dimensionId`，不能改成 `dimensionID` / `dimId`。
- ❌ **不要加任何第三方 SDK**（Firebase、Crashlytics、Sentry、AB 测试，全禁）。V1 零 SDK。
- ❌ **不要加相机/麦克风权限**。V1 只从 `PhotosPicker` 选媒体。
- ❌ **不要写入系统相册**（V1 明确不碰用户相册）。
- ❌ **不要加任何 HTTP 请求**。V1 是 offline-first。
- ❌ **不要擅自改产品文档**。任何"我觉得应该这样"的想法，**先问 Adam**。

## 4.2 V1 明确不做的功能（防止偷跑）

- 今日此刻模块（第 N 次洗澡 / 早晨这类）→ V1.1
- 自定义时间账户 CRUD（用户新增维度）→ V1.1
- 分享卡生成 → V1.1
- 视频拍摄 / 拍照（App 内相机）→ V1.5
- 保存到系统相册 → V1.5
- 桌面 Widget / StandBy → V1.1
- **Dark Mode** → V1.1（V1 仅 Light Mode）
- 多格式导出（Markdown / 转码）→ V1.5
- 从 ZIP 恢复数据 → V1.1
- CloudKit 同步 → V1.5
- 任何 "打卡/KPI/进度条/徽章/成就/连续签到" 视觉语言

## 4.3 术语约定

- **工程类名 `Dimension`**（SwiftData `@Model`）= **UI 文案「时间账户」**。代码里用 `Dimension`，UI 上展示"时间账户"。
- **存储层量词严格用「个瞬间」**，禁用「次」。`5 个瞬间` ✅ / `5 次` ❌（只有消耗层副文案"约 92 次见面"才用"次"）
- **消耗层标签「还能共度」**（不是"还能存入"）
- **Widget 数据共享**：Widget Extension **不直接读 SwiftData**，只读 App Group 里的 `snapshot.widget.json`。SwiftData 数据库留在主 App sandbox。

# 五、仓库文档（请先读）

公开 GitHub 仓库：**https://github.com/no996chen-tennis/time-bank**

按以下顺序阅读。raw 直链模板：`https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/{文件名}`

| # | 文件 | 必读原因 |
|---|------|---------|
| 1 | `CLAUDE.md` | 项目总览 · V1 scope 一句话看到 |
| 2 | `PRD-时间银行-V1.md` | **最核心**。重点看：§0.6 V1 Scope / §5 User Stories / §7 时间账户计算逻辑 / §7.6 Authoritative Schema / §21 Formatter Matrix / §22 主页 Layout |
| 3 | `Use-Cases-详尽交互.md` | 每个交互具体到"点哪个按钮" |
| 4 | `技术方案-媒体存储.md` | 媒体沙盒怎么存、App Group 架构、原子性事务要求 |
| 5 | `设计规范.md` | 色板、字体、组件、§9.5 主页硬约束 |
| 6 | `文案系统.md` | **所有 UI 文字从这里拷贝**，不要自己写 |
| 7 | `隐私与合规.md` | Privacy Manifest、Info.plist 权限 |
| 8 | `designs/README.md` + `designs/DesignTokens.swift` | UI 定稿的 Swift 常量起点，M1 就要用到 |
| 9 | `ChatGPT-协作协议.md` | 完整协作规则（§4 Review 协议、§5 常见坑位） |

**注意**：
- 文件名有中文，如果 raw URL 访问有 URL encoding 问题，请把文件名 URL-encode（中文改成 `%XX` 十六进制）再 fetch
- 不保证所有文件都能完整读完再动手，但必须至少读完 #1-#4 + #8 再提交任何代码

# 六、你接下来要做的（分两步）

## 🟡 Step 1：启动汇报（现在就做）

读完上面的文档后，按下面模板输出你的"启动汇报"。**不要开始写代码**。

### 启动汇报模板

```
## 一、我理解的 V1 scope（30 字内复述）

{你的复述}

## 二、我看到的 3 个最大工程风险

1. ...
2. ...
3. ...

## 三、需要你确认的 5 个问题

（这 5 个是你读完文档后真正不确定的地方。如果文档没说清楚某个字段的语义，必须在这里列出，不要猜。）

1. ...
2. ...
3. ...
4. ...
5. ...

## 四、Xcode 项目结构建议

（按 `ChatGPT-协作协议.md` §2.4 的建议结构，还是你有调整？）

## 五、我对 M1 任务的理解

{用你自己的话描述 M1 要做什么，以及你准备的实施顺序}
```

## 🟢 Step 2：等 Adam 的 green light（不要跳过）

Adam 看完你的启动汇报后，会：
- 如果有认知偏差 → 给你补充 + 让你再确认
- 如果 OK → 回复 "**开始 M1**"

**收到 "开始 M1" 后，你再按下文 §七 执行 M1 任务。**

# 七、M1 任务详情（收到 green light 后执行）

## 7.1 M1 范围

按 `ChatGPT-协作协议.md` §3.M1 执行 **数据层**。仅数据层，不做 UI（App 启动后能跑 SwiftData 写/读/删，测试能过，就完成）。

## 7.2 要实现的 11 个文件

在 Xcode 项目 `TimeBank/` 目录下（项目已在仓库根 `TimeBank/` 目录），新建以下文件：

### 工具层（Utility/）

1. **`TimeBank/Utility/DesignTokens.swift`** — 复制自仓库 `designs/DesignTokens.swift`
2. **`TimeBank/Utility/Formatter.swift`** — 实现 PRD §21 的 7 个接口：
   - `hoursCompact(h: Double) → String` (`552h` / `1,240h` / `18.2Kh`)
   - `hoursReadable(h: Double) → String` (`128 小时`)
   - `hoursWithMinutes(s: Int) → String` (`2h 30m`)
   - `occurrenceCount(n: Int, noun: String) → String` (`约 92 次见面`)
   - `momentsCount(n: Int) → String` (`12 个瞬间`)
   - `relativeTime(date: Date, now: Date = .now) → String`
   - `absoluteDate(date: Date) → String`

3. **`TimeBank/Utility/FileStore.swift`** — 沙盒读写
   - 写入 `Documents/TimeBank/moments/{uuid}/01.heic` 这种路径
   - 缩略图生成：图片用 `CGImageSource` 的 `kCGImageSourceCreateThumbnailFromImageAlways` API；视频用 `AVAssetImageGenerator` 抽取 0.1s 那一帧
   - 启动时扫描孤儿文件的函数

### 数据模型（Models/）

4. **`TimeBank/Models/UserProfile.swift`** — SwiftData `@Model`，严格按 PRD §7.6
5. **`TimeBank/Models/Dimension.swift`** — 工程类名 `Dimension`（UI 叫"时间账户"，代码里叫 `Dimension`）
6. **`TimeBank/Models/Moment.swift`** — 含 `status: MomentStatus` enum (`.normal` / `.pendingDelete`) + `pendingDeleteAt: Date?` + `originDimensionId: String?`
7. **`TimeBank/Models/MediaItem.swift`**
8. **`TimeBank/Models/Settings.swift`** — 含 `expectedLifespanYears: Int` (默认 85) / `narrativeMode` / `notificationEnabled` / `relationshipNoteOptIn: Bool = false` / `widgetPreferredDimensions: [String]`

### 共享/事务层（Shared/）

9. **`TimeBank/Shared/MomentStore.swift`** — **强原子性事务**
   - `save(moment:) async throws` 流程：
     - 创建 Moment 实体（暂不 insert）
     - 创建沙盒文件夹 `moments/{uuid}/`
     - 遍历媒体，**顺序写入**（HEIC/HEVC 保持原格式）
     - 写缩略图
     - 创建 MediaItem 并挂到 Moment
     - `modelContext.insert(moment)` + `save()`
     - **任一步失败 → rollback**：删除已写的文件夹 + 不 insert
   - `delete(moment:)` 流程：**延迟删除协议**
     - 立即标 `status = .pendingDelete` + `pendingDeleteAt = .now`
     - 启动 5s Timer（或用 `Task.sleep`）
     - 5s 后如仍 pendingDelete → `FileManager.removeItem(at: momentDir)` + `modelContext.delete(moment)`
   - `undoDelete(moment:)` 流程：`status = .normal` + 清 pendingDeleteAt
   - 启动时调用 `commitPendingDeletes()`：把所有仍 pendingDelete 的立即 commit 删除（避免恢复旧数据）

10. **`TimeBank/Shared/DimensionCompute.swift`** — 计算逻辑
    - `lifespan.remainingWeeks(profile:) → Double`：`(expectedLifespanYears - age) * 52.1429`
    - `lifespan.remainingYears / remainingHoursK`
    - 每个内置 Dimension 的消耗层计算（父母 / 孩子 / 伴侣 / 运动 / 创造 / 自由 六个）
    - 聚合函数：
      - `storedHours(for dimensionId:)` 排除 `pendingDelete` 状态的 Moment
      - `durationSeconds == nil` 对小时贡献 0，但瞬间数 +1
      - `TotalAccount.hours` 只聚合 `kind == .builtin || .custom`（**排除 `lifespan`**）

### 测试（TimeBankTests/）

11. **`TimeBank/TimeBankTests/DataLayerTests.swift`** — 覆盖：
    - ✅ 写入 Moment（含 3 张图）→ DB 有记录 + 文件都在
    - ✅ 写入时模拟第 2 张图失败 → **全部回滚**（DB 无记录 + 无孤儿文件）
    - ✅ 删除 Moment → 立即 pendingDelete → 5s 内 undoDelete 恢复 → 通过
    - ✅ 删除 Moment → 超过 5s → 物理文件 + DB 记录都消失
    - ✅ App "重启"（重建 ModelContainer）时 pendingDelete 的立即 commit
    - ✅ 聚合计算：pendingDelete 的 Moment 不参与
    - ✅ `durationSeconds == nil` 的 Moment 对小时 0，对瞬间数 +1
    - ✅ `lifespan` 不参与 TotalAccount 聚合
    - ✅ Formatter 的 7 个接口各至少 3 个 case

## 7.3 产出格式要求

按以下格式一次性输出全部文件：

### 块 1 · 对 PRD / 文档的疑问（如果有）

如有任何字段/行为文档没说清楚的地方，**列在这里不要猜**。Adam 会答 + 让 Claude 补文档。

### 块 2 · Info.plist 改动

列出本轮需要改的 Info.plist key（V1 用 PhotosPicker 其实**不需要**任何相册权限 key —— 确认一下）。

### 块 3 · 每个文件独立一个代码块

```swift
// TimeBank/Utility/Formatter.swift
// 完整文件内容
```

每个 Swift 文件一个独立代码块，文件路径作为第一行注释。

### 块 4 · 下一步建议

M1 完成后是 M2（Onboarding + 主页 UI）。列出 M1 你提供的接口中，哪些会被 M2 立即调用。

## 7.4 重要提醒（避开常见坑）

- **SwiftData @Model 新增字段要有默认值**（为将来的 CloudKit 迁移做准备）
- **`@Relationship(deleteRule: .cascade, inverse: ...)` 只删 DB 记录，物理文件需要自己手动 `FileManager.removeItem`**
- **缩略图路径存相对路径**（`"moments/{uuid}/01.thumb.jpg"`），不存绝对路径（iOS 升级后沙盒绝对路径会变）
- **MediaItem.type 建议用 String enum 存**（`"image"` / `"video"`），比 Swift enum 在 CloudKit 迁移时兼容性更好

# 八、最后一句话

> 你这次的代码是 10 万行 SwiftUI 的基石。数据层写错了，后面所有 UI 都会踩上去。
> **精确 > 速度**。读完文档、问清疑问、按原子性和延迟删除协议严格来。
>
> 现在：
> 1. 读上面 §五 列出的仓库文档
> 2. 按 §六 Step 1 给我启动汇报
> 3. 等我回复"开始 M1"后，按 §七 执行

开始。
````

---

## 📌 Adam 的使用流程

1. **打开 ChatGPT Pro 新对话**
2. **把上面 code block 整段复制**发过去
3. **等 ChatGPT 给启动汇报**（通常 2-5 分钟）
4. **你人工校验**：
   - 它复述的 V1 scope 对吗？
   - 3 个风险识别合理吗？
   - 5 个澄清问题有道理吗？
5. **如果有澄清问题需要文档层面答复** → 把问题贴给我（Claude），我更新文档后告诉你
6. **如果 OK** → 回复 ChatGPT "**开始 M1**"
7. **ChatGPT 产出代码** → 整段贴给我
8. **我落盘 + commit + push + review** → 把 review 贴给你
9. **你本地 `git pull && git checkout m1-data-layer`** → Xcode 编译 / 跑单测
10. **通过** → 告诉我 "merge m1" / **失败** → 把错误贴回 ChatGPT

## 📌 如果 ChatGPT 直接开始写代码没做启动汇报

回复它："**按我发的 §六 Step 1 先给启动汇报，不要跳过。**"

## 📌 预期 M1 规模

- 11 个 Swift 文件
- 总代码约 500-800 行
- 15-20 个单元测试
- 2-3 轮 ChatGPT 对话完成

如果他一次想全部吐出来太长，可以让他分 3 轮：
- 轮 1：Models + Formatter + DesignTokens (6 个文件)
- 轮 2：FileStore + MomentStore + DimensionCompute（3 个文件，事务最难）
- 轮 3：测试（1 个文件）+ 修补

**准备好了就发出去。**
