# designs/ — UI 定稿包

> 本目录是 ChatGPT 写 SwiftUI 代码时的**视觉真相源**。
> 最后更新：2026-04-22 · V1.3.2

## 文件清单

| 文件 | 用途 |
|------|------|
| `v1-ui-final.html` | Claude Design UI 定稿（6 屏 React 组件 + tokens + 插画）· 7.7MB bundle · 双击本地打开查看 |
| `DesignTokens.swift` | 从 HTML 里提取的 Swift 常量文件，ChatGPT 可直接放入工程的 `Utility/Tokens.swift` |

## ChatGPT 写代码时如何用

1. 先双击 `v1-ui-final.html` 在浏览器里看一遍 6 屏视觉（了解色彩、插画、间距、阴影节奏）
2. 把 `DesignTokens.swift` 复制到 `TimeBank/Utility/Tokens.swift` 作为起点
3. 编写 SwiftUI View 时：
   - 颜色 → `Color.tbDimParents` / `Color.tbInk` 等（不硬编码 hex）
   - 字号 → `.font(.tbHeadL)` / `.font(.tbDisplayM)`（不裸写 size）
   - 间距 → `.padding(TBSpace.s5)` / `VStack(spacing: TBSpace.s3)`
   - 圆角 → `.cornerRadius(TBRadius.lg)`
   - 动画 → `.animation(TBAnimation.transition, value: ...)`

## 插画策略

HTML 里的插画是**纯 SVG 几何拼贴**（圆 + 椭圆 + 圆角矩形），每个时间账户 (Dimension) 有对应的小插画 icon：

- `parents` - 两个相靠的椭圆（老人并肩）
- `kids` - 大圆 + 小圆（牵手）
- `partner` - 两个交叠的圆（依偎）
- `create` - 抽象光晕（灵感）
- `sport` - 圆 + 虚线轨道（动）
- `free` - 单独的圆（独处）

SwiftUI 实现时：
- **简单方案**：用 `SF Symbols`（heart.fill / person.2.fill 等）先跑通流程
- **到位方案**：M3/M4 阶段，让设计师从 HTML 里导出 SVG，在 Xcode 里用 `SFSymbolsRenderer` 或 `Canvas` 重绘
- **V1 可接受**：先用 emoji 或 SF Symbols 占位，V1.1 再精修插画

## 和 PRD / Use Cases 的关系

当 UI 定稿和 PRD 冲突时，以下是最终决策（V1.3.2 Adam 2026-04-22 拍板）：

1. **"维度" → "时间账户"**：所有用户可见文案用后者，Swift 类名保留 `Dimension`
2. **消耗层标签**："还能共度"（不是"还能存入"）
3. **主页顶部**：双层账户卡（时间余额 + 已存入）—— ChatGPT 写 SwiftUI 时要加回来，HTML 里只有单层
4. **底部 Tab**：主页 / 账户 / 我 三 Tab + 中央 FAB —— HTML 里是"家/存入/我"，要按 PRD 改
5. **维度数量**：6 个默认显示（不是 HTML 里的 4 个）
6. **媒体网格**：3×3（9 格）—— HTML 里是 3×2，要按 PRD 改

以上差异不用再跑 Claude Design，由 ChatGPT 直接在 SwiftUI 里按 PRD §22 实现。
