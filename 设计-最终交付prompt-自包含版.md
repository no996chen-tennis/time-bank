# 时间银行 · 自包含设计交付 Prompt（Headspace 风 · 不依赖外部文档）

> Version: 1.0 | Date: 2026-04-22 | 风格：A · Warm Illustration / Headspace 浅色
>
> **本文用途**：发给一个**完全没有上下文**的对话框（新 Claude Design / ChatGPT 设计 GPT / v0 / Figma AI 等）。
> 本文不依赖 GitHub fetch、不依赖历史对话，产品背景 / scope / 约束 / 页面清单全部内嵌。
>
> **使用方法**：把下方 `📋 完整 Prompt` 下面的 code block 整段复制 + 附上 4-6 张 Headspace 截图 → 发送。

---

## 📋 完整 Prompt（整段复制）

````markdown
你是一款 iOS App 的 Lead Designer。这是一次**完整工程级设计交付会话**——我会一次性给你产品 brief、视觉风格、14 屏页面清单、输出格式要求。请一次性全部产出，不要问澄清问题，不要画"占位图"。

---

# 第一部分 · 产品介绍

## 一句话

「**时间银行**」是一款 iOS App，让用户看到和父母 / 孩子 / 伴侣还能共度多少小时，并把有意义的瞬间（图文）永久存进自己的"账户"。

## 核心机制：双层模型

**消耗层（Counter Layer）**：根据用户的生日、家人年龄、见面频率等自动计算"你和父母还能共度约 552 小时（约 92 次见面）"这种数字。每张维度卡片上展示。

**存储层（Deposit Layer）**：用户主动把有意义的时刻（一次旅行、一顿饭、一个生日）手动"存进"对应维度。带标题 + 长文字 + 图片（只从系统 PhotosPicker 选入，V1 不拍摄）。这些瞬间**永久保留，不会被消耗层扣减**。展示为"已存入 56h · 12 个瞬间"。

两层在每张维度卡片同时对照展示 —— 一个在减少，一个在增加。这就是 App 叫"时间银行"的核心：有流出、有存入、有账户余额。

## 6 个内置维度

陪父母（珊瑚橘）/ 陪孩子（金黄）/ 陪伴侣（薰衣草紫）/ 创造（晨雾蓝）/ 运动（薄荷绿）/ 自由时间（蜜桃色）

每个维度独立展示双数字（消耗 vs 存储）+ 副文案（如"约 92 次见面"、"黄金期剩 7.2 年"）。

## Memorial Mode（关键情感机制）

任何关系维度（父母 / 孩子 / 伴侣）可以被标记为"纪念模式"—— 用于承接"家人离世"的场景。

进入纪念模式后：
- 不再显示消耗层数字（不冷冰冰地提醒"还剩 X 年"）
- 只保留已存入的瞬间（图文永久）
- 视觉保持温暖（不变灰、不变冷）
- 卡片下显示 chip："致爸爸"

---

# 第二部分 · 视觉风格（已定稿）

## 风格定位：Warm Illustration · Headspace 浅色

**感觉像抱着一只猫的下午。** 温暖治愈 · 插画承载 · 浅色主背景 · 低饱和温暖色。

### 色板目标（从参考图取精确值）

- **主背景**：奶咖米白（约 #FBF4EC）
- **卡片背景**：纯白或更浅奶色
- **主文字**：深可可（约 #2D2520），不是纯黑
- **次文字**：暖灰（约 #8B7968）

**6 个维度色**（低饱和，饱和度 ≤ 60%）：
- 陪父母 · 珊瑚橘（约 #E89A7C）
- 陪孩子 · 金黄（约 #E8C47C）
- 陪伴侣 · 薰衣草紫（约 #C29DD4）
- 创造 · 晨雾蓝（约 #A8C4D9）
- 运动 · 薄荷绿（约 #8EC7A8）
- 自由 · 蜜桃色（约 #D4A07C）

### 字体

- 中文：阿里普惠 Medium / OPPO Sans Medium（geometric 圆润）
- 英文/数字：DM Sans / Poppins / SF Pro Rounded
- **Medium 500 是默认字重**（不要 Light 不要 Bold）
- 大数字可 Semibold，但必须圆润字形

### 质感

