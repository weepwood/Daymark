# Daymark UI 设计与组件库优化方案

> 配套文档：`docs/OPTIMIZATION.md`（工程与数据层）
> 审查日期：2026-11-04 ｜ 依赖版本核实来源：pub.dev API
> 交付性质：**仅新增本方案文档，未修改任何业务源码与 `pubspec.yaml`**

---

## 0. 三个关键判断

1. **现有 UI 的问题不是"不好看"，而是"没有系统"。** 视觉方向（Material 3、紫色主色、卡片列表、深浅主题）本身成立且完成度高，真正拖后腿的是：`task_home_page.dart` 单文件 588 行塞了 12 个私有构建方法、13 个硬编码 HEX 色值、10 余种字号、5 种字重、20 余个手写间距常量、5 处各自为政的宽度判断。结果是深浅主题不一致、同一优先级在两处显示不同颜色、窄窗口溢出、无法局部刷新。
2. **引入组件库之前必须先定 SDK 基线。** 项目锁 `Flutter >=3.35 / Dart >=3.9`，CI 固定 `3.35.0`；而 2026 年主流 Flutter UI 库已普遍要求 3.41 / 3.47，**直接加最新版会解析失败**（详见第 2 节）。
3. **推荐「渐进增强」，不推荐「整套换皮」。** 保留 Material 3 骨架 + 自建轻量 Design Token 层 + 点状引入交互复杂的组件（Toast / 滑动 / 弹层 / 骨架屏 / 图标 / 图表）；`shadcn_ui` / `forui` 作为可选的整包路线列出，但不建议现在全量替换。

---

## 1. 现状 UI 体检

| 维度 | 现状（源码证据） | 问题 |
| --- | --- | --- |
| 色彩 | `app.dart:52` 种子色 `#675AF0`；进度条渐变 `#7265F5→#4E43BC`；统计卡 3 色；优先级色在 `task_home_page.dart:567` 与 `task_editor.dart:173` **重复定义且色号不一致**（如 high：`#E46A69` vs `#EC6A6A`）；完成绿 `#4AAE94` | 无语义 token，深色主题下固定色对比度失衡；同一任务在列表/编辑器颜色不同 |
| 排版 | 字号 10/11/12/13/15/18/19/20/21/24/25/30 混用；字重 w500/w600/w700/w800/w900 混用；`fontFamily: null` | 无 type scale，信息层级靠手感；大字号下 `maxLines` + 固定高度易截断 |
| 间距/圆角 | `EdgeInsets` 中手写 4/5/8/9/10/11/12/13/14/15/16/17/18/19/20/21/22/25/26/27/28/29/32/33/34/40/42/54/58…；圆角 9/13/14/20/24/99 | 不成栅格，跨页面难对齐，改一处牵一片 |
| 图标 | Material Icons 的 `rounded` / `outlined` / 无后缀混用（`Icons.flag_outlined`、`Icons.flag_rounded`、`Icons.today_rounded`…） | 线宽与圆角风格不统一，视觉显"杂" |
| 响应式 | `900`（桌面）、`680`（编辑器弹窗）、`600`（统计卡）、`560`（筛选文字）、`550`（优先级标签）、`380`（统计卡）共 6 个魔数，散落各方法 | 无统一断点，平板宽度区间行为不可预测 |
| 层级 | `Card(elevation: 0)` + 纯色 surface，侧栏与内容区靠 1px `VerticalDivider` | 深色下卡片与背景区分度弱；无 focus ring 规范 |
| 状态 | 有 empty / loading（转圈）/ error（横幅）；缺 hover、pressed、focus、skeleton、离线只读 | 桌面端没有 hover 反馈与键盘操作，任务多时加载体验单薄 |
| 反馈 | 删除用 `SnackBar` + 撤销；新建/编辑用 `SnackBar` 提示 | SnackBar 会互相顶掉，连续删两条时第一条的撤销机会直接消失 |
| 组件化 | 1 个 588 行 StatefulWidget + 1 个 226 行编辑器 | 无法单测单个组件、无法 golden test、无法局部 rebuild |

---

## 2. 前置决策：SDK 基线（必须先定）

### 2.1 版本冲突实测

pub.dev 数据核实于 2026-11-04：

