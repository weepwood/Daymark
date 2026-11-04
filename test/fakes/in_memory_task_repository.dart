import 'package:daymark_flutter/data/task_repository.dart';
import 'package:daymark_flutter/models/task_item.dart';

/// In-memory repository for controller tests. No platform channels, no mocks.
class InMemoryTaskRepository implements TaskRepository {
  InMemoryTaskRepository({this.snapshot});

  TaskSnapshot? snapshot;
  final List<List<TaskItem>> writes = <List<TaskItem>>[];
  bool failRead = false;
  bool failWrite = false;
  bool backupRestored = false;
  int readCount = 0;
  int writeAttempts = 0;

  /// 1-based index of a single deterministic write failure.
  int failWriteAt = -1;

  @override
  Future<TaskSnapshot?> read() async {
    readCount++;
    if (failRead) throw StateError('storage unavailable');
    return snapshot;
  }

  @override
  Future<void> write(List<TaskItem> tasks) async {
    writeAttempts++;
    if (failWrite || writeAttempts == failWriteAt) {
      throw StateError('write failed');
    }
    final copy = List<TaskItem>.of(tasks);
    writes.add(copy);
    snapshot = TaskSnapshot(copy);
  }

  @override
  Future<bool> restoreBackup() async {
    backupRestored = true;
    return true;
  }
}
