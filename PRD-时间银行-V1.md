# 时间银行 — 产品需求文档（PRD）

> Version: 1.3 | Date: 2026-04-22 | Author: Adamchen
>
> **V1.3 主要变更（依据 ChatGPT 2026-04-22 review 定稿 + Adam 2026-04-22 设计方向决策）：**
> - **V1 scope 明确收窄**（配合 12 周 timeline + 初学者工程可行性）
> - **仅 Light Mode**（Dark Mode 短期无规划，从 V1.1+ 列表移除）
> - 新增 §7.6 Authoritative Schema Appendix（工程唯一 schema 源）
> - 新增 §21 Formatter Matrix（单位显示规则）
> - Memorial mode 从"父母特判"升级为"任何关系时间账户通用能力"，升 P0
> - 账户 Tab 升 P0；"今日此刻"、自定义时间账户 CRUD、分享卡、视频拍摄、保存到相册、桌面 Widget、StandBy、多格式导出、从 ZIP 恢复——全部推迟到 V1.1+
> - CloudKit 同步拆两阶段（metadata → media）
> - 通知默认文案改为中性，关系型提醒改为 opt-in
>
> **V1.3.1 补丁（2026-04-22 晚 · Claude Design 首版 review 后）：**
> - **新增「时间余额」内置顶部时间账户**（`Dimension.id = "lifespan"`）：主单位用**周**（呼应《四千周》），副文案 "N 年 · N Kh"
> - 主页顶部卡从"单层已存入"升级为**双层账户卡**：上半「时间余额」+ 下半「已存入」
> - Tab Bar 从 2 Tab 改为 **3 Tab**（主页 / 账户 / 我），浮动 + 按钮保留在中间
> - 主页 "管理" 入口删除（V1 不做自定义时间账户）
> - 主页内容高度硬约束 ≤ 一屏 852px（见 §22 Homepage Layout Constraint）
>
> **V1.3.2 补丁（2026-04-22 晚 · Claude Design UI 定稿后）：**
> - **术语全局调整**：产品功能层面的「维度」统一改为「**时间账户**」（更契合"时间银行"比喻；Swift Schema 类名仍保留 `Dimension` 作为工程术语）
> - **消耗层标签调整**：「还能存入」改为「**还能共度**」（"存入"有金融感，"共度"更自然温暖）
> - 以下 UI 定稿确认（来自 Claude Design final pass）：维度色板、插画系统（纯几何拼贴）、圆润 radius（12/20/24/32/pill）、Token 完整结构
>
> **V1.2 主要变更：** 单位统一到小时（h）为主、"次/年/瞬间"为副；补充信息架构、Release Criteria、风险登记、空态清单、无障碍、i18n、Push/通知策略、Changelog。
>
> **V1.1 主要变更：** 引入"时间存储层"作为产品第二大核心机制。

## 0. 文档使用说明

本 PRD 被以下角色共用，每个角色先看"你最该看的章节"：

| 角色 | 最该看 | 配套子文档 |
|------|-------|-----------|
| **PM (Adam)** | 全文，重点 §1-5、§10-12 | — |
| **iOS 工程师 (Codex / 外部协作)** | §6-7.5、§12、§15 | `Use-Cases-详尽交互.md`（**交付交互真相源**）、`技术方案-媒体存储.md`、`开发上线指南.md` |
| **UX Researcher** | §1-4、§13 | `用户研究.md` |
| **UI 设计师 / Brand** | §5-5.5、§14 空态 | `设计规范.md` |
| **内容设计 / 文案** | §5.5 文案调性、§14 空态 | `文案系统.md` |
| **数据 / 增长** | §8、§10 Release Criteria | `增长与上线.md` |
| **法务 / Privacy** | §16 隐私与合规 | `隐私与合规.md` |
| **QA** | §10 Release Criteria、§14 空态/错误态 | `Use-Cases-详尽交互.md` 附录 D 测试矩阵 |

## 0.5. TL;DR（30 秒读完）

**时间银行**是一款 iOS App，让用户同时看到"人生中重要关系时间账户的剩余小时数"（消耗层）和"自己手动存入的有意义时刻"（存储层，带图文）。存储层时刻永久不被扣减，两层在每张时间账户卡片上形成对照。

**差异化（克制版）**：我们没看到主流产品把"关系时间账户剩余时间 + 存入式记忆账户 + local-first 隐私承诺 + Widget 触达"这四个要素整合在一个体验里。单点都有人做（WeCroak 做死亡提醒、Your Time 做剩余人生、Day One 做记录容器），但这套组合是新的。moat 在组合，不在单点。

**V1 上线目标**：12 周内上架 App Store，30 天 500+ 下载，Day 7 留存 30%+，首月人均存入 5+ 瞬间。

**V1 商业模式**：完全免费、无账号、本地存储、一次性买断感（未来 V2+ 考虑订阅云同步 Pro）。

## 0.6. V1 Scope 白皮书（2026-04-22 定稿）

### V1 明确做（P0）

```
Onboarding         · 4 步（生日 → 关系 chip 多选 → 条件化详情 → 完成）
主页                · 6 内置时间账户卡片（visible 由 onboarding 决定）
                    · 每卡双数字（消耗 vs 存储）
                    · 顶部总账户卡片
时间账户详情             · 参数编辑 + 时间账户级时间线
时刻 CRUD           · 新增（文字 + 图片，只从系统 PhotosPicker 选）
                    · 详情（图片轮播、文字、元信息）
                    · 编辑（所有字段）
                    · 换时间账户
                    · 删除（延迟 5s + Undo Toast）
                    · 批量选择 + 批量换时间账户 + 批量删除
账户 Tab            · 总账户数字、环形图、年度视图、X 年前的今天
Memorial mode       · 任何关系时间账户可进入（纪念模式，只保留存储层）
Widget              · 1 个锁屏 Widget family（小号）+ 基础时间账户偏好
通知                 · 每天最多 1 次（默认中性文案，关系型提醒为 opt-in）
导出                 · Raw ZIP（原媒体 + JSON + README，一种格式）
外观                 · Light Mode Only（设计方向见 `设计提示词-浅色5风格.md`）
本地存储             · SwiftData + FileManager 沙盒
```

### V1 明确不做（推迟到 V1.1 / V1.5 / V2）

```
V1.1（上线后第 1 迭代）
  · 今日此刻模块（第 N 次洗澡等）
  · 桌面 Widget（中 / 大号）
  · 自定义时间账户 CRUD
  · 分享卡生成
  · 从 ZIP 恢复数据

V1.5（上线后 3 个月内）
  · CloudKit 同步（先 metadata-only，再原媒体）
  · 多格式导出（Markdown for Obsidian、转码 MP4/JPG）
  · 视频拍摄（App 内原生拍视频）
  · 月度回顾

V2+
  · StandBy 模式
  · Apple Watch complication
  · 智能存入建议（基于相册+日历检测）
  · 年度回顾视频
  · 时刻关联（旅行集合类父子关系）
  · 自定义 tag
```

### 为什么这样砍

1. **拍视频 / 保存到相册**：砍掉能保住"不碰系统相册、不加麦克风权限"的硬承诺。这是 V1 隐私营销主张的核心。
2. **今日此刻 / 自定义时间账户 CRUD**：V1 先验证"关系时间账户 + 双数字"主命题是否成立；这两个是独立小产品，可以后补。
3. **分享卡**：冷启动传播可以靠用户截图"双数字卡片"本身完成，不必在产品里专门做"分享卡生成"。增长文档相应调整（见 `增长与上线.md`）。
4. **桌面 Widget / StandBy**：每一个都是工程坑。Swift 初学者 12 周只能保 1 个锁屏 Widget。Dark Mode 短期无规划（产品策略上认为奶咖暖色 Light 是核心调性的载体）。
5. **多格式导出 / 从 ZIP 恢复**：V1 导出只保证"用户数据可带走"（信任锚），V1 明说"导出是归档，不是可直接重建的库"。

---

## 1. Problem Statement

人们知道"时间有限"，但从未真正感受过。我们不知道自己还能和父母见多少次面，不知道陪孩子的高质量时间其实只剩几年，不知道每天的洗澡、吃饭、散步都是有限次数的体验。现有的 Life Clock 类产品（如 WeCroak、Your Time）只做生命总倒计时，制造焦虑但不提供洞察，更没有任何产品在做"家人剩余时间"和"日常体验觉知"。

这个问题影响所有成年人，尤其是 25-45 岁有家庭的人。不解决的代价是：人们持续在"赶时间"模式中生活，直到某天突然意识到重要的时间窗口已经关闭。

**同时还有第二层问题——**
相册里有很多珍贵的照片，但它们被埋在"按时间倒序"的海量流水里，没有被赋予**"这一小时属于陪爸妈"**这样的上下文。用户知道这些时刻重要，但缺乏一个容器把它们**按关系/时间账户**结构化地沉淀下来，导致这些瞬间从未真正"被存进去"，只是在相册里慢慢被新照片淹没。

## 1.5. 双层产品模型（V1.1 新增）

时间银行的核心比喻是**银行账户**，所以产品由两层构成：

```
 ┌──────────────────────────────────────────┐
 │  消耗层（Counter Layer）                   │
 │  - 时间在不可逆流逝                          │
 │  - 展示："第 N 次 / 还剩 N 次"               │
 │  - 自动计算，用户无需输入                     │
 │  - 对应：主页时间账户卡片、日常时刻、Widget    │
 └──────────────────────────────────────────┘
                     ↕
 ┌──────────────────────────────────────────┐
 │  存储层（Deposit Layer）【V1.1 新增】         │
 │  - 用户主动把有意义的时刻"存进"某时间账户          │
 │  - 带图片/视频/文字/时长                      │
 │  - 永久封存，不会被消耗层扣减                   │
 │  - 展示："已存入 X 小时 / Y 个瞬间"             │
 │  - 对应：时间账户时间线、时刻详情页、回顾           │
 └──────────────────────────────────────────┘
```

