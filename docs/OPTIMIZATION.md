# Daymark 项目分析与优化方案

> 审查日期：2026-11-04
> 审查对象：`D:\Project\Daymark`（Git `2405bb5`，Flutter / Dart 源码包）
> 交付性质：**仅新增本方案文档，未修改任何业务源码**

---

## 0. 结论摘要

Daymark 是一个完成度不低的离线待办应用：模型不可变、筛选逻辑是纯函数、写入做了串行化、失败时主动关闭保存以保护旧数据，甚至自带 CI。它的**代码风格与基础设计高于平均水平**。

但当前版本存在 **4 个会直接影响数据正确性或功能可用性的缺陷**，以及一个更根本的工程事实：**这份代码从未在装有 Flutter SDK 的环境里编译过**（README 第 84 行明确说明，本机复核也确认无 `flutter` / `dart` 命令）。因此第一优先级不是加功能，而是「让项目可复现地跑起来 → 修数据层 → 补回归测试 → 再谈架构与体验」。

| 维度 | 评价 |
| --- | --- |
| 功能完整度 | 良好（CRUD、撤销、筛选、多视图、主题、自适应） |
| 数据可靠性 | **偏弱**（首启未落盘、冷启动竞态、单条坏数据全盘失败） |
| 性能伸缩性 | **偏弱**（整页重建 + 无懒加载 + 全量 JSON 重写） |
| 可测试性 | 中等（纯逻辑有测试，最关键的 Controller / Repository 反而没测） |
| 工程可复现性 | **偏弱**（无平台目录、无 lock 文件、CI 依赖 `flutter create` 兜底） |

---

## 1. 项目现状

### 1.1 技术栈与规模

| 项 | 内容 |
| --- | --- |
| 框架 | Flutter >= 3.35 / Dart >= 3.9，Material 3 |
| 状态管理 | `ChangeNotifier` + 页面内 `setState` + 手动 `addListener` |
| 持久化 | `shared_preferences ^2.5.3` 的 `SharedPreferencesAsync`，单 key 全量 JSON |
| 依赖 | 仅 `shared_preferences`；无路由、无 DI、无数据库、无 l10n |
| 代码量 | `lib/` 8 个文件 1245 行，`test/` 3 个文件 109 行，合计 1354 行 |
| 平台目录 | **缺失**（`android/` `ios/` `web/` `windows/` 等均未纳入仓库） |
| 锁文件 | **缺失**（无 `pubspec.lock`） |
| CI | GitHub Actions：checkout → flutter 3.35.0 → `flutter create .` → pub get → analyze → test → build web |

### 1.2 数据流

```
TaskHomePage (StatefulWidget，持有视图/筛选/搜索状态)
   │  add / update / toggle / remove / restore
   ▼
TaskController (ChangeNotifier，持有 List<TaskItem>)
   │  _changed(): notifyListeners() + 串行 Future 写快照
   ▼
TaskRepository (read: jsonDecode / write: jsonEncode)
   ▼
SharedPreferencesAsync["daymark.tasks.v1"]
```

`TaskHomePage.build()` 每次都调用纯函数 `filterTasks()` 重算列表，并用 `for (final task in visible)` 在 `SingleChildScrollView` 里一次性铺开所有卡片。

### 1.3 值得保留的设计

- `TaskItem` 完全不可变，`copyWith` 用 `_unchanged` 哨兵正确支持「把 nullable 字段显式清空」（`task_item_test.dart` 有覆盖）。
- `filterTasks` / `compareDays` / `isOverdue` 是无副作用纯函数且注入 `now`，测试可确定性断言。
- `TaskController._pendingWrite` 用 `then` 链串行化写入，避免慢的旧快照覆盖新快照，思路正确。
- 读失败时 `_loadFailed = true` 并关闭保存，避免用空列表覆盖磁盘上的真实数据 —— 保护意图正确。
- 枚举反序列化对未知值有 fallback；删除操作带 SnackBar 撤销；深浅主题、桌面/移动双布局齐备。

---

## 2. 审查方法与边界

