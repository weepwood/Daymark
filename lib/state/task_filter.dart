import '../models/task_item.dart';

enum TaskView { all, today, upcoming, important, completed }

extension TaskViewText on TaskView {
  String get label => switch (this) {
        TaskView.all => '全部任务',
        TaskView.today => '今天',
        TaskView.upcoming => '即将到期',
        TaskView.important => '重要任务',
        TaskView.completed => '已完成',
      };
}

int compareDays(DateTime a, DateTime b) {
  final left = DateTime.utc(a.year, a.month, a.day);
  final right = DateTime.utc(b.year, b.month, b.day);
  return left.compareTo(right);
}

bool isOverdue(TaskItem task, DateTime now) =>
    !task.isCompleted &&
    task.dueAt != null &&
    compareDays(task.dueAt!, now) < 0;

List<TaskItem> filterTasks(
  Iterable<TaskItem> tasks, {
  TaskView view = TaskView.all,
  String query = '',
  TaskCategory? category,
  TaskPriority? priority,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();
  final needle = query.trim().toLowerCase();
  final filtered = tasks.where((task) {
    if (category != null && task.category != category) return false;
    if (priority != null && task.priority != priority) return false;
    if (needle.isNotEmpty &&
        !task.title.toLowerCase().contains(needle) &&
        !task.description.toLowerCase().contains(needle)) {
      return false;
    }
    return switch (view) {
      TaskView.all => true,
      TaskView.today => !task.isCompleted && task.dueAt != null &&
          compareDays(task.dueAt!, today) <= 0,
      TaskView.upcoming => !task.isCompleted && task.dueAt != null &&
          compareDays(task.dueAt!, today) > 0,
      TaskView.important => !task.isCompleted && task.priority == TaskPriority.high,
      TaskView.completed => task.isCompleted,
    };
  }).toList();

  filtered.sort((a, b) {
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    if (a.dueAt != null && b.dueAt != null) {
      final dateSort = compareDays(a.dueAt!, b.dueAt!);
      if (dateSort != 0) return dateSort;
    } else if (a.dueAt != null) {
      return -1;
    } else if (b.dueAt != null) {
      return 1;
    }
    if (a.priority != b.priority) return b.priority.index.compareTo(a.priority.index);
    return b.createdAt.compareTo(a.createdAt);
  });
  return filtered;
}
