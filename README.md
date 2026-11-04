# Daymark · Flutter 任务管理

一款简洁的离线优先任务管理 App，使用 **Flutter + Material 3 + SharedPreferencesAsync** 构建，不依赖后端服务。

> **v1.1 重构说明**：本版本按 `docs/OPTIMIZATION.md` 与 `docs/UI_DESIGN.md` 实施了数据层修复、设计 token 层、组件化拆分与响应式重构。完整变更见 `docs/IMPLEMENTATION.md`。

## 当前状态（请先读）

- SDK 基线 **Flutter 3.47 / Dart 3.13**；本机已安装 **Flutter 3.47.9 / Dart 3.13.7**（`D:\App\FlutterSDK\flutter`，已加入用户 PATH）。
- 依赖：`shared_preferences`、`toastification`、`flutter_slidable`、`skeletonizer`、`gap`、`cupertino_icons`，全部为纯 Dart / 本地资源包，不联网。
- **已完成真实编译验证**（2026-11-04）：`flutter create --platforms=web`、`flutter pub get`、`flutter analyze`（0 issues）、`flutter test`（26/26 通过）、`flutter build web --release`（成功）。`pubspec.lock` 与 `web/` 平台工程已生成。
- 所有改动都在 Git 工作区内，原始版本可通过 `git diff` / `git checkout -- <file>` 找回。

## 功能

- 新建、编辑、删除、完成/取消完成任务，删除后支持撤销
- 工作 / 生活 / 学习 / 健康 / 其他分类；高 / 中 / 低优先级；可选截止日期、逾期提示
- 全部任务、今天（含逾期）、即将到期、重要任务、已完成视图
- 标题和备注搜索（200ms 防抖）、分类及优先级筛选（可清除）
- 总完成率与任务汇总、四种空状态、加载骨架屏
- 移动端：抽屉 + 底部导航 + 滑动完成/删除；平板：NavigationRail；桌面：固定侧栏 + hover 操作
- 桌面键盘快捷键：`N` 新建、`/` 聚焦搜索、`Ctrl/Cmd + K` 搜索、`Ctrl/Cmd + Enter` 保存
- Material 3 浅色与深色主题（保存偏好）、跨午夜自动刷新日期判定
- 首次打开提供 6 条演示任务并**立即落盘**，删除后不会重新生成
- 单条坏数据被隔离、写前保留原始备份、读取失败进入只读且可重试

## 环境要求

- Flutter 3.47 或更新版本（Dart 3.13 或更新版本）
- Windows、macOS、Linux、Android、iOS 或 Web 所需的 Flutter 工具链

## 运行

仓库已附带 `web/` 平台工程与 `pubspec.lock`，安装 Flutter 3.47+ 后可直接运行：

```bash
flutter pub get
flutter run -d chrome
```

Web 正式构建产物在 `build/web/`，用任意静态服务器托管即可（不要直接用 `file://` 打开，Service Worker 与资源路径需要 HTTP）：

```bash
flutter build web --release
cd build/web && python -m http.server 8787
# 浏览器访问 http://localhost:8787
```

如需桌面 / 移动端平台目录，再执行：

```bash
flutter create --platforms=windows,android,ios --project-name daymark_flutter --org com.daymark .
flutter devices
flutter run -d windows
```

## 测试与构建

```bash
flutter analyze
flutter test --coverage
flutter build web --release
```

CI（`.github/workflows/flutter-ci.yml`）使用 Flutter 3.47.9，自动执行 analyze / test / web build。

## 目录结构

```text
lib/
├── main.dart                         # 引导、全局错误捕获
├── app.dart                          # 初始化门控、主题、Toast 容器、生命周期 flush
├── models/task_item.dart             # 不可变模型、值相等、容错序列化
├── data/
│   ├── task_repository.dart          # 抽象仓储接口 + TaskSnapshot
│   ├── prefs_task_repository.dart    # JSON 实现：逐条容错、备份 key
│   └── demo_tasks.dart               # 首启演示数据
├── state/
│   ├── task_controller.dart          # 状态机、冷启动门控、串行写 + revision
│   ├── task_filter.dart              # 纯函数：视图/筛选/排序/统计
│   └── app_settings.dart             # 主题偏好
├── theme/
│   ├── app_colors.dart               # 语义色 ThemeExtension（浅/深）
│   ├── app_tokens.dart               # 4pt 间距、圆角、断点、type scale
│   └── app_theme.dart                # 缓存的 ThemeData
└── ui/
    ├── adaptive_shell.dart           # 统一断点 → 抽屉 / 导航栏 / 侧栏
    ├── task_home_page.dart           # 主编排、快捷键、生命周期、Sliver 列表
    └── widgets/                      # 侧栏、头部、统计、筛选、任务行、空状态、编辑器
test/                                 # 模型 / 筛选 / 控制器 / 组件 测试 + 内存仓储 fake
web/                                  # Flutter Web 平台工程（index.html / manifest / icons）
docs/                                 # 优化方案、UI 方案、实施报告
```

## 数据说明

所有任务保存在当前设备的应用私有存储（Web 为浏览器本地存储），**不会自动同步到其他设备**。

- 任务 key：`daymark.tasks.v1`；写前备份：`daymark.tasks.backup`
- 每条记录带 `v: 1` schema 版本号，为后续迁移留出空间
- 读取时逐条容错：格式错误的记录会被跳过并在界面提示，不会让整个列表不可用
- 写入串行化 + revision 检查，保证旧快照不会覆盖新数据，且写失败状态不会被旧结果卡住
- 当前 JSON 全量读写适合个人小型待办列表；任务量超过约 2000 条、需要附件/复杂搜索/同步时，建议新增一个 `TaskRepository` 实现迁移到 Drift / Isar

## 设计系统与组件库

- 语义色、字号、间距、圆角、断点全部来自 `lib/theme/`，组件内不写死 `Color(0xFF...)` 与 `fontSize`
- 图标统一使用 Material Icons 的圆角/线性风格；`lucide_icons_flutter` 的全量替换需在能编译验证后逐个核对图标名
- 字体目前使用系统字体栈。**未使用运行时字体下载**，以保持完全离线可用；如需 Inter / Noto Sans SC，请把字体文件放进 `assets/fonts/` 并在 `pubspec.yaml` 声明
- 更多选型理由、版本核实与视觉稿见 `docs/UI_DESIGN.md`

## 后续扩展

导入导出与文件备份、逐条撤销 Toast 队列、入场动效、golden test 基线、日历视图、7 日完成趋势、提醒通知、重复任务、子任务、拖拽排序，以及可选的端到端加密云同步。