- 逐行阅读了全部 8 个 `lib/*.dart`、3 个 `test/*.dart`、`pubspec.yaml`、`analysis_options.yaml`、CI 配置、`.gitignore`、`README.md`，并查看了 Git 历史。
- 本机 **无 Flutter / Dart SDK**（`command -v flutter` / `dart` 均为 NOT FOUND），因此**未执行** `flutter analyze`、`flutter test`、`flutter build`；本文所有结论为静态审查结果，落地时须先做一次真实编译验证。
- 对「优先级筛选菜单无法清除」这一条，额外核对了 Flutter `stable` 分支 `popup_menu.dart` 源码：`PopupMenuButtonState.showButtonMenu()` 中 `if (newValue == null) { widget.onCanceled?.call(); return; }`，确认 `onSelected` 不会被调用。
- Git 历史显示 `2405bb5` 提交是为了修复「`flutter create` 生成的默认 `test/widget_test.dart` 引用 `MyApp` 导致测试失败」，侧面印证了第 3.3 节的工程隐患。

---

## 3. 问题清单

优先级定义：**P0** = 数据丢失 / 功能不可用，必须立即修；**P1** = 明显影响体验、性能或可维护性；**P2** = 打磨与长期演进。

### 3.1 P0 — 数据正确性与可用性

| # | 位置 | 问题 | 后果 |
| --- | --- | --- | --- |
| P0-1 | `task_controller.dart:24` | 冷启动竞态：`load()` 异步进行中 UI 已可交互（移动端 FAB、桌面侧栏不受 `isLoading` 遮罩保护） | 用户在加载完成前新建任务，`add()` 会把「只含新任务的列表」写入磁盘；随后 `load()` 用磁盘旧数据覆盖内存，且不再写回 → **原有任务在下次启动后丢失** |
| P0-2 | `task_controller.dart:26` | 首次启动的 6 条演示任务只赋值 `_tasks`，**没有落盘** | 用户不改动就关闭 App，下次启动 `read()` 仍返回 `null`，演示任务重新生成（且 `dueAt` 按新日期重算）。README「删除后不会自动重新生成」只在用户发生过一次写操作时才成立 |
| P0-3 | `task_repository.dart:17`、`task_item.dart:79` | `jsonDecode` 后整批 `map(fromJson)`，任意一条记录类型错误 / 日期格式非法 / 字段缺失都会抛异常 | 整个 `read()` 失败 → 进入 `_loadFailed`，界面变空、保存被禁用，且 UI 上**没有「重试加载」入口**（`task_home_page.dart:161` 的重试按钮只在 `error` 以「保存失败」开头时出现）→ 用户只能杀进程重启 |
| P0-4 | `task_home_page.dart:424` | `PopupMenuButton<TaskPriority?>` 中「全部优先级」项的 `value` 为 `null` | Flutter 把 `null` 返回值当作「取消菜单」，**`onSelected` 不触发**。一旦选中某个优先级，就再也无法清除筛选，只能重启 App |
| P0-5 | `task_controller.dart:87-96` | 写失败后 `_error` 被置位，`_changed()` 因 `if (_error != null) return` 静默跳过后续所有写入；同时排队中的写操作仍可能成功却不会清除 `_error` | 界面显示修改成功但实际未落盘；错误状态与真实写入结果可能不一致 |

**补充（同为 P0 级工程项）**：项目当前不可编译验证。README 自述「因环境缺少 Flutter / Dart CLI，无法执行 analyze / test」，仓库又缺平台目录 —— 任何语法 / API 版本不兼容问题都要等到有人真正装好 SDK 才暴露。

### 3.2 P1 — 性能、状态管理与测试