- 圆角大：卡片 20pt+，按钮胶囊 100pt，chip 100pt
- 柔和暖色阴影：`0 4 12 rgba(232,154,124,0.15)`
- 插画风格：细线条 + 大色块（不是纯线条也不是纯扁平）
- 每个维度 icon 是小插画（不是符号）：两人剪影 / 牵手 / 对坐等

### 动效

- Spring 弹性（damping 0.7-0.8）
- 按钮按下"呼吸"感
- 存入成功：心形光点 + 放射微光 + 轻微震动

---

# 第三部分 · 参考图片

我在这条消息里附上了 4-6 张 Headspace 真实截图。请这样使用：

**吸收（抽象层面的风格语言）：**
- 从图中取精确色号（校准上面色板）
- 字体气质（Geometric / Humanist / Rounded ?）
- 插画的线条粗细、填充与线条比例
- 圆角程度（按钮、卡片）
- 阴影柔和度和色调
- 留白节奏
- 色彩饱和度基线

**禁止直接复制（版权 + 原创性）：**
- ❌ 不要照搬图标或插画的具体造型
- ❌ 不要用 Headspace 的品牌橙色
- ❌ 不要出现 "冥想圆圈动画" 这种 Headspace 标志性元素

**翻译要求**：把 Headspace 这套"治愈型视觉语言"翻译到**家人关系 + 时间沉淀**主题：
- 冥想小人 → 两人并肩剪影
- 橙色主色 → 珊瑚粉 / 蜂蜜黄
- 禅意圆圈 → 时间流沙 / 光晕 / 瞬间泡泡

最终输出应该**像 Headspace 的远房表亲** —— 同样的治愈温度，但绝不混淆是同一个 App。

---

# 第四部分 · V1 硬约束（不可破坏）

## 技术约束
- iOS 17+ / SwiftUI 可实现
- **Light Mode Only**（V1 不做 Dark Mode）
- iPhone 16 Pro 尺寸 393×852

## 产品约束 · 存储层量词
- 严格使用 **"个瞬间"**，**禁用 "次"**
- 例：`已存入 12 个瞬间` ✅ / `已存入 12 次` ❌
- 只有在消耗层副文案才用 "次"，例：`约 92 次见面` ✅

## 产品约束 · 单位格式
- 小时简写：`552h` / `7,488h` / `18.2Kh`（≥ 10000 用 K）
- 小时完整：`128 小时`（仅主页顶部总账户用）
- 瞬间计数：`12 个瞬间`
- 次数副文案：`约 92 次见面`
- 相对时间：`3 天前` / `1 年前的今天`

## V1 不做清单（防止偷跑）
- ❌ 视频拍摄 / 拍照（V1 只从相册选）
- ❌ 写系统相册
- ❌ 分享卡（V1.1+）
- ❌ 桌面 Widget / StandBy（V1 只 1 个锁屏 Widget）
- ❌ Dark Mode
- ❌ "今日此刻"模块（第 N 次洗澡那类）
- ❌ 自定义维度 CRUD
- ❌ 社交 / 朋友圈 / 评论 / 点赞
- ❌ "打卡 / KPI / 进度条 / 徽章 / 成就 / 连续签到" 视觉语言
- ❌ emoji（除 Memorial mode 等极少必要场景）

---

# 第五部分 · 要设计的 14 屏（按顺序全部画出来）

每屏按这个模板输出：

```
## Screen N · [名字]
**功能**: [一句话说明]
**尺寸**: iPhone 16 Pro 393×852
**Layout**（从上到下）:
  - [元素描述，使用什么 token / 组件]
**状态**: 正常 / loading / error（如适用）
**交互**: tap A → B
**示意图**: [高保真 UI]
```

## 核心 6 屏

### Screen 1 · Welcome 启动页
- 居中一幅温暖插画（两人坐在窗前看夕阳 / 两个小剪影靠在一起等意象）
- 大标题（中文宋体或温暖无衬线）：**"时间在流逝。被感受过的时间会留下。"**
- 副标题（次文字）：**"看见还能和在意的人共度多少小时，把有意义的时刻留下来。"**
- 底部主按钮"**开始**"（珊瑚橘胶囊）
- 最底部微小字："**开始前所有数据都只在你这台 iPhone 上**"

### Screen 2 · Onboarding Step 2 · 关系 chip 多选
- 顶部进度指示（02 / 04）+ 左上"返回" + 右上"跳过"
- 大标题：**"你和谁共度着时间？"**
- 副标题：**"勾上的维度会出现在主页，随时可以改。"**
- 4 个垂直排列的大号 chip（左插画 icon + 中标签 + 右勾选圆圈），可多选：
  1. 👫 **父母健在**
  2. 🧸 **有孩子**
  3. 💜 **有伴侣**
  4. ☕ **独处也是一种时间**