| 包 | 最新版本 | 要求 Flutter | 在 3.35 下最后可用版本 |
| --- | --- | --- | --- |
| `forui` | 0.27.7 | **>=3.47** | 0.16.0（2025-10，相差 11 个小版本） |
| `shadcn_ui` | 0.57.4 | **>=3.41** | 0.53.6（2026-04） |
| `wolt_modal_sheet` | 0.12.0 | >=3.44 | 0.11.0（2025-02） |
| `flutter_slidable` | 5.2.0 | >=3.47 | 4.0.3（2025-09） |
| `flex_color_scheme` | 9.0.0 | >=3.47 | 8.3.1（2025-10） |
| `google_fonts` | 9.0.0 | >=3.47 | 8.1.0（2026-04） |
| `toastification` | 3.2.2 | >=3.38 | 3.0.3（2025-06） |
| `fl_chart` / `skeletonizer` / `table_calendar` / `lucide_icons_flutter` / `dynamic_color` / `gap` | 1.3.0 / 3.0.0 / 3.3.0 / 4.0.2 / 2.1.0 / 3.0.1 | ≤3.32 或仅 Dart 约束 | **最新版即可用** |
| `flutter_animate` | 4.5.2（2024-11） | >=2.0.0 | 最新版即可用（但久未更新，见 4.4） |

### 2.2 两条路线

| | 路线 A：升级基线（**推荐**） | 路线 B：锁定 3.35 |
| --- | --- | --- |
| 做法 | `sdk: '>=3.13.0 <4.0.0'`、`flutter: '>=3.47.0'`，CI 改 `flutter-version: '3.47.0'` | 保持现有约束，逐个 pin 旧版本 |
| 可用组件 | 全部最新 | 一批 2025 年旧版，forui 只能用 0.16.0 |
| 代价 | 需重跑一次编译验证，检查 3.35→3.47 的 API 变动 | 无升级成本，但被锁在落后生态，安全修复与文档都对不上 |
| 适用 | **推荐**：本项目从未编译验证过（见 `OPTIMIZATION.md` Phase 0），反正要装 SDK、跑 CI，升级的边际成本几乎为零 | 只有当必须长期钉死 3.35 时才选 |

> 升级时重点回归：`CardThemeData`、`Color.withValues`、`showModalBottomSheet(showDragHandle:)`、`MediaQuery.sizeOf` —— 这些都是较新 API，3.47 仍保留，风险可控，但必须实机验证。同时把 `pubspec.lock` 与至少 `web/` 平台目录提交进仓库。

---

## 3. 设计系统（Design Tokens）

**先建 token，再选组件库。** 否则引入再多库也只会把"不一致"扩散到更多组件上。

### 3.1 语义色 —— 用 `ThemeExtension` 消灭硬编码

```dart
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.priorityHigh, required this.priorityMedium, required this.priorityLow,
    required this.overdue, required this.success, required this.surfaceRaised,
    required this.borderSubtle, required this.categoryWork, required this.categoryStudy,
  });

  final Color priorityHigh, priorityMedium, priorityLow, overdue, success;
  final Color surfaceRaised, borderSubtle, categoryWork, categoryStudy;

  static const light = AppSemanticColors(/* ... */);
  static const dark = AppSemanticColors(/* ... */);

  @override
  AppSemanticColors copyWith({/* ... */}) => this; // 省略实现
  @override
  ThemeExtension<AppSemanticColors> lerp(covariant ThemeExtension<AppSemanticColors>? other, double t) => this;
}

extension SemanticOnContext on BuildContext {
  AppSemanticColors get semantic => Theme.of(this).extension<AppSemanticColors>()!;
}
```

| 语义 token | 浅色 | 深色 | 用途 |
| --- | --- | --- | --- |
| `priorityHigh` | `#D64545` | `#FF8A80` | 高优先级点 / 标签 / 图标 |
| `priorityMedium` | `#B7791F` | `#E8B96A` | 中优先级 |
| `priorityLow` | `#2E8B6B` | `#6FCFAE` | 低优先级 |
| `overdue` | `#C62828` | `#FF9E9E` | 逾期日期文字 |
| `success` | `#2E8B6B` | `#6FCFAE` | 已完成勾选、Toast |
| `surfaceRaised` | `#FFFFFF` | `#1B1D26` | 卡片 / 弹层 |
| `borderSubtle` | `#E6E7EC` | `#2E303B` | 1px 描边 |
| `brand` | `#5B4BD6` | `#A99BFF` | 主按钮、选中态、进度环 |

