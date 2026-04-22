# 时间银行 · Claude Design 最终交付 Prompt（Headspace 风定稿版）

> Version: 1.0 | Date: 2026-04-22 | 风格定稿：**A. Warm Illustration（Headspace 浅色）**
>
> 本文是对 Claude Design **一次性最终交付会话**使用的 prompt。Adam 已锁定主视觉方向为 Headspace 温暖治愈系。
>
> **使用场景：** 只有一次机会跑这个 session，所以 prompt 结构化为 5 Part 一次产出完整工程包。

---

## 🎯 使用说明

### 一次性跑完的准备

1. **开一个 Claude Design 新 session**（不要在旧会话里叠加）
2. **准备 4-6 张 Headspace 真实截图**（见下方"截图选什么"指南）
3. **把下方 §完整 Prompt 整段复制**，连同截图一起发送到 Claude Design
4. **跑完后把输出保存成一个 md 文件**（不要只截图），交给 ChatGPT 时要整段文字粘贴
5. 中途如果 Claude Design 偏离结构（想"画个漂亮图吧"），立刻纠正："请回到 Part N 继续按结构化格式输出"

### 截图选什么（4-6 张最佳）

挑**互补覆盖不同要素**的截图，不要都是主页：

| # | 选哪种界面 | 为什么 |
|---|-----------|-------|
| 1 | 主页 / 首屏 | 看整体色板、品牌感 |
| 2 | 带插画的空态或欢迎页 | 看插画风格核心 |
| 3 | 卡片列表（课程 / sessions） | 看卡片设计、圆角、阴影、字体层级 |
| 4 | 一个表单或设置页 | 看字段、按钮、交互组件 |
| 5 | 带大数字或数据的页面（如果有） | 看 typography 节奏 |
| 可选 +1 | 播放器或详情页 | 看沉浸式布局和元信息排版 |

如果能在截图上轻量标注更好（圈出"这个色"、"这个圆角"、"这个字体感觉"）。不方便标注也没关系。

### 附件放哪

**直接附在 Claude Design 的对话里**，和 prompt 同一条消息发送。**不要放 GitHub 仓库**——Headspace 截图是版权素材，放公开仓库有侵权风险，且 Claude Design 不主动 fetch 外部图片 URL。

---

## 📋 完整 Prompt（复制粘贴给 Claude Design）

下方整段复制（连同 4-6 张 Headspace 截图一起发）：

````markdown
你是时间银行（iOS App）的 Lead Designer。这是我们最后一次 Claude Design 会话——额度有限，必须**一次性交付完整工程包**。

## 🔴 关键背景

1. 你的输出会被整段拷贝给另一个 AI（ChatGPT），作为他写 SwiftUI 代码的全部视觉依据
2. 所以**必须是 ChatGPT 友好格式**：JSON token / Swift 伪代码 / 精确 spec 表
3. 图片只作注解，不做主要信息载体
4. **精确 > 漂亮**。宁可文字说明到位、图少一点，也不要漂亮图但说不清尺寸

## 🎨 主视觉风格（已定稿）

**A. Warm Illustration（Headspace 浅色 · 温暖治愈 · 插画承载）**

具体色板 / 字体 / 质感 / 灵感参考，请先读这份文档里的「风格 1 · Warm Illustration」章节：
https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/设计提示词-浅色5风格.md

## 📎 参考图片（随本条消息附上 N 张 Headspace 截图）

我附上了 N 张 Headspace 的真实截图作为视觉参考。请这样使用它们：

**吸收这些（抽象层面的风格语言）：**
- 具体色板的 hex 值（从图中取色）
- 字体气质（看起来是 Geometric / Humanist / Rounded ？）
- 插画的线条粗细、填充与线条的比例
- 圆角程度（按钮、卡片、媒体容器）
- 阴影的柔和度和色调（是纯黑投影还是暖色投影？）
- 留白节奏
- 色彩饱和度基线

**禁止直接复制（版权 + 原创性）：**
- ❌ 不要照搬任何图标或插画的具体造型
- ❌ 不要使用 Headspace 的品牌橙色作为主色
- ❌ 不要出现任何"冥想圆圈动画"这种 Headspace 标志性元素

**翻译要求：**
把 Headspace 这套"治愈型视觉语言"翻译到时间银行的产品主题——**家人关系 + 时间沉淀**。比如：
- Headspace 的"冥想小人"→ 时间银行的"两人并肩剪影"
- Headspace 的橙色主色 → 改用更接近"陪伴 / 家庭温度"的珊瑚粉或蜂蜜黄
- Headspace 的"禅意圆圈"→ 改用"时间流沙 / 光晕 / 瞬间泡泡"等契合时间主题的抽象图形

所以你的最终输出应该**像 Headspace 的远房表亲**——看一眼就能感受到同样的治愈温度，但绝不会混淆是同一个 App。

## 📚 必读上下文（动手前全部扫一遍）

1. **PRD**（重点 §0.6 V1 Scope / §5 User Stories / §7.6 Schema / §8 P0 清单 / §21 Formatter Matrix）：
   https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/PRD-时间银行-V1.md
