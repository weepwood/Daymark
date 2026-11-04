import 'package:flutter/material.dart';

import '../models/task_item.dart';
import '../state/task_controller.dart';
import '../state/task_filter.dart';
import 'widgets/task_editor.dart';

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onThemeToggle,
  });

  final TaskController controller;
  final bool isDark;
  final VoidCallback onThemeToggle;

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TaskView _view = TaskView.all;
  TaskCategory? _category;
  TaskPriority? _priority;
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant TaskHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _selectView(TaskView view) {
    setState(() => _view = view);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.of(context).pop();
  }

  Future<void> _create() async {
    final draft = await showTaskEditor(context);
    if (draft == null || !mounted) return;
    widget.controller.add(
      title: draft.title,
      description: draft.description,
      category: draft.category,
      priority: draft.priority,
      dueAt: draft.dueAt,
    );
    _toast('任务已添加');
  }

  Future<void> _edit(TaskItem task) async {
    final draft = await showTaskEditor(context, initial: task);
    if (draft == null || !mounted) return;
    widget.controller.update(task.copyWith(
      title: draft.title,
      description: draft.description,
      category: draft.category,
      priority: draft.priority,
      dueAt: draft.dueAt,
    ));
    _toast('修改已保存');
  }

  void _delete(TaskItem task) {
    widget.controller.remove(task);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('任务已删除'),
      action: SnackBarAction(label: '撤销', onPressed: () => widget.controller.restore(task)),
    ));
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;
    final now = DateTime.now();
    final tasks = controller.tasks;
    final visible = filterTasks(
      tasks,
      view: _view,
      query: _query,
      category: _category,
      priority: _priority,
      now: now,
    );
    final completed = tasks.where((task) => task.isCompleted).length;
    final pending = tasks.length - completed;
    final dueToday = tasks.where((task) =>
        !task.isCompleted && task.dueAt != null && compareDays(task.dueAt!, now) <= 0).length;
    final important = tasks.where((task) =>
        !task.isCompleted && task.priority == TaskPriority.high).length;

    return Scaffold(
      key: _scaffoldKey,
      drawer: desktop ? null : Drawer(
        child: SafeArea(child: _sidebar(tasks, now)),
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              SizedBox(width: 254, child: _sidebar(tasks, now)),
            if (desktop) VerticalDivider(width: 1, thickness: 1, color: colors.outlineVariant.withValues(alpha: .5)),
            Expanded(
              child: controller.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: desktop ? 42 : 19, vertical: desktop ? 34 : 18),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _header(desktop, now),
                              if (controller.error != null) ...[
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: colors.errorContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(children: [
                                    Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(controller.error!,
                                        style: TextStyle(color: colors.onErrorContainer))),
                                    if (controller.error!.startsWith('保存失败'))
                                      TextButton(onPressed: controller.retrySave, child: const Text('重试')),
                                  ]),
                                ),
                              ],
                              const SizedBox(height: 29),
                              _progressBanner(tasks.length, completed, pending),
                              const SizedBox(height: 20),
                              _stats(dueToday, important, completed),
                              const SizedBox(height: 33),
                              _sectionHeading(visible.length),
                              const SizedBox(height: 15),
                              _searchAndFilters(),
                              const SizedBox(height: 16),
                              _categoryChips(),
                              const SizedBox(height: 17),
                              if (visible.isEmpty)
                                _emptyState()
                              else
                                for (final task in visible)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 11),
                                    child: _taskTile(task, now),
                                  ),
                              const SizedBox(height: 32),
                              Center(child: Text('DAYMARK · 每一次完成，都值得记录',
                                style: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: .6), fontSize: 11, letterSpacing: 1.1))),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: desktop ? null : FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('新建任务'),
      ),
    );
  }

  Widget _header(bool desktop, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (!desktop) ...[
          IconButton(
            tooltip: '打开菜单',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
          const SizedBox(width: 5),
        ],
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${now.year} 年 ${now.month} 月 ${now.day} 日 · ${weekdays[now.weekday - 1]}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            Text(_view.label, style: TextStyle(fontSize: desktop ? 30 : 25, fontWeight: FontWeight.w800, letterSpacing: -.7)),
          ],
        )),
        if (desktop)
          FilledButton.icon(
            onPressed: _create,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('新建任务'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 17)),
          )
        else
          IconButton(
            tooltip: widget.isDark ? '切换到浅色模式' : '切换到深色模式',
            onPressed: widget.onThemeToggle,
            icon: Icon(widget.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
      ],
    );
  }

  Widget _sidebar(List<TaskItem> tasks, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    final sections = <(TaskView, IconData, int)>[
      (TaskView.all, Icons.grid_view_rounded, tasks.length),
      (TaskView.today, Icons.wb_sunny_outlined,
        tasks.where((t) => !t.isCompleted && t.dueAt != null && compareDays(t.dueAt!, now) <= 0).length),
      (TaskView.upcoming, Icons.calendar_month_outlined,
        tasks.where((t) => !t.isCompleted && t.dueAt != null && compareDays(t.dueAt!, now) > 0).length),
      (TaskView.important, Icons.flag_outlined,
        tasks.where((t) => !t.isCompleted && t.priority == TaskPriority.high).length),
      (TaskView.completed, Icons.task_alt_rounded,
        tasks.where((t) => t.isCompleted).length),
    ];
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(17, 28, 17, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 40),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF675AF0), borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.layers_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daymark', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.3)),
                Text('让每一天更有条理', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            ]),
          ),
          Padding(padding: const EdgeInsets.only(left: 13, bottom: 13),
            child: Text('工作空间', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600))),
          for (final (view, icon, count) in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: _view == view ? scheme.primaryContainer.withValues(alpha: .72) : Colors.transparent,
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => _selectView(view),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                    child: Row(children: [
                      Icon(icon, color: _view == view ? scheme.primary : scheme.onSurfaceVariant, size: 21),
                      const SizedBox(width: 12),
                      Expanded(child: Text(view.label, style: TextStyle(
                        fontWeight: _view == view ? FontWeight.w700 : FontWeight.w500,
                        color: _view == view ? scheme.onPrimaryContainer : scheme.onSurface))),
                      Text('$count', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                  ),
                ),
              ),
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            title: const Text('深色模式', style: TextStyle(fontSize: 13)),
            leading: Icon(widget.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 21),
            trailing: Switch.adaptive(value: widget.isDark, onChanged: (_) => widget.onThemeToggle()),
          ),
          Padding(padding: const EdgeInsets.only(left: 13, top: 8),
            child: Text('v1.0 · 离线本地存储', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _progressBanner(int total, int completed, int pending) {
    final percent = total == 0 ? 0.0 : completed / total;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7265F5), Color(0xFF4E43BC)],
        ),
      ),
      child: Stack(children: [
        Positioned(right: -42, top: -82, child: Container(width: 240, height: 240,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: .13), width: 38)))),
        Positioned(right: 26, bottom: -124, child: Container(width: 210, height: 210,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .055)))),
        Padding(
          padding: const EdgeInsets.all(27),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('你的今日进度', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 13)),
              const SizedBox(height: 11),
              const Text('保持专注，稳步向前 ✨',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 21)),
              const SizedBox(height: 12),
              Text(total == 0 ? '创建第一条任务，开始你的计划吧' : '已完成 $completed 项任务，还有 $pending 项等待完成',
                  style: TextStyle(color: Colors.white.withValues(alpha: .87), fontSize: 13)),
              const SizedBox(height: 21),
              ClipRRect(borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: percent, minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: .26),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))),
            ])),
            const SizedBox(width: 20),
            SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(child: CircularProgressIndicator(
                value: percent,
                strokeWidth: 7,
                backgroundColor: Colors.white.withValues(alpha: .21),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              )),
              Text('${(percent * 100).round()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _stats(int dueToday, int important, int completed) {
    final entries = [
      ('今日待办', '$dueToday', Icons.today_rounded, const Color(0xFF6561E9)),
      ('重要任务', '$important', Icons.flag_rounded, const Color(0xFFEE946B)),
      ('已完成', '$completed', Icons.check_circle_rounded, const Color(0xFF4AAE94)),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 600 ? 3 : constraints.maxWidth >= 380 ? 2 : 1;
      final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final (label, value, icon, color) in entries)
          SizedBox(width: itemWidth, child: Card(
            margin: EdgeInsets.zero,
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 19), child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(
                color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(13)),
                child: Icon(icon, color: color, size: 21)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              ])),
            ])),
          )),
      ]);
    });
  }

  Widget _sectionHeading(int count) {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Text('任务清单', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(width: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
        child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimaryContainer))),
    ]);
  }

  Widget _searchAndFilters() {
    final scheme = Theme.of(context).colorScheme;
    return Row(children: [
      Expanded(child: TextField(
        key: const ValueKey('task_search'),
        onChanged: (value) => setState(() => _query = value),
        decoration: InputDecoration(
          hintText: '搜索任务名称或备注...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      )),
      const SizedBox(width: 11),
      PopupMenuButton<TaskPriority?>(
        tooltip: '按优先级筛选',
        initialValue: _priority,
        onSelected: (value) => setState(() => _priority = value),
        itemBuilder: (context) => [
          const PopupMenuItem<TaskPriority?>(value: null, child: Text('全部优先级')),
          for (final priority in TaskPriority.values)
            PopupMenuItem<TaskPriority?>(value: priority, child: Text(priority.label)),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
          decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(14)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.tune_rounded, size: 19, color: _priority == null ? scheme.onSurface : scheme.primary),
            if (MediaQuery.sizeOf(context).width > 560) ...[
              const SizedBox(width: 8),
              Text(_priority?.label ?? '筛选', style: const TextStyle(fontSize: 13)),
            ],
          ]),
        ),
      ),
    ]);
  }

  Widget _categoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
          label: const Text('全部分类'),
          selected: _category == null,
          onSelected: (_) => setState(() => _category = null),
        )),
        for (final category in TaskCategory.values)
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: Text(category.label),
            selected: _category == category,
            onSelected: (_) => setState(() => _category = category),
          )),
      ]),
    );
  }

  Widget _taskTile(TaskItem task, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = isOverdue(task, now);
    final color = _priorityColor(task.priority);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _edit(task),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Semantics(
              label: task.isCompleted ? '标记为未完成' : '完成任务',
              child: IconButton(
                tooltip: task.isCompleted ? '标记为未完成' : '标记为完成',
                onPressed: () => widget.controller.toggle(task),
                icon: Icon(task.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: task.isCompleted ? const Color(0xFF4AAE94) : scheme.outline, size: 27),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted ? scheme.onSurfaceVariant : scheme.onSurface)),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(task.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 9),
              Wrap(spacing: 12, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_categoryIcon(task.category), size: 13, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(task.category.label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                ]),
                if (task.dueAt != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: overdue ? scheme.error : scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(_dueText(task.dueAt!, now, overdue),
                      style: TextStyle(color: overdue ? scheme.error : scheme.onSurfaceVariant, fontSize: 12,
                        fontWeight: overdue ? FontWeight.w700 : FontWeight.normal)),
                  ]),
              ]),
            ])),
            if (MediaQuery.sizeOf(context).width >= 550) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(9)),
                child: Text(task.priority.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ] else
              Icon(Icons.flag_rounded, size: 17, color: color),
            PopupMenuButton<String>(
              tooltip: '任务操作',
              onSelected: (value) {
                if (value == 'edit') _edit(task);
                if (value == 'delete') _delete(task);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: ListTile(dense: true,
                  leading: Icon(Icons.edit_outlined), title: Text('编辑'), contentPadding: EdgeInsets.zero)),
                PopupMenuItem(value: 'delete', child: ListTile(dense: true,
                  leading: Icon(Icons.delete_outline_rounded), title: Text('删除'), contentPadding: EdgeInsets.zero)),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 58, horizontal: 20),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Container(width: 72, height: 72,
          decoration: BoxDecoration(shape: BoxShape.circle, color: scheme.primaryContainer.withValues(alpha: .55)),
          child: Icon(Icons.inbox_outlined, color: scheme.primary, size: 34)),
        const SizedBox(height: 19),
        const Text('这里暂时没有任务', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 7),
        Text('调整筛选条件，或者创建一条新任务。',
          textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 19),
        TextButton.icon(onPressed: _create,
          icon: const Icon(Icons.add_rounded), label: const Text('创建任务')),
      ]),
    );
  }
}

Color _priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.high => const Color(0xFFE46A69),
  TaskPriority.medium => const Color(0xFFD59A46),
  TaskPriority.low => const Color(0xFF4AAE94),
};

IconData _categoryIcon(TaskCategory category) => switch (category) {
  TaskCategory.work => Icons.work_outline_rounded,
  TaskCategory.personal => Icons.home_outlined,
  TaskCategory.study => Icons.menu_book_outlined,
  TaskCategory.health => Icons.favorite_border_rounded,
  TaskCategory.other => Icons.folder_outlined,
};

String _dueText(DateTime date, DateTime today, bool overdue) {
  if (overdue) return '已逾期 · ${date.month}/${date.day}';
  final difference = DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  if (difference == 0) return '今天截止';
  if (difference == 1) return '明天截止';
  return '${date.month}/${date.day} 截止';
}
