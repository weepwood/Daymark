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

  test('priority filter sentinel maps to a nullable priority', () {
    expect(PriorityFilter.all.priority, isNull);
    expect(PriorityFilter.high.priority, TaskPriority.high);
    expect(PriorityFilter.values.every((v) => v.label.isNotEmpty), isTrue);
  });

  test('summary distinguishes overall completion from today load', () {
    final summary = summarize(sample, now);
    expect(summary.total, 4);
    expect(summary.completed, 1);
    expect(summary.pending, 3);
    expect(summary.dueToday, 2);
    expect(summary.important, 1);
    expect(summary.ratio, 0.25);
  });

  test('completed view sorts by completion time, not due date', () {
    final older = TaskItem(id: 'older', title: '旧', createdAt: now,
        dueAt: DateTime(2026, 11, 3), completedAt: DateTime(2026, 11, 1));
    final newer = TaskItem(id: 'newer', title: '新', createdAt: now,
        dueAt: DateTime(2026, 11, 1), completedAt: DateTime(2026, 11, 4));
    final result = filterTasks([older, newer], view: TaskView.completed, now: now);
    expect(result.map((t) => t.id), ['newer', 'older']);
  });

  test('view counts match their filters', () {
    for (final view in TaskView.values) {
      expect(countForView(sample, view, now),
          filterTasks(sample, view: view, now: now).length);
    }
  });
}
