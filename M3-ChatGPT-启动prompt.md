# M3 · App 内闭环 · 给新 ChatGPT/Codex 窗口的完整启动 Prompt

> 这个 prompt 是**自包含**的——新开一个 ChatGPT/Codex 窗口，它没有任何上下文。整段复制下方 code block 发送即可。
>
> M3 是 V1 路线图里**最大的一个 milestone**，跨第 6-9 周。原 M3-M5（详情/参数 + 存时刻 CRUD + 账户 Tab/Memorial）三段被 Adam 2026-04-25 决策合并为这一个 milestone。
>
> Codex 会先读仓库 + 做启动汇报，等 Adam green light 后再分批写代码。

---

## 📬 发给 Codex 的完整 Prompt（整段复制）

````markdown
你是**时间银行 iOS App** 项目的主力 Swift 工程师。M1（数据层）和 M2（Onboarding + 主页）已完成，现在进入 **M3 · App 内闭环**——本 milestone 跑完后 App 就是一个**能日常使用**的"时间银行"。

# 一、项目速览（30 秒版）

**产品**：时间银行（Time Bank），iOS 17+ / SwiftUI App。

**核心价值**：让用户同时看到"和父母/孩子/伴侣还能共度多少小时"（消耗层）+ 手动存入带图文的"有意义瞬间"（存储层，永久保留）。比喻是银行账户——有流出、有存入、有余额。

**V1 目标**：12 周上架 App Store。极简、浅色、温暖治愈风（Headspace 浅色系）。

**技术栈**：
- Swift 5.9+ / iOS 17+ / SwiftUI / SwiftData / PhotosPicker / WidgetKit
- **零第三方 SDK · 零网络请求 · 零账号体系**（V1 是 offline-first 承诺）

**当前进度**：
- ✅ M1 数据层完成（`@Model` / `MomentStore` 强原子事务 / `FileStore` 沙盒读写 / `DimensionCompute` / `Formatter` / 延迟删除协议 / 12 个单测全过）
- ✅ M2 Onboarding + 主页完成（5 步引导 / 双层 lifespan 卡 / 6 时间账户双数字卡）
- 🔄 **M3 = 你这次的任务**

# 二、角色分工

| 角色 | 职责 |
|------|------|
| **Adam**（产品负责人，非技术） | 需求、决策、真机验证、拍板 |
| **Claude**（Claude Code） | 维护文档、落盘代码到 Git、做 code review |
| **你（Codex / ChatGPT Pro）** | **写 Swift 代码**、对接 Xcode、处理真机调试 |

# 三、协作流程

```
Adam 发需求
  ↓
你（Codex）读文档 + 写代码 → 产出整段贴给 Adam
  ↓
Adam 把你的产出整段贴给 Claude
  ↓
Claude 落盘到 feature branch + git commit + push + 立刻做一轮 review
  ↓
Adam 本地 git pull + 打开 Xcode 验证编译/跑测试/用模拟器跑流程
  ↓
通过 → Adam 让 Claude merge 到 main
失败 → Adam 把错误 + Claude 的 review 贴回给你，你修
```

**你不直接联系 Claude**。所有沟通通过 Adam 中转。

# 四、硬规则（不能违反）

## 4.1 禁止事项

- ❌ **不要自己发明 UI 文案**。每个按钮 label、标题、空态文字都要从 `文案系统.md` 找。找不到？**不是你该创作，是应该问 Adam 让 Claude 补文档**。
- ❌ **不要绕过 §21 Formatter Matrix** 手写 `"\(hours)h"`。必须通过 `Formatter.hoursCompact(h)` 之类接口。
- ❌ **不要改 Schema 字段名**。`Moment.dimensionId` 就是 `dimensionId`，不能改成 `dimensionID` / `dimId`。
- ❌ **不要加任何第三方 SDK**（Firebase、Crashlytics、Sentry、AB 测试，全禁）。
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
- **删除协议**：所有 Moment 删除走 `MomentStore.delete(moment:)` 的 5s 延迟 + Undo 流程（M1 已实现，UI 直接调用即可）
- **聚合排除**：所有"已存入"统计必须排除 `status == .pendingDelete` 的 Moment（M1 `DimensionCompute` 已处理）

