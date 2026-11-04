import 'package:flutter_test/flutter_test.dart';
import 'package:daymark_flutter/models/task_item.dart';

void main() {
  final created = DateTime(2026, 11, 4, 8, 30);
  final due = DateTime(2026, 11, 7);
  final sample = TaskItem(
    id: 'task-1',
    title: '测试序列化',
    description: '描述文本',
    category: TaskCategory.study,
    priority: TaskPriority.high,
    createdAt: created,
    dueAt: due,
  );

  test('JSON round-trip preserves task attributes', () {
    final decoded = TaskItem.fromJson(sample.toJson());
    expect(decoded.id, 'task-1');
    expect(decoded.title, '测试序列化');
    expect(decoded.description, '描述文本');
    expect(decoded.category, TaskCategory.study);
    expect(decoded.priority, TaskPriority.high);
    expect(decoded.createdAt, created);
    expect(decoded.dueAt, due);
    expect(decoded.isCompleted, false);
  });

  test('copyWith supports explicitly clearing nullable fields', () {
    final completed = sample.copyWith(completedAt: DateTime(2026, 11, 4));
    expect(completed.isCompleted, true);
    final reset = completed.copyWith(completedAt: null, dueAt: null);
    expect(reset.isCompleted, false);
    expect(reset.dueAt, isNull);
    expect(reset.id, sample.id);
  });

  test('unknown enum values fall back safely', () {
    final decoded = TaskItem.fromJson({
      ...sample.toJson(),
      'priority': 'unknown',
      'category': 'unknown',
    });
    expect(decoded.priority, TaskPriority.medium);
    expect(decoded.category, TaskCategory.personal);
  });
}