| # | 位置 | 问题 | 建议 |
| --- | --- | --- | --- |
| P1-1 | `task_home_page.dart:52-54` | `controller.addListener(_refresh)` → 每次变更 `setState(() {})` **重建整个页面**（含侧栏、进度卡、统计、搜索框、全部任务卡） | 用 `ValueListenableBuilder` / `AnimatedList` 或 `Selector` 做局部刷新；`TaskItem` 补 `==` / `hashCode` 以便精确比对 |
| P1-2 | `task_home_page.dart:139,180` | `SingleChildScrollView` + `for` 循环，无懒加载，任务全部一次性布局 | 改 `ListView.builder` / `SliverList`，`ValueKey(task.id)` 保留状态，`RepaintBoundary` 包裹行 |
| P1-3 | `task_home_page.dart:414` | 搜索框每次输入即 `setState` + 全量过滤 + 整页重建，无防抖 | 150–250 ms debounce，且只重建列表区域 |
| P1-4 | `task_repository.dart:23` | 每次改动都 `jsonEncode` 全部任务并整串写回，O(n)；单 key 无备份、无 schema 版本 | 短期：写前把旧值备份到 `daymark.tasks.backup`；中期：迁移至 Drift / Isar，按行更新 |
| P1-5 | `task_home_page.dart:108` | `DateTime.now()` 在 `build()` 中取，但**没有定时刷新、也没有生命周期监听** | 实现 `WidgetsBindingObserver`，在 `resumed` 与跨午夜 Timer 时触发刷新，否则隔夜回来「今天 / 逾期」判定仍是昨天 |
| P1-6 | `app.dart:26`、`task_controller.dart:99` | `dispose()` 只置 `_closed`，不 await `_pendingWrite`；App 切后台无 flush | 监听 `paused` / `detached` 时 `await controller.flush()` |
| P1-7 | `test/` | 只有模型序列化、筛选纯函数、编辑器渲染 3 类测试；**Controller 与 Repository 零覆盖** | 补：首启落盘、冷启动竞态、坏数据容错、串行写顺序、写失败重试、删除撤销、跨午夜日期边界、优先级筛选可清除的 widget 测试 |
| P1-8 | `app.dart:53-74` | `theme()` 在每次 `build` 中重建两个 `ThemeData`（含 `ColorScheme.fromSeed` 计算） | 提升为 `static final`，主题偏好在 `main()` 中预先 await 后再 `runApp`，同时消除启动时的浅色闪屏 |

### 3.3 P1/P2 — 工程化与产品体验

| # | 位置 | 问题 |
| --- | --- | --- |
| P1-9 | `.github/workflows/flutter-ci.yml:25` | CI 靠 `flutter create --project-name daymark_flutter .` 现场生成平台工程，会写入 `.metadata` / 平台目录 / 默认测试文件；历史上已因此出过一次测试失败。应提交平台目录（至少 `web/`），或限定 `--platforms=web` 并显式保护 `test/` |
| P1-10 | 仓库根 | 无 `pubspec.lock`，`^2.5.3` 每次解析到不同版本 → 构建不可复现；App 项目应提交 lock 文件 |
| P2-1 | `analysis_options.yaml` | 仅 include `flutter_lints` 且忽略了 `invalid_use_of_visible_for_testing_member`（源码中并未使用 `@visibleForTesting`）；建议删除该豁免，补 `prefer_const_declarations` / `unawaited_futures` / `avoid_dynamic_calls` 等，CI 加 `--fatal-infos` |
| P2-2 | `main.dart` | 无 `runZonedGuarded` / `FlutterError.onError` / `PlatformDispatcher.onError`，线上崩溃无记录 |
| P2-3 | `task_home_page.dart:567` vs `task_editor.dart:173` | 优先级色值在两处重复定义且**不一致**（如 high：`0xFFE46A69` vs `0xFFEC6A6A`），同一个任务在列表和编辑器里颜色不同；且固定色未适配深色主题对比度。应抽为 `ThemeExtension` 或统一常量 |
| P2-4 | `task_home_page.dart:340-346` | 标题写「你的今日进度」，实际计算的是**全部任务**的完成率；统计卡「今日待办」其实包含逾期。语义与数字对不上 |
| P2-5 | `task_home_page.dart:246-317` | 侧栏 `Column` 内含 `Spacer()` 且无滚动，窗口高度较小时会 `RenderFlex overflow`；应包 `SingleChildScrollView` |
| P2-6 | `task_home_page.dart:58` | 关闭抽屉用 `Navigator.of(context).pop()`，应改用 `_scaffoldKey.currentState?.closeDrawer()`，避免误关其他路由 |
| P2-7 | `task_filter.dart:65` | 优先级排序依赖枚举声明顺序（`low < medium < high`），插入新值即改变语义；应定义显式 `sortOrder` |
| P2-8 | `task_filter.dart:55-67` | 「已完成」视图按 `dueAt` 排序而非 `completedAt`，看不到「最近完成」；建议该视图单独按完成时间倒序 |
| P2-9 | 全项目 | 中文文案与日期格式全部硬编码，无 `l10n` / ARB；无导入导出与备份，卸载 App 即永久丢数据 |
| P2-10 | `README.md` | 与实现有出入：演示任务「不会重新生成」不成立；目录结构漏列 `test/widget_test.dart`；「静态检查」表述与实际未编译验证冲突 |

---

## 4. 目标架构

保持「轻量」，但把**持久化与安全边界**做实，把**纯逻辑与 UI**进一步解耦。不建议一上来引入 BLoC / Clean Architecture 全家桶。