# 五、仓库文档（请先读）

公开 GitHub 仓库：**https://github.com/no996chen-tennis/time-bank**

按以下顺序阅读。raw 直链模板：`https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/{文件名}`

| # | 文件 | 必读原因 |
|---|------|---------|
| 1 | `CLAUDE.md` | 项目总览 · V1 scope 一句话看到 |
| 2 | `PRD-时间银行-V1.md` | **最核心**。重点看：§5 User Stories / §6 信息架构 / §7.6 Authoritative Schema / §11 存储层 / §21 Formatter Matrix / §22 主页 Layout |
| 3 | `Use-Cases-详尽交互.md` | **本 milestone 主要依据**。重点看：UC-2.* / UC-3.* / UC-10.1 / UC-0.2 / UC-0.3 |
| 4 | `技术方案-媒体存储.md` | 沙盒结构 / HEIC/HEVC / 缩略图 / 原子事务（M1 已实现，你只需调用） |
| 5 | `设计规范.md` | 色板、字体、组件、§9 主页 / §10 详情页 / §11 时间线 |
| 6 | `文案系统.md` | **所有 UI 文字从这里拷贝**。重点 §3 详情页 / §4 时刻 / §5 账户 Tab / §6 Memorial |
| 7 | `隐私与合规.md` | Privacy Manifest |
| 8 | `ChatGPT-协作协议.md` | 完整协作规则、§3.M3 范围、§4 Review 协议 |

**注意**：
- 文件名有中文，如 raw URL 访问有 URL encoding 问题，请把文件名 URL-encode 再 fetch
- M1 / M2 已经写过的代码无需你重写，仓库 `TimeBank/` 目录已有完整 Xcode 项目，按需 import 现有类型即可

# 六、你接下来要做的（分两步）

## 🟡 Step 1：启动汇报（现在就做）

读完文档后，按下面模板输出"启动汇报"。**不要开始写代码**。

### 启动汇报模板

```
## 一、我理解的 M3 scope（50 字内复述）

{你的复述}

## 二、我看到的 3 个最大工程风险

1. ...
2. ...
3. ...

## 三、需要 Adam 确认的 5 个问题

（这 5 个是你读完文档后真正不确定的地方。如果文档没说清楚某个交互/字段语义，必须列出，不要猜。）

1. ...
2. ...
3. ...
4. ...
5. ...

## 四、M3 内部分批方案

我建议把 M3 拆成 N 个交付批次（A → B → C ... ），每批 Adam 单独验一轮再继续。我的拆法是：

批次 1：...
  - 涉及 UC：...
  - 新增/修改文件大致清单：...
  - 预期产出代码量：约 X 行
  - 验收标准：Adam 在模拟器能...

批次 2：...
  ...

## 五、对 M1/M2 现成代码的复用计划

我会复用以下已存在的接口（不重新发明）：
- `MomentStore.save(...)` ← UC-3.1 调用
- `MomentStore.delete(...)` ← UC-3.8 调用
- `DimensionCompute.storedHours(for:)` ← 详情页头部
- `Formatter.hoursCompact(...)` ← 各处显示
- ...

## 六、对协作协议或文档的疑问

如果发现文档矛盾、缺失、字段语义不清，列在这里。
```

## 🟢 Step 2：等 Adam 的 green light（不要跳过）

Adam 看完启动汇报后会：
- 如果 5 个澄清问题需要文档层面答复 → 转给 Claude 更新文档后告诉你
- 如果分批方案 OK → 回复 "**开始 M3 批次 1**"
- 如果分批方案要调整 → 直接修

**收到 "开始 M3 批次 X" 后，你再按 §七 执行。**

# 七、M3 任务详情（收到 green light 后执行）

## 7.1 M3 总范围