**核心叙事：**
- 时间仍然在流逝（消耗层），但"被感受过的时间"会留在账户里永远属于你（存储层）
- 消耗层给出"稀缺感"，存储层给出"积累感"
- 每存入一个时刻，该时间账户的"已存入"数字变大，给用户一种"时间资产在复利增长"的正反馈
- 名字真正对应机制：**时间** + **银行** = 有流出、有存入、有账户余额

## 2. Goals

**用户目标：**
- 用户首次看到自己的时间数据后，产生"我要更珍惜这些时间"的感受（定性验证）
- 用户每天通过 Widget 至少被"提醒"一次，自然地看到时间数据
- 用户能在 30 秒内完成初始设置，无需手动计算任何数字
- 用户首月至少存入 5 个"有意义时刻"到时间银行（验证存储层是否被接受）

**产品目标：**
- V1 上线后 30 天内获得 500+ 下载
- Day 7 留存率达到 30%（Widget 驱动的被动留存）
- App Store 评分 4.5+ 星

## 3. Non-Goals（V1 明确不做）

- **社交关系链 / 社区 / UGC 公开发布**：不做关注、朋友圈、评论区。V1 是纯个人工具。（注：时刻分享卡是 V1.1 功能，仅走系统分享表，不构成社交关系）
- **健康数据接入**：不对接 HealthKit 或运动手表数据。V1 用用户自己填的合理值，保持极简。
- **AI 个性化建议**：不做"你应该多陪陪爸妈"这类推送。产品只呈现数据，不说教。
- **Android 版本**：V1 只做 iOS（含 Widget），Android 放在验证市场后。
- **付费/订阅**：V1 完全免费，先验证产品价值。
- **云服务器 / 账号体系**：V1 不联网、不注册，数据完全本地。
- **App 内相机拍照 / 拍视频**：V1 只从系统 PhotosPicker 选媒体，不申请相机/麦克风权限（V1.5 再加）。
- **写入系统相册**：V1 不写相册，保持"不碰用户相册"的隐私主张（V1.5 视用户反馈再议）。

## 4. Target Users

**核心用户画像：** 25-45 岁，有家庭（父母健在、有孩子或伴侣），日常忙碌，感觉时间"不够用"但说不清楚花在了哪里。对 Die With Zero / 四千周这类理念有共鸣但缺乏工具。

**次要用户：** 20-30 岁年轻人，尚未组建家庭，但想追踪个人成长时间账户（运动、创造、学习）。

## 5. User Stories

### 新用户引导

As a 新用户, I want to 只输入最少的信息就看到我的时间全景, so that 我不会因为设置太复杂而放弃。

**验收标准：**
- 引导流程不超过 4 步（生日 → 关系选择 chip → 条件化详情 → 完成）
- 只需输入：生日、性别（可选）、**用户主动勾选的**家人基本信息
- **明确支持单身、丁克、无父母、独处人群**：Step 2 用 chip 多选"你和谁共度着时间？"，未勾选的时间账户不展示、不占位、不提示
- 允许 Step 2 一个都不勾（走自由时间账户 + 日常时刻即可）
- 所有字段默认值由系统根据年龄自动计算
- 从打开 App 到看到主页不超过 60 秒
- 支持后续补充（UC-0.2）和"标记已故"（UC-0.3）等特殊路径

**详细交互见：** `Use-Cases-详尽交互.md` UC-0.1 ~ UC-0.3

### 查看时间账户

As a 用户, I want to 一眼看到我在各个人生时间账户的剩余时间, so that 我能直观感受到什么是真正重要的。

**验收标准：**
- 主页**仅展示用户在 onboarding 里勾选了的关系时间账户**（父母/孩子/伴侣）+ 通用时间账户（运动/创造/自由）
- 内置时间账户在数据库中始终存在，但通过 `Dimension.status = visible | hidden` 控制展示
- 用户可后续在设置里把 hidden 的时间账户转为 visible
- 每张卡片显示双数字（消耗 + 存储）+ 副文案
- 点击卡片进入详情页，展示计算逻辑和时间线
- 数字默认使用"第 N 次"正向叙事，可切换为"剩余 N 次"（V1.1 实现）

### 调整计算方式

As a 用户, I want to 修改默认的计算参数, so that 数据更贴合我的实际情况。

**验收标准：**
- 在每张卡片的详情页可以编辑参数（如运动时长、见面频率等）
- 修改后实时刷新数字
- 提供"恢复默认值"选项
- 参数范围有合理上下限，防止输入极端值

### 自定义追踪项

As a 用户, I want to 创建属于我自己的时间账户, so that 我能追踪对我个人有意义的事情。

**验收标准：**
- 主页底部有"添加新时间账户"入口
- 创建时需填写：名称、图标（从预设中选）、计算方式（每周 X 小时 或 每年 X 次 等）
- 自定义时间账户和系统内置时间账户在主页混排
- 最多可创建 10 个自定义时间账户

### 感受日常时刻

As a 用户, I want to 看到日常小事的"第 N 次"计数, so that 我能意识到这些平凡瞬间其实也值得被感受。

**验收标准：**
- "今日此刻"模块展示 5-8 个日常时刻（洗澡、吃饭、早晨、日落、散步等）
- 每个时刻显示"第 N 次"和一句温暖的提示语
- 用户可以自定义或隐藏某些时刻
- 数字基于用户出生日期自动计算

### 锁屏 Widget

As a 用户, I want to 不打开 App 就能在锁屏上看到时间提醒, so that 我在日常生活中被自然地提醒。

**验收标准：**
- 支持 iOS 锁屏 Widget（小尺寸）
- Widget 内容每天轮换（今天显示家人、明天显示运动、后天显示日常时刻）
- Widget 文案温暖正向，不制造焦虑
- 用户可以在设置中选择 Widget 偏好展示哪些时间账户

### 创造/工作时间账户

As a 用户, I want to 追踪我投入在创造性工作上的时间, so that 我能看到自己在"留下作品"这件事上还有多少时间。

**验收标准：**
- "创造"作为系统内置时间账户，在引导流程中可设置
- 默认按职业生涯阶段计算（25-65 岁为主要创造期，65+ 为自由创造期）
- 用户可自定义"创造"的具体含义（写代码、做产品、写作、创业等）
- 详情页展示洞察：如"你的黄金创造期还有约 X 年"

---

### 【存储层】存入一个时刻（Deposit a Moment）

As a 用户, I want to 把一段有意义的时间手动"存入"对应的时间账户, so that 这段时间被永久记录下来，不会像消耗层那样随着日子流逝而扣减。

**用户故事场景：**
我带爸妈去了一趟杭州，两天一夜。回来之后，我在"陪父母"卡片里点"存入时刻"，输入标题"杭州西湖 48 小时"、时长 48 小时、上传了 8 张照片和 1 段 30s 的视频，写了一段话"爸这辈子第一次坐游船，他说比他想的大多了"。保存后，"陪父母"卡片多显示一行"已存入 3 个瞬间 · 56 小时"。

**验收标准：**
- 任何主页卡片（含日常时刻）都可直接点"+"新增时刻
- 新增表单字段：标题（可选）、发生时间（默认今天）、时长（可选，预设滑块）、文字（长文本、多行、支持 Emoji）、媒体（图/视频，最多 9 条，可混排）
- 媒体通过 `PhotosPicker`（iOS 16+）或原生相机拍摄获取，无需请求"读取所有相册"的敏感权限
- 保存后原图原视频存入 App 沙盒（不污染用户相册），同时生成缩略图用于时间线渲染
- 存入流程 ≤ 30 秒（熟手场景）
- 存入完成后有一个温暖的动效反馈（不是成就徽章，而是像"一滴光进入账户"的感觉）

### 【存储层】查看一个时间账户下的时间线

As a 用户, I want to 点开任一时间账户看到我存入的所有时刻, so that 我能一次性回顾我在这个关系/主题下积累的所有珍贵片段。

**验收标准：**
- 每个时间账户详情页下半部分是该时间账户的"时间线"
- 每条时刻展示：第一张图缩略图 / 标题 / 发生时间 / 时长 / 文字首句
- 按发生时间倒序（默认），可切换为正序
- 长按一条时刻可进入多选模式，批量删除 / 导出 / 换时间账户
- 时间线顶部显示汇总："共存入 Y 小时 · N 个瞬间 · 覆盖 M 个月"

### 【存储层】回看一个时刻

As a 用户, I want to 点开一个时刻看到全部内容, so that 我能沉浸式地重新感受那段时间。

**验收标准：**
- 点开进入全屏详情页
- 顶部媒体区：多图可左右滑动，视频可点播放
- 中间元信息：发生时间（精确到日）、时长、归属时间账户、距今多久
- 下方文字展开显示
- 底部：编辑 / 分享为图片 / 换时间账户 / 删除
- 支持"今天的 X 年前"等回忆提醒：若某条时刻正好在 1/2/5 年前的今天发生，首页顶部会出现一条"X 年前的今天"的软提示卡片

### 【存储层】跨时间账户"时间资产总览"

As a 用户, I want to 看到我的时间银行总账户, so that 我能直观感受到自己到底存下了多少被感受过的时间。

