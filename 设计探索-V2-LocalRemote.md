# 时间银行 · UI 设计探索 V3 · Local Remote 风

> 角色：你是一位移动 App 视觉设计师。我是 Adam，时间银行 App 的 PM。
>
> **本份特别**：我希望你的设计参考台北 / 纽约设计工作室 **Local Remote** 的视觉语言。但我没在 brief 里替他们定 spec —— **你必须自己去看他们的作品，提炼方向**。
>
> 这次的 brief 故意写得**松**。我希望看到你的判断 + 你对 Local Remote 美学的解读，不是机械执行。

---

## 1. 产品 DNA（30 秒）

时间银行 = 把"时间"当银行账户的 iOS App。

两层叠加：
- **消耗层**：算"和父母还能共度多少小时"等。温柔提醒"现在很值钱"，不是焦虑倒计时。
- **存储层**：手动把"有意义的瞬间"（带图文）存进对应账户。**永不被消耗**。

哲学：《四千周》(Oliver Burkeman) + 银行账户隐喻。**核心不是焦虑，是"被感受到的时间不会被带走"**。

调性：**克制 · 温暖 · 不焦虑 · 让人每天想点开看一下**。

---

## 2. 核心情绪关键词

**永远写**：温柔 / 留白 / 让人慢下来 / 不打扰

**永远不写**：❌ 倒计时 / 焦虑 / KPI / 徽章 / 强 saturation / 闪光

---

## 3. 5 屏清单 + 真实数据（不要用占位 lorem ipsum · 必须用「林晚」）

### Persona「林晚」

```
基础：1985-03-15 (41) / 女 / 预期寿命 85
父母：父亲 1955 (71)、母亲 1958 (68)，均在世
孩子：1 个 2018 (8)
伴侣：1986 (40)，每天共处 4h

主页 lifespan：上「约还剩 2,288 周」副「44 年 · 386 Kh」/ 下「128 小时」副「27 个瞬间 · 跨 5 个时间账户」

主页 6 张时间账户卡：
  陪父母  | 还能共度 552h · 约 92 次见面     | 已存入 56h · 12 个瞬间
  陪孩子  | 还能共度 6,840h · 每周约 14 小时 | 已存入 23h · 8 个瞬间
  陪伴侣  | 还能共度 43,800h · 每天约 4h 共处 | 已存入 14h · 5 个瞬间
  运动    | 未来 9,560h · 每周约 5 小时       | 已存入 18h · 6 个瞬间
  创造    | 未来 39,000h · 每周约 40 小时     | 已存入 15h · 4 个瞬间
  自由    | 占清醒时间约 56%                   | 已存入 2h · 2 个瞬间
```

### 陪父母时间线 (S2)

| # | 标题 | 时长 | 发生 | 媒体 | 笔记 |
|---|---|---|---|---|---|
| 1 | 妈做的腌菜 | 30m | 2026-03-15 | 1 张 | 她说还是我小时候那个味道。 |
| 2 | 爸第一次坐高铁 | 6h | 2026-02-08 | 4 张 | 他全程靠窗看风景，没说话。 |
| 3 | 一起买菜 | 1h | 2026-01-22 | 2 张 | 妈知道每个摊主的名字。 |
| 4 | 教爸爸用 iPad | 45m | 2025-12-30 | 1 张 | 他终于会自己看视频了。 |

### S3 用："孩子第一次系鞋带" / 陪孩子 / 不计 / 2026-03-10 / 扩展到 4 张图轮播

### S5 年度回顾（跨年）

| 年 | 月 | 时长 | 瞬间 |
|---|---|---|---|
| 2026 | 3 | 12h | 4 |
| 2026 | 2 | 8h | 3 |
| 2026 | 1 | 6h | 2 |
| 2025 | 12 | 4h | 2 |

---

### 5 屏

#### S1 主页 · 产品门面
1. "你好，林晚" 上午 10:30
2. **lifespan 双层卡** ⭐ **重点 · 出 2-3 变体**（详 §4）
3. section 标题 + 6 张双数字时间账户卡
4. Tab Bar + FAB