- 底部"下一步"按钮

### Screen 3 · 主页（总账户 + 维度卡片）
- 顶部 greeting："**下午好，Adam**" + 右上设置 icon
- 顶部**总账户卡片**（大号暖色渐变卡，珊瑚橘到蜜桃色）：
  - "已存入"
  - **"128"**（大号数字）+ "小时"
  - "27 个瞬间 · 跨 4 个维度"
- "**维度 · 4 个**" 小标题
- 4 张双数字维度卡片（垂直列表）：
  - **陪父母**：左侧小插画 + `552h 约 92 次见面` ↔ `56h 12 个瞬间`
  - **陪孩子**：`7,488h 黄金期剩 7.2 年` ↔ `24h 5 个瞬间`
  - **陪伴侣**：`18.2Kh 约共度 40 年` ↔ `32h 7 个瞬间`
  - **创造**：`45.7Kh 黄金期剩 22 年` ↔ `12h 3 个瞬间`
- 底部 Tab Bar：**家** / **存入**（中间凸起 "+" 浮动按钮）/ **我**

### Screen 4 · 维度详情（陪父母）
- 顶部导航"返回" + 标题"**陪父母**" + 右上"+"
- 顶部大号插画（两个老人剪影 + 温暖光晕背景）
- 大标题 **"552h"**（极大字号）+ 副文案 "**约 92 次见面**"
- 参数卡片（横向三格）：**预期 61** / **每年 4 次** / **每次 6h**
- 分隔："**已存入 56h** · **12 个瞬间**"
- 时间线卡片（每条一个瞬间）：
  - 64×64 缩略图 + 标题 + 日期 · 时长 + 笔记首句
- 两条示例：
  - "**杭州西湖 48 小时**" · 2026-03-22 · 48h · "爸这辈子第一次坐游船..."
  - "**妈妈做了一锅红烧肉**" · 2026-02-10 · 3h · "妈妈说这是她学会..."

### Screen 5 · 新增时刻表单
- 顶部"取消" + 标题"**新增瞬间**" + 右上"—"（折叠）
- 字段卡片（白底圆角）：
  - 标题：[输入框] "杭州西湖 48 小时"
  - 存入：[下拉] **陪父母**
  - 发生在：[日期] 2026-03-22
  - 时长：[滑块] 48 小时
- 大号文本域 placeholder："**想说点什么...**"
- 3 × 3 媒体方格（空格子圆角 16pt，点击唤起系统 PhotosPicker）
- 底部 "**3 / 9 个媒体**" 计数（小字）
- 底部主按钮 "**存入时间银行**"（珊瑚橘胶囊，全宽）

### Screen 6 · 时刻详情（回看）
- 顶部"返回" + 右上"⋯"
- 顶部大号媒体轮播（占屏幕 45%）：支持多图左右滑 + 分页点
- 大标题："**杭州西湖 48 小时**"
- Chip 行（一行多个）：陪父母 / 48 小时 / 5 个瞬间 / 1 个视频 · 灰色小胶囊
- 笔记正文（完整展开，行高 1.8，温暖字体）
- 底部三按钮（横向等分）：**[编辑][换维度][删除]**

---

## 关键补充 8 屏（必画）

### Screen 7 · Memorial Mode 维度详情
- 同 Screen 4 布局，但**移除消耗层**（不显示"552h 约 92 次见面"和参数卡）
- 顶部插画保留温暖（一个远山剪影或光晕）
- 大数字只显示"**56h**"
- 副标题 chip："**致爸爸**"（带心形 icon + 维度名）
- 中段换成一段温柔文字："**在这里保留和爸爸的时间。想起的时候，就来看看。**"
- 时间线保留全部已存入瞬间
- 整体视觉保持温暖（不变灰、不变冷）

### Screen 8 · Onboarding 标记已故独立页
- 这是用户在设置里把"爸爸"标记为已故后的独立全屏承接页（不是 Alert）
- 顶部温柔小插画（一片光晕或远山剪影）
- 主标题：**"谢谢你告诉我"**
- 正文（2-3 段温柔文字）：
  "**接下来这个维度会变成纪念模式。**"
  "**你和爸爸已经共度过的时间，永远不会被扣减。**"
  "**如果你存入新的瞬间（回忆、老照片），它们也会被保留。**"