**验收标准：**
- 主页顶部或二级页展示一个"总账户"视图
- 展示：累计存入时长（如 "128 小时"）、时刻数量、各时间账户占比（环形图）
- 提供年度视图："2026 年你存入了 X 小时"
- 这个数字**永远只增不减**

### 【存储层】"存入"与"消耗"的关系

As a 用户, I want to 在消耗层看到存储层的沉淀, so that 两层之间是对照的、有张力的、完整的。

**验收标准：**
- 每张时间账户卡片同时显示两组数字（按 §21 Formatter Matrix 格式）：
  - 消耗层：`552h · 约 92 次见面`
  - 存储层：`56h · 12 个瞬间`
- 视觉上：消耗层数字是会变小的，存储层数字是会变大的，形成对照
- 明确告知用户："消耗层是估算，存储层是你真的记录下来的"

### 【Memorial Mode】纪念某位家人 / 关系

As a 用户, I want to 在经历失去后，温柔地把这个时间账户转为"只纪念，不计算", so that 产品不会继续在我面前显示冷冰冰的"还剩 X 小时"。

**适用范围**：任何关系类型时间账户 —— parents / kids / partner / 以及 V1.1 后的自定义关系时间账户（如"爷爷"、宠物名）。不仅限于 parents。

**验收标准：**
- 入口：设置 → 个人信息 → 家人详情 → 「标记已故」；用独立页而非 Alert 承接（交互温柔）
- 时间账户进入 memorial 后：
  - 数字区只保留"已存入 56h · 12 个瞬间"，不再显示剩余小时 / 副文案
  - 卡片下方显示 chip："致爸爸"
  - 时间账户色保留（不变灰、不变冷）
  - Widget 上该时间账户不再作为"剩余倒计时"类内容轮播，只作为"回忆触达"出现（若开启）
- 用户可随时"取消标记"（场景：误操作 / 心理准备好重看数字）
- 所有已存入的时刻完整保留，永不因 memorial 状态改变可见性

### 【存储层】自动建议"存入"

As a 用户, I want to 在我刚拍完照片后收到一条温柔的建议, so that 我不会错过把当下存进时间银行的时机。

**验收标准（V2+，非 V1 阻塞项）：**
- App 打开时检测：近 24h 内是否有多张连拍照片 + 当时有日历事件（如"爸爸生日"）
- 如果检测到，首页出现一条软卡片："昨天下午 3-5 点，你拍了 14 张照片。要存进'陪父母'吗？"
- 用户点一下即可进入存入流程，媒体已预填好
- 用户可永久关闭此提醒

### 【存储层】导出与备份

As a 用户, I want to 导出我所有存入的时刻, so that 我不会担心 App 失败或停更导致这些珍贵内容丢失。

**验收标准：**
- 设置页提供"导出全部数据"入口
- 导出为一个 ZIP，内含：所有原图/原视频 + 按时间账户分文件夹 + 一个 JSON 或 Markdown 结构化索引
- 导出位置让用户选：保存到"文件" App、分享到其他 App、或存到 iCloud Drive
- 明确承诺："你存入时间银行的每一份内容，永远属于你，可随时完整带走"

## 6. Requirements

### P0 — Must Have（V1 必须有 · 2026-04-22 定稿）

| # | 功能 | 验收标准 |
|---|------|----------|
| P0-1 | 引导流程（4 步 + Pre-permission） | 生日 → 关系 chip 多选 → 条件化详情 → 完成。**支持 0 勾选**（单身 / 无父母 / 只用自我时间账户）。总耗时 ≤ 60s |
| P0-2 | 主页 · 双数字时间账户卡片 | 只展示 onboarding 勾选了的内置时间账户 + 通用时间账户（运动/创造/自由）。每张卡片同时显示"消耗层剩余 h + 存储层已存入 h + 副文案"，格式按 §21 Formatter Matrix |
| P0-3 | 主页 · 顶部总账户卡片 | 累计存入小时数、瞬间数、跨几个时间账户 |
| P0-4 | 时间账户详情页 | 上半 = 消耗层大数字 + 副文案 + 参数编辑卡；下半 = 该时间账户时间线 |
| P0-5 | 时间账户参数编辑 | 每个内置时间账户的核心参数（频率、每次时长、预期寿命等）可调；恢复默认值 |
| P0-6 | 存储层 · 新增时刻 | 字段：时间账户、发生时间、时长（可空）、标题、长文本、图片（最多 9 张，只从 PhotosPicker 选，不做 App 内拍照/拍视频）。**V1 允许从相册选视频**，但 V1 不提供 App 内相机录视频。保存走**强原子性事务** |
| P0-7 | 存储层 · 时间账户时间线 | 时间账户详情页下半部分展示全部时刻，倒序，缩略图+标题+时长+笔记首句 |
| P0-8 | 存储层 · 时刻详情页 | 全屏媒体轮播（图+视频播放）、文字展开、Chip、底部动作：编辑 / 换时间账户 / 删除。**V1 不含"分享卡"** |
| P0-9 | 时刻 CRUD 完整闭环 | 编辑所有字段、换时间账户、删除走延迟 5s + Undo Toast 协议 |
| P0-10 | 批量选择 + 批量换时间账户 + 批量删除 | 时间线长按进入批量模式 |
| P0-11 | 账户 Tab | 独立二级 Tab：总账户数字、环形占比图、年度柱状视图、"X 年前的今天"卡片 |
| P0-12 | Memorial Mode | 任何关系时间账户（parents/kids/partner/custom）可标记为"纪念模式"：不再计算消耗、只保留存储层；视觉保持温暖（不变灰）|
| P0-13 | 锁屏 Widget（1 种 family） | 小号锁屏 Widget，显示时间账户数字或温暖文案；从 App 生成的预计算快照读取（走 App Group）|
| P0-14 | 每日温暖通知（opt-in） | 默认中性文案；**关系型提醒（"你上次见爸妈是 X 天前"）默认关闭**，用户主动在设置里 opt-in 并可随时关闭 |
| P0-15 | 本地数据存储 | SwiftData + FileManager 沙盒；无联网、无账号 |
| P0-16 | 数据导出 | 单一格式：Raw ZIP（原图/原视频 + JSON 索引 + 人类可读 README）。**V1 不做 Markdown 导出、转码导出、从 ZIP 恢复**|
| P0-17 | Light Mode 完整适配 | Release Criteria 只验收 Light，不含 Dark；设计方向见 `设计提示词-浅色5风格.md` |
| P0-18 | 孤儿文件清理 | App 启动时自动扫描并清理沙盒中"无 SwiftData 记录"的媒体文件夹 |
| P0-19 | 无障碍基线 | VoiceOver 标签齐全；44pt 触控；Dynamic Type 到 `.accessibility1` |
| P0-20 | Privacy Manifest + 最小权限 | 仅需 PhotosPicker（免权限）；不索相册写入权限、不索麦克风权限、不索相机权限（V1） |
| **P0-21** | **时间余额（lifespan）顶部时间账户** | **内置 `Dimension.id = "lifespan"` (`kind = systemTop`)；主页顶部双层卡上半展示 `约 N 周` + 副 `N 年 · N Kh`；预期寿命默认 85 可在设置调** |
| **P0-22** | **主页顶部双层账户卡** | **上半 lifespan「时间余额」+ 下半「已存入」共用一个珊瑚橘渐变卡；中间柔和分隔线；高度 ≤ 240pt** |
| **P0-23** | **3 Tab 底部导航** | **主页 / 账户 / 我**；中央浮动 + 按钮（新增瞬间）保留；Account Tab 独立而非"我"的子页 |
| **P0-24** | **主页一屏容纳** | **全部关键内容（双层卡 + 至少 4 张时间账户卡片完整双数字区）必须在 iPhone 16 Pro 852pt 屏高内第一屏可见，不依赖滚动；详见 §22** |

### P1 — V1.1（首次迭代，上线 1-2 月内）

| # | 功能 | 说明 |
|---|------|------|
| P1-1 | "今日此刻"模块 | 第 N 次洗澡 / 吃饭 / 早晨等；走隐藏时间账户 `daily` |
| P1-2 | 自定义时间账户 CRUD | 用户新增/编辑/排序/删除自定义时间账户，最多 10 个 |
| P1-3 | 桌面 Widget（中号 + 大号） | Home Screen Widget 多时间账户 grid |
| P1-4 | 分享卡生成 | 1080×1920 图片，**仅走系统分享表**，V1.1 不加相册写入权限 |
| P1-5 | 从 ZIP 恢复数据 | 设置页导入 ZIP 重建时间银行 |
| P1-6 | 叙事模式切换 | "第 N 次" ↔ "剩余 N 次"全局切换 |
| P1-7 | 创造时间账户子分类 | 编程 / 写作 / 创业等子项 |

### P1.5 — V1.5（上线 3 个月内）

| # | 功能 | 说明 |
|---|------|------|
| P1.5-1 | CloudKit 同步 · 阶段 A | **只同步 metadata + 缩略图**（< 50MB/千时刻），跨设备秒级一致，不动原媒体 |
| P1.5-2 | CloudKit 同步 · 阶段 B | 原图/原视频懒加载下载（CKAsset 按需），加失败兜底 UI |
| P1.5-3 | 多格式导出 | Markdown（Obsidian 友好）+ 转码压缩 ZIP |
| P1.5-4 | App 内视频拍摄 | 加 Camera + Microphone 权限；真机链路测过 |
| P1.5-5 | 月度回顾 | "一封温柔的信"形式展示本月时间分布 |
| P1.5-6 | 保存到相册（可选） | 用户可选；加 `NSPhotoLibraryAddUsageDescription`，商店描述明示 |

