import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';
import 'task_repository.dart';

class PrefsTaskRepository implements TaskRepository {
  PrefsTaskRepository(this._preferences);

  static const tasksKey = 'daymark.tasks.v1';
  static const backupKey = 'daymark.tasks.backup';

  final SharedPreferencesAsync _preferences;

  @override
  Future<TaskSnapshot?> read() async {
    final raw = await _preferences.getString(tasksKey);
    if (raw == null) return null;

    // Keep the raw payload before touching it, so a corrupt file is recoverable.
    await _preferences.setString(backupKey, raw);

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Stored tasks are not a JSON list');
    }

    final tasks = <TaskItem>[];
    var skipped = 0;
    for (final entry in decoded) {
      try {
        if (entry is Map<String, dynamic>) {
          tasks.add(TaskItem.fromJson(entry));
        } else if (entry is Map) {
          tasks.add(TaskItem.fromJson(Map<String, dynamic>.from(entry)));
        } else {
          skipped++;
        }
      } catch (_) {
        skipped++;
      }
    }
    return TaskSnapshot(tasks, skipped: skipped);
  }

  @override
  Future<void> write(List<TaskItem> tasks) async {
    final payload = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await _preferences.setString(tasksKey, payload);
  }

  @override
  Future<bool> restoreBackup() async {
    final backup = await _preferences.getString(backupKey);
    if (backup == null) return false;
    await _preferences.setString(tasksKey, backup);
    return true;
  }
}
