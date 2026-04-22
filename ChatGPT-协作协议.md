# 时间银行 · ChatGPT × Claude 协作协议

> Version: 1.0 | Date: 2026-04-22
>
> **如果你是 ChatGPT，这是你第一个要读的文件。**
> 读完这篇后按 "§7 给 ChatGPT 的启动指令" 开工。

---

## 0. 角色分工

| 角色 | 在这个项目里做什么 |
|------|------------------|
| **Adam**（产品/非技术创始人） | 产品决策、用户访谈、上架、运营、当最终拍板人 |
| **Claude（Claude Code）** | 文档维护、review ChatGPT 产出、产品一致性守护 |
| **ChatGPT（Pro，可浏览 GitHub）** | **写 Swift 代码**、对接 Xcode 项目、处理真机调试 |
| **Codex（如需要）** | 偶尔做第二意见 review（非主力）|

**工作流：**
```
Adam 提需求 / 决策
    ↓
Claude 更新文档 + 准备交付包
    ↓
ChatGPT 读文档 + 写代码 + 返回到 Adam
    ↓
Adam 把代码运行、测试、发现问题
    ↓
Claude review ChatGPT 代码 vs 文档一致性
    ↓
有偏差 → Claude 给修改建议；一致 → 合并进项目
```

**硬规则：**
- **ChatGPT 不改文档**。任何"我觉得应该这样改"的想法必须先跟 Adam 沟通，由 Adam 决定是否让 Claude 改文档。
- **Claude 不写最终 Swift 代码**（偶尔可以给 snippet），因为主力开发在 ChatGPT 那边。
- **双方都不能破坏 §7.6 Authoritative Schema**。字段名、类型、枚举值必须完全一致。

---

## 1. 仓库权威文件索引

所有真相源在这个公开仓库里：**https://github.com/no996chen-tennis/time-bank**

ChatGPT 应该**按这个顺序**读：

| 顺序 | 文件 | 为什么重要 |
|------|------|-----------|
| 1 | `CLAUDE.md` | 项目总览 + V1 scope 一句话看到 |
| 2 | `PRD-时间银行-V1.md` §0.5 TL;DR + §0.6 V1 Scope | 知道要做什么不做什么 |
| 3 | `PRD-时间银行-V1.md` §7.6 Authoritative Schema Appendix | **工程唯一 schema 源**，写 Swift `@Model` 照这个来 |
| 4 | `PRD-时间银行-V1.md` §21 Formatter Matrix | 所有单位显示的唯一接口 |
| 5 | `Use-Cases-详尽交互.md` | 每个交互具体到"点哪个按钮" |
| 6 | `技术方案-媒体存储.md` | 媒体怎么存、App Group 怎么配、媒体兼容矩阵 |
| 7 | `设计规范.md` | 色板、字体、组件规格 |
| 8 | `文案系统.md` | **所有 UI 文字从这里拷贝，不要自己写** |
| 9 | `隐私与合规.md` | Privacy Manifest、Info.plist 权限描述 |
| 10 | `开发上线指南.md` | Xcode、Developer Program 流程 |

**raw 直链模板：**
```
https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/{文件名.md}
```

---

## 2. ChatGPT 的硬性工作规则

### 2.1 禁止事项

- ❌ **不要自己发明 UI 文案**。哪怕一个"保存"按钮的 label 也要从 `文案系统.md` 里找对应的。找不到？**不是你该写，是应该让 Claude 补文档**。
- ❌ **不要绕过 §21 Formatter Matrix** 手写 `"\(hours)h"`。一定要通过 `Formatter.hoursCompact(h)` 接口。
- ❌ **不要改 Schema 字段名**。`Moment.dimensionId` 就是 `dimensionId`，不是 `dimensionID` 也不是 `dimId`。
- ❌ **不要加任何第三方 SDK**（统计、崩溃、广告、AB 测试）。V1 是零 SDK 承诺。
- ❌ **不要加相机/麦克风权限** 到 V1 的 Info.plist。V1 只从 PhotosPicker 选媒体。
- ❌ **不要写入系统相册**。V1 不碰。
- ❌ **不要在 V1 加任何网络请求**（除了 Apple 系统自己的 OSLog / WidgetKit 刷新）。V1 是 offline-first。

### 2.2 写代码时的必读检查

每次写完一个 PR 级别的 feature 前，ChatGPT 自问：
- [ ] 这个功能在 `Use-Cases-详尽交互.md` 里有对应的 UC 吗？
- [ ] UC 写的是 V1 做还是 `[V1.1+]`？如果是后者 → **立刻停手**，不是 V1 范围
- [ ] 用到的字段在 §7.6 Schema 里定义了吗？没有就是偷跑了
- [ ] UI 文案从 `文案系统.md` 的哪一节来的？
- [ ] 错误处理是否遵循"强原子性"（任何一步失败全部回滚）？
- [ ] 删除 Moment 是不是走了延迟 5s + Undo 协议？

### 2.3 代码风格

