import '../models/task_item.dart';

/// First-launch sample data. Kept out of the controller so state logic stays
/// focused on state, and so tests can inject a fixed clock.
List<TaskItem> demoTasks(DateTime now) {
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
