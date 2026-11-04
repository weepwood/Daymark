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

/// Sentinel enum for the priority popup. Using `null` as the "all" value is a
/// bug: PopupMenuButton treats a null result as a cancelled menu, so onSelected
/// never fires and the filter cannot be cleared.
enum PriorityFilter { all, low, medium, high }

extension PriorityFilterValue on PriorityFilter {
  TaskPriority? get priority => switch (this) {
        PriorityFilter.all => null,
        PriorityFilter.low => TaskPriority.low,
        PriorityFilter.medium => TaskPriority.medium,
        PriorityFilter.high => TaskPriority.high,
      };

  String get label => switch (this) {
        PriorityFilter.all => '全部优先级',
        PriorityFilter.low => TaskPriority.low.label,
        PriorityFilter.medium => TaskPriority.medium.label,
        PriorityFilter.high => TaskPriority.high.label,
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

class TaskSummary {
  const TaskSummary({
    required this.total,
    required this.completed,
    required this.pending,
    required this.dueToday,
    required this.important,
  });

  final int total;
  final int completed;
  final int pending;
  final int dueToday;
  final int important;

  double get ratio => total == 0 ? 0 : completed / total;
}

TaskSummary summarize(Iterable<TaskItem> tasks, DateTime now) {
  var completed = 0;
  var dueToday = 0;
  var important = 0;
  var total = 0;
  for (final task in tasks) {
    total++;
    if (task.isCompleted) {
      completed++;
      continue;
    }
    if (task.dueAt != null && compareDays(task.dueAt!, now) <= 0) dueToday++;
    if (task.priority == TaskPriority.high) important++;
  }
  return TaskSummary(
    total: total,
    completed: completed,
    pending: total - completed,
    dueToday: dueToday,
    important: important,
  );
}

int countForView(Iterable<TaskItem> tasks, TaskView view, DateTime now) {
  switch (view) {
    case TaskView.all:
      return tasks.length;
    case TaskView.today:
      return tasks
          .where((t) =>
              !t.isCompleted &&
              t.dueAt != null &&
              compareDays(t.dueAt!, now) <= 0)
          .length;
    case TaskView.upcoming:
      return tasks
          .where((t) =>
              !t.isCompleted &&
              t.dueAt != null &&
              compareDays(t.dueAt!, now) > 0)
          .length;
    case TaskView.important:
      return tasks
          .where((t) => !t.isCompleted && t.priority == TaskPriority.high)
          .length;
    case TaskView.completed:
      return tasks.where((t) => t.isCompleted).length;
  }
}

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
      TaskView.today => !task.isCompleted &&
          task.dueAt != null &&
          compareDays(task.dueAt!, today) <= 0,
      TaskView.upcoming => !task.isCompleted &&
          task.dueAt != null &&
          compareDays(task.dueAt!, today) > 0,
      TaskView.important =>
        !task.isCompleted && task.priority == TaskPriority.high,
      TaskView.completed => task.isCompleted,
    };
  }).toList();

  if (view == TaskView.completed) {
    // Most recently completed first, not by due date.
    filtered.sort((a, b) {
      final left = a.completedAt;
      final right = b.completedAt;
      if (left != null && right != null) return right.compareTo(left);
      return b.createdAt.compareTo(a.createdAt);
    });
    return filtered;
  }

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
    final order = a.priority.sortOrder.compareTo(b.priority.sortOrder);
    if (order != 0) return order;
    return b.createdAt.compareTo(a.createdAt);
  });
  return filtered;
}
