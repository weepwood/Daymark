import 'package:flutter/material.dart';

import '../state/task_filter.dart';
import '../theme/app_tokens.dart';
import 'widgets/app_sidebar.dart';

/// Single place where width decides the navigation shape.
/// compact -> drawer + bottom bar, medium -> rail, expanded/large -> sidebar.
class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({
    super.key,
    required this.breakpoint,
    required this.view,
    required this.counts,
    required this.isDark,
    required this.onThemeToggle,
    required this.onViewSelected,
  });

  final AppBreakpoint breakpoint;
  final TaskView view;
  final Map<TaskView, int> counts;
  final bool isDark;
  final VoidCallback onThemeToggle;
  final ValueChanged<TaskView> onViewSelected;

  @override
  Widget build(BuildContext context) {
    return switch (breakpoint) {
      AppBreakpoint.compact => const SizedBox.shrink(),
      AppBreakpoint.medium => _rail(context),
      AppBreakpoint.expanded || AppBreakpoint.large => SizedBox(
          width: SizeToken.sidebarWidth,
          child: AppSidebar(
            view: view,
            counts: counts,
            isDark: isDark,
            onThemeToggle: onThemeToggle,
            onViewSelected: onViewSelected,
          ),
        ),
    };
  }

  Widget _rail(BuildContext context) {
    return NavigationRail(
      selectedIndex: TaskView.values.indexOf(view),
      onDestinationSelected: (index) =>
          onViewSelected(TaskView.values[index]),
      labelType: NavigationRailLabelType.all,
      backgroundColor: context.colors.surfaceRaised,
      indicatorColor: context.colors.selectedBg,
      trailing: IconButton(
        tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
        onPressed: onThemeToggle,
        icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: Text('全部'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.wb_sunny_outlined),
          label: Text('今天'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: Text('到期'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.flag_outlined),
          label: Text('重要'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.task_alt_rounded),
          label: Text('完成'),
        ),
      ],
    );
  }
}