- 底部两按钮：**[进入纪念模式]**（主按钮）/ **[我再想想]**（次按钮）

### Screen 9 · 主页首次空态
- 同 Screen 3 布局，但：
  - 总账户卡变 CTA 卡片："**还没有瞬间被存下来 · 试试存第一个**" + 小插画
  - 维度卡片的"已存入"全部为 **0h · 0 个瞬间**
- 空态插画：空相框 / 一片光晕 / 等待中的图形

### Screen 10 · 维度详情空态
- 同 Screen 4 但时间线区域为空
- 空态卡片：小插画 + 文案 "**还没有陪父母的瞬间。下次回家时，可以带一点回来。**"
- CTA 按钮 "**+ 存入第一个**"

### Screen 11 · 账户 Tab（正常态 + 空态）
- 顶部标题 "**账户**"
- 大号总数字：**"128 小时"** + "**27 个瞬间**"
- **环形图**（各维度占比）
- **年度柱状图**："本月 12h · 上月 18h · 今年累计 128h"
- "**X 年前的今天**" 卡片（如果匹配）
- **空态版本**（另画一版）：总数字为 0 + 插画 + "**第一个瞬间还在等待**" + 按钮

### Screen 12 · Widget 锁屏小号 × 3 种内容变体（170×170）
- **变体 A · 数字主**：中心大数字 "552h" + 副 "陪父母 · 约 92 次见面"
- **变体 B · 文案主**：整块一段温暖文字 "你和妈妈还能一起吃约 312 顿饭"
- **变体 C · 最近瞬间**：小维度 icon + "最近：杭州西湖 48h · 3 天前"

### Screen 13 · 保存失败 Alert
- iOS 系统 Alert 样式
- 标题："**这个瞬间没存下来**"
- 正文："**手机存储不够了，瞬间和照片都没保存。清理一下再试？**"
- 两按钮：**[取消][清理空间]**

### Screen 14 · 删除 Undo Toast
- 屏幕底部浮现 Toast（圆角 16pt + 柔和阴影）
- 左侧：小圆形倒计时环（5 → 0）
- 中间文案：**"删了 1 个瞬间 · 5s 内可撤销"**
- 右侧：**[撤销]** 按钮（珊瑚橘文字）
- 5s 后自动消失

---

# 第六部分 · 必须输出的 5 Part 内容

## Part 1 · Design Tokens（给 ChatGPT 写 SwiftUI 用）

### 1.1 Colors（Swift extension 格式）

```swift
extension Color {
    // Backgrounds
    static let bg          = Color(hex: "...")  // 主背景
    static let bgAlt       = Color(hex: "...")  // 卡片
    static let bgTint      = Color(hex: "...")  // 三级
    static let border      = Color(hex: "...")
    static let borderSoft  = Color(hex: "...")

    // Text
    static let textPrimary   = Color(hex: "...")
    static let textSecondary = Color(hex: "...")
    static let textTertiary  = Color(hex: "...")

    // 6 Dimension colors
    static let dimParents = Color(hex: "...")
    static let dimKids    = Color(hex: "...")
    static let dimPartner = Color(hex: "...")
    static let dimCreate  = Color(hex: "...")
    static let dimSport   = Color(hex: "...")
    static let dimFree    = Color(hex: "...")

    // Semantic
    static let accent   = Color(hex: "...")  // 主 CTA
    static let warm     = Color(hex: "...")
    static let danger   = Color(hex: "...")
    static let success  = Color(hex: "...")
}
```

每色后一行注释：`// WCAG AA 在 bg 上对比度 X.XX ✓/✗`

### 1.2 Typography

| Token | 中文字体 | 英文/数字 | Size | Weight | Line Height | Letter Spacing | Use Case |
|-------|---------|----------|------|--------|-------------|---------------|---------|
| displayLarge | | | | | | | 维度详情大数字 552h |
| displayMedium | | | | | | | 主页总账户 128 |
| title1 | | | | | | | 页面大标题 |
| title2 | | | | | | | 模块标题 |
| body | | | | | | | 正文 |
| bodySm | | | | | | | 次级正文 |
| caption | | | | | | | 元信息 |
| micro | | | | | | | small caps 标签 |

然后给 Swift extension（`Font.dtDisplayLarge = Font.custom("...", size: ..).weight(...)`）。