#### S2 陪父母详情
导航 → 大数字 552h + 副两行 → 洞察一句 → 计算方式卡 → "已存入瞬间 · 12 个 · 56h" → 4 row → "到这里就是最早的了"

#### S3 时刻详情（"孩子第一次系鞋带" 4 图轮播）
导航 → 4 图轮播 → 标题 → 元信息 → 3 chip → 笔记 → 底部三按钮

#### S4 存时刻编辑器（已 prefill "妈做的腌菜"内容）

#### S5 账户 Tab
summary → 环形图 5 段 + legend → 年度回顾 2026/2025

---

## 4. 风格 · Local Remote

### ⚠️ 重要 · 你必须自己做的功课

**在动笔前，请你访问以下链接，自己看 + 提炼他们的视觉语言**：

1. **官网**：https://www.localremote.co/ —— 看他们做的所有项目
2. **Instagram**：https://www.instagram.com/local.remote/ —— feed 里有大量作品截图
3. **TASA 字体**：https://www.serbyte.net/fonts/tasa-orbiter —— 他们设计的 neo-grotesque sans，免费可下
4. **TASA Typeface Collection 仓库**：https://github.com/localremotetw/TASA-Typeface-Collection
5. **设计平台介绍页**：https://designeverywhere.co/profile/local-remote/

我故意**不替他们定 spec**——因为：
- 我没看过他们所有的作品（fetch 被 403 屏蔽）
- 你（AI 工具）能直接上网看图，比我转述更准
- 我不希望你机械执行我的 spec，而是真的吸收他们的视觉语言

### 我能告诉你的（基于公开信息）

| 维度 | 已知事实 |
|---|---|
| **基地** | 台北 + 纽约双城工作室 |
| **业务** | 品牌咨询 / 沉浸式 storytelling / 跨物理 + 数字 + 环境 |
| **代表作** | TASA 台湾太空总署 rebrand · 500Mook 出版物（联合报合作）· Pepper 宠物品牌 identity |
| **自有字体** | TASA Orbiter（neo-grotesque · 几何方角 · 系统化词汇 · 直角转角）· TASA Explorer（geometric · 锐角终端） |
| **服务范围** | book design / editorial / typography / brand identity / illustration / packaging |

### 我推断的核心 DNA（**仅供参考 · 你看完图后自己修正**）

- **Typography-first** —— 字体本身是主角，不靠插画/摄影撑场。这正好契合时间银行的"数据驱动主页"
- **现代主义 + 东亚精致**杂交 —— 像瑞士网格学派 + 一点日韩现代书籍设计的清冷
- **系统化、严格网格但留白大**
- **极克制配色** —— 大概率是黑/白 + 1-2 个克制 accent
- **中英双语混排自然** —— "Time Bank · 时间银行"双语 anchor 适配
- **印刷感的物质温度** —— 出版物 + 包装背景，有"墨 + 纸"的物质记忆
- **TASA 太空总署气质** —— 精确、几何、宽阔留白、institutional 但不冷漠

### 给你的关键挑战

1. **请使用 TASA Orbiter 字体**（Google Fonts 上有，名称 "TASA Orbiter"）作为这次设计的主字体——这是 Local Remote 自家字体，用它最贴近他们的风格。
2. **中英双语融入设计**——把"约还剩 2,288 周"和"About 2,288 Weeks Left"自然并列，让双语成为视觉节奏的一部分。
3. **TASA 字体 + 严格网格 + 系统化品牌识别** = 你这次的核心 toolkit。
4. **如果你看完官网 / Instagram，请在 HTML 顶部用注释写下你提炼出来的 3-5 条 Local Remote 风格 DNA**——证明你真的看过、理解过。

### Lifespan 卡 · 必须出 2-3 个变体（重点）

请基于你对 Local Remote 美学的解读出以下方向：