规则：**品牌紫只出现在「主操作 / 选中态 / 进度」三处**，其余一律中性灰阶 + 语义色小面积点缀。所有颜色对背景对比度 ≥ 4.5:1（WCAG AA）。

### 3.2 排版 scale

| 级别 | 字号 / 行高 / 字重 | 用途 |
| --- | --- | --- |
| `display` | 28 / 34 / 500 | 页面主标题（桌面视图名） |
| `headline` | 20 / 28 / 500 | 弹窗标题、区块标题 |
| `title` | 15 / 22 / 500 | 任务标题 |
| `body` | 13 / 20 / 400 | 备注、正文 |
| `label` | 12 / 16 / 500 | 统计标签、chip |
| `caption` | 11 / 16 / 400 | 日期、计数、脚注 |

全部写入 `ThemeData.textTheme`；组件内**禁止再写 `fontSize:` 常量**。中文字体打包 `Inter` + `Noto Sans SC` 子集到 `assets/fonts/`，在 `pubspec.yaml` 的 `flutter.fonts` 声明 —— **不要用 `google_fonts` 运行时下载**（见 4.4）。

### 3.3 间距 / 圆角 / 尺寸

| Token | 值 | Token | 值 |
| --- | --- | --- | --- |
| `space1` | 4 | `radiusSm` | 8 |
| `space2` | 8 | `radiusMd` | 12 |
| `space3` | 12 | `radiusLg` | 16 |
| `space4` | 16 | `radiusXl` | 24 |
| `space6` | 24 | `controlSm/Md/Lg` | 32 / 40 / 48 |
| `space8` | 32 | `touchTarget` | ≥ 48 |
| `space12` | 48 | `contentMaxWidth` | 1120 |

### 3.4 层级与状态

- 层级：`pageBg → surface → surfaceRaised → overlay`，每一级靠 **1px `borderSubtle` 描边 + 轻微明度差** 区分，不靠阴影（深色模式尤其重要）。
- 每个可交互组件必须定义 8 态：`default / hover / pressed / focus / selected / disabled / loading / error`。桌面端 `focus` 统一 2px `brand` 焦点环，移动端靠 ripple。

---

## 4. 组件库选型

### 4.1 推荐路线：渐进增强（点状引入）

以下版本对应**路线 A（Flutter 3.47）**；括号中为路线 B 的 pin 版本。

| 包 | 版本 | 替换 / 补强点 | 收益 | 风险 |
| --- | --- | --- | --- | --- |
| `lucide_icons_flutter` | ^4.0.2 | 全部 `Icons.*` | 统一 1.5px 线性图标，Linear/Vercel 观感 | 纯图标数据，风险极低；需一次性批量替换 |
| `toastification` | ^3.2.2（B: 3.0.3） | 全部 `SnackBar` | 支持堆叠、不互相顶掉 → **连续删除仍可逐条撤销** | 需在 `MaterialApp` 外包一层 `ToastificationWrapper` |
| `flutter_slidable` | ^5.2.0（B: 4.0.3） | 任务行移动端操作 | 左滑完成、右滑删除，移动端少两次点击 | 与 `InkWell` 手势需协调，须实机测 |
| `wolt_modal_sheet` | ^0.12.0（B: 0.11.0） | `showModalBottomSheet` / `showDialog` | 可拖拽、多步、带 drag handle，桌面/移动一套代码 | 0.x API 变动较快，锁死小版本 |
| `skeletonizer` | ^3.0.0 | `CircularProgressIndicator` | 加载时显示列表骨架，避免"空白转圈" | 需为任务行准备 fake 数据 |
| `flutter_animate` | ^4.5.2 | 入场 / 完成 / 删除动画 | 声明式 stagger、scale、fade，几行代码完成微交互 | **最后发布 2024-11**，与 3.47 兼容性需实机验证；备选见 4.4 |
| `gap` | ^3.0.1 | `SizedBox(width:/height:)` | 间距语法糖，配合 `spaceN` 更可读 | 可不用，直接 `SizedBox` 也行 |
| `fl_chart` | ^1.3.0 | 新增"完成趋势"卡片 | 7 日完成率折线，替代语义错误的"今日进度" | 仅 Phase 3 需要，按需引入 |
| `table_calendar` | ^3.3.0 | 新增日历视图 | 按月查看到期分布 | 仅 Phase 3 需要，视觉需按 token 定制 |
| `dynamic_color` | ^2.1.0 | 可选系统取色 | Android 12+ 跟随壁纸 | 其他平台无效果，收益有限，可不引 |

