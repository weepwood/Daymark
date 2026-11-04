enum TaskPriority { low, medium, high }

enum TaskCategory { work, personal, study, health, other }

extension PriorityText on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => '低优先级',
        TaskPriority.medium => '中优先级',
        TaskPriority.high => '高优先级',
      };
}

extension CategoryText on TaskCategory {
  String get label => switch (this) {
        TaskCategory.work => '工作',
        TaskCategory.personal => '生活',
        TaskCategory.study => '学习',
        TaskCategory.health => '健康',
        TaskCategory.other => '其他',
      };
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.createdAt,
    this.description = '',
    this.category = TaskCategory.personal,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  TaskItem copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    Object? dueAt = _unchanged,
    Object? completedAt = _unchanged,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      dueAt: identical(dueAt, _unchanged) ? this.dueAt : dueAt as DateTime?,
      completedAt: identical(completedAt, _unchanged)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'dueAt': dueAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    T readEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
      for (final entry in values) {
        if (entry.name == value) return entry;
      }
      return fallback;
    }

    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: readEnum(TaskCategory.values, json['category'], TaskCategory.personal),
      priority: readEnum(TaskPriority.values, json['priority'], TaskPriority.medium),
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueAt: json['dueAt'] == null ? null : DateTime.parse(json['dueAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}

const _unchanged = Object();
