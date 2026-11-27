import 'package:material_ui/material_ui.dart';

enum AppTab { home, progress, badges, completed }

enum ActivityTimeframe { week, month, year }

class Habit {
  final String id;
  final String name;
  final String color;
  final String createdAt;
  final int targetDays;
  final String? completedAt;
  final String? category;
  final String? notes;

  const Habit({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    required this.targetDays,
    this.completedAt,
    this.category,
    this.notes,
  });

  Habit copyWith({
    String? id,
    String? name,
    String? color,
    String? createdAt,
    int? targetDays,
    String? completedAt,
    bool clearCompletedAt = false,
    String? category,
    String? notes,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      targetDays: targetDays ?? this.targetDays,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      color: (json['color'] ?? '#fa114f').toString(),
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      targetDays: (json['targetDays'] is num)
          ? (json['targetDays'] as num).toInt()
          : int.tryParse('${json['targetDays'] ?? 0}') ?? 0,
      completedAt: json['completedAt'] as String?,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'createdAt': createdAt,
      'targetDays': targetDays,
      if (completedAt != null) 'completedAt': completedAt,
      if (category != null) 'category': category,
      if (notes != null) 'notes': notes,
    };
  }
}

class TodoModel {
  final String id;
  final String text;
  final bool completed;
  final String createdAt;

  /// Optional 24-hour reminder time formatted as `"HH:mm"`.
  final String? reminderTime;

  const TodoModel({
    required this.id,
    required this.text,
    required this.completed,
    required this.createdAt,
    this.reminderTime,
  });

  /// Normalizes a `"HH:mm"` string or returns `null` if empty or invalid.
  static String? normalizeReminderTime(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == 'null') return null;
    final parts = trimmed.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Parses `"HH:mm"` into `(hour, minute)` or returns `null`.
  static ({int hour, int minute})? parseReminderTime(String? raw) {
    final normalized = normalizeReminderTime(raw);
    if (normalized == null) return null;
    final parts = normalized.split(':');
    return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Formats `"HH:mm"` as human-readable 12-hour time such as `"9:30 AM"`.
  static String? formatReminderTime(String? raw) {
    final parsed = parseReminderTime(raw);
    if (parsed == null) return null;
    final period = parsed.hour >= 12 ? 'PM' : 'AM';
    final displayHour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final displayMinute = parsed.minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  TodoModel copyWith({
    String? id,
    String? text,
    bool? completed,
    String? createdAt,
    String? reminderTime,
    bool clearReminderTime = false,
  }) {
    return TodoModel(
      id: id ?? this.id,
      text: text ?? this.text,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      reminderTime:
          clearReminderTime ? null : (reminderTime ?? this.reminderTime),
    );
  }

  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: (json['id'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      completed: json['completed'] == true,
      createdAt:
          (json['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
      reminderTime: normalizeReminderTime(json['reminderTime']?.toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
      'createdAt': createdAt,
      if (reminderTime != null) 'reminderTime': reminderTime,
    };
  }
}

class HabitColorOption {
  final String name;
  final String hex;
  final Color color;

  const HabitColorOption({
    required this.name,
    required this.hex,
    required this.color,
  });
}

class HabitCategoryOption {
  final String value;
  final String label;
  final IconData icon;

  const HabitCategoryOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

enum BadgeCriteriaType { completions, streak }

class GlobalBadge {
  final String id;
  final String name;
  final String desc;
  final IconData icon;
  final int req;
  final BadgeCriteriaType type;
  final String tier;

  const GlobalBadge({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.req,
    required this.type,
    required this.tier,
  });
}

class HabitMilestone {
  final String tier;
  final int req;
  final IconData icon;

  const HabitMilestone({
    required this.tier,
    required this.req,
    required this.icon,
  });
}

class IndividualHabitBadge {
  final String id;
  final String name;
  final String desc;
  final IconData icon;
  final int req;
  final String tier;
  final String habitId;
  final String habitColor;

  const IndividualHabitBadge({
    required this.id,
    required this.name,
    required this.desc,
    required this.icon,
    required this.req,
    required this.tier,
    required this.habitId,
    required this.habitColor,
  });
}

class TierStyle {
  final Color textColor;
  final Color borderColor;
  final Color bgTop;
  final Color bgBottom;
  final Color shadowColor;
  final Color glowColor;

  const TierStyle({
    required this.textColor,
    required this.borderColor,
    required this.bgTop,
    required this.bgBottom,
    required this.shadowColor,
    required this.glowColor,
  });
}

class DailyQuote {
  final String text;
  final String author;

  const DailyQuote({required this.text, required this.author});
}

class ChartBarPoint {
  final String label;
  final double value;
  final double max;
  final bool isToday;
  final bool isCompleted;
  final String tooltip;

  const ChartBarPoint({
    required this.label,
    required this.value,
    required this.max,
    required this.isToday,
    this.isCompleted = false,
    this.tooltip = '',
  });
}

class HourlyBucket {
  final int hour;
  final String label;
  final int value;
  final int max;

  const HourlyBucket({
    required this.hour,
    required this.label,
    required this.value,
    required this.max,
  });
}

class UserStats {
  final int totalCompletionsCount;
  final int totalPoints;
  final int maxStreakDays;
  final String rank;

  const UserStats({
    required this.totalCompletionsCount,
    required this.totalPoints,
    required this.maxStreakDays,
    required this.rank,
  });
}

class NoteDraft {
  final String habitId;
  final String date;
  final String content;

  const NoteDraft({
    required this.habitId,
    required this.date,
    required this.content,
  });

  NoteDraft copyWith({String? content}) {
    return NoteDraft(
      habitId: habitId,
      date: date,
      content: content ?? this.content,
    );
  }
}