### 4.2 备选路线：整套组件库

| | `shadcn_ui` 0.57.4 | `forui` 0.27.7 |
| --- | --- | --- |
| 风格 | shadcn/ui 移植，组件覆盖广（Button/Card/Dialog/Sheet/Toast/Calendar/Progress…） | 同为 shadcn 启发，50+ 组件，自带 Sidebar、Tile Group、Line Calendar，最贴近 Linear 观感 |
| 主题体系 | 自有 `ShadTheme`，组件可单个使用，能渐进迁移、与现有 Material 组件共存 | 独立 `FTheme` + `FScaffold` 体系，基本要换掉整层 UI |
| SDK | Flutter >=3.41 | **Flutter >=3.47（0.26.0+ 硬性要求）** |
| 迁移成本 | 中：可先只换表单、弹窗、Toast | 高：相当于重写 UI |
| 建议 | 若确实想要 shadcn 视觉语言，**优先它**，且只做渐进替换 | 仅在新项目或决定彻底重做 UI 时选 |

> 二者都自带 Toast / Sheet / Calendar / Popover，若选整包路线，**第 4.1 节里对应的小库就不要重复引入**（尤其 `toastification`、`wolt_modal_sheet`、`table_calendar`）。

### 4.3 明确不引入

- `getwidget` / `velocity_x`：长期停滞，风格与 M3 冲突，且不能解决 token 问题。
- `fluent_ui` / `macos_ui`：平台专属设计语言，与"跨平台统一"目标相悖。
- `responsive_framework` 1.5.1：最后发布 2024-08，而 Flutter 自带 `LayoutBuilder` / `MediaQuery` 足够（见 5.2）。
- 不叠加 `flex_color_scheme`：它和自建 `ThemeExtension` 职责重叠，二选一即可；本项目用 `ColorScheme.fromSeed` + 语义扩展已足够。

### 4.4 离线优先的两条硬约束

1. **字体必须随包分发**。`google_fonts` 默认运行时从网络拉取字体，与 README 的"完全离线可用"冲突。若坚持用，须把字体文件放进 `assets/fonts/` 并设置 `GoogleFonts.config.allowRuntimeFetching = false`；更简单的做法是**不引入该包**，直接 `pubspec.yaml → flutter.fonts` 声明本地字体。
2. **所有引入的库不得隐式联网**。上述推荐库均为纯本地渲染；`dynamic_color` 只读系统壁纸色板，不联网。

---

## 5. 页面与组件重构

### 5.1 把 588 行拆成组件清单

| 新组件 | 来源方法 | 目标行数 | 备注 |
| --- | --- | --- | --- |
| `AdaptiveShell` | `build()` 布局判断 | ~80 | 统一断点，输出侧栏 / 导航栏 / 抽屉 |
| `AppSidebar` | `_sidebar()` | ~90 | 包 `SingleChildScrollView`（修小窗口溢出） |
| `ViewHeader` | `_header()` | ~55 | 日期 + 视图名 + 主操作 |
| `ProgressSummary` | `_progressBanner()` | ~70 | 去掉渐变横幅与装饰圆环，改紧凑进度条 + 语义正确的"总完成率" |
| `StatsRow` | `_stats()` | ~55 | 用 `LayoutBuilder` + token 列宽 |
| `TaskSearchBar` | `_searchAndFilters()` | ~60 | 带清除按钮 + debounce |
| `FilterBar` | `_categoryChips()` | ~45 | 分类 chips + 优先级下拉（修 P0-4 的 null value） |
| `TaskListView` | `for (final task in visible)` | ~70 | `ListView.builder` + `RepaintBoundary` |
| `TaskTile` | `_taskTile()` | ~110 | 桌面 hover 操作、移动 `Slidable` |
| `DueBadge` / `PriorityBadge` / `CategoryIcon` | 内联逻辑 | ~30 each | 语义色统一走 `context.semantic` |
| `EmptyStateView` | `_emptyState()` | ~55 | 四种状态分支 |
| `TaskEditorSheet` | `task_editor.dart` | ~180 | 表单分组、日期快捷选项、快捷键保存 |

