# 留存机制调研 · 顶尖产品扫描 + iOS「不打开 App 的触达面」

> 2026-06-10 · Claude 调研。核心结论：①「状态随时间恶化的 widget」是被验证的留存神器（Duolingo：装 widget 的学习者约半数保持 6 个月+连胜；Finch D1 54%）；② iOS 17 interactive widget 可做"一键存入"不打开 App；③ **"状态随一天推移变化"在 iOS 上几乎零成本**（timeline 预排，时间流逝是确定性的，不消耗刷新预算）——时间银行的核心展示恰好全是"确定性时间函数"，与平台能力天作之合。

## A. 产品扫描

| 产品 | 核心机制 | 可借鉴 |
|------|---------|--------|
| **Apple Journal** | Journaling Suggestions 解决"写什么"；Smart 提醒（学习作息/位置，在最可能写的时间地点推） | 锁屏 widget 给"入口动词"而非状态展示 |
| **Day One** | On This Day 推送+widget = 数据飞轮；四种 widget 自选 | "去年今天你和妈妈在……"比任何催促都强 |
| **Daylio** | 两次点击完成打卡 | 单次存入 ≤30 秒、最好 10 秒 |
| **Finch** | widget 常驻"活宠物"；完成任务→宠物 6 小时冒险（appointment 回访窗口）；D1/D7 54%/37% | 照顾的不是宠物，是"你们的关系账户" |
| **时间规划局（中文）** | 人生剩余天数/电量百分比；**70+ 锁屏组件、100+ 桌面组件，组件即产品**；¥30/年订阅 | 品类已验证付费；但全是"冷数字恐吓"，无"和谁共度"+无"存入"对冲 → 明确空位 |
| **Memento Mori / Lifetime** | 4000 周格子、当前周金色脉动 | 人生余额可视化有真实需求 |
| **Locket / Widgetable** | widget 即产品；双人共享 widget = 增长引擎 | 伴侣共享账户是 V2 最大机会（需后端） |
| **Duolingo widget** | Duo 表情随一天未完课渐变"绝望"，25 张插画；**完成首课后立刻弹动画教程引导装 widget** | 状态机渐变 + 首存后引导装 widget（验证过的关键转化点） |
| **蔚来签到** | 损失厌恶 + 未签到状态外显桌面 + 一步完成 | Adam 自己的三年不断签体验就是 PRD |

## B. iOS 触达面技术盘点

| 技术面 | 能力边界 | 时间银行用法 |
|--------|---------|-------------|
| **WidgetKit + iOS 17 交互** | 刷新预算约 40-70 次/天，但 **timeline 预排确定性状态零成本**；`Text(timerInterval:)` 倒计时自动走字零刷新；按钮绑 App Intent 直接执行不打开 App | P0：状态机 widget（0:00 重置→18:00 催促→21:30 强催促）+ 一键存入打卡；图文存入深链进预填编辑页 |
| **锁屏 widget** | accessoryCircular/Rectangular/Inline | P0：今日未存入圆环 / "余额 -1 天" |
| **本地通知** | 待定上限 64 条滚动补排；可带图片附件；**UNTextInputNotificationAction 可在通知内打字**；UNLocationNotificationTrigger 地理围栏纯本地可用 | P0：晚间未存入提醒（带去年今日照片）+ 通知内写一句话直接存入；P1：离开父母家围栏"刚道别？存下今天" |
| **Live Activities/灵动岛** | 必须前台启动、最长 12h、push-to-start 需后端 | **不适合**常驻入口；只做"见面日"仪式计时（P2） |
| **StandBy** | 自动复用 systemSmall，零额外开发 | 床头"时间银行相框"（P1，近零成本） |
| **Watch + Smart Stack relevance** | TimelineEntryRelevance 可让条目特定时段浮顶 | 21:00-23:00 未存入条目自动浮顶（P2） |
| **iOS 18 Control** | 控制中心/锁屏控件位/Action Button | 实体键一按进拍照存入流（P2） |
| **Journaling Suggestions API** | 仅 iPhone；只在用户打开 picker 时呈现、只返回勾选内容；**无后台信号** | 不能做"刚聚会完"后台触发；但可把存入成本从 5 分钟压到 10 秒（一键导入聚会照片+地点+人） |

## 触达矩阵（P0 四件套 = 蔚来体验的 iOS 完整复刻，全部纯本地可做）

1. 桌面 medium widget：余额 + 今日存入状态随时间渐变（timeline 预排）
2. 锁屏 widget：极简状态
3. widget「存入此刻」一键打卡（App Intent）
4. 晚间本地通知：带去年今日照片 + 文本输入 action 直接存

之后：⑤ On This Day widget/推送轮播 ⑥ 地理围栏 ⑦ Journaling Suggestions 降本 ⑧ StandBy ⑨ Watch ⑩ Control ⑪ 见面日 Live Activity ⑫ V2 伴侣共享 widget（Locket 模式，需后端）

## 主要来源

- Duolingo widget 官方复盘: blog.duolingo.com/widget-feature; Deconstructor of Fun streaks
- Finch 拆解: Deconstructor of Fun; Locket: Fast Company / What a Startup
- Apple Journal: Apple Newsroom / Support; Day One widgets 官方博客
- 时间规划局 App Store (id1473733265); Memento Mori / Lifetime App Store
- 蔚来小组件公告 nio.cn/app-article-507969
- WidgetKit 刷新预算: swiftsenpai.com + Apple docs; interactive widgets / ActivityKit / StandBy / Smart Stack relevance / iOS 18 Controls / Journaling Suggestions: developer.apple.com