2. **Use Cases**（每屏对应哪个 UC）：
   https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/Use-Cases-详尽交互.md
3. **文案系统**（所有 UI 文字必须从这里拷贝，不要编）：
   https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/文案系统.md
4. **设计规范骨架**（token 命名惯例）：
   https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/设计规范.md

## ⚠️ V1 硬约束

- iOS 17+ / SwiftUI / **Light Mode Only**
- 存储层量词严格用 `个瞬间`，**禁用 `次`**
- V1 不做：分享卡 / 视频拍摄 / 拍照 / 保存相册 / 桌面或 StandBy Widget / 自定义时间账户 CRUD / 今日此刻 / 多格式导出 / Dark Mode
- 严禁 "打卡 / KPI / 进度条 / 徽章 / 成就 / 连续签到" 视觉语言

---

# 🎯 一次性输出内容（按 Part 1-5 顺序全部交付）

## Part 1 · Design Tokens（最关键，ChatGPT 直接用）

### 1.1 Colors · 以 Swift extension 形式输出

```swift
extension Color {
    // Backgrounds
    static let bg          = Color(hex: "...")  // 主背景
    static let bgAlt       = Color(hex: "...")  // 卡片背景
    static let bgTint      = Color(hex: "...")  // 三级容器
    static let border      = Color(hex: "...")
    static let borderSoft  = Color(hex: "...")

    // Text
    static let textPrimary   = Color(hex: "...")
    static let textSecondary = Color(hex: "...")
    static let textTertiary  = Color(hex: "...")

    // Dimension colors (6 个内置时间账户)
    static let dimParents = Color(hex: "...")
    static let dimKids    = Color(hex: "...")
    static let dimPartner = Color(hex: "...")
    static let dimCreate  = Color(hex: "...")
    static let dimSport   = Color(hex: "...")
    static let dimFree    = Color(hex: "...")

    // Semantic
    static let accent   = Color(hex: "...")  // 主 CTA
    static let warm     = Color(hex: "...")  // 次 accent
    static let danger   = Color(hex: "...")
    static let success  = Color(hex: "...")
}
```

每色后面加一行注释：`// WCAG AA 在 bg 上对比度 X.XX ✓/✗`

### 1.2 Typography · 表格 + Swift extension

先给规格表：
| Token | 中文字体 | 英文数字字体 | Size | Weight | Line Height | Letter Spacing | Use Case |
|-------|---------|-------------|------|--------|-------------|---------------|---------|
| displayLarge | | | | | | | 时间账户详情大数字 |
| displayMedium | | | | | | | 主页总账户数字 |
| title1 | | | | | | | 页面大标题 |
| title2 | | | | | | | 模块标题 |
| body | | | | | | | 正文 |
| bodySm | | | | | | | 次级正文 |
| caption | | | | | | | 元信息 |
| micro | | | | | | | small caps 标签 |

然后给 Swift extension：
```swift
extension Font {
    static let dtDisplayLarge = Font.custom("...", size: 44).weight(...)
    // ...
}
```

### 1.3 Spacing / Radius / Shadow · 表格

| Token | Value | Use Case |
|-------|-------|----------|
| spaceXs | 4pt | icon 内边距 |
| spaceSm | 8pt | ... |
| ... (full scale) | | |

| Token | Value |
|-------|-------|
| radiusSm | 8pt |
| ... | |

| Token | CSS / Swift | Use |
|-------|-------------|-----|
| shadowSm | 0 1 2 rgba(0,0,0,0.04) | 卡片 resting |
| shadowMd | 0 4 12 rgba(0,0,0,0.06) | 卡片 elevated |
| shadowLg | 0 8 24 rgba(0,0,0,0.08) | Sheet / Modal |

### 1.4 Motion · 时间曲线规范

| Token | Timing | Curve | SwiftUI API | Use Case |
|-------|--------|-------|-------------|---------|
| microPress | 150ms | ease-out | `.easeOut(duration: 0.15)` | 按钮按下 |
| transition | 350ms | spring | `.spring(response: 0.5, damping: 0.85)` | 页面切换 |
| heroMoment | 1200ms | spring | `.spring(response: 0.5, damping: 0.7)` | 存入成功签名动效 |

---

## Part 2 · 8 个核心组件规格

每个组件输出：
- **结构**：从外到内嵌套关系
- **状态**：default / pressed / disabled / empty
- **尺寸**：外框 / padding / gap
- **使用的 token**：只引用 Part 1 定义的
- **SwiftUI 骨架**：30-40 行结构伪代码

要画的组件：
1. **DimensionCard**（双数字卡片 · 最核心）—— normal / memorial / empty 三态
2. **MomentCard**（时间线单条）
3. **ChipMulti**（chip 多选，用于 Onboarding Step 2）
4. **MediaSlot**（9 宫格媒体位，4 态：empty / add / filled / video）
5. **FormRow**（设置页 / 表单行）
6. **EmptyState**（通用空态 · 插画 + 文案 + CTA）
7. **Buttons**（Primary / Secondary / Danger 三种）
8. **BottomSheet**（底部动作表）

