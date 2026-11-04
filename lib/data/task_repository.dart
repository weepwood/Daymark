import '../models/task_item.dart';

/// Result of a read. [skipped] counts malformed entries that were isolated
/// instead of failing the whole load.
class TaskSnapshot {
  const TaskSnapshot(this.tasks, {this.skipped = 0});

  final List<TaskItem> tasks;
  final int skipped;
}

/// Abstract boundary: swapping JSON storage for Drift / cloud sync later only
/// requires a new implementation, and makes the controller unit-testable.
abstract interface class TaskRepository {
  /// Returns null on first launch. An empty list means "user deleted everything".
  Future<TaskSnapshot?> read();

  Future<void> write(List<TaskItem> tasks);

  /// Restores the last raw payload, used by the read-failure recovery action.
  Future<bool> restoreBackup();
}
