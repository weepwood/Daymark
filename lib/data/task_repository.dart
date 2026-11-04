import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_item.dart';

class TaskRepository {
  TaskRepository(this._preferences);

  static const _tasksKey = 'daymark.tasks.v1';
  final SharedPreferencesAsync _preferences;

  /// Returns null on first launch, and an empty list when all tasks are deleted.
  Future<List<TaskItem>?> read() async {
    final raw = await _preferences.getString(_tasksKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => TaskItem.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<void> write(List<TaskItem> tasks) async {
    final payload = jsonEncode(tasks.map((task) => task.toJson()).toList());
    await _preferences.setString(_tasksKey, payload);
  }
}