每个组件 `const` 构造、只依赖传入参数与 `Theme.of(context)`，便于 **golden test** 与局部 rebuild（呼应 `OPTIMIZATION.md` 的 P1-1/P1-2）。

### 5.2 统一断点

```dart
enum AppBreakpoint { compact, medium, expanded, large }

AppBreakpoint breakpointOf(double width) => switch (width) {
  < 600  => AppBreakpoint.compact,   // 手机：底部导航 + FAB
  < 900  => AppBreakpoint.medium,    // 平板：NavigationRail
  < 1200 => AppBreakpoint.expanded,  // 桌面：固定 240 侧栏
  _      => AppBreakpoint.large,     // 宽屏：侧栏 + 内容区 maxWidth 1120
};
```

全项目**只允许** `breakpointOf(MediaQuery.sizeOf(context).width)` 一处判断宽度，删除所有 560/550/600/680/900 魔数。

### 5.3 任务行信息架构

- **桌面**：勾选框 → 标题 + 备注 → 分类（图标 + 文字）→ 截止徽章 → 优先级（**语义色小圆点 + 文字**，不再是彩色胶囊）→ hover 时才出现编辑/删除/更多；整行可键盘聚焦，Enter 编辑、Space 切换完成。
- **移动**：`flutter_slidable` 左滑完成、右滑删除；优先级收缩为小圆点；日期与分类放第二行。
- 已完成任务：`lineThrough` + 降透明度，并显示完成时间（而非只按 `dueAt` 排序）。

### 5.4 空状态四分

| 状态 | 文案方向 | 主操作 |
| --- | --- | --- |
| 首次无任务 | 「从第一条任务开始」 | 新建任务 |
| 筛选无结果 | 「当前筛选下没有任务」 | 清除筛选 |
| 搜索无结果 | 「没有匹配 'xxx' 的任务」 | 清空搜索 |
| 全部完成 | 「今天的都完成了」 | 查看已完成 |

### 5.5 编辑器

保留桌面 `Dialog` / 移动 `Sheet` 的双形态，但统一走 `wolt_modal_sheet` 一套 API；补：字段分组（内容 / 属性 / 时间）、日期快捷选项（今天 / 明天 / 下周）、`Ctrl/Cmd + Enter` 保存、标题为空时实时提示、字数计数可见。

### 5.6 可选新增（Phase 3）

命令面板（`Ctrl/Cmd + K`：搜索 + 新建 + 切视图）、日历视图（`table_calendar`）、7 日完成趋势（`fl_chart`）、拖拽排序。这些都建立在组件化完成之后，否则会再次把逻辑塞回主页面。

---

## 6. 微交互规范

| 场景 | 现在 | 建议 |
| --- | --- | --- |
| 列表入场 | 无 | 首屏 stagger fade + 8px 上移，40ms 间隔，仅首次加载 |
| 勾选完成 | 立即重绘 | checkbox scale 弹动 + 标题划线渐显 + 行淡出到"已完成"分区 |
| 删除 | 直接消失 + SnackBar | `AnimatedList` 移除动画 + `toastification` 堆叠撤销（逐条可撤销） |
| 主题切换 | 瞬时 | MaterialApp 自带过渡即可，`ThemeData` 缓存后不再重建两次 |
| 加载 | 居中转圈 | `skeletonizer` 任务行骨架 |
| 搜索 | 每次输入全页 rebuild | 200ms debounce + 清除按钮 + 结果数变化动画 |
| 筛选 | chip 无动画 | `AnimatedSwitcher` + chip 选中态 150ms |

```dart
// flutter_animate 示意（也可全用内置 AnimatedSwitcher / TweenAnimationBuilder 零依赖替代）
TaskTile(task: task)
    .animate(delay: (index * 40).ms)
    .fadeIn(duration: 220.ms, curve: Curves.easeOut)
    .moveY(begin: 8, end: 0, duration: 220.ms, curve: Curves.easeOut);
```

> `flutter_animate` 最后发布为 2024-11-25 的 4.5.2，与 Flutter 3.47 的兼容性需实机验证。若 `pub get` 或运行期报错，**优先改用 Flutter 内置动画**（`AnimatedList` / `AnimatedSwitcher` / `TweenAnimationBuilder`）实现同样效果，零依赖更稳妥。

