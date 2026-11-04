import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../state/task_filter.dart';
import '../../theme/app_tokens.dart';

/// Scrollable sidebar: no Spacer, so short desktop windows never overflow.
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.view,
    required this.counts,
    required this.isDark,
    required this.onThemeToggle,
    required this.onViewSelected,
  });

  final TaskView view;
  final Map<TaskView, int> counts;
  final bool isDark;
  final VoidCallback onThemeToggle;
  final ValueChanged<TaskView> onViewSelected;

  static const _items = <(TaskView, IconData)>[
    (TaskView.all, Icons.grid_view_rounded),
    (TaskView.today, Icons.wb_sunny_outlined),
    (TaskView.upcoming, Icons.calendar_month_outlined),
    (TaskView.important, Icons.flag_outlined),
    (TaskView.completed, Icons.task_alt_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surfaceRaised,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(Space.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.brand,
                        borderRadius: BorderRadius.circular(RadiusToken.sm),
                      ),
                      child: Icon(Icons.layers_rounded,
                          color: colors.onBrand, size: 19),
                    ),
                    const Gap(Space.s3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daymark', style: context.textStyles.titleMedium),
                        Text('让每一天更有条理',
                            style: context.textStyles.labelSmall
                                ?.copyWith(color: colors.textSecondary)),
                      ],
                    ),
                  ]),
                  const Gap(Space.s8),
                  Padding(
                    padding: const EdgeInsets.only(left: Space.s3),
                    child: Text('工作空间',
                        style: context.textStyles.labelSmall
                            ?.copyWith(color: colors.textSecondary)),
                  ),
                  const Gap(Space.s2),
                  for (final (itemView, icon) in _items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.s1),
                      child: _SidebarItem(
                        label: itemView.label,
                        icon: icon,
                        count: counts[itemView] ?? 0,
                        selected: view == itemView,
                        onTap: () => onViewSelected(itemView),
                      ),
                    ),
                  const Gap(Space.s6),
                  Divider(color: colors.borderSubtle),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text('深色模式', style: context.textStyles.bodyMedium),
                    secondary: Icon(
                      isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      size: 20,
                    ),
                    value: isDark,
                    onChanged: (_) => onThemeToggle(),
                  ),
                  Text('v1.1 · 离线本地存储',
                      style: context.textStyles.labelSmall
                          ?.copyWith(color: colors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = selected ? colors.brand : colors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: '$label，$count 项',
      child: Material(
        color: selected ? colors.selectedBg : Colors.transparent,
        borderRadius: BorderRadius.circular(RadiusToken.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(RadiusToken.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.s3,
              vertical: Space.s3,
            ),
            child: Row(children: [
              Icon(icon, size: 19, color: foreground),
              const Gap(Space.s3),
              Expanded(
                child: Text(
                  label,
                  style: (selected
                          ? context.textStyles.labelMedium
                          : context.textStyles.bodyMedium)
                      ?.copyWith(color: foreground),
                ),
              ),
              Text('$count',
                  style: context.textStyles.labelSmall
                      ?.copyWith(color: colors.textSecondary)),
            ]),
          ),
        ),
      ),
    );
  }
}