---

## Part 3 · 14 个屏幕（高保真 UI + 精确注解）

### 每屏用统一模板输出：

```
### Screen N · [名字]
**对应 UC**: UC-X.Y
**尺寸**: iPhone 16 Pro 393×852
**Layout**（从上到下，每行一元素）:
  - [element] at y=0, height=H, padding P, uses [token], uses [Component]
  - ...
**状态**: 正常 / loading / error（如适用）
**交互**: tap A → navigate to B; long-press → trigger C
**文案来源**: 文案系统 §X.Y
**示意草图**: [ASCII 草图 / 或简单 SVG / 或文字描述]
```

### 核心 6 屏（已定稿）

1. Welcome 启动页
2. Onboarding Step 2（chip 多选：父母健在 / 有孩子 / 有伴侣 / 独处也是一种时间）
3. 主页（顶部总账户卡 + 双数字时间账户卡片 list）
4. 时间账户详情（大数字 + 参数卡 + 时间线）
5. 新增时刻表单（字段 + 9 宫格媒体 + 强原子性提示）
6. 时刻详情（媒体轮播 + chip + 笔记 + 3 动作按钮）

### 关键补充 8 屏（必画）

7. **Memorial Mode 时间账户详情** —— 只显示"已存入 56h · 12 个瞬间"，不显示消耗数字；卡片下 chip 写"致爸爸"；视觉保持温暖不变冷
8. **Onboarding 标记已故独立页**（UC-0.3）—— 情感最重的一屏，必须独立页承接而非 Alert
9. **主页首次空态**（0 个瞬间）—— 空态 EmptyState 引导存入第一个
10. **时间账户详情空态**（某时间账户 0 个瞬间）—— 文案参见文案系统 §2.7
11. **账户 Tab**（正常态 + 空态）—— 环形图 + 年度视图
12. **Widget 锁屏小号**（170×170）—— 3 种内容变体（数字主 / 文案主 / 最近瞬间）
13. **保存失败 Alert**（磁盘满场景）—— 文案系统 §2.7 错误态
14. **删除 Undo Toast**（5s 倒计时 + [撤销] 按钮）

---

## Part 4 · 存入成功动效（产品唯一签名动效）

不画整段视频，给 3 关键帧 + Swift 伪代码：

**时间线：**
- Frame 0ms · 按钮被按下 → scale 0.95 + haptic light
- Frame 100-300ms · 表单内容淡出（opacity 1 → 0.3）
- Frame 400ms · 一颗光点从屏幕中心升起到 Y=35% 位置
- Frame 800-1000ms · 光点飞向右上角对应时间账户卡位置
- Frame 1000-1200ms · 时间账户卡"已存入"数字 roll-up（X → X+Δ）
- Frame 1200ms · 光点溶解 + 模态 dismiss

**必须包含：**
- SwiftUI 伪代码（`.matchedGeometryEffect` / `.animation` / `.transition`）
- Reduce Motion 降级方案（简单 fade）
- Haptic Feedback 触发点（`UINotificationFeedbackGenerator().notificationOccurred(.success)`）

---

## Part 5 · DimensionCard 完整 SwiftUI 参考实现

给 **DimensionCard**（最核心组件）一段 30-50 行 SwiftUI 参考代码。要求：

- 所有颜色走 `Color.dimParents` 这种 token（不硬编码 hex）
- 所有字号走 `.font(.dtDisplayLarge)` 这种 extension
- 所有间距走 `.padding(.horizontal, Space.md)`
- 展示三态：normal / memorial / empty
- 使用 `Formatter.hoursCompact(552)` 占位调用（不要写 "552h"）
- 注释写"为什么"不写"做了什么"

这段代码将成为 ChatGPT 写其他所有组件的模板，**质量必须高**。

---

## 输出顺序与格式要求

严格按 Part 1 → Part 5 顺序。每部分用清晰标题分隔。

- Part 1：直接上 Swift 代码块和表格
- Part 2：每个组件用"结构描述 + 状态表 + 伪代码"三段式
- Part 3：每屏严格按上面的模板
- Part 4：时间轴 + Swift 伪代码
- Part 5：单个 Swift 代码块（完整可运行思路，不必真能 build）

## 最后一句话

你这次的输出会被原样拷贝给 ChatGPT 作为他写 10 万行 SwiftUI 代码的全部视觉依据。你现在的精确度 = 6 周后代码的质量。宁愿说得啰嗦，也不要留模糊。
````

---

## 📌 跑完之后的动作

1. **整段保存 Claude Design 的输出** 成一个本地 md 文件，命名 `设计交付包-V1-输出.md`
2. 若质量满意 → 把这份交付包也 push 到 GitHub（保留为工程 brief 的附件）
3. ChatGPT 开始写代码时，把整份交付包贴给它作为视觉真相源
4. 后续 UI 微调不再开 Claude Design，改走 ChatGPT 直接修改 SwiftUI → Claude review 的流程
