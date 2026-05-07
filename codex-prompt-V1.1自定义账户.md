# Codex 任务：实施 V1.1 自定义时间账户 CRUD + 主页编辑模式

## 你要做什么

按 [`方案-V1.1-自定义时间账户-2026-04-27.md`](方案-V1.1-自定义时间账户-2026-04-27.md) 落地代码。所有决策都已在方案文档锁定。

**先读这两个文件再动手**：
1. [`方案-V1.1-自定义时间账户-2026-04-27.md`](方案-V1.1-自定义时间账户-2026-04-27.md) — 完整 spec、文件清单、风险、验收
2. [`designs/mockup-自定义账户-2026-04-27.html`](designs/mockup-自定义账户-2026-04-27.html) — 8 屏 wireframe（浏览器打开）

## 范围（一句话）

让用户能在主页加 / 排序 / 删自己的时间账户（最多 10 个），3 种计算公式（每周 N 小时 / 每天 N 小时 / 每年 N 次 × 每次 M 小时）；UI 复用现有视觉风格（V1.3.2 暖色调），visual rebrand 在下个迭代。

## 上下文

- 当前分支：`m3-app-loop`（V0.1 反馈修复已 merge）
- PRD 基线：V1.3.2（2026-04-22 UI 定稿）
- iOS Target：模拟器 iPhone 17 + iOS 26.4
- 上一个版本：Claude 已修完 V0.1 的 11 条反馈（见 `修复方案-V0.1反馈-2026-04-27.md`）

## 必读 PRD 章节（不要凭脑补）

- **PRD §5 自定义追踪项** L223-231 —— 验收标准
- **PRD §7.6 Authoritative Schema** L569-712 —— Dimension model 与 CustomDimensionParams 必须先改这里
- **PRD §22 主页 layout** —— 首屏 ≥4 张卡的硬约束
- **PRD §11 设置 Tab** L932-939 —— 时间账户管理入口位置

## 关键决策（已锁定 · 不要质疑）

| 决策 | 值 |
|---|---|
| 入口 | 主页右上 `[编辑] [+]` + 主页底部虚线"+ 添加自定义时间账户" + 设置 Tab "时间账户管理" |
| 计算公式 | 3 preset 收敛：每周 N 小时 / 每天 N 小时 / 每年 N 次 × 每次 M 小时 |
| 图标库 | SF Symbols 16 个（**不用 Emoji**），具体 symbol 名见方案 § D |
| 颜色 | 10 色（6 内置 + 4 新增 coral/mint/denim/mauve） |
| 上限 | 10 个自定义账户 |
| 预览卡 | 创建 sheet **顶部 sticky**（滑 slider 时实时跳动）|
| 排序 | 主页编辑模式下拖动调整 sortIndex |
| 编辑模式入口 | 显式：右上「编辑」按钮 ｜ 隐式：长按任一卡片 0.5s（iOS 主屏 jiggle 风） |
| 编辑模式动效 | 卡片像 iOS app 图标一样小幅抖动 ±1-1.5°、周期 0.28-0.32s、phase 错开（详见方案 § F 伪代码）|
| 删除 | DemotionStore.demote（瞬间转 other） |

## 必须先看的现有代码

- `TimeBank/Models/Dimension.swift` — `kind: .custom` 已支持，UUID id 已支持，sortIndex 已支持
- `TimeBank/Models/DimensionParams.swift` — 加 CustomDimensionParams 进这里
- `TimeBank/Shared/DimensionCompute.swift` — `consumeHours` / `subtitleData` 加 default 分支
- `TimeBank/Shared/DimensionDemotionStore.swift` — `demote(dimensionID:)` 通用接口已就绪，删除直接复用
- `TimeBank/Features/Home/HomeView.swift` — 主页主要改这里（双按钮、底部虚线、编辑模式）
- `TimeBank/Features/DimensionDetail/DimensionParameterEditorView.swift` — 加 default case 渲染 CustomDimensionParams 编辑器
- `TimeBank/Utility/DesignTokens.swift` — 加 4 个新色 + 重写 DimensionPalette 按 colorKey 索引
- `TimeBank/TimeBankTests/DataLayerTests.swift` L541-588 — 已有 customDimension 测试用例需要更新成 CustomDimensionParams

## 实施顺序

见方案文档 §「实施顺序建议（给 Codex）」13 步。

## 主要风险（先看再写）

见方案文档 § R1-R6。最容易踩的是：
- **R1**: DimensionPalette 改 colorKey 索引涉及 8 处调用点，grep 别漏
- **R2**: DimensionDetailCopy 现有 default 返回空，要补通用文案否则自定义账户详情页空白
- **F 章主页编辑模式**: 改 List vs 保留 ScrollView 是大决策点，先评估再选

## 验收

见方案文档 §「验收 Checklist」。重点：
- Build + Test 全过
- iPhone 17 模拟器手动走完 13 条 user flow（包含创建/编辑/删除/排序/上限）
- PRD §7.6 同步更新
- PR 附主要 5-6 个截图

## 不要做什么

- ❌ 不要做 visual rebrand（下个迭代）
- ❌ 不要做 widget（再下个迭代）
- ❌ 不要扩大改动范围 / 重构无关代码
- ❌ 不要改 PRD §22 主页 layout 硬约束（首屏 ≥4 张卡）
- ❌ 不要改 Formatter Matrix（除非加 CustomDimensionParams 的新接口）
- ❌ 不要质疑已锁定的决策；如真有顾虑，PR description 单独提

## 完成后

1. PR description 写清楚 13 步每一步对应的 commit
2. 截图主要 5-6 屏放 PR
3. 列出未实现的 known issues / 留给下个版本的事
4. ping Adam review

祝顺利。