```
- Swift 5.9+ / iOS 17+（利用 SwiftData、PhotosPicker、WidgetKit）
- SwiftUI 优先，UIKit 只在系统强制时用
- 所有 @Model 定义与 §7.6 Schema 一致
- 所有显示走 Formatter（新建 `Utility/Formatter.swift`）
- 所有本地化字符串走 String Catalog（iOS 17+ 新 API）
- 文件命名：模块名 + 类型，如 `Moment/MomentListView.swift`
- 函数长度 < 60 行，超出拆子函数
- 注释写"为什么"，不写"做了什么"
```

### 2.4 文件组织建议

```
TimeBank/
├── App/                        · App 入口、Scene
├── Models/                     · SwiftData @Model
│   ├── UserProfile.swift
│   ├── Dimension.swift
│   ├── Moment.swift
│   ├── MediaItem.swift
│   └── Settings.swift
├── Features/
│   ├── Onboarding/             · UC-0.* 实现
│   ├── Home/                   · 主页
│   ├── DimensionDetail/        · UC-2.*
│   ├── Moment/                 · UC-3.*（最大模块）
│   ├── Account/                · UC-10 账户 Tab
│   ├── Memorial/               · UC-0.3 + memorial mode
│   ├── Export/                 · UC-7.*
│   └── SettingsUI/             · UC-8.*
├── Widget/                     · 锁屏 Widget 独立 target
├── Shared/                     · App 与 Widget 共享代码
│   ├── SnapshotWriter.swift    · 写 App Group snapshot.widget.json
│   └── WidgetSnapshot.swift    · 数据结构（双方都用）
├── Utility/
│   ├── Formatter.swift         · 唯一单位接口
│   ├── FileStore.swift         · 沙盒文件读写
│   └── MomentStore.swift       · 强原子性事务
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.xcstrings
└── Info.plist
```

---

## 3. Milestone 工作包（12 周路线图）

ChatGPT 按顺序完成，每个 Milestone 产出一个可独立 demo 的版本：

### M1 · 数据层（第 3-4 周）
**目标：** 能创建、读取、删除 Moment + MediaItem，但还没有 UI。
**交付：**
- 所有 `@Model` 按 §7.6 完整实现
- `MomentStore` 强原子性事务（写入 Moment 走 transaction，任一步失败全回滚）
- `FileStore` 沙盒读写 + 缩略图生成（`CGImageSource` / `AVAssetImageGenerator`）
- 孤儿文件扫描与清理
- `Formatter` 所有接口
- 单元测试覆盖"写入 → 读取 → 删除（延迟）→ Undo → 最终 commit" 完整流程

### M2 · Onboarding + 主页（第 5 周）
**目标：** 完成引导 + 首次看到主页。
**交付：**
- UC-0.1 4 步引导（生日 / chip 多选 / 条件化详情 / 完成）
- UC-0.2 设置补充家人信息
- 主页顶部总账户卡片
- 主页双数字维度卡片（按 onboarding 勾选显示）
- Pre-permission 通知弹窗

### M3 · 维度详情 + 参数编辑（第 6 周）
**交付：**
- UC-2.1 / 2.2 / 2.3（不做 2.4-2.7）
- UC-2.3 所有内置维度的参数滑块

### M4 · 存储层核心（第 7 周 · 最关键）
**交付：**
- UC-3.1 / 3.2 / 3.3（新建时刻完整流程）
- UC-3.4 / 3.5（时间线 + 详情）
- UC-3.6 / 3.7（编辑 / 换维度）
- UC-3.8 延迟删除 + Undo 协议（**重点**）
- UC-3.9 / 3.10 / 3.11 批量选择、批量删除、批量换维度

### M5 · 账户 Tab + Memorial Mode（第 8-9 周）
**交付：**
- UC-10.1 账户 Tab（环形图、年度视图）
- UC-0.3 + §5.5 Memorial Mode 任意关系维度可进入 / 退出
- 统一维度下沉协议（Moment 迁 `other` + `originDimensionId`）

### M6 · Widget（第 10 周 · 第二大风险点）
**交付：**
- App Group `group.com.adamchen.timebank` 配置
- `SnapshotWriter` 在主 App 每次关键变更后写入 snapshot.widget.json
- Widget Extension target + 单一锁屏 small family
- Widget 引导页（UC-6.1）
- Widget 偏好维度配置（UC-6.3 简化版）

### M7 · 导出 + 设置（第 10-11 周）
**交付：**
- UC-7.1 / UC-7.2（Raw ZIP 导出）
- UC-7.3 清空数据（双 Alert 确认）
- UC-8.1 叙事模式（如果来得及，V1.1 也行）
- UC-8.2 通知偏好

### M8 · 打磨 + TestFlight（第 11 周）
**交付：**
- 所有空态文案
- 所有错误态弹窗
- VoiceOver 标签
- Dynamic Type 走查
- Release Criteria §12 全过
- 10 条真机测试矩阵（技术方案 §8.4）