- **变体 A · 系统化 brand spec**：TASA Orbiter 大字数字 + 严格 12-col 网格 + 双语并列。整卡像 Local Remote brand identity 的内页 spec sheet——精确、克制、专业。
- **变体 B · 出版物 editorial**：参考他们 500Mook 出版物的排版语言 —— column rule + 左右栏目 + serif/sans 混排。整卡像 Local Remote 给某本季刊设计的 cover 内页。
- **变体 C · TASA Mission control**：参考他们 TASA 太空总署 rebrand 的"institutional + cosmic"气质 —— 精确数字 + neo-grotesque + 一抹星空蓝或火星红 accent + 极简几何辅助 element。整卡像太空总署仪表板，但被设计师重新优雅化。

竖向并列，label "变体 A / B / C"。

### 整体感

像 Local Remote 给一家高级杂志、一个文化机构、或一个独立品牌做的视觉系统。**精确、系统、克制，但每一处细节都是被设计过的**。中英双语是 native 的视觉，typography 是主角，留白是结构。

---

## 5. 硬约束（只锁这 3 条 · 其余你自己定）

1. **数据真实**：用 §3 林晚精确数字
2. **双数字双层结构**：lifespan + 6 卡的双数字必须保留
3. **文案逐字**：不准改"陪父母" / "已存入" / "还能共度"

---

## 6. 输出格式

**首选 HTML** ：一个 .html 文件含 5 屏 + lifespan 2-3 变体。

- 顶部 H1 "Local Remote 风 · 林晚 v1"
- **HTML 顶部用 `<!-- -->` 注释写下你提炼的 3-5 条 LR 风格 DNA**
- Google Fonts 引入 TASA Orbiter（重要）+ 思源黑体作为中文 fallback
- 字体用 Google Fonts CDN
- 假图 picsum.photos

**备选 PNG**：5 张 1179×2556px，命名 `linwan-localremote-S1-home.png` 等。

---

## 7. 不要做的事

- ❌ 不看官网就动笔——必须先 fetch 看图
- ❌ 不用 TASA Orbiter 字体（这是 LR 自家字体，不用就失去了灵魂）
- ❌ 中英不混排（双语是 LR 的 native 语言）
- ❌ 装饰性插画 / 花纹 / emoji
- ❌ 渐变 / 玻璃 / 大圆角（这些不是 LR 风）
- ❌ Onboarding / 设置等辅助页
- ❌ Logo / icon 设计
- ❌ Memorial mode

---

## 8. 工具特化指令

### Claude Design：
> **第一步**：先 fetch https://www.localremote.co/ 和 https://designeverywhere.co/profile/local-remote/，看他们的作品图。
>
> **第二步**：在 HTML 顶部注释写 3-5 条你提炼的 LR 风格 DNA。
>
> **第三步**：按 §1-§7 输出 `time-bank-localremote.html`，5 屏 + lifespan 2-3 变体。**TASA Orbiter 必用**。

### Stitch：
> 先看 Local Remote 官网，再做 Figma frame。**挑战**：把 LR 的 typography-first + 系统化网格在 Figma Auto Layout 里实现。

### Gemini：
> 先 fetch Local Remote 官网（你应该有 web fetch 能力）。然后输出 HTML 只代码。在 HTML 顶部注释**列你看到的 3-5 个 LR 视觉特征**。Google Fonts 引入 TASA Orbiter（如不在 Google Fonts，从 GitHub https://github.com/localremotetw/TASA-Typeface-Collection 下载）。

### Codex Image：
> **第一步**：fetch 几张 Local Remote 作品图作为视觉锚（特别是 TASA rebrand / 500Mook / Pepper）。
>
> **第二步**：渲染 S1 主页 mockup PNG 1179×2556px。
> - 文字占位符
> - 氛围参考 LR 的现代主义 + 东亚精致
> - 用 TASA Orbiter 风格的字体感（neo-grotesque · 方角 · 几何）
> - 输出 S1 后等反馈

---

## 准备好就开工。**关键提醒**：在动笔之前，请确认你已经看过 Local Remote 官网和 Instagram。如果你的工具不支持 web fetch，请告诉我，我会想办法给你截图。
