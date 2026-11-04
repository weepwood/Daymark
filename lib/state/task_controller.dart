import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/demo_tasks.dart';
import '../data/task_repository.dart';
import '../models/task_item.dart';

enum TaskPhase { loading, ready, readFailure }

enum TaskSaveState { idle, failed }

/// Single source of truth for tasks. All mutations are rejected until [load]
/// completes, which closes the cold-start race where a task created while the
/// repository was still reading could be persisted as the entire task list.
class TaskController extends ChangeNotifier {
  TaskController(this._repository);

  final TaskRepository _repository;
  List<TaskItem> _tasks = [];
  TaskPhase _phase = TaskPhase.loading;
  TaskSaveState _saveState = TaskSaveState.idle;
  Future<void> _pendingWrite = Future<void>.value();
  bool _loadStarted = false;
  bool _closed = false;
  int _nextId = 0;
  int _revision = 0;
  int _skipped = 0;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  TaskPhase get phase => _phase;
  TaskSaveState get saveState => _saveState;
  bool get isLoading => _phase == TaskPhase.loading;
  bool get canEdit => _phase == TaskPhase.ready;
  bool get hasWriteError => _saveState == TaskSaveState.failed;
  int get skippedRecords => _skipped;

  String? get errorMessage => switch (_phase) {
        TaskPhase.loading => null,
        TaskPhase.readFailure => '读取本地数据失败。为避免覆盖旧数据，当前为只读状态。',
        TaskPhase.ready => hasWriteError
            ? '保存失败：任务仍显示在页面上，但尚未写入磁盘，请重试。'
            : null,
      };

  Future<void> load() async {
    if (_loadStarted) return;
    _loadStarted = true;
    try {
      final snapshot = await _repository.read();
      if (snapshot == null) {
        _tasks = demoTasks(DateTime.now());
        // Persist first-launch samples so they never regenerate on next start.
        await _repository.write(_tasks);
      } else {
        _tasks = snapshot.tasks;
        _skipped = snapshot.skipped;
      }
      _phase = TaskPhase.ready;
    } catch (_) {
      _tasks = [];
      _phase = TaskPhase.readFailure;
    }
    _notify();
  }

  Future<void> retryLoad() async {
    if (!_closed) {
      _phase = TaskPhase.loading;
      _loadStarted = false;
      _notify();
    }
    await load();
  }

  /// Waits for queued writes, used on app pause / shutdown.
  Future<void> flush() => _pendingWrite;

  TaskItem? add({
    required String title,
    required String description,
    required TaskCategory category,
    required TaskPriority priority,
    DateTime? dueAt,
  }) {
    if (!_guard()) return null;
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
    if (!_guard()) return;
    if (!_tasks.any((item) => item.id == task.id)) return;
    _tasks = [for (final item in _tasks) if (item.id == task.id) task else item];
    _changed();
  }

  void toggle(TaskItem task) {
    update(task.copyWith(completedAt: task.isCompleted ? null : DateTime.now()));
  }

  void remove(TaskItem task) {
    if (!_guard()) return;
    _tasks = _tasks.where((item) => item.id != task.id).toList();
    _changed();
  }

  void restore(TaskItem task) {
    if (!_guard()) return;
    if (_tasks.any((item) => item.id == task.id)) return;
    _tasks = [..._tasks, task];
    _changed();
  }

  void retrySave() {
    if (!_guard() || !hasWriteError) return;
    _saveState = TaskSaveState.idle;
    _changed();
  }

  Future<bool> restoreBackup() async {
    try {
      return await _repository.restoreBackup();
    } catch (_) {
      return false;
    }
  }

  bool _guard() => _phase == TaskPhase.ready && !_closed;

  void _changed() {
    _notify();
    final revision = ++_revision;
    final snapshot = List<TaskItem>.of(_tasks);
    // Serialized writes + revision guard: only the newest result updates the
    // error state, so an older failure cannot leave the UI stuck in "failed".
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _repository.write(snapshot);
        if (!_closed && revision == _revision && _phase == TaskPhase.ready) {
          _saveState = TaskSaveState.idle;
          _notify();
        }
      } catch (_) {
        if (!_closed && revision == _revision && _phase == TaskPhase.ready) {
          _saveState = TaskSaveState.failed;
          _notify();
        }
      }
    });
  }

  void _notify() {
    if (!_closed) notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}