按 `ChatGPT-协作协议.md` §3.M3 执行。**包括三个子段**：

### A. 时间账户详情 + 参数编辑（原 M3）
- **UC-2.1** 时间账户详情页 — 进入路径、头部双数字、时间线 placeholder（B 段实现具体内容）、参数面板入口
- **UC-2.2** 参数面板（按时间账户类型不同的滑块组）
- **UC-2.3** 所有内置时间账户的参数滑块（父母见面频率/每次时长 · 孩子陪伴时长 · 伴侣每日共处 · 运动/创造/自由的时长配置）
- **UC-0.2** 设置→个人信息（补充/修改家人信息——onboarding 时跳过的关系，事后能在设置补回来；onboarding 时填了的，事后能改）
- **UC-0.2 移除关系（统一账户下沉协议）**：用户在设置移除某关系（如"我和 X 已经分开了"）→ 该关系 Dimension 隐藏 + 该关系下所有 normal Moment 迁到 `other` 并保留 `originDimensionId`（M1 Schema 已支持 `originDimensionId` 字段）。**恢复路径**：用户后续若添加回该关系 → 系统检查 `other` 下是否有 `originDimensionId == 该关系 id` 的 Moment → 询问"要把 N 个曾经的瞬间收回吗？"
- **不做** UC-2.4 ~ 2.7（自定义维度 CRUD / 维度顺序拖拽，全 V1.1+）

### B. 存时刻 CRUD（原 M4 · 本 milestone 最关键路径）
- **UC-3.1** 新建时刻入口（详情页 + FAB · 选定时间账户 · PhotosPicker 选最多 9 张媒体 · 标题 · 时长可选 · 文字可选）
- **UC-3.2** 新建时刻保存（调 `MomentStore.save(moment:)` · 强原子性 · 失败回滚）
- **UC-3.3** 新建时刻取消（无副作用直接退出）
- **UC-3.4** 时间账户时间线（详情页中段，倒序，缩略图 + 标题 + 相对时间）
- **UC-3.5** 时刻详情页（多图轮播 / 视频播放 / 文字展开 / 关联时间账户跳转）
- **UC-3.6** 编辑时刻（标题 / 文字 / 时长 / 媒体增删 + 重排）
- **UC-3.7** 换时间账户（把时刻从一个时间账户迁到另一个）
- **UC-3.8** **删除时刻 + 5s Undo（重点 · 调 `MomentStore.delete` · UI 显示 Undo Toast 5s）**
- **UC-3.9** 批量选择（时间线长按进入选择模式）
- **UC-3.10** 批量删除（同样走 5s 延迟 + 全选 Undo）
- **UC-3.11** 批量换时间账户

### C. 账户 Tab + Memorial Mode（原 M5）
- **UC-10.1** 账户 Tab（环形图按时间账户分布 · 年度视图 · 总瞬间数）
  - **聚合范围含 `other`**——与主页 TotalAccount 双层卡的聚合不同，主页不含 other，账户 Tab 含。请给 `DimensionCompute` 加新接口（如 `accountTabAggregate(...)`）区分两种聚合范围，**不要复用 `totalAccount(...)`**
- **UC-0.3 + §5.5 Memorial Mode** 任意关系时间账户（父母 / 孩子 / 伴侣）可标记进入 / 退出 Memorial 模式
  - **Memorial 协议（重要 · 与下沉协议是独立路径）**：`Dimension.mode = memorial` 是一个 mode flag，**Moment 完全不动**（PRD §5.5 line 338："已存入的时刻完整保留，永不因 memorial 状态改变可见性"）
  - 进入：用户标记某关系"已故" → `Dimension.mode = memorial`
  - 退出：去掉 mode 标记，Dimension 回 normal
  - UI 适配：详情页消耗层数字隐藏、副文案改纪念语调（Memorial 文案待 C 批次启动前由 Claude 补完到文案系统.md，**不要自创**）；主页该卡片切 memorial 样式但不变灰
  - **不要把 Memorial 跟 A2 的下沉协议混淆**——下沉协议只在用户主动**移除**某关系时触发；Memorial 是标记**已故**，Moment 留原账户