### 1.3 Spacing / Radius / Shadow

```
spaceXs = 4pt, spaceSm = 8pt, spaceMd = 12pt, spaceLg = 16pt, spaceXl = 24pt, space2xl = 32pt

radiusSm = 8pt, radiusMd = 12pt, radiusLg = 16pt, radiusXl = 24pt, radiusFull = 100pt

shadowSm = 0 1 2 rgba(...)   卡片 resting
shadowMd = 0 4 12 rgba(...)  卡片 elevated
shadowLg = 0 8 24 rgba(...)  Modal / Sheet
```

### 1.4 Motion

| Token | Timing | Curve | SwiftUI | Use |
|-------|--------|-------|---------|-----|
| microPress | 150ms | ease-out | `.easeOut(0.15)` | 按钮按下 |
| transition | 350ms | spring | `.spring(response: 0.5, damping: 0.85)` | 页面切换 |
| heroMoment | 1200ms | spring | `.spring(response: 0.5, damping: 0.7)` | 存入成功 |

## Part 2 · 8 个核心组件规格

每个组件：结构描述 + 各状态（default/pressed/disabled/empty）+ 精确尺寸 + SwiftUI 伪代码骨架

1. **DimensionCard**（双数字卡片 · 最核心）—— normal / memorial / empty 三态
2. **MomentCard**（时间线单条）
3. **ChipMulti**（chip 多选，用于 Onboarding Step 2）
4. **MediaSlot**（9 宫格媒体位，4 态：empty / add / filled / video）
5. **FormRow**（设置 / 表单行）
6. **EmptyState**（通用空态 · 插画 + 文案 + CTA）
7. **Buttons**（Primary / Secondary / Danger）
8. **BottomSheet**（底部动作表）

## Part 3 · 14 屏幕 UI

按上面第五部分的 14 屏清单逐个画高保真图。每屏一个标题 + 统一模板注解。

## Part 4 · 存入成功动效规格

3 关键帧 + Swift 伪代码：
- Frame 0ms · 按钮按下 scale 0.95 + haptic light
- Frame 100-300ms · 表单内容淡出（opacity 1 → 0.3）
- Frame 400ms · 光点从屏幕中心升起到 Y=35%
- Frame 800-1000ms · 光点飞向右上角对应维度卡
- Frame 1000-1200ms · 数字 roll-up（56 → 104）
- Frame 1200ms · 光点溶解 + 模态 dismiss

必须包含：
- SwiftUI 伪代码（`.matchedGeometryEffect` / `.animation` / `.transition`）
- Reduce Motion 降级方案（简单 fade）
- Haptic 触发点（`UINotificationFeedbackGenerator().notificationOccurred(.success)`）

## Part 5 · DimensionCard 完整 SwiftUI 参考实现

30-50 行 Swift 代码，作为其他所有组件的模板。要求：
- 所有颜色走 `Color.dimParents` 这种 token（不硬编码 hex）
- 所有字号走 `.font(.dtDisplayLarge)` 这种 extension
- 所有间距走 `.padding(.horizontal, Space.md)`
- 展示三态：normal / memorial / empty
- 使用 `Formatter.hoursCompact(552)` 占位调用（不要写 "552h"）
- 注释写"为什么"不写"做了什么"

---

# 最后要求

严格按 Part 1 → Part 5 顺序输出。

**精确 > 漂亮**。你的输出会被整段拷贝给另一个 AI（ChatGPT）作为 10 万行 SwiftUI 代码的视觉依据。所以：
- Token 用可粘贴的 Swift 代码块
- 组件用表格 + 伪代码
- 屏幕按统一模板
- 动效用时间轴 + 伪代码
- 代码用真实 SwiftUI 语法

宁可啰嗦不要模糊。一次性交付，不要问澄清问题。开始。
````

---

## 📌 发送前检查清单

- [ ] 上方 code block 整段已复制
- [ ] 附上 4-6 张 Headspace 截图（主页、空态、卡片列表、表单、大数字页、播放器等互补类型）
- [ ] 发送对象是新的对话（没有历史上下文）

## 📌 跑完之后

1. **整段保存**对话输出为一个本地 `.md` 文件
2. 满意 → 把输出文件 push 到 GitHub 作为 ChatGPT 的工程 brief
3. 不满意 → 找我一起看哪部分出了问题，用剩余额度定点补
