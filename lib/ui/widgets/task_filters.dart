import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../models/task_item.dart';
import '../../state/task_filter.dart';
import '../../theme/app_tokens.dart';

class TaskSearchBar extends StatelessWidget {
  const TaskSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    required this.onClear,
    this.focusNode,
    this.controller,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final FocusNode? focusNode;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => TextField(
        key: const ValueKey('task_search'),
        focusNode: focusNode,
        controller: controller,
        onChanged: onChanged,
        style: context.textStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: '搜索任务名称或备注...',
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: '清空搜索',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 17),
                ),
        ),
      );
}

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.category,
    required this.priorityFilter,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.visibleCount,
  });

  final TaskCategory? category;
  final PriorityFilter priorityFilter;
  final ValueChanged<TaskCategory?> onCategoryChanged;
  final ValueChanged<PriorityFilter> onPriorityChanged;
  final int visibleCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('任务清单', style: context.textStyles.headlineSmall),
          const Gap(Space.s2),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: Space.s2, vertical: 2),
            decoration: BoxDecoration(
              color: colors.selectedBg,
              borderRadius: BorderRadius.circular(RadiusToken.pill),
            ),
            child: Text('$visibleCount',
                style: context.textStyles.labelSmall
                    ?.copyWith(color: colors.brand)),
          ),
          const Spacer(),
          // Sentinel enum keeps every popup value non-null, so "全部优先级"
          // actually reaches onSelected (previously treated as a cancellation).
          PopupMenuButton<PriorityFilter>(
            tooltip: '按优先级筛选',
            initialValue: priorityFilter,
            onSelected: onPriorityChanged,
            itemBuilder: (context) => [
              for (final value in PriorityFilter.values)
                PopupMenuItem<PriorityFilter>(
                  value: value,
                  child: Text(value.label),
                ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Space.s3, vertical: Space.s3),
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                border: Border.all(color: colors.borderSubtle),
                borderRadius: BorderRadius.circular(RadiusToken.sm),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.tune_rounded,
                    size: 17,
                    color: priorityFilter == PriorityFilter.all
                        ? colors.textSecondary
                        : colors.brand),
                const Gap(Space.s2),
                Text(
                  priorityFilter == PriorityFilter.all
                      ? '筛选'
                      : priorityFilter.label,
                  style: context.textStyles.labelSmall,
                ),
              ]),
            ),
          ),
        ]),
        const Gap(Space.s3),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(right: Space.s2),
              child: ChoiceChip(
                label: const Text('全部分类'),
                selected: category == null,
                onSelected: (_) => onCategoryChanged(null),
              ),
            ),
            for (final value in TaskCategory.values)
              Padding(
                padding: const EdgeInsets.only(right: Space.s2),
                child: ChoiceChip(
                  label: Text(value.label),
                  selected: category == value,
                  onSelected: (_) => onCategoryChanged(value),
                ),
              ),
          ]),
        ),
      ],
    );
  }
}