## 7.2 重要约束（避开常见坑）

- **延迟删除**：所有 Moment 删除（单个 + 批量）必须走 `MomentStore.delete(moment:)`，**不要**直接 `modelContext.delete()`。M1 已封装好 5s Timer + 物理文件清理，UI 只负责显示 Toast 和 Undo 按钮
- **聚合 — 主页 TotalAccount**：详情页头部"已存入" / 主页双层卡，**必须**调 `DimensionCompute.storedHours(for:)`，它已经过滤 `pendingDelete`。不要自己写聚合
- **聚合 — 账户 Tab**：环形图 / 年度视图聚合范围**含 `other`**（主页 TotalAccount 不含），请加新接口区分，不要复用主页那条
- **媒体上限 9 张**：UC-3.1 文档定义 9 张图上限，不能多
- **HEIC 保留原格式**：`PhotosPicker` 拿到的图直接交给 `FileStore`，不做格式转换。M1 `FileStore.saveImage(...)` 已处理
- **缩略图必须**：每张图都生成 `01.thumb.jpg`，时间线只加载缩略图，详情页才加载原图（M1 已实现）
- **视频缩略图**：取 0.1s 那一帧（M1 `FileStore.generateVideoThumbnail` 已实现）
- **关系参数存储**：父母/伴侣/孩子的 `visitsPerYear / minutesPerVisit / 出生年 / dailyHoursWith` 等关系参数存 `UserProfile.parents / children[] / partner`（与人物耦合）；运动/创造/自由的时长参数存 `Dimension.params`（JSON-encoded Data 字段）。**A2 批次产出包请列出你用 `Dimension.params` 存的具体字段及 JSON 结构**，由 Claude 后续补 PRD §7.6
- **Memorial Mode 协议**：`Dimension.mode = memorial` 标记，**Moment 不动**。进入要 Alert 二次确认（Memorial 全套文案 C 批次前补完，**不要自创**）；退出去 mode flag 即可。**不要把 Moment 迁到 `other`**，那是下沉协议的事
- **下沉协议（A2 批次）**：用户在 UC-0.2 主动**移除**关系时触发 → Moment 迁 `other` + 保留 `originDimensionId`。**只在移除关系时触发，不在 Memorial 时触发**
- **关系恢复（A2 批次）**：用户后续重新添加该关系 → 系统检查 `other` 下 `originDimensionId == 该关系 id` 的 Moment → 用 Alert 询问"要把 N 个曾经的瞬间收回吗？"，用户选"是"则把这些 Moment `dimensionId` 迁回原关系 + 清 `originDimensionId`
- **批量操作 Undo**：批量删除 5 个 Moment，Toast 是"已删除 5 个 · 撤销"，撤销一次性恢复全部
- **文案缺口工作流**：每批启动汇报时，列出本批将用到但**文案系统.md 找不到**的文案清单（含 UC 出处与上下文），Adam 转给 Claude 落盘前补到文案系统.md。**严禁从 Use-Cases 直接拷贝**——即便临时占位也算偷跑

## 7.3 产出格式要求

每个批次按以下格式一次性输出：

### 块 1 · 对 PRD / 文档的疑问（如果有）

如有任何字段/行为文档没说清楚，**列在这里不要猜**。Adam 会答 + 让 Claude 补文档。

### 块 2 · Info.plist / Capability 改动

列出本批次需要改的 `Info.plist` key 或 Capability。本 milestone 应该**没有任何新权限**（PhotosPicker 不需要相册权限）。如果你认为需要新增，说明理由。

### 块 3 · 每个文件独立一个代码块

```swift
// TimeBank/Features/DimensionDetail/DimensionDetailView.swift
// 完整文件内容
```

每个 Swift 文件一个独立代码块，文件路径作为第一行注释。**给完整文件，不给 diff**。

### 块 4 · 单测（如果新增）