### P2 — V2+（探索）

| # | 功能 | 说明 |
|---|------|------|
| P2-1 | StandBy 模式 | 大字时钟显示 |
| P2-2 | Apple Watch Complication | 表盘数字 |
| P2-3 | 智能存入建议 | 基于相册连拍 + 日历事件软提示 |
| P2-4 | 年度回顾视频 | 自动生成 "你的 X 年时间银行" 短视频 |
| P2-5 | 时刻关联 | 旅行集合类父子关系 |
| P2-6 | 自定义 tag | Moment 打 tag |
| P2-7 | 时间快照对比 | 实际 vs 计划 |

## 7. 时间账户计算逻辑

### 单位统一规则（V1.3.1 全局约定）

**两种时间的区分（2026-04-22 补充）：**

| 类型 | 特点 | 主单位 | 适用时间账户 | 哲学依据 |
|------|------|-------|---------|---------|
| **连续流逝型** | 时间不管你做什么都在流 | **周** | `lifespan` 时间余额 | 《四千周》Oliver Burkeman |
| **分散累加型** | 具体场景中累积出来的 | **小时 (h)** | 陪父母 / 陪孩子 / 陪伴侣 / 运动 / 创造 / 自由 | 实际体验累加 |

为什么不全改周：陪父母 "3.3 周"（552h ÷ 168h）数学对但直觉怪——用户实际每年见 4 次 × 6h，这不是"3 周"能描述的感受。**顶部时间余额走周（作为哲学 anchor），其他时间账户走小时（作为具体场景 anchor）**，这种"刻意不一致"是设计选择不是 bug。

**副文案用「次」「年」作人类尺度翻译**——"552 小时"对普通人抽象，"约 92 次见面"立刻可想象。

**存储层量词用「瞬间」（不用"次"）**——避免与消耗层的"次"混淆；一个瞬间可能是 2h 也可能是 48h，强调"被感受的片段"而非"打卡"。

**卡片展示固定格式：**

```
♡ 陪父母                                       ›
 ───────────────────────────────────────
 还能共度                           已存入
   552h                              56h
 约 92 次见面                       12 个瞬间
```

### 内置时间账户默认值

**时间余额（lifespan · 顶部系统时间账户 · V1.3.1 新增）：**
- 输入：用户的生日（已有）、预期寿命（默认 85，可在设置调）
- 计算：`剩余周数 = (预期寿命 - 当前年龄) × 52.1429`（一年约 52.1429 周）
- **主显示**：`约 2,704 周` · **副文案**：`45 年 · 473 Kh`
- **不参与其他时间账户聚合**（它是总体人生倒计时，不和"陪父母"等分散累加型时间账户相加）
- 展示位置：主页顶部双层卡的上半部分（见 §22）
- 存储层：**没有**（Memorial mode 对 lifespan 无意义，人生整体不标记已故）

**陪父母：**
- 输入：父母出生年份、每年见面次数
- 预期寿命：82 岁（默认值，可调）
- 每次见面时长：6 小时（默认值，可调）
- 计算：剩余小时 = (82 - 父母当前年龄) × 每年见面次数 × 每次见面小时
- **主显示**：`552h` · **副文案**：`约 92 次见面`

**陪孩子：**
- 输入：孩子年龄
- 高质量陪伴时间按年龄递减：0-5 岁 30h/周、6-12 岁 20h/周、13-17 岁 10h/周、18+ 岁 2h/周
- 核心窗口：18 岁前
- **主显示**：`7,488h` · **副文案**：`黄金期剩 7.2 年`

**运动：**
- 按年龄段动态调整：50 岁前 5h/周、50-80 岁 3h/周、80+ 岁 1h/周
- **主显示**：`8,160h` · **副文案**：`每周约 5h`

**创造/工作：**
- 主要创造期：当前年龄到 65 岁
- 自由创造期：65-预期寿命
- 每周创造时间：主要期 40h/周（可调）、自由期 20h/周
- **主显示**：`45,760h` · **副文案**：`黄金期剩 22 年`

**陪伴侣：**
- 每日共处时间：4h（默认值，可调）
- 计算基于自己或伴侣中较短的预期寿命
- **主显示**：`18,240h`（> 10,000 用千分位或 "18.2Kh"） · **副文案**：`约共度 40 年`

**自由时间：**
- 总可支配时间（每天 14 小时清醒可支配时间）
- 减去以上所有时间账户的时间
- **主显示**：`176,320h` · **副文案**：`约 20 年自由时间`

### 存储层展示规则

- **单卡片底部**："已存入 56h · 12 个瞬间"（小时为主，瞬间数为辅）
- **总账户（主页顶部）**："已存入 128 小时 · 27 个瞬间 · 跨 5 个时间账户"
- **时刻详情页**：发生时长 `48h` · 媒体数 `5 个媒体`

### 大数字可读性规则

| 范围 | 格式 |
|------|------|
| < 1,000 | `552h` |
| 1,000 – 9,999 | `7,488h`（千分位） |
| 10,000 – 99,999 | `18.2Kh`（一位小数 K）|
| ≥ 100,000 | `176Kh` |

### 日常时刻计数

| 时刻 | 计算方式 | 示例文案 |
|------|----------|----------|
| 洗澡 | 出生天数 | 第 12,483 次洗澡，感受热水的温度 |
| 吃饭 | 出生天数 × 3 | 第 37,449 顿饭，好好尝尝味道 |
| 早晨 | 出生天数 | 第 12,483 个早晨，感受一下阳光 |
| 日落 | 剩余天数 | 还能看约 15,330 次日落 |
| 散步 | 剩余天数 | 还能散约 15,330 次步 |
| 上厕所 | 出生天数 × 6 | 第 74,898 次上厕所（是的，这也是你的时间）|
| 做饭 | 出生天数 × 0.7 | 第 8,738 次做饭 |

## 7.5. 存储层数据模型（V1.1 新增）

### 实体关系

```
User (1) ──── (N) Dimension ──── (N) Moment ──── (N) MediaItem
                                     │
                                     └── 归属一个时间账户（可换）
```

### Dimension（时间账户）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | String | "parents" / "kids" / "create" / "partner" / "sport" / "free" 或 UUID（自定义时间账户）|
| name | String | 展示名 |
| kind | Enum | builtin / custom |
| iconKey | String | 图标标识 |
| createdAt | Date | 创建时间 |

### Moment（存入的一个时刻）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| dimensionId | String | 所属时间账户（可改） |
| title | String? | 可选标题（如"杭州西湖 48 小时"）|
| note | String | 长文本，默认空 |
| happenedAt | Date | 事件发生时间（不是录入时间）|
| durationSeconds | Int? | 时长，单位秒，可空（有些时刻没"时长"概念）|
| createdAt | Date | 录入时间 |
| updatedAt | Date | 最后编辑时间 |
| mediaItems | [MediaItem] | 关联媒体列表 |

### MediaItem（媒体文件）
| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 主键 |
| momentId | UUID | 所属时刻 |
| type | Enum | image / video |
| relativePath | String | 相对 Documents/TimeBank/ 的路径 |
| thumbnailPath | String? | 缩略图相对路径（由 App 生成的 200x200 JPG）|
| fileSize | Int64 | 字节数 |
| durationSeconds | Int? | 视频长度，图片为 null |
| sortIndex | Int | 在时刻内部的展示顺序 |
| createdAt | Date | 写入时间 |

## 7.6. Authoritative Schema Appendix（工程唯一真相源）

> 本节是工程实现 SwiftData / CloudKit / 导出 JSON 的**唯一 schema 源**。V1.3 之后任何字段改动必须先改这里再改代码。

### 保留标识符 (Reserved IDs)

```
Dimension.id 保留值：
  "lifespan"                                                      ← 【V1.3.1 新增】顶部系统时间账户 · 时间余额 · 主页顶部专属
  "parents" / "kids" / "partner" / "sport" / "create" / "free"    ← 内置可见关系/通用时间账户
  "daily"                                                         ← 系统隐藏时间账户（V1.1"今日此刻"使用，V1 预留但不启用）
  "other"                                                         ← 孤儿瞬间承接时间账户（当 Moment 归属时间账户被删时迁入）
  其余 UUID                                                       ← 用户自定义时间账户（V1.1+ 启用）
```

### UserProfile

```swift
@Model final class UserProfile {
    @Attribute(.unique) var id: UUID           // 恒为单例 ID
    var birthday: Date                          // 必填
    var gender: Gender                          // male / female / other / undisclosed
    var expectedLifespanYears: Int              // V1.3.1 新增 · 默认 85 · 用于 lifespan 时间账户计算
    var parents: ParentsInfo?                   // null = onboarding 未勾选
    var children: [ChildInfo]                   // [] = 未勾选或没有
    var partner: PartnerInfo?                   // null = 未勾选或单身
    var soloEmphasis: Bool                      // 是否勾选"独处也是一种时间"
    var extras: [ExtraRelation]                 // 宠物、好友等

    var createdAt: Date
    var updatedAt: Date
}

struct ParentsInfo: Codable {
    var father: FamilyMember?                   // null = 缺省或已故前未填
    var mother: FamilyMember?
    var visitsPerYear: Int                      // 默认 4
    var hoursPerVisit: Double                   // 默认 6.0，最小 0.5
    var expectedLifespan: Int                   // 默认 82
}

struct FamilyMember: Codable {
    var birthYear: Int
    var deceased: Bool                          // memorial mode 触发点
    var deceasedAt: Date?                       // 仅 deceased=true 时有值
}

struct ChildInfo: Codable {
    var id: UUID
    var birthYear: Int
    var gender: Gender?                         // 可空
    var deceased: Bool                          // 罕见但必须支持
    var deceasedAt: Date?
}

struct PartnerInfo: Codable {
    var birthYear: Int
    var hoursPerDay: Double                     // 默认 4.0
    var deceased: Bool
    var deceasedAt: Date?
}

struct ExtraRelation: Codable {
    var id: UUID
    var kind: String                            // "pet" / "friend" / "custom"
    var name: String
    var birthYear: Int?
}

enum Gender: String, Codable {
    case male, female, other, undisclosed
}
```

