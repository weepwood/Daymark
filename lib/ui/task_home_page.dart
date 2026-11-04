import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../models/task_item.dart';
import '../state/task_controller.dart';
import '../state/task_filter.dart';
import '../theme/app_tokens.dart';
import 'adaptive_shell.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/empty_state_view.dart';
import 'widgets/task_editor.dart';
import 'widgets/task_filters.dart';
import 'widgets/task_header.dart';
import 'widgets/task_list.dart';

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

class _TaskHomePageState extends State<TaskHomePage>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();
  TaskView _view = TaskView.all;
  TaskCategory? _category;
  PriorityFilter _priority = PriorityFilter.all;
  String _query = '';
  late DateTime _now;
  Timer? _midnightTimer;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _debounce?.cancel();
    _searchFocus.dispose();
    _searchController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshClock();
  }

  void _refreshClock() {
    if (!mounted) return;
    setState(() => _now = DateTime.now());
    _scheduleMidnightRefresh();
  }

  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
    _midnightTimer = Timer(nextMidnight.difference(now), _refreshClock);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = value);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    if (mounted) setState(() => _query = '');
  }

  void _clearFilters() {
    _clearSearch();
    setState(() {
      _category = null;
      _priority = PriorityFilter.all;
    });
  }

  void _selectView(TaskView view) {
    setState(() => _view = view);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  void _toast(String message) {
    toastification.show(
      context: context,
      title: Text(message),
      alignment: Alignment.bottomRight,
      autoCloseDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _create() async {
    final draft = await showTaskEditor(context);
    if (draft == null || !mounted) return;
    final created = widget.controller.add(
      title: draft.title,
      description: draft.description,
      category: draft.category,
      priority: draft.priority,
      dueAt: draft.dueAt,
    );
    _toast(created == null ? '数据尚未就绪，请稍后重试' : '任务已添加');
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
      action: SnackBarAction(
        label: '撤销',
        onPressed: () => widget.controller.restore(task),
      ),
    ));
  }

  Widget _boxSliver(Widget child, {double bottom = 0}) => SliverToBoxAdapter(
        child: boxed(
          Padding(
            padding: EdgeInsets.only(bottom: bottom),
            child: child,
          ),
        ),
      );

  Widget _errorBanner(TaskController controller) {
    final colors = context.colors;
    final readFailure = controller.phase == TaskPhase.readFailure;
    return Container(
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: colors.priorityHigh.withValues(alpha: .1),
        border: Border.all(color: colors.priorityHigh.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(RadiusToken.md),
      ),
      child: Row(children: [
        Icon(Icons.warning_amber_rounded, color: colors.priorityHigh, size: 20),
        const SizedBox(width: Space.s3),
        Expanded(
          child: Text(controller.errorMessage ?? '',
              style: context.textStyles.bodySmall
                  ?.copyWith(color: colors.textPrimary)),
        ),
        TextButton(
          onPressed: () async {
            if (readFailure) {
              await controller.restoreBackup();
              await controller.retryLoad();
            } else {
              controller.retrySave();
            }
          },
          child: const Text('重试'),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakpoint = context.breakpoint;
    final compact = breakpoint == AppBreakpoint.compact;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyN): () {
          if (!_searchFocus.hasFocus) unawaited(_create());
        },
        const SingleActivator(LogicalKeyboardKey.slash): () {
          if (!_searchFocus.hasFocus) _searchFocus.requestFocus();
        },
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            () => _searchFocus.requestFocus(),
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            () => _searchFocus.requestFocus(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: _scaffoldKey,
          drawer: compact
              ? Drawer(
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) => AppSidebar(
                      view: _view,
                      counts: _counts(),
                      isDark: widget.isDark,
                      onThemeToggle: widget.onThemeToggle,
                      onViewSelected: _selectView,
                    ),
                  ),
                )
              : null,
          bottomNavigationBar: compact
              ? NavigationBar(
                  selectedIndex: TaskView.values.indexOf(_view),
                  onDestinationSelected: (index) =>
                      _selectView(TaskView.values[index]),
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.grid_view_rounded), label: '全部'),
                    NavigationDestination(
                        icon: Icon(Icons.wb_sunny_outlined), label: '今天'),
                    NavigationDestination(
                        icon: Icon(Icons.calendar_month_outlined), label: '到期'),
                    NavigationDestination(
                        icon: Icon(Icons.flag_outlined), label: '重要'),
                    NavigationDestination(
                        icon: Icon(Icons.task_alt_rounded), label: '完成'),
                  ],
                )
              : null,
          floatingActionButton: compact
              ? FloatingActionButton.extended(
                  onPressed: _create,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新建任务'),
                )
              : null,
          body: SafeArea(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => _body(breakpoint),
            ),
          ),
        ),
      ),
    );
  }

  Map<TaskView, int> _counts() {
    final tasks = widget.controller.tasks;
    return {
      for (final view in TaskView.values)
        view: countForView(tasks, view, _now),
    };
  }

  Widget _body(AppBreakpoint breakpoint) {
    final controller = widget.controller;
    final compact = breakpoint == AppBreakpoint.compact;
    final tasks = controller.tasks;
    final visible = filterTasks(
      tasks,
      view: _view,
      query: _query,
      category: _category,
      priority: _priority.priority,
      now: _now,
    );
    final summary = summarize(tasks, _now);
    final error = controller.errorMessage;
    final emptyReason = tasks.isEmpty
        ? EmptyReason.firstRun
        : _query.isNotEmpty
            ? EmptyReason.search
            : (_category != null || _priority != PriorityFilter.all)
                ? EmptyReason.filtered
                : EmptyReason.allDone;

    return Row(children: [
      if (!compact)
        AdaptiveShell(
          breakpoint: breakpoint,
          view: _view,
          counts: _counts(),
          isDark: widget.isDark,
          onThemeToggle: widget.onThemeToggle,
          onViewSelected: _selectView,
        ),
      if (!compact)
        VerticalDivider(width: 1, thickness: 1, color: context.colors.borderSubtle),
      Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? Space.s4 : Space.s8,
          ),
          child: CustomScrollView(
            slivers: <Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: Space.s6)),
              _boxSliver(
                ViewHeader(
                  now: _now,
                  view: _view,
                  isDesktop: !compact,
                  isDark: widget.isDark,
                  onCreate: _create,
                  onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                  onThemeToggle: widget.onThemeToggle,
                  onSearchTap: () => _searchFocus.requestFocus(),
                ),
                bottom: Space.s6,
              ),
              if (error != null) _boxSliver(_errorBanner(controller), bottom: Space.s4),
              _boxSliver(SummaryBar(summary: summary), bottom: Space.s6),
              _boxSliver(
                TaskSearchBar(
                  query: _query,
                  focusNode: _searchFocus,
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
                bottom: Space.s4,
              ),
              _boxSliver(
                FilterBar(
                  category: _category,
                  priorityFilter: _priority,
                  onCategoryChanged: (value) => setState(() => _category = value),
                  onPriorityChanged: (value) => setState(() => _priority = value),
                  visibleCount: visible.length,
                ),
                bottom: Space.s4,
              ),
              TaskListSliver(
                tasks: visible,
                now: _now,
                compact: compact,
                loading: controller.isLoading,
                onToggle: controller.toggle,
                onEdit: (task) => unawaited(_edit(task)),
                onDelete: _delete,
              ),
              if (visible.isEmpty && !controller.isLoading)
                _boxSliver(
                  EmptyStateView(
                    reason: emptyReason,
                    query: _query,
                    onCreate: _create,
                    onClear: () {
                      if (emptyReason == EmptyReason.search) {
                        _clearSearch();
                      } else {
                        _clearFilters();
                      }
                    },
                  ),
                  bottom: Space.s6,
                ),
              _boxSliver(
                Center(
                  child: Text(
                    'DAYMARK · 每一次完成，都值得记录',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                bottom: Space.s12,
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
