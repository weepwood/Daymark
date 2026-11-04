import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../models/task_item.dart';
import '../../state/task_filter.dart';
import '../../theme/app_tokens.dart';

Widget boxed(Widget child) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: SizeToken.contentMaxWidth),
        child: child,
      ),
    );

/// A real lazy list (SliverList), not a for-loop inside SingleChildScrollView.
class TaskListSliver extends StatelessWidget {
  const TaskListSliver({
    super.key,
    required this.tasks,
    required this.now,
    required this.compact,
    required this.loading,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TaskItem> tasks;
  final DateTime now;
  final bool compact;
  final bool loading;
  final ValueChanged<TaskItem> onToggle;
  final ValueChanged<TaskItem> onEdit;
  final ValueChanged<TaskItem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SliverToBoxAdapter(
        child: boxed(const Skeletonizer(
          enabled: true,
          child: _SkeletonList(),
        )),
      );
    }
    if (tasks.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final task = tasks[index];
          return RepaintBoundary(
            key: ValueKey(task.id),
            child: boxed(
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s3),
                child: TaskTile(
                  task: task,
                  now: now,
                  compact: compact,
                  onToggle: () => onToggle(task),
                  onEdit: () => onEdit(task),
                  onDelete: () => onDelete(task),
                ),
              ),
            ),
          );
        },
        childCount: tasks.length,
      ),
    );
  }
}

class TaskTile extends StatefulWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.now,
    required this.compact,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final DateTime now;
  final bool compact;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final card = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: _TaskCard(
        task: widget.task,
        now: widget.now,
        showInlineActions: !widget.compact && _hovered,
        onToggle: widget.onToggle,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
      ),
    );

    if (!widget.compact) return card;

    final colors = context.colors;
    return Slidable(
      key: ValueKey(widget.task.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onToggle(),
            backgroundColor: colors.success,
            foregroundColor: Colors.white,
            icon: widget.task.isCompleted
                ? Icons.undo_rounded
                : Icons.check_rounded,
            label: widget.task.isCompleted ? '取消' : '完成',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: colors.priorityHigh,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline_rounded,
            label: '删除',
          ),
        ],
      ),
      child: card,
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.now,
    required this.showInlineActions,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final DateTime now;
  final bool showInlineActions;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final overdue = isOverdue(task, now);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(RadiusToken.md),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(Space.s4),
          child: Row(children: [
            Semantics(
              label: task.isCompleted ? '标记为未完成' : '完成任务',
              button: true,
              child: IconButton(
                tooltip: task.isCompleted ? '标记为未完成' : '标记为完成',
                onPressed: onToggle,
                constraints: const BoxConstraints(
                  minWidth: SizeToken.touchTarget,
                  minHeight: SizeToken.touchTarget,
                ),
                icon: Icon(
                  task.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: task.isCompleted ? colors.success : colors.textSecondary,
                  size: 24,
                ),
              ),
            ),
            const Gap(Space.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleMedium?.copyWith(
                      decoration:
                          task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted
                          ? colors.textSecondary
                          : colors.textPrimary,
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const Gap(Space.s1),
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                  const Gap(Space.s2),
                  Wrap(
                    spacing: Space.s3,
                    runSpacing: Space.s1,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Meta(
                        icon: _categoryIcon(task.category),
                        label: task.category.label,
                        color: colors.textSecondary,
                      ),
                      if (task.dueAt != null)
                        _Meta(
                          icon: Icons.calendar_today_outlined,
                          label: _dueText(task.dueAt!, now, overdue),
                          color: overdue ? colors.overdue : colors.textSecondary,
                          bold: overdue,
                        ),
                      if (task.isCompleted && task.completedAt != null)
                        _Meta(
                          icon: Icons.check_rounded,
                          label: '已完成',
                          color: colors.success,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(Space.s2),
            PriorityBadge(priority: task.priority),
            if (showInlineActions)
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: '编辑',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                ),
              ]),
          ]),
        ),
      ),
    );
  }
}

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = context.colors.priority(priority);
    final short = switch (priority) {
      TaskPriority.high => '高',
      TaskPriority.medium => '中',
      TaskPriority.low => '低',
    };
    return Semantics(
      label: priority.label,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(Space.s1),
        Text(short,
            style: context.textStyles.labelSmall?.copyWith(color: color)),
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    required this.color,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const Gap(Space.s1),
          Text(
            label,
            style: (bold
                    ? context.textStyles.labelMedium
                    : context.textStyles.labelSmall)
                ?.copyWith(color: color),
          ),
        ],
      );
}

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
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;
  if (difference == 0) return '今天截止';
  if (difference == 1) return '明天截止';
  return '${date.month}/${date.day} 截止';
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s3),
              child: Card(
                child: ListTile(
                  leading: const CircleAvatar(radius: 12),
                  title: Text('加载任务占位标题 $i'),
                  subtitle: const Text('分类 · 截止日期 · 优先级'),
                ),
              ),
            ),
        ],
      );
}