```
lib/
├── main.dart                     # 引导：await 初始化 + 全局错误捕获 + runApp
├── app.dart                      # 主题（static final ThemeData）、路由
├── domain/
│   ├── task_item.dart            # 不可变模型 + ==/hashCode + 版本化序列化
│   ├── task_filter.dart          # 纯函数：视图、查询、排序
│   └── task_stats.dart           # 从 UI 抽出的统计计算（便于单测）
├── data/
│   ├── task_repository.dart      # 抽象接口
│   ├── prefs_task_repository.dart# 实现：容错解析、schema 迁移、备份 key
│   └── demo_tasks.dart           # 演示数据（从 controller 中移出）
├── state/
│   ├── task_controller.dart      # 只管状态机：loading / ready / readError / writeError
│   └── app_settings.dart         # 主题偏好（与任务数据解耦）
└── ui/
    ├── task_home_page.dart       # 拆分为 widgets/ 下若干小组件
    └── widgets/                  # task_list / task_tile / sidebar / stats / editor / filters
test/                             # domain + data + state + widget + golden
```

关键原则：

1. **Repository 必须是接口**，为将来换 Drift / 云同步留出替换点，也让 Controller 可用 fake 单测。
2. **Controller 显式状态机**，取代现在靠 `_error` 字符串前缀判断 UI 行为（`error!.startsWith('保存失败')`）的脆弱写法。建议 `sealed class TaskState { loading / ready(tasks) / readFailure(raw) / writeFailure(pending) }`。
3. **UI 只读状态**，筛选/统计参数集中在可测试的 selector 中，避免 `build()` 里散落 5 处 `where(...)`。

---

## 5. 分阶段实施路线

| 阶段 | 目标 | 主要动作 | 验收标准 |
| --- | --- | --- | --- |
| **Phase 0**<br>可复现 | 让任何人 clone 后能一条命令跑通 | 安装 SDK 并真实执行 `flutter analyze` / `test` / `build web`；提交 `pubspec.lock` 与至少 `web/` 平台目录；CI 去掉或收窄 `flutter create`，加 `--fatal-infos`、coverage 上传；修正 README 描述 | CI 全绿；`flutter analyze` 零 issue；本机与 CI 结果一致 |
| **Phase 1**<br>数据可靠性 | 修完 P0，数据不再丢 | 冷启动门控（加载完成前禁止写入或排队）；首启演示任务落盘；`fromJson` 逐条容错 + `schemaVersion` + 备份 key；优先级筛选改哨兵枚举；写状态用 revision 管理；补 Controller / Repository / widget 回归测试 | 新增 ≥ 10 个覆盖上述 bug 的测试且全部通过；人工冷启动/杀进程/坏 JSON 演练通过 |
| **Phase 2**<br>性能与体验 | 千条任务仍流畅 | 列表改 `ListView.builder` + 局部刷新 + 搜索防抖；`TaskItem` 补值相等；主题缓存与启动预加载；生命周期刷新与退出 flush；统一颜色到 `ThemeExtension`；修复文案/滚动/排序语义 | 1000 条任务下滚动无明显掉帧；隔夜回归「今天」判定正确 |
| **Phase 3**<br>产品化 | 从 demo 走向可用产品 | 导入导出 JSON / 文件备份；可选 Drift 迁移（阈值：任务 > 2000 或需要附件/全文搜索）；`l10n`；崩溃上报；提醒通知、重复任务、子任务、拖拽排序；必要时端到端加密同步 | 有明确的数据迁移与回滚方案；每个新功能配套测试 |

> 关于「是否现在就换数据库」：**不建议**。当前 JSON 方案在数百条任务量级完全够用，Phase 1/2 的收益远大于换库；把 Repository 抽象出来即可，等触发阈值再替换实现。

---

## 6. 关键补丁参考实现

以下为示意代码，用于说明修复方向，落地时需结合 Phase 0 的真实编译结果调整。

### 6.1 冷启动门控 + 首启落盘（P0-1 / P0-2）

```dart
Future<void> load() async {
  if (_loadStarted) return;              // 防重入
  _loadStarted = true;
  try {
    final stored = await _repository.read();
    if (stored == null) {
      _tasks = demoTasks(DateTime.now());
      await _repository.write(_tasks);   // 关键：首启内容必须落盘
    } else {
      _tasks = stored;
    }
    _state = TaskState.ready(_tasks);
  } catch (error) {
    _state = TaskState.readFailure(error);
  }
  notifyListeners();
}

void _mutate(List<TaskItem> next) {
  if (_state is! TaskStateReady) return; // 未就绪时拒绝写入
  _tasks = next;
  _persist();
}
```

