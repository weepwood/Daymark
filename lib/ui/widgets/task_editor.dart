import 'package:flutter/material.dart';

import '../../models/task_item.dart';

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

Future<TaskDraft?> showTaskEditor(BuildContext context, {TaskItem? initial}) {
  if (MediaQuery.sizeOf(context).width < 680) {
    return showModalBottomSheet<TaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: TaskEditor(initial: initial),
      ),
    );
  }
  return showDialog<TaskDraft>(
    context: context,
    builder: (context) => Dialog(
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
    _descriptionController = TextEditingController(text: widget.initial?.description ?? '');
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final editing = widget.initial != null;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .87),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 12, 26, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(editing ? '编辑任务' : '创建新任务',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                  IconButton(tooltip: '关闭', onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 5),
              Text('把要做的事记录下来，按自己的节奏完成。',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 25),
              Text('任务名称', style: theme.textTheme.labelLarge),
              const SizedBox(height: 9),
              TextFormField(
                controller: _titleController,
                autofocus: !editing,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: '例如：完成本周项目计划', counterText: ''),
                validator: (value) => (value == null || value.trim().isEmpty) ? '请输入任务名称' : null,
              ),
              const SizedBox(height: 19),
              Text('备注（可选）', style: theme.textTheme.labelLarge),
              const SizedBox(height: 9),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                minLines: 2,
                maxLength: 500,
                decoration: const InputDecoration(hintText: '添加细节或说明...'),
              ),
              const SizedBox(height: 13),
              Text('任务分类', style: theme.textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in TaskCategory.values)
                    ChoiceChip(
                      label: Text(category.label),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('优先级', style: theme.textTheme.labelLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final priority in TaskPriority.values)
                    ChoiceChip(
                      avatar: Icon(Icons.flag_rounded, size: 16, color: switch (priority) {
                        TaskPriority.high => const Color(0xFFEC6A6A),
                        TaskPriority.medium => const Color(0xFFE6A647),
                        TaskPriority.low => const Color(0xFF55B49A),
                      }),
                      label: Text(priority.label),
                      selected: _priority == priority,
                      onSelected: (_) => setState(() => _priority = priority),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text('截止日期', style: theme.textTheme.labelLarge),
              const SizedBox(height: 9),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 17),
                    label: Text(_dueAt == null ? '设置日期（可选）' :
                        '${_dueAt!.year}-${_dueAt!.month.toString().padLeft(2, '0')}-${_dueAt!.day.toString().padLeft(2, '0')}'),
                  ),
                  if (_dueAt != null)
                    IconButton(
                      tooltip: '清除截止日期',
                      onPressed: () => setState(() => _dueAt = null),
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17)),
                    child: const Text('取消'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton.icon(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 17)),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(editing ? '保存修改' : '创建任务'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
