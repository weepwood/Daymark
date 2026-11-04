import 'package:flutter_test/flutter_test.dart';
import 'package:daymark_flutter/models/task_item.dart';
import 'package:daymark_flutter/state/task_filter.dart';

void main() {
  final now = DateTime(2026, 11, 4, 14);
  final sample = <TaskItem>[
    TaskItem(id: 'overdue', title: '交付报告', description: '项目总结',
        createdAt: now, dueAt: DateTime(2026, 11, 2), priority: TaskPriority.high,
        category: TaskCategory.work),
    TaskItem(id: 'today', title: '今天阅读', createdAt: now,
        dueAt: DateTime(2026, 11, 4), category: TaskCategory.study),
    TaskItem(id: 'upcoming', title: '后天运动', createdAt: now,
        dueAt: DateTime(2026, 11, 6), category: TaskCategory.health),
    TaskItem(id: 'done', title: '已完成事项', createdAt: now,
        dueAt: DateTime(2026, 11, 2), completedAt: now),
  ];

  test('today includes overdue and today, excluding completed', () {
    final result = filterTasks(sample, view: TaskView.today, now: now);
    expect(result.map((t) => t.id), ['overdue', 'today']);
  });

  test('upcoming shows only future incomplete tasks', () {
    final result = filterTasks(sample, view: TaskView.upcoming, now: now);
    expect(result.map((t) => t.id), ['upcoming']);
  });

  test('important and completed views are independent', () {
    expect(filterTasks(sample, view: TaskView.important, now: now).single.id, 'overdue');
    expect(filterTasks(sample, view: TaskView.completed, now: now).single.id, 'done');
  });

  test('search supports description and can combine category', () {
    final result = filterTasks(sample, query: '项目总结', category: TaskCategory.work, now: now);
    expect(result.single.id, 'overdue');
    expect(filterTasks(sample, query: '项目总结', category: TaskCategory.health, now: now), isEmpty);
  });

  test('date comparison ignores time-of-day', () {
    expect(compareDays(DateTime(2026, 11, 4, 23), DateTime(2026, 11, 4, 1)), 0);
    expect(isOverdue(sample.first, now), true);
    expect(isOverdue(sample.last, now), false);
  });
}