### Dimension

```swift
@Model final class Dimension {
    @Attribute(.unique) var id: String          // 保留值 or UUID
    var name: String
    var kind: DimensionKind
    var status: DimensionStatus                  // visible / hidden / deleted
    var mode: DimensionMode                      // normal / memorial
    var iconKey: String
    var colorKey: String                         // rose / warm / lavender / sage / sky / peach
    var sortIndex: Int
    var params: Data                             // JSON-encoded 时间账户参数（按 kind 不同）
    var createdAt: Date
    var updatedAt: Date
}

enum DimensionKind: String, Codable {
    case builtin           // 6 内置关系/通用时间账户
    case systemTop         // V1.3.1 · 仅 lifespan 一个 · 顶部专属 · 不进入时间账户列表/聚合
    case custom            // V1.1+ 用户自建
    case systemHidden      // 系统内部，不展示给用户（如 daily、other）
    case systemVirtual     // 聚合用，无实际持久化（V2+ 预留）
}

enum DimensionStatus: String, Codable {
    case visible           // 主页展示
    case hidden            // 存在但不展示（如 onboarding 未勾选）
    case deleted           // 软删除，数据保留
}

enum DimensionMode: String, Codable {
    case normal            // 消耗层 + 存储层都展示
    case memorial          // 只展示存储层
}
```

### Moment

```swift
@Model final class Moment {
    @Attribute(.unique) var id: UUID
    var dimensionId: String                      // 当前归属
    var originDimensionId: String?               // 曾经的时间账户（因迁移到 other 时记录，方便"找回"）
    var title: String?
    var note: String                             // 默认 ""
    var happenedAt: Date
    var durationSeconds: Int?                    // null = 不计时长
    var status: MomentStatus                     // normal / pendingDelete
    var pendingDeleteAt: Date?                   // 仅 status=pendingDelete 时有值
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \MediaItem.moment)
    var mediaItems: [MediaItem] = []
}

enum MomentStatus: String, Codable {
    case normal
    case pendingDelete                            // 延迟 5s 删除 + Undo 协议使用
}
```

### Settings

```swift
@Model final class Settings {
    @Attribute(.unique) var id: UUID             // 单例

    // Narrative
    var narrativeMode: NarrativeMode              // positive / reverse

    // Notification
    var notificationEnabled: Bool
    var notificationHour: Int                     // 0-23，默认 9
    var notificationTone: NotificationTone        // neutral（默认） / reflective / poetic
    var relationshipNoteOptIn: Bool               // **默认 false** · 是否允许关系型提醒

    // Widget
    var widgetPreferredDimensions: [String]       // Dimension.id 列表
    var widgetTone: WidgetTone                    // warm / minimal / poetic

    // Appearance：字段已彻底移除（V1.3.2 + Codex review 二轮后定稿）
    // 产品仅 Light Mode，无 Dark Mode 规划。如未来需要恢复，加字段是 SwiftData 兼容操作。

    // Privacy
    var hasSeenPrivacyIntro: Bool

    // Dev / 统计
    var momentCountForReviewTrigger: Int          // 评分请求节流计数
}
```

### 聚合规则（重要）

```
Dimension.storedHours(d) = SUM(m.durationSeconds ?? 0 for m in Moments where
    m.dimensionId == d.id AND m.status == .normal) / 3600.0

Dimension.storedMomentCount(d) = COUNT(m for m in Moments where
    m.dimensionId == d.id AND m.status == .normal)

TotalAccount.hours = SUM(d.storedHours for d in Dimensions where
    d.status != .deleted AND d.kind IN (.builtin, .custom))   // ← 只聚合 builtin + custom
TotalAccount.moments = SUM(d.storedMomentCount ...同条件...)

// lifespan 独立计算（不参与聚合）
Lifespan.remainingWeeks   = (profile.expectedLifespanYears - age) * 52.1429
Lifespan.remainingYears   = profile.expectedLifespanYears - age
Lifespan.remainingHoursK  = Lifespan.remainingYears * 365.25 * 24 / 1000   // "Kh" 单位
```

**关键规则：**
- **`pendingDelete` 状态的 Moment 不参与聚合**（UI 上已删除的立刻消失，不等 5s commit）
- **`durationSeconds == nil` 的 Moment 对"小时"贡献为 0，但"瞬间数"计 1**
- `systemHidden` 时间账户（如 daily）**不计入总账户**，但其内部瞬间可在 V1.1 账户页单独展示
- **`systemTop` 时间账户（lifespan）**：**独立展示在主页顶部**，不进入时间账户列表、不进入 TotalAccount 聚合、无存储层

### 持久化位置

```
App Sandbox / Documents / TimeBank /
├── moments /                              ← 媒体文件
│   └── {moment.id.uuidString} /
│       ├── 01.heic                        ← 原图
│       ├── 01.thumb.jpg                   ← 缩略图 200×200
│       ├── 02.mov                         ← 原视频（仅从相册选入，V1 无 App 内拍摄）
│       └── 02.thumb.jpg
├── export /                               ← 临时导出目录（每次导出清理）
├── snapshot.widget.json                   ← 给 Widget Extension 读（通过 App Group）
└── db.sqlite (SwiftData 默认位置)
```

### App Group（工程架构决策）

- **App Group ID**：`group.com.adamchen.timebank`
- **主 App 与 Widget Extension 共享路径**：`FileManager.containerURL(forSecurityApplicationGroupIdentifier:)`
- **共享数据策略**：
  - SwiftData 数据库**不放 App Group**（避免 SwiftData 并发问题）
  - 主 App 每次关键数据变更后，**写一份 `snapshot.widget.json` 到 App Group 容器**
  - Widget 只读这份 snapshot，不直接读 SwiftData
  - Snapshot 字段：每个 visible 时间账户的 `{id, name, iconKey, colorKey, consumeHours, storedHours, momentCount, lastMoment}` + `topText`（当前 Widget 文案池随机抽的一条）

## 8. Success Metrics

### Leading Indicators（上线 1-4 周看）

| 指标 | 目标 | 测量方式 |
|------|------|----------|
| 引导完成率 | > 80% | 开始引导 → 到达主页的转化率 |
| Widget 安装率 | > 40% | 安装 Widget 的用户占比 |
| 日活 Widget 曝光 | > 1次/天 | Widget 刷新 + 展示次数 |
| App 打开频率 | 2-3次/周 | 周均打开次数 |

### Lagging Indicators（上线 1-3 月看）

| 指标 | 目标 | 测量方式 |
|------|------|----------|
| Day 7 留存 | > 30% | Widget 驱动的被动留存 |
| Day 30 留存 | > 15% | Widget 仍然保留的用户 |
| App Store 评分 | 4.5+ | 用户评价 |
| 自然下载增长 | 月环比 +20% | App Store Connect |

### 存储层专属指标（V1.1 新增）

| 指标 | 目标 | 含义 |
|------|------|------|
| 首月人均存入时刻数 | ≥ 5 | 验证"存入"这个动作是否被用户采纳 |
| 首月人均媒体数 | ≥ 15 | 用户是否真的上传图片/视频，而非只写文字 |
| 存入完成率 | ≥ 75% | 打开"新增时刻"表单 → 成功保存的转化率 |
| 时刻详情页打开次数 / 月 | ≥ 3/人 | 验证"回看存下的瞬间"是否形成习惯 |
| 导出功能使用率 | 5-15% | 不必太高，但存在本身提升信任 |

## 9. Open Questions

| 问题 | 谁来回答 | 优先级 |
|------|----------|--------|
| 产品名是否沿用"时间银行"，还是换成更感性的名字？ | Adam（创始人） | 非阻塞 |
| 预期寿命数据用哪个国家/地区的统计？是否按性别区分？ | 产品决策 | 非阻塞 |
| Widget 内容轮换算法怎么设计，避免每天重复？ | 开发阶段决定 | 非阻塞 |
| 是否需要 App 内引导用户添加 Widget？（很多用户不知道怎么加）| 设计阶段决定 | 阻塞 |
| "创造"时间账户的默认子分类有哪些？ | Adam 决定 | 非阻塞 |
| 数据统计是否需要（匿名使用分析），如果需要用什么方案？ | 开发阶段决定 | 非阻塞 |

## 10. Timeline（V1.3 收窄后的 12 周版）

