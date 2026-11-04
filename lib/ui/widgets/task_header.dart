import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../state/task_filter.dart';
import '../../theme/app_tokens.dart';

class ViewHeader extends StatelessWidget {
  const ViewHeader({
    super.key,
    required this.now,
    required this.view,
    required this.isDesktop,
    required this.isDark,
    required this.onCreate,
    required this.onMenu,
    required this.onThemeToggle,
    required this.onSearchTap,
  });

  final DateTime now;
  final TaskView view;
  final bool isDesktop;
  final bool isDark;
  final VoidCallback onCreate;
  final VoidCallback onMenu;
  final VoidCallback onThemeToggle;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return Row(children: [
      if (!isDesktop)
        IconButton(
          tooltip: '打开菜单',
          onPressed: onMenu,
          icon: const Icon(Icons.menu_rounded),
        ),
      if (!isDesktop) const Gap(Space.s2),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${now.year} 年 ${now.month} 月 ${now.day} 日 · ${weekdays[now.weekday - 1]}',
                style: context.textStyles.labelSmall
                    ?.copyWith(color: colors.textSecondary)),
            const Gap(Space.s1),
            Text(view.label, style: context.textStyles.displaySmall),
          ],
        ),
      ),
      if (isDesktop) ...[
        SizedBox(
          width: 180,
          child: OutlinedButton.icon(
            onPressed: onSearchTap,
            icon: const Icon(Icons.search_rounded, size: 17),
            label: const Text('搜索  /'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.s3, vertical: Space.s3),
            ),
          ),
        ),
        const Gap(Space.s2),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded, size: 19),
          label: const Text('新建任务'),
          style: FilledButton.styleFrom(
            backgroundColor: colors.brand,
            foregroundColor: colors.onBrand,
            padding: const EdgeInsets.symmetric(
                horizontal: Space.s4, vertical: Space.s4),
          ),
        ),
      ] else
        IconButton(
          tooltip: isDark ? '切换到浅色模式' : '切换到深色模式',
          onPressed: onThemeToggle,
          icon: Icon(isDark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined),
        ),
    ]);
  }
}

/// Compact summary: replaces the large gradient banner. The number is the
/// overall completion rate, and the label says so (previously "今日进度").
class SummaryBar extends StatelessWidget {
  const SummaryBar({super.key, required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final percent = (summary.ratio * 100).round();
    return Container(
      padding: const EdgeInsets.all(Space.s4),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(RadiusToken.md),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final stacked = constraints.maxWidth < 480;
        final progress = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('总完成率',
                      style: context.textStyles.labelSmall
                          ?.copyWith(color: colors.textSecondary)),
                  Text('$percent%', style: context.textStyles.labelMedium),
                ],
              ),
              const Gap(Space.s2),
              ClipRRect(
                borderRadius: BorderRadius.circular(RadiusToken.pill),
                child: LinearProgressIndicator(
                  value: summary.ratio,
                  minHeight: 6,
                  backgroundColor: colors.borderSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.brand),
                ),
              ),
              const Gap(Space.s2),
              Text('已完成 ${summary.completed} 项 · 待办 ${summary.pending} 项',
                  style: context.textStyles.labelSmall
                      ?.copyWith(color: colors.textSecondary)),
          ],
        );
        final figures = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Figure(value: summary.dueToday, label: '今日 / 逾期', color: colors.brand),
            const Gap(Space.s4),
            _Figure(value: summary.important, label: '重要', color: colors.priorityHigh),
            const Gap(Space.s4),
            _Figure(value: summary.completed, label: '已完成', color: colors.success),
          ],
        );
        return stacked
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                progress,
                const Gap(Space.s4),
                figures,
              ])
            : Row(children: [
                Expanded(child: progress),
                const Gap(Space.s6),
                figures,
              ]);
      }),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value',
              style: context.textStyles.headlineSmall?.copyWith(color: color)),
          Text(label,
              style: context.textStyles.labelSmall
                  ?.copyWith(color: context.colors.textSecondary)),
        ],
      );
}
