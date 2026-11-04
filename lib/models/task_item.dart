enum TaskPriority { low, medium, high }

enum TaskCategory { work, personal, study, health, other }

extension PriorityText on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => '低优先级',
        TaskPriority.medium => '中优先级',
        TaskPriority.high => '高优先级',
      };

  int get sortOrder => switch (this) {
        TaskPriority.high => 0,
        TaskPriority.medium => 1,
        TaskPriority.low => 2,
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

/// Immutable task model. Value equality lets selectors rebuild only changed rows.
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

  static const int schemaVersion = 1;

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
        'v': schemaVersion,
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'priority': priority.name,
        'createdAt': createdAt.toIso8601String(),
        'dueAt': dueAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  /// Tolerant decode: only `id`, `title` and `createdAt` are required.
  /// A single malformed field must never make the whole list unreadable.
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    if (id is! String || title is! String) {
      throw const FormatException('Task is missing id or title');
    }
    final created = _parseDate(json['createdAt']);
    if (created == null) {
      throw const FormatException('Task has an invalid createdAt');
    }

    return TaskItem(
      id: id,
      title: title,
      description: json['description'] is String
          ? json['description'] as String
          : '',
      category:
          readEnum(TaskCategory.values, json['category'], TaskCategory.personal),
      priority:
          readEnum(TaskPriority.values, json['priority'], TaskPriority.medium),
      createdAt: created,
      dueAt: _parseDate(json['dueAt']),
      completedAt: _parseDate(json['completedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.category == category &&
          other.priority == priority &&
          other.createdAt == createdAt &&
          other.dueAt == dueAt &&
          other.completedAt == completedAt;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        description,
        category,
        priority,
        createdAt,
        dueAt,
        completedAt,
      );
}

T readEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
  for (final entry in values) {
    if (entry.name == value) return entry;
  }
  return fallback;
}

const _unchanged = Object();