| 阶段 | 时间 | 产出 | 可行性判断 |
|------|------|------|-----------|
| 产品定义 + Claude Design | 第 1-2 周 | PRD 定稿、Claude Design 出 Onboarding + 主页 2 屏，选定风格 | ✅ 文档已基本就绪，主要是设计出图 |
| SwiftUI 基础 + 数据层 | 第 3-4 周 | SwiftData 全量 schema + 本地存储 + Moment CRUD + 导出 | 重点：严格照 §7.6 schema 来；ChatGPT 出代码，Claude 做 review |
| Onboarding + 主页 + 时间账户详情 | 第 5-7 周 | 可用的 UI 闭环（能 onboarding → 看主页 → 看详情 → 存一条 Moment） | 最容易超时的阶段；一旦卡住立即向外求助 |
| 账户 Tab + Memorial Mode + 参数编辑 | 第 8-9 周 | P0-11、P0-12 + 所有参数编辑体验 | |
| 锁屏 Widget（1 family） | 第 10 周 | App Group 共享 snapshot → Widget 渲染 | Widget 是第二大风险点，只做 1 种 family 降低风险 |
| TestFlight 打磨 | 第 11 周 | 修 bug、dogfood、邀请 5-10 人内测 | |
| App Store 提交 | 第 12 周 | 提交审核 + 上线 | 预审核通过率低，预留缓冲 |

**关键假设：**
- Apple Developer 审批已在第 1 周完成（✅ Adam 已注册）
- ChatGPT + Claude 协同写代码工作流顺畅（见 `ChatGPT-协作协议.md`）
- 如第 5-7 周出现严重卡点，**立即启动 scope 再砍**（砍 P0-11 账户 Tab 或 P0-12 Memorial Mode 到 V1.1），不允许 timeline 延期

**如果 timeline 被挤爆的降级方案：**
- L1 降级：砍 P0-11 账户 Tab（推到 V1.1）→ 主页顶部保留总账户卡片即可
- L2 降级：砍 P0-10 批量操作 → 用户只能单条删除
- L3 降级：砍 P0-16 导出 → 只答应用户 V1.1 补（但这会损失信任资产，慎用）

## 11. 信息架构（IA）

```
时间银行 App
│
├── [引导流程]（首次启动）
│   ├── 启动页（品牌调性展示）
│   ├── Step 1 — 生日 + 性别
│   ├── Step 2 — 家人信息（父母出生年、孩子年龄、伴侣年龄、见面频率）
│   ├── Step 3 — 完成（教用户"你也可以手动存入有意义的时刻"）
│   └── 请求通知权限（可跳过）
│
├── [主页 Tab]  · 底部 Tab 左一
│   ├── 顶部：「你好 Adam」问候 + 右上齿轮→[设置]
│   ├── 顶部：双层账户卡（V1.3.1 新增，见 §22）
│   │   ├── 上半：时间余额（lifespan）· 约 N 周 · N 年/N Kh
│   │   └── 下半：已存入 · N 小时 · N 个瞬间 · 跨 M 个时间账户
│   ├── 时间账户卡片列表（6 内置，仅展示 visible 的，禁"管理"入口）
│   │   └── 点卡片 → [时间账户详情]
│   ├── [V1 无"今日此刻"模块，V1.1 补]
│   └── 浮动按钮「+」→ [新增时刻表单]
│
├── [时间账户详情页]
│   ├── 顶部 — 消耗层（剩余小时 + 副文案）
│   ├── 中段 — 计算参数（可编辑）
│   ├── 下段 — 存储层时间线（时刻卡片列表）
│   │   └── 点时刻 → [时刻详情页]
│   └── 右上「+」→ [新增时刻表单]（预填当前时间账户）
│
├── [新增时刻表单]（模态）
│   ├── 时间账户选择 / 发生时间 / 时长 / 标题
│   ├── 长文本备注
│   ├── 媒体 Picker（最多 9）
│   └── 保存 → 返回并高亮新卡片
│
├── [时刻详情页]
│   ├── 顶部媒体轮播
│   ├── 标题 / 元信息 / Chip
│   ├── 长文本
│   └── 动作：编辑 / 换时间账户 / 分享卡 / 删除
│
├── [账户 Tab]（V1.1 新增 · 存储层总览）
│   ├── 累计存入时长
│   ├── 瞬间数量
│   ├── 环形图（各时间账户占比）
│   └── 年度视图
│
└── [设置 Tab]
    ├── 个人信息（生日、家人）
    ├── 时间账户管理（新增/编辑/排序/删除自定义时间账户）
    ├── Widget 引导
    ├── 叙事模式切换（第 N 次 / 剩余 N 次）
    ├── 数据 — 导出 / 占用空间 / iCloud 同步开关 (V1.5)
    ├── 关于（版本、隐私政策、联系方式）
    └── 高级 — 清除缩略图缓存、重置
```

**导航模式（V1.3.1 锁定）**：底部 3 Tab + 中央浮动按钮：

```
  [🏠 主页]    [📊 账户]    [＋]    [👤 我]
```

- **主页 / 账户 / 我** 三个 Tab（Tab Bar 上的真 Tab 是这 3 个）
- **中央浮动 +** 是全局"新增瞬间"快捷入口（不是 Tab，是 FAB），位置在两个 Tab 之间偏上
- **不再有"设置"Tab**——设置入口走「我」Tab 下面
- 引导完成后默认进入主页

## 12. Release Criteria（V1 上线门槛）

上线前每一条都必须 ✅：

### 功能完整性
- [ ] P0-1 ~ P0-20 全部完成并在真机上可用
- [ ] 自动化 UI Test 覆盖三条主路径：引导、新增时刻、查看时刻
- [ ] Widget 在真机锁屏可显示（只验收锁屏；桌面 Widget、StandBy V1 不做）
- [ ] V1 **不涉及** iCloud 同步（V1.5 才做），本地模式即正常模式

### 数据完整性
- [ ] **强原子性**：任何时刻的保存是原子的——全部写入成功才算成功，中间任一步失败全部回滚（元数据 + 媒体文件）
- [ ] App 崩溃或中途杀进程不会留下孤儿文件（启动时扫描 `moments/` 无对应 DB 记录的文件夹并清理）
- [ ] 启动时对所有 `pendingDelete` 状态的 Moment 立即 commit 物理删除
- [ ] 一键导出的 ZIP 解压后结构清晰、媒体可打开、JSON 有效

### Schema 合规
- [ ] 代码中的 SwiftData `@Model` 与 §7.6 Authoritative Schema 完全一致
- [ ] 所有 UI 展示走 §21 Formatter Matrix 接口，不手写单位

### 性能
- [ ] 冷启动到主页 ≤ 1.5s（iPhone 12 及以上）
- [ ] 时间线 100 条时刻滚动帧率 ≥ 55fps
- [ ] 新增单条时刻（3 图）从点"保存"到回到主页 ≤ 2s

### 质量
- [ ] 连续使用 30 天 + 100+ 时刻 + 500+ 媒体不崩溃（自己日用验证）
- [ ] 从 iPhone SE（最小屏）到 iPhone 16 Pro Max 布局都不溢出
- [ ] **Light Mode 全场景走查**（产品仅 Light Mode，无 Dark Mode 规划）
- [ ] Dynamic Type 到 `.accessibility1` 不截断关键内容（≥ accessibility2 允许截断但不崩）

### 合规
- [ ] Privacy Manifest（PrivacyInfo.xcprivacy）声明完整
- [ ] Info.plist 所有权限描述文案自然、真实、简短
- [ ] 隐私政策、用户协议、商店描述都可访问
- [ ] 没有任何第三方 SDK 收集用户数据（V1 承诺 100% 本地）

### 商店
- [ ] App Store Connect 元数据填完：名称、副标题、描述、关键词、What's New
- [ ] 至少 6 张截图（5.5"、6.5"、6.7" 三套尺寸）
- [ ] App 预览视频（30s 以内，展示核心流程）
- [ ] 至少 10 条真实用户内测反馈（TestFlight）并处理完所有 P0/P1 bug

## 13. 风险登记（Risk Register）

| ID | 风险 | 概率 | 影响 | 缓解 |
|----|------|------|------|------|
| R1 | Widget 在用户手机上一直不显示 | 中 | 高 | App 内专门的 Widget 引导页（GIF 教学），设置页按钮"如何添加 Widget" |
| R2 | 用户无法理解"存入时刻"的价值，低使用率 | 中 | 高 | 引导流程最后一步用一句话 + 动效示范；首次进主页出现一条"尝试存入你的第一个时刻"空态引导 |
| R3 | 媒体上传后占用空间过大，用户抱怨 | 中 | 中 | 设置页显示占用；上传时提示大视频尺寸；V1.5 提供"压缩旧媒体"功能 |
| R4 | "预期寿命"数字触发用户情感不适（尤其父母） | 低 | 高 | 文案绝不说"父母还剩 X 年"；改成"你们还能共度 552h" + 副文案"约 92 次见面" |
| R5 | App Store 审核因隐私问题被拒 | 低 | 高 | 严格执行 Privacy Manifest、所有权限文案真实化、提交前自查（见 §16） |
| R6 | SwiftData 在真实设备上的数据丢失 bug | 低 | 灾难 | 启动时自检数据一致性；每日本地自动备份最近 7 天的数据库快照到沙盒 |
| R7 | CloudKit 同步冲突导致时刻丢失 | 低 | 灾难 | V1 不做同步；V1.5 同步以本地为准 + 冲突时保留两份（后缀 v2） |
| R8 | 用户存入的 noste 含敏感文字被 iCloud 截获（其实不会）引发信任危机 | 低 | 中 | 隐私政策明确：所有数据都在用户 iCloud 私有库，Apple 官方端到端加密 |
| R9 | Adam 本人 SwiftUI 经验不足拖延 timeline | **高** | 中 | 已确定 ChatGPT 写代码 + Claude review 的协同模式；预留 L1-L3 降级方案；若第 5-7 周无明显进展，立刻砍 P0-11/P0-10 |
| R10 | 没用户——冷启动 500 下载目标达不到 | 中 | 中 | 详见 `增长与上线.md`：小红书 + 独立开发者圈 + 产品猎人矩阵 |
| R11 | Widget 与主 App 数据共享架构决策拖延 | 中 | 高 | §7.6 已明定：App Group + snapshot.widget.json，主 App 写、Widget 只读；开发第 1 天就建 App Group |
| R12 | SwiftData + CloudKit 升级到 V1.5 时旧数据不兼容 | 中 | 高 | 所有 @Model 新增字段强制有默认值；V1 发布前做一次"冷启动新装+迁移"完整走查 |
| R13 | 用户情绪不适："已故家人"错误触发 memorial mode | 低 | 高 | Memorial mode 入口二次确认 + 独立页（非 Alert）+ 可取消标记 |
| R14 | 隐私主张和实际行为不一致（被 reviewer 抓） | 低 | 高 | V1 完全不索相册写入/相机/麦克风权限；发版前人工走一次所有系统权限弹窗 |