同时在 `main()` 中 `await controller.load()` 后再 `runApp()`，或用 `FutureBuilder` 显示启动占位；`isLoading` 期间 FAB / 侧栏一并禁用。

### 6.2 容错解析 + 版本迁移（P0-3）

```dart
Future<List<TaskItem>?> read() async {
  final raw = await _preferences.getString(_tasksKey);
  if (raw == null) return null;
  await _preferences.setString(_backupKey, raw);   // 写前留底
  final decoded = jsonDecode(raw);
  if (decoded is! List) throw const FormatException('invalid root');
  final result = <TaskItem>[];
  for (final entry in decoded) {
    try {
      if (entry is Map<String, dynamic>) result.add(TaskItem.fromJson(entry));
    } catch (_) {
      // 跳过坏记录，记录日志，不让单条数据毁掉整个列表
    }
  }
  return result;
}
```

`TaskItem.fromJson` 内所有字段改为安全读取（`json['id'] as String? ?? ...`、`DateTime.tryParse`），并增加 `schemaVersion` 字段支撑未来迁移。

### 6.3 优先级筛选可清除（P0-4）

```dart
enum PriorityFilter { all, low, medium, high }   // 不用 null 表达「全部」

PopupMenuButton<PriorityFilter>(
  initialValue: _priorityFilter,
  onSelected: (value) => setState(() => _priorityFilter = value),
  itemBuilder: (context) => [
    const PopupMenuItem(value: PriorityFilter.all, child: Text('全部优先级')),
    // ...其余项 value 均非 null
  ],
)
```

### 6.4 局部刷新与懒加载（P1-1 / P1-2）

```dart
ValueListenableBuilder<List<TaskItem>>(
  valueListenable: controller.visibleTasks,   // selector 中做 filter + sort
  builder: (context, tasks, _) => ListView.builder(
    itemCount: tasks.length,
    itemBuilder: (context, i) => RepaintBoundary(
      key: ValueKey(tasks[i].id),
      child: TaskTile(task: tasks[i]),
    ),
  ),
)
```

### 6.5 跨午夜刷新（P1-5）

```dart
class _TaskHomePageState extends State<TaskHomePage> with WidgetsBindingObserver {
  Timer? _midnightTimer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshClock();
    if (state == AppLifecycleState.paused) unawaited(controller.flush());
  }

  void _refreshClock() {
    if (!mounted) return;
    setState(() => _now = DateTime.now());
    _scheduleNextMidnight();
  }
}
```

---

## 7. 验收清单

- [ ] `flutter analyze --fatal-infos --fatal-warnings` 零问题
- [ ] `flutter test --coverage` 通过，行覆盖率 ≥ 70%，`state/` 与 `data/` 覆盖率 ≥ 85%
- [ ] 冷启动期间狂点「新建任务」不丢数据（自动化 widget 测试）
- [ ] 首次启动后直接杀进程重启，演示任务不重复生成
- [ ] 手工把存储中的某条 JSON 改坏，App 仍能打开其余任务并给出可恢复提示
- [ ] 选中优先级筛选后能点「全部优先级」清除
- [ ] 断网 / 存储写失败后，界面明确显示「未保存」，重试后数据一致
- [ ] 1000 条任务下搜索与滚动流畅，跨午夜后「今天」视图自动更新
- [ ] 深浅主题切换无闪屏，重启后偏好保留
- [ ] CI 不依赖 `flutter create` 覆盖仓库文件即可完成 analyze / test / build

---

## 8. 明确暂不做的事

- **不上后端 / 云同步**：README 已定位「离线优先」，在导入导出与备份落地前谈同步会放大数据一致性问题。
- **不引入重型状态管理框架**：当前规模用手写 `ChangeNotifier` + `ValueListenableBuilder` 足够；等出现多页面共享状态、路由栈、异步依赖编排时再评估 Riverpod。
- **不做主题大改版**：现有 Material 3 视觉已完成度高，优先修 P2-3 的颜色一致性与深色对比度即可。
- **不在 Phase 0 之前动源码**：先把编译验证跑通，否则任何修改都无法确认是否引入回归。