### M9 · App Store 提交（第 12 周）
**交付：**
- Privacy Manifest
- Info.plist 权限描述（V1 只需要 `NSUserNotificationsUsageDescription` 如果需要）
- App Store Connect 元数据
- 6 张截图
- 30s 预览视频
- 提交审核

---

## 4. 与 Claude 的协作格式

### 4.1 ChatGPT 向 Claude 求 review

在 GitHub 仓库提 Issue 或 PR，标题格式：

```
[M3 · UC-2.3] 参数编辑滑块实现 / 求 review
```

正文结构：
```
## 对应 UC / PRD 章节
链接 + 引用关键行

## 我做了什么
{简述}

## 需要 review 的重点
- 文案是否都来自 文案系统.md
- Schema 字段是否完全按 §7.6
- {具体不确定的地方}

## 附件
- PR 链接 / Gist 链接 / 代码片段
```

### 4.2 Claude 的 review 格式

Claude 会按以下维度 review：
- ✅ 文案一致性（是否从文案系统拷贝）
- ✅ Schema 一致性
- ✅ Formatter 使用
- ✅ 强原子性
- ✅ 是否偷跑 V1.1+ 功能
- ✅ 隐私承诺是否破坏

### 4.3 Adam 的决策格式

当 Claude 和 ChatGPT 就某个问题意见不一致，或遇到文档没写的灰色地带：
- 两边把问题总结给 Adam
- Adam 做决策
- Claude 更新文档
- ChatGPT 据新文档继续

---

## 5. ChatGPT 常见坑位 Checklist

以下是 ChatGPT 做这类项目最容易犯的错，请提前警觉：

### 5.1 "我觉得这样更好"型偷跑
- 不要擅自加"每日打卡"、"徽章系统"、"成就动画"
- 不要把存储层量词改回"次"
- 不要给 App 加"分享到微信/微博"按钮
- 不要在 V1 加 AI / GPT 功能

### 5.2 隐私破坏型
- 不要加 Firebase / Crashlytics / Sentry 等统计
- 不要加任何 HTTP 请求
- 不要读系统相册（用 PhotosPicker）
- 不要写系统相册

### 5.3 架构型
- SwiftData 数据库**不放** App Group（详见技术方案 §3½.2）
- Widget 不直接读 SwiftData，只读 snapshot.widget.json
- 缩略图用 `CGImageSource` 的 thumbnail API，不要加载整图再缩放
- 视频缩略图用 `AVAssetImageGenerator`，取 0.1s 那一帧

### 5.4 事务型
- Moment 保存是**一体的**：元数据 + 媒体文件 + 缩略图
- 任一步失败都要回滚（包括删除已写的部分文件）
- 删除 Moment 是**延迟的**：标 `pendingDelete` + 5s Timer
- 聚合计算必须排除 `pendingDelete` 状态的 Moment

---

## 6. 每周同步节奏（建议）

**周一：** ChatGPT 看当周 Milestone 清单 + 问所有模糊的地方
**周三：** ChatGPT 提交一次中间代码给 Claude review
**周五：** 完成当周 Milestone，Claude 检查 Release Criteria
**周日：** Adam 做真机 dogfood，写下发现的问题

卡点超 2 天 → 立即升级到 Adam，决定是否动用"降级方案 L1/L2/L3"（PRD §10）。

---

## 7. 给 ChatGPT 的启动指令（第一次对话用这段）

> 你是时间银行（iOS App）项目的主力 Swift 工程师。
>
> 我（Adam）是非技术创始人，Claude Code 负责产品文档和 review，你负责写代码。
>
> 请先按顺序阅读以下公开 GitHub 仓库的文件（全部文档，没有代码）：
>
> 1. https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/ChatGPT-协作协议.md（**就是这篇，你现在在看**）
> 2. https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/CLAUDE.md
> 3. https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/PRD-时间银行-V1.md
> 4. https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/Use-Cases-详尽交互.md
> 5. https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/技术方案-媒体存储.md
> 6. https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/设计规范.md
> 7. https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/文案系统.md
> 8. https://raw.githubusercontent.com/no996chen-tennis/time-bank/main/隐私与合规.md
>
> 读完后用以下格式汇报：
>
> **一、我读到的 V1 scope（30 字内复述）**
> {你的复述}
>
> **二、我发现 3 个最大的工程风险**
> 1. ...
> 2. ...
> 3. ...
>
> **三、我准备从 M1（数据层）开始做，需要你先确认的 5 个问题**
> {你的问题}
>
> **四、Xcode 项目结构建议（沿用协作协议 §2.4 还是你有调整？）**
>
> 不要开始写代码，先完成这个汇报。确认之后我才告诉你开工。

---

## 8. 最后一句话

这个产品的核心护城河是**克制**。ChatGPT 天然想加功能、加 SDK、加动画。请记得：**V1 最有价值的不是"你加了什么"，而是"你克制住了什么"。**

如果不确定某个东西该不该加，默认答案是"**不加**"，回来问 Adam。
