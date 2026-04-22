# M1 数据层 · 启动 ChatGPT 的 Prompt

> 这是 Adam 发给 ChatGPT 的**第一条 M1 任务 prompt**。整段复制即可。
> 前置假设：ChatGPT 已按 `ChatGPT-协作协议.md` §7 完成启动汇报。

---

## 📬 发给 ChatGPT 的内容（整段复制）

````markdown
M1 · 数据层启动

按 `ChatGPT-协作协议.md` §3.M1 交付清单，以下是本轮任务。

## 任务范围

在 GitHub 仓库 https://github.com/no996chen-tennis/time-bank 的 `TimeBank/` Xcode 项目骨架内，实现以下文件（仅数据层，不做 UI）：

1. **Utility/DesignTokens.swift** - 复制自仓库 `designs/DesignTokens.swift`，作为之后 UI 的色/字/间距源
2. **Utility/Formatter.swift** - 按 PRD §21 Formatter Matrix 实现 7 个接口
3. **Utility/FileStore.swift** - 沙盒读写 + 缩略图生成（`CGImageSource` + `AVAssetImageGenerator`）
4. **Models/UserProfile.swift** - SwiftData `@Model`，严格按 PRD §7.6
5. **Models/Dimension.swift** - 注意工程类名是 `Dimension`，但 UI 文案是"时间账户"
6. **Models/Moment.swift** - 含 `status: MomentStatus` (normal/pendingDelete) 和 `originDimensionId`
7. **Models/MediaItem.swift**
8. **Models/Settings.swift** - 含 `expectedLifespanYears` (默认 85)、`narrativeMode`、`notificationEnabled` 等
9. **Shared/MomentStore.swift** - **强原子性事务**：写入 Moment 走 transaction，任一步失败全回滚（删文件 + 撤销 SwiftData 插入）
10. **Shared/DimensionCompute.swift** - lifespan 计算 + 6 个内置时间账户的消耗层数字计算逻辑（周/小时/年 各 formatter）
11. **TimeBankTests/DataLayerTests.swift** - 单元测试覆盖：
    - 写入 Moment (含 3 张图) → 成功
    - 写入时第 2 张图模拟失败 → **全部回滚**（DB 无记录 + 无孤儿文件）
    - 删除 Moment（延迟 5s + Undo 协议）：立即标 pendingDelete → 5s 内恢复 → 最终 commit
    - 聚合计算：pendingDelete 的 Moment 不参与聚合
    - durationSeconds == nil 的 Moment 对小时贡献 0，对瞬间数 +1

## 硬性约束（重复提醒）

- ❌ **不要写任何 UI 代码** - M1 只做数据层。`App/TimeBankApp.swift` 的 `ContentView` 保持 Xcode 默认即可（M2 再替换）
- ❌ **不要改 `Dimension.id` / `Dimension.kind` 等字段名**，严格照 PRD §7.6
- ❌ **不要加第三方 SDK**
- ❌ **不要写入系统相册**（V1 不碰）
- ❌ **不要加 Camera / Microphone 权限**（V1 不索）
- ❌ **不要做孤儿文件清理的后台任务**（V1 在 App 启动时同步扫描一次就够）

## 产出格式（重要）

请按以下格式输出：

### 1. 文件列表
- `TimeBank/Utility/Formatter.swift` (完整内容)
- `TimeBank/Models/UserProfile.swift` (完整内容)
- ... 每个文件独立一个代码块，带完整路径注释

### 2. Info.plist 改动
列出需要在 Info.plist 里新增/修改的 key（V1 应该只需要 `NSPhotoLibraryUsageDescription` 对应的文案——等等，V1 用 PhotosPicker 其实不需要。请你确认）。

### 3. 对 PRD / Use Cases 的疑问
如有任何字段/行为文档没写清楚的地方，**列出来问我，不要猜**。不允许偷偷决定字段含义。

### 4. 下一步建议
M1 完成后，下一步是 M2（Onboarding + 主页）。请说明 M1 完成后你打算哪些接口能被 M2 立即调用。

## 交付流程

- 你把上面产出整段贴给 Adam（用户）
- Adam 转发给 Claude
- Claude 机械落盘到 feature branch `m1-data-layer` + commit + push + review
- Adam 本地 git pull 打开 Xcode 验证编译 / 跑单测
- 通过 → Adam 命令 Claude merge 到 main；失败 → Adam 把错误贴回给你

请开始 M1。
````

---

## 📌 Adam 使用流程

1. 打开 ChatGPT，确保 ChatGPT 已经读过仓库（如果是新对话，先让它按 `ChatGPT-协作协议.md` §7 做启动汇报）
2. 整段复制上面 code block 发给 ChatGPT
3. 等 ChatGPT 产出代码
4. 把他的输出**整段贴给 Claude**（Claude Code 这边）
5. Claude 会落盘到 feature branch + commit + push + 自动 review

## 📌 如果 ChatGPT 问澄清问题

这是好事（说明他没在猜），让他列清楚，你把问题转给 Claude 这边，我更新文档后再返给他。

## 📌 预期 M1 产出规模

- 11 个 Swift 文件
- 总代码量 ≈ 500-800 行
- 单元测试 15-20 个
- 应该在 2-3 个 ChatGPT 会话内完成

如果他一次想全部吐出来，你可以让他分 3 轮：
- 轮 1：Models + Formatter + DesignTokens
- 轮 2：FileStore + MomentStore（事务部分最难）
- 轮 3：测试 + 修补问题