---

## 7. 无障碍与适配

- 所有语义色对比度 ≥ 4.5:1；优先级**不能只靠颜色**，同时保留文字/圆点形状差异。
- 支持系统动态字体：移除 `maxLines` + 固定高度的组合，任务行高度改为自适应；在 200% `textScaler` 下跑 golden test。
- 触控目标 ≥ 48×48；`ChoiceChip`、`PopupMenuButton` 触发区补足内边距。
- `Semantics` 标注「未完成 / 已完成」「高优先级」「已逾期」；删除与完成时调用 `SemanticsService.announce`。
- 桌面键盘：Tab 顺序、焦点环、`N` 新建、`/` 聚焦搜索、`Ctrl/Cmd + K` 命令面板、`J/K` 移动、`Space` 完成。
- 尊重 `MediaQuery.disableAnimations`（减少动态效果）。

---

## 8. 落地顺序与验收

| 步骤 | 内容 | 验收 |
| --- | --- | --- |
| **U0** | 定 SDK 基线（推荐升 3.47）、提交 lock 与平台目录、真实跑通 `analyze/test/build` | CI 全绿；`pub get` 无版本冲突 |
| **U1** | 建 token 层：`AppSemanticColors` / `AppSpacing` / type scale / 断点；把 13 个硬编码色、全部字号与间距替换为 token | 全局搜索不再有 `Color(0xFF…)`（除 token 定义文件）；深浅两套 golden 截图人工比对 |
| **U2** | 拆组件 + 统一 `AdaptiveShell` + 修空状态/加载/反馈；引入 `lucide_icons_flutter`、`toastification`、`skeletonizer` | 单文件 ≤ 180 行；窄窗口无 `RenderFlex overflow`；连续删除两条都能撤销 |
| **U3** | 交互增强：`flutter_slidable`、`wolt_modal_sheet`、微交互、键盘/无障碍；按需加日历与图表 | 键盘可完成全流程；200% 字体无截断；golden test 覆盖浅/深 × 手机/桌面 × 4 种空状态 |

**Golden test 建议矩阵**：`{light, dark} × {compact, expanded} × {默认, 加载, 空, 筛选空, 错误}` = 20 张基线图，接入 CI 防视觉回归。这是引入组件库后最值钱的一项投资。

---

## 9. 可直接粘贴的依赖片段（路线 A）

```yaml
# pubspec.yaml
environment:
  sdk: '>=3.13.0 <4.0.0'
  flutter: '>=3.47.0'

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.5.3
  lucide_icons_flutter: ^4.0.2
  toastification: ^3.2.2
  flutter_slidable: ^5.2.0
  wolt_modal_sheet: ^0.12.0
  skeletonizer: ^3.0.0
  flutter_animate: ^4.5.2
  gap: ^3.0.1

flutter:
  uses-material-design: true
  fonts:
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-Medium.ttf
          weight: 500
```

```yaml
# .github/workflows/flutter-ci.yml 关键改动
- uses: subosito/flutter-action@v2
  with:
    channel: stable
    flutter-version: '3.47.0'
    cache: true
# 用已提交的平台目录替代现场生成；如仍需 create，限定平台并保护 test/
- run: flutter create --platforms=web --project-name daymark_flutter --org com.daymark .
- run: flutter analyze --fatal-infos
- run: flutter test --coverage
```

---

## 10. 风险与避坑

1. **先升 SDK 再加库**，否则会在旧版本上装一堆 2025 年的包，后期双倍迁移成本。
2. **不要同时引入两套组件体系**（如 `shadcn_ui` + `toastification` + `wolt_modal_sheet`），Toast / Sheet 会打架。
3. **不要引入运行时下载字体的方案**，会破坏"完全离线可用"这一产品承诺。
4. **`wolt_modal_sheet` / `flutter_slidable` 均为 0.x / 大版本活跃期**，建议在 `pubspec.lock` 中锁定并定期评估升级。
5. **组件化与数据层修复并行时容易冲突**：`OPTIMIZATION.md` 的 Phase 1（P0 数据缺陷）应排在 U2 大规模重构之前，否则拆组件会掩盖数据回归。
6. 本机无 Flutter/Dart SDK，本文所有版本号来自 pub.dev API 核实，**但依赖组合的真实可解析性与运行效果仍需 `flutter pub get` + 实机验证**。
