import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/task_repository.dart';
import '../models/task_item.dart';

class TaskController extends ChangeNotifier {
  TaskController(this._repository);

  final TaskRepository _repository;
  List<TaskItem> _tasks = [];
  bool _isLoading = true;
  String? _error;
  Future<void> _pendingWrite = Future<void>.value();
  int _nextId = 0;
  bool _loadFailed = false;
  bool _closed = false;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    try {
      _tasks = await _repository.read() ?? _demoTasks(DateTime.now());
      _error = null;
      _loadFailed = false;
    } catch (_) {
      _loadFailed = true;
      _error = '读取本地数据失败。为避免覆盖旧数据，当前已关闭保存功能。';
      _tasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  TaskItem add({
    required String title,
    required String description,
    required TaskCategory category,
    required TaskPriority priority,
    DateTime? dueAt,
  }) {
    final now = DateTime.now();
    final task = TaskItem(
      id: '${now.microsecondsSinceEpoch}-${_nextId++}',
      title: title.trim(),
      description: description.trim(),
      category: category,
      priority: priority,
      dueAt: dueAt,
      createdAt: now,
    );
    _tasks = [..._tasks, task];
    _changed();
    return task;
  }

  void update(TaskItem task) {
    _tasks = [for (final item in _tasks) if (item.id == task.id) task else item];
    _changed();
  }

  void toggle(TaskItem task) {
    update(task.copyWith(completedAt: task.isCompleted ? null : DateTime.now()));
  }

  void remove(TaskItem task) {
    _tasks = _tasks.where((item) => item.id != task.id).toList();
    _changed();
  }

  void restore(TaskItem task) {
    if (_tasks.any((item) => item.id == task.id)) return;
    _tasks = [..._tasks, task];
    _changed();
  }

  void retrySave() {
    if (_loadFailed) return;
    _error = null;
    _changed();
  }

  void _changed() {
    if (_closed) return;
    notifyListeners();
    if (_error != null) return;
    final snapshot = List<TaskItem>.of(_tasks);
    // Serialize writes: a slow older snapshot can never overwrite a newer one.
    _pendingWrite = _pendingWrite.then((_) => _repository.write(snapshot)).catchError((Object _) {
      _error = '保存失败：任务仍保留在当前页面，请检查设备存储后重试。';
      if (!_closed) notifyListeners();
    });
  }
  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}

List<TaskItem> _demoTasks(DateTime now) {
  DateTime date(int offset) => DateTime(now.year, now.month, now.day + offset);
  TaskItem item(
    String id,
    String title,
    TaskCategory category,
    TaskPriority priority,
    int? dueOffset, {
    String description = '',
    bool done = false,
  }) =>
      TaskItem(
        id: 'demo-$id',
        title: title,
        description: description,
        category: category,
        priority: priority,
        createdAt: now.subtract(const Duration(days: 1)),
        dueAt: dueOffset == null ? null : date(dueOffset),
        completedAt: done ? now : null,
      );

  return [
    item('1', '整理本周任务计划', TaskCategory.work, TaskPriority.high, 0,
        description: '确定优先级并安排各项工作时间'),
    item('2', '完成 Flutter 首页布局', TaskCategory.work, TaskPriority.high, 0),
    item('3', '阅读 30 分钟', TaskCategory.study, TaskPriority.medium, 1),
    item('4', '运动与拉伸', TaskCategory.health, TaskPriority.low, 2),
    item('5', '整理个人设计资源库', TaskCategory.personal, TaskPriority.medium, 4),
    item('6', '梳理产品需求', TaskCategory.work, TaskPriority.medium, -1, done: true),
  ];
}