## 14. 空态 & 错误态清单（Designer / Copywriter 交付物）

**空态**：

| 场景 | 出现位置 | 文案建议 | 视觉 |
|------|---------|---------|------|
| 主页 · 尚未存入任何时刻 | 总账户卡片下方 | "你的时间银行还是空的。存入第一个有意义的时刻？" + CTA | 轻柔的光晕插画 |
| 时间账户详情 · 该时间账户 0 时刻 | 时间线区域 | "这里还没有被存下的时刻。下次和 {爸妈} 见面后，记得回来存进时间银行。" | 小插画，不是"暂无数据" |
| 账户 Tab · 没有任何数据 | 中间 | "存入第一个时刻，就能在这里看到你的时间资产图。" | — |
| 搜索 · 无结果 | 搜索框下 | "没找到相关的时刻。" | — |
| 自定义时间账户 · 0 个自定义 | 时间账户管理页 | "你可以追踪任何对你重要的时间，比如阅读、旅行、冥想。" + CTA | — |

**错误态**：

| 场景 | 文案建议 | 动作 |
|------|---------|------|
| 保存时刻失败（磁盘满） | "手机存储空间不够了。清理一些再试试？" | 「打开系统设置」按钮 |
| 媒体加载失败（文件丢失） | "这个媒体文件找不到了。可能被系统清理了。" | 「删除占位」按钮 |
| iCloud 同步失败 (V1.5) | "iCloud 同步暂时失败，你的数据还在手机上，安全。" | 「重试」按钮 |
| 网络错误（V1 基本无联网） | — | 不适用 |
| 相机权限被拒 | "要用相机记录当下的瞬间，需要你授权一下。" | 「打开设置」按钮 |

## 15. 通知与触达策略

**V1 只保留 1 种通知**：**每日温暖提醒**（默认可开/关，新用户首次询问时是 Pre-permission，非强推）

- 触达频率：每天最多 1 次，默认上午 9:00，用户可关 / 可改时间
- **默认文案池（"neutral tone" — V1 默认启用）：**
  - "今天也过去了一些时间。你想留下哪一小段？"
  - "现在这一刻，是你以后回想起的'过去'。"
  - "过去 24 小时有什么值得存进来的吗？"
  - "今天的光，刚好落在今天。"
  - "这是你的第 N 个早晨。"
- **"关系型提醒"文案池（opt-in，V1 默认关闭，设置里显式开启）：**
  - "距离上次见爸妈，已经过了一些天"
  - "1 年前的今天，你存入了 '杭州西湖 48 小时'"
  - 开启后仍只走每日 1 次的频率，不叠加
- 点击通知 → 进入"新增时刻"表单（预填"今天"）

**V1 明确不做的通知**：
- ❌ 每日任务打卡提醒（违反产品哲学"不是 KPI"）
- ❌ 默认发送"你已经 X 天没陪爸妈了"等 guilt 文案（关系型提醒必须 opt-in）
- ❌ 推广/营销通知
- ❌ 锁屏自动弹窗

**V2+ 可能：**
- 月底回顾通知（本月你存入了 X 小时）
- 基于相册检测的存入建议

## 16. 隐私与合规（§详见 `隐私与合规.md`）

**V1 核心承诺**（必须在商店描述 + 引导页都明说）：

1. **所有数据存在你的 iPhone 上**，我们不收集、不上传、不看
2. **没有账号注册**，用 App 不需要任何登录
3. **没有任何第三方统计 SDK**（V1 连匿名分析都不做，如要做至少等 V1.5）
4. **V1.5 iCloud 同步**走的是你自己的 iCloud 私有库，Apple 端到端加密，开发者（Adam）也看不到
5. **完整导出权**：任何时候都可一键带走所有数据（ZIP）

**合规清单**（完整版见 `隐私与合规.md`）：
- [ ] `PrivacyInfo.xcprivacy` 正确声明"不收集数据"
- [ ] `NSCameraUsageDescription` 真实友好
- [ ] 隐私政策页面上线可访问
- [ ] App Store Review Guideline 5.1（Privacy）自查
- [ ] 中国大陆版：《个人信息保护法》适配

## 17. 无障碍（Accessibility）

- 所有交互元素 44×44pt 最小触控区
- VoiceOver 标签：每张时间账户卡片朗读为 "{时间账户名}，还能共度 X 小时，已存入 Y 小时"
- Dynamic Type 支持到 `.accessibility2`（最大到第二档辅助尺寸）
- 颜色对比度 WCAG AA（普通文本 4.5:1，大文本 3:1）
- 不只用颜色传递信息（消耗层/存储层用"↓/↑"图标 + 颜色双编码）
- Reduce Motion 下存入成功动效降级为淡入

## 18. 国际化（i18n）

- **V1 仅中文**，但代码层全部走 `String Catalog`（iOS 17+），方便后续加英文
- 数字格式走 `NumberFormatter`，K 简写用系统本地化
- 日期走 `DateFormatter` + 当前 locale
- **V1.5 计划**：加英文版，开放海外 App Store
- 文案库（见 `文案系统.md`）同时维护中/英两套

## 19. 商业化（Business Model）

**V1**：完全免费、无订阅、无内购

**V1.5（可选）**：如果用户数 > 2000 且 DAU > 500，引入 **时间银行 Pro**：
- iCloud 高级同步（含媒体原文件）
- 无限自定义时间账户（免费版限 10 个）
- 年度回顾视频生成
- 12 元/年 或 88 元买断

**V2**：可能加"时间银行 · 协作版"（家庭成员共享某些时间账户）——定价再议

## 20. Changelog

| 版本 | 日期 | 主要变更 |
|------|------|---------|
| V1.3.2 | 2026-04-22 晚晚 | Claude Design UI 定稿：术语"维度 → 时间账户"；消耗层标签"还能存入 → 还能共度"；UI token 从 Claude Design 导入作为 Swift 源 |
| V1.3.1 | 2026-04-22 晚 | Claude Design 首版 review 后：新增 `lifespan` 顶部时间账户（周为单位）+ 双层账户卡 + 3 Tab 导航；删除"管理"入口；补 §22 主页 layout 硬约束 |
| V1.3 | 2026-04-22 | ChatGPT review 定稿：V1 scope 明确收窄（砍今日此刻/自定义时间账户/分享卡/视频拍摄/保存相册/桌面 Widget/StandBy/Light/多格式导出/恢复），Memorial mode 抽象化升 P0，账户 Tab 升 P0，补 §7.6 Authoritative Schema、§21 Formatter Matrix，CloudKit 拆两阶段 |
| V1.2 | 2026-04-19 | 单位统一到小时；补充 §0 文档使用说明、§11 IA、§12 Release Criteria、§13 风险登记、§14 空态、§15 通知、§16 隐私、§17 a11y、§18 i18n、§19 商业化 |
| V1.1 | 2026-04-19 | 引入存储层（图文视频沉淀）、双层模型、数据模型 |
| V1.0 | 2026-04-01 | 初版 PRD：消耗层 6 时间账户、日常时刻、Widget-first |

## 21. Formatter Matrix（展示单位规则）

所有 UI 文本展示必须通过这套 formatter，不允许在 View 层手写拼接。

### 语义单位

| Semantic | 用途 | 示例输出 | 使用场景 |
|----------|------|---------|---------|
| `hoursCompact(h)` | 小时简写 | `552h`、`1,240h`、`18.2Kh` | 卡片主数字、Widget |
| `hoursReadable(h)` | 小时完整 | `128 小时`、`48 小时` | 主页顶部总账户、时刻详情 chip |
| `hoursWithMinutes(s)` | 带分钟 | `2h 30m`、`30m` | 新增时刻表单时长滑块预览、参数编辑 |
| `occurrenceCount(n, noun)` | 次数（消耗层用）| `约 92 次见面` | parents 卡副文案 |
| `weeklyHours(h)` | 每周小时数 | `每周约 30 小时`、`每周约 5 小时`、`每周约 40 小时` | kids / sport / create 卡副文案 |
| `dailyHoursWith(h, action)` | 每天小时 + 动作 | `每天约 4 小时共处` | partner 卡副文案 |
| `percentOfAwake(pct)` | 占清醒时间百分比 | `占清醒时间约 56%` | free 卡副文案 |
| `lifespanSubtitle(years, hoursK)` | lifespan 顶部卡副文案 | `45 年 · 473 Kh` | 顶部时间余额卡（§22.4） |
| `momentsCount(n)` | 瞬间数（存储层唯一量词）| `12 个瞬间`、`1 个瞬间` | 存储层所有场景 |
| `relativeTime(date)` | 相对时间 | `3 天前`、`1 年前的今天`、`发生在 3 小时前` | 时刻详情、时间线 |
| `absoluteDate(date)` | 绝对日期 | `2026-03-22` | 时刻详情二级展示 |

