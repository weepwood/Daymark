import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../models/task_item.dart';
import '../../theme/app_tokens.dart';

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.dueAt,
  });

  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime? dueAt;
}

/// One editor, two presentations chosen by the shared breakpoint.
Future<TaskDraft?> showTaskEditor(BuildContext context, {TaskItem? initial}) {
  final compact = breakpointOf(MediaQuery.sizeOf(context).width) ==
      AppBreakpoint.compact;
  if (compact) {
    return showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.colors.surfaceRaised,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: TaskEditor(initial: initial),
      ),
    );
  }
  return showDialog<TaskDraft>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: context.colors.surfaceRaised,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 530),
        child: TaskEditor(initial: initial),
      ),
    ),
  );
}

class TaskEditor extends StatefulWidget {
  const TaskEditor({super.key, this.initial});

  final TaskItem? initial;

  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskCategory _category;
  late TaskPriority _priority;
  DateTime? _dueAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.initial?.description ?? '');
    _category = widget.initial?.category ?? TaskCategory.work;
    _priority = widget.initial?.priority ?? TaskPriority.medium;
    _dueAt = widget.initial?.dueAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: '选择截止日期',
    );
    if (selected != null && mounted) setState(() => _dueAt = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(TaskDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      priority: _priority,
      dueAt: _dueAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final editing = widget.initial != null;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
      },
      child: Focus(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .87),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                Space.s6, Space.s3, Space.s6, Space.s6),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(editing ? '编辑任务' : '创建新任务',
                          style: context.textStyles.headlineSmall),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ]),
                  Text('把要做的事记录下来，按自己的节奏完成。',
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: colors.textSecondary)),
                  const Gap(Space.s6),
                  Text('任务名称', style: context.textStyles.labelMedium),
                  const Gap(Space.s2),
                  TextFormField(
                    controller: _titleController,
                    autofocus: !editing,
                    maxLength: 100,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: '例如：完成本周项目计划',
                      counterText: '',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? '请输入任务名称' : null,
                  ),
                  const Gap(Space.s4),
                  Text('备注（可选）', style: context.textStyles.labelMedium),
                  const Gap(Space.s2),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    minLines: 2,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: '添加细节或说明...',
                      counterText: '',
                    ),
                  ),
                  const Gap(Space.s3),
                  Text('任务分类', style: context.textStyles.labelMedium),
                  const Gap(Space.s2),
                  Wrap(
                    spacing: Space.s2,
                    runSpacing: Space.s2,
                    children: [
                      for (final value in TaskCategory.values)
                        ChoiceChip(
                          label: Text(value.label),
                          selected: _category == value,
                          onSelected: (_) => setState(() => _category = value),
                        ),
                    ],
                  ),
                  const Gap(Space.s4),
                  Text('优先级', style: context.textStyles.labelMedium),
                  const Gap(Space.s2),
                  Wrap(
                    spacing: Space.s2,
                    runSpacing: Space.s2,
                    children: [
                      for (final value in TaskPriority.values)
                        ChoiceChip(
                          avatar: Icon(Icons.flag_rounded,
                              size: 15, color: colors.priority(value)),
                          label: Text(value.label),
                          selected: _priority == value,
                          onSelected: (_) => setState(() => _priority = value),
                        ),
                    ],
                  ),
                  const Gap(Space.s4),
                  Text('截止日期', style: context.textStyles.labelMedium),
                  const Gap(Space.s2),
                  Wrap(
                    spacing: Space.s2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final (label, days) in [
                        ('今天', 0),
                        ('明天', 1),
                        ('下周', 7),
                      ])
                        ActionChip(
                          label: Text(label),
                          onPressed: () => setState(
                            () => _dueAt =
                                _today.add(Duration(days: days)),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: _selectDate,
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(_dueAt == null
                            ? '选择日期'
                            : '${_dueAt!.year}-${_dueAt!.month.toString().padLeft(2, '0')}-${_dueAt!.day.toString().padLeft(2, '0')}'),
                      ),
                      if (_dueAt != null)
                        IconButton(
                          tooltip: '清除截止日期',
                          onPressed: () => setState(() => _dueAt = null),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                    ],
                  ),
                  const Gap(Space.s6),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(Space.s4)),
                        child: const Text('取消'),
                      ),
                    ),
                    const Gap(Space.s3),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.brand,
                          foregroundColor: colors.onBrand,
                          padding: const EdgeInsets.all(Space.s4),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(editing ? '保存修改' : '创建任务'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