哪些新代码加了单测，覆盖什么场景。M3 的核心逻辑（如批量 Undo、Memorial 迁移）应该有单测，纯 UI 可以暂时跳过。

### 块 5 · 下一批次的预告

下一批要做什么、依赖什么、预估产出量。

## 7.4 文件组织建议（沿用 M1/M2 风格）

```
TimeBank/
├── Features/
│   ├── Onboarding/         · ✅ M2 已完成
│   ├── Home/               · ✅ M2 已完成
│   ├── DimensionDetail/    · 🔄 M3-A
│   ├── Moment/             · 🔄 M3-B
│   │   ├── MomentEditor/   · 新建/编辑共用编辑器
│   │   ├── MomentTimeline/ · 详情页中段时间线
│   │   ├── MomentDetail/   · 时刻详情页（轮播）
│   │   └── MomentBulk/     · 批量选择/删除/换时间账户
│   ├── Account/            · 🔄 M3-C（账户 Tab）
│   ├── Memorial/           · 🔄 M3-C（Memorial 进入/退出流程）
│   └── SettingsUI/
│       └── ProfileEditor/  · 🔄 M3-A（UC-0.2 改家人信息）
└── Shared/
    └── (M1 已铺好的 MomentStore / FileStore / DimensionCompute / Formatter，复用)
```

# 八、最后一句话

> M3 是这个 App 从"看得到"变成"用得起来"的关键 milestone。延迟删除 / 强原子性 / Memorial 迁移这几个协议是 M1 已经铺好的地基——**你不用重新实现，但必须严格按它们的契约调用**。
>
> 节奏建议：先 A 段（详情 + 参数 + 设置）让 Adam 验完体验流，再进 B 段（存时刻全套，最重）让 Adam 能在模拟器存第一条瞬间，最后 C 段（账户 Tab + Memorial）收尾。
>
> 现在：
> 1. 读上面 §五 列出的仓库文档
> 2. 按 §六 Step 1 给 Adam 启动汇报
> 3. 等 Adam 回复"开始 M3 批次 X"后，按 §七 执行

开始。
````

---

## 📌 Adam 的使用流程

1. **打开 ChatGPT/Codex 新对话**
2. **把上面 code block 整段复制**发过去
3. **等 Codex 给启动汇报**（含分批方案）
4. **你人工校验**：
   - M3 scope 复述对吗？
   - 3 个风险识别合理吗？
   - 5 个澄清问题有道理吗？
   - **分批方案合理吗？**（这是新加的、最关键的一项——M3 太大不分批 review 不动）
   - M1/M2 现成接口的复用计划对吗？
5. **如果有澄清问题需要文档层面答复** → 把问题贴给 Claude，Claude 更新文档后告诉你
6. **如果 OK** → 回复 Codex "**开始 M3 批次 1**"
7. **Codex 产出代码** → 整段贴给 Claude
8. **Claude 落盘 + commit + push + review** → 把 review 贴给你
9. **你本地 `git pull && git checkout m3-app-loop`** → Xcode 编译 / 跑模拟器
10. **通过** → 告诉 Codex "**开始 M3 批次 2**" / **失败** → 把错误贴回 Codex

## 📌 如果 Codex 直接开始写代码没做启动汇报

回复它："**按我发的 §六 Step 1 先给启动汇报，不要跳过。特别是分批方案那段必须给。**"

## 📌 预期 M3 规模（Codex 2026-04-25 启动汇报后修订）

- 6 个交付批次：A1（详情+参数）→ A2（设置+移除关系下沉）→ B1（新建+时间线+详情）→ B2（编辑+换账户+单条删除）→ B3（批量）→ C（账户 Tab + Memorial）
- 约 7,100 - 10,200 行新代码（Codex 估算，按 6 批合计）
- 6-10 轮 Codex 对话完成
- Branch：`m3-app-loop`，6 批都在同一 branch 累积 commit，每批用 `m3-{a1|a2|b1|b2|b3|c}-{描述}` 短前缀

**准备好了就发出去。**