### 大数字 K 简写规则

| 范围 | 格式 | 示例 |
|------|------|------|
| < 1,000 | 完整 | `552h` |
| 1,000 – 9,999 | 千分位 | `7,488h` |
| 10,000 – 99,999 | 一位小数 K | `18.2Kh` |
| ≥ 100,000 | 整数 K | `176Kh` |

### 存储层严格禁用的量词

| 禁用 | 替换 |
|------|------|
| ~~已存入 12 次~~ | 已存入 12 **个瞬间** |
| ~~存了 5 次~~ | 存了 **5 个瞬间** |
| ~~你的打卡~~ | 你的**瞬间** |
| ~~记录~~（作名词时） | **瞬间** / **时刻** |

"次" 只允许出现在**消耗层副文案**里（"约 92 次见面"），描述的是预期事件次数，不是用户真的做了多少次。

### 工程接口（Swift）

```swift
enum Formatter {
    static func hoursCompact(_ h: Double) -> String
    static func hoursReadable(_ h: Double) -> String
    static func hoursWithMinutes(_ seconds: Int) -> String
    static func occurrenceCount(_ n: Int, noun: String) -> String       // 约 N 次 <noun>
    static func weeklyHours(_ h: Double) -> String                       // 每周约 N 小时
    static func dailyHoursWith(_ h: Double, action: String) -> String    // 每天约 N 小时<action>
    static func percentOfAwake(_ pct: Double) -> String                  // 占清醒时间约 N%
    static func lifespanSubtitle(years: Double, hoursK: Double) -> String // N 年 · N Kh
    static func momentsCount(_ n: Int) -> String
    static func relativeTime(_ date: Date, relativeTo now: Date = .now) -> String
    static func absoluteDate(_ date: Date) -> String
}
```

所有 SwiftUI View 必须调用这些方法，不得自己拼 `"\(hours)h"` 或 `"约 \(n) 次..."`。

### 6 内置时间账户的副文案接口映射

| Dimension | 副文案文字 | 调用接口 |
|-----------|----------|---------|
| `lifespan` | `45 年 · 473 Kh` | `lifespanSubtitle(years:, hoursK:)` |
| `parents` | `约 92 次见面` | `occurrenceCount(_:noun:)` · noun = "见面" |
| `kids` | `每周约 30 小时` | `weeklyHours(_:)` |
| `partner` | `每天约 4 小时共处` | `dailyHoursWith(_:action:)` · action = "共处" |
| `sport` | `每周约 5 小时` | `weeklyHours(_:)` |
| `create` | `每周约 40 小时` | `weeklyHours(_:)` |
| `free` | `占清醒时间约 56%` | `percentOfAwake(_:)` |

## 22. Homepage Layout Constraint（主页一屏约束）· V1.3.1 新增

### 22.1 视野预算

iPhone 16 Pro 可视区（含 Dynamic Island + Home Indicator 安全区外）**≈ 789pt 可用高度**（852pt 屏高 − 54pt status bar − 9pt home indicator）。

主页必须把"用户第一眼能看到的关键内容"压进这 789pt。允许滚动，但**滚动前用户必须能看见**：

- [x] 顶部 greeting（你好 Adam + 设置图标）
- [x] 双层账户卡完整（时间余额 + 已存入）
- [x] 至少 4 张时间账户卡片的**完整双数字区**（不能只露出色块被截断）
- [x] 底部 Tab Bar 完整可见

### 22.2 垂直高度预算（参考）

| 区域 | 高度预算 | 说明 |
|------|---------|------|
| Status bar | 54pt | 系统 |
| Greeting 区 | 48-56pt | 下午好 + Adam + ⚙ |
| 双层账户卡 | **≤ 240pt** | 上半 lifespan 120pt + 分隔线 8pt + 下半 deposited 112pt |
| "时间账户 · N 个" 小标题 | 28pt | 不含"管理"字样 |
| 时间账户卡片 × 4 | **每张 ≤ 140pt**, gap 12 | 4 张共 596pt；压缩比 V1.3 版低 24pt |
| Tab Bar | 84pt | 系统 |
| **合计** | **≤ 1106pt** | 仍超 789pt |
| 允许滚动显示 | 317pt | 底部 1-2 张时间账户卡可滚到 |

总和 ≈ 1106pt，超出 317pt——意味着可滚显示底部 2 张时间账户卡。**这是允许的**，只要滚动前第一屏能看到 **双层卡 + 前 4 张时间账户卡双数字区完整**。

### 22.3 DimensionCard 的紧凑规格

```
┌──────────────────────────────────────── 140pt ↑
│ [插画 40×40]  陪父母                 ›   │ 48pt  · header
│  (余 76pt)                              │
│ ┌─────── 还能共度 ┐ ┌─────── 已存入 ───┐ │
│ │ 552h           │ │ 56h            │ │  · 72pt · dual
│ │ 约 92 次见面    │ │ 12 个瞬间       │ │
│ └────────────────┘ └────────────────┘ │
│ padding 14 + 14 + header + dual + padding │
└──────────────────────────────────────── ↓
```

硬约束：
- 卡片总高 ≤ 140pt
- header 区 ≤ 48pt（插画 40 + margin 4 上下）
- dual-numbers 区 ≤ 72pt（标签 14 + 主数字 28 + 副文案 14 + padding 16 内边距）
- 卡片外 padding 14（左右），内部两小块 gap 10

### 22.3.1 6 内置时间账户的消耗层显示文案（V1.3.2 定稿）

| Dimension | 主数字（消耗层） | 副文案 | 副文案数字含义 | 用户路径 |
|-----------|---------------|--------|--------------|---------|
| `parents` | `552h` | `约 92 次见面` | 剩余年 × 见面频率 | Onboarding 勾选父母 + 详情页 UC-2.3 调 visitsPerYear/hoursPerVisit |
| `kids` | `还能共度 X 小时` | `每周约 30 小时` | 当前最年幼孩子年龄段对应的 hoursPerWeek（0-6=30、6-13=20、13-18=10、18+=2） | Onboarding 填孩子出生年 |
| `partner` | `还能共度 X 小时` | `每天约 4 小时共处` | partner.hoursPerDay 直接显示 | Onboarding 勾选伴侣 + 详情页调 hoursPerDay |
| `sport` | `未来 X 小时` | `每周约 5 小时` | 当前年龄段的 hoursPerWeek（< 50=5、50-80=3、> 80=1） | 详情页 UC-2.3 调三段每周时长 |
| `create` | `未来 X 小时` | `每周约 40 小时` | 当前年龄 < focusedPhaseEndAge 取 focusedPhaseHoursPerWeek，否则取 freePhaseHoursPerWeek | 详情页调专注期截止年龄 + 各期每周时长 |
| `free` | `未来 X 小时` | `占清醒时间约 56%` | free 账户消耗 / (剩余年 × 365.25 × awakeHoursPerDay) × 100，数学上 = 1 - 其他 5 账户占比 | 详情页调每天清醒时长 |

工程接口映射详见 §21 末尾"6 内置时间账户的副文案接口映射"表。

### 22.4 双层账户卡规格

```
╭──────────────────────── 240pt ↑
│ ◌  时间余额                     │
│                                │ 上半 120pt
│      约 2,704 周                │
│     45 年 · 473 Kh              │
│ ────── opacity 0.25 分隔线 ─── │ 8pt
│ ♡  已存入            128 小时     │
│                      27 个瞬间    │ 下半 112pt
│                      跨 5 个时间账户   │
╰──────────────────────── ↓
```

- 卡片整体珊瑚橘渐变底 `linear-gradient(135deg, #F5C79E 0%, #E89A7C 50%, #D4A07C 100%)`
- 上半 + 分隔线 + 下半 **是一个卡**，不是两个
- 分隔线用 `rgba(255, 255, 255, 0.25)` 或 `rgba(45, 37, 32, 0.1)` 柔和
- 上半 lifespan icon 建议用 ⧗ 或自绘沙漏
- 下半 deposited icon 建议用 ♡ 或自绘"存入"符号

### 22.5 禁止项

- ❌ 不允许因为容纳不下而省略 dual-numbers 的副文案（"约 92 次见面"、"12 个瞬间"必须完整）
- ❌ 不允许把 lifespan 放进"时间账户列表"（它必须是顶部卡，不是第 7 张卡片）
- ❌ 不允许 "时间账户 · N 个" 标题右侧有"管理"入口（V1 无自定义时间账户）
- ❌ 不允许 Tab Bar 只有 2 Tab（必须是 3 Tab + 中央 FAB）

---

## 配套文档索引

- `用户研究.md` — Persona / 用户旅程 / 访谈脚本
- `设计规范.md` — 色板 / 字体 / 组件 / 动效原则
- `文案系统.md` — Tone of voice / 文案库 / Widget 轮换池
- `隐私与合规.md` — Privacy Manifest / 合规清单 / 权限说明
- `增长与上线.md` — ASO / 冷启动 / 内容营销计划
- `Use-Cases-详尽交互.md` — **所有模块 CRUD 逐步交互说明**（工程师 & QA 唯一真相源）
- `技术方案-媒体存储.md` — iOS 沙盒 + CloudKit + 导出方案
- `开发上线指南.md` — 从零到 App Store 完整流程

---

*此文档随讨论持续更新。*
