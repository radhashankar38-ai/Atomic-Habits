import 'dart:math' as math;
import '../constants/app_constants.dart';
import '../models/habit.dart';

String formatDate(DateTime date) {
  final local = date.isUtc ? date.toLocal() : date;
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

bool isDateCompleted(List<String>? completions, String dateStr) {
  if (completions == null || completions.isEmpty) return false;
  return completions.any((c) {
    if (c.endsWith('Z') || (c.length > 10 && c.contains('+'))) {
      final parsed = _parseLocalDateTime(c);
      if (parsed != null) return formatDate(parsed) == dateStr;
    }
    return c.startsWith(dateStr);
  });
}

DateTime? _parseLocalDateTime(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

int calculateStreak(
  List<String>? completions,
  String? createdAt, {
  DateTime? nowOverride,
}) {
  if (completions == null) return 0;

  final today = nowOverride ?? DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayStr = formatDate(todayStart);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final yesterdayStr = formatDate(yesterday);

  final todayCompleted = isDateCompleted(completions, todayStr);
  final yesterdayCompleted = isDateCompleted(completions, yesterdayStr);

  if (todayCompleted || yesterdayCompleted) {
    var count = 0;
    var checkDate = todayCompleted ? todayStart : yesterday;
    while (isDateCompleted(completions, formatDate(checkDate))) {
      count++;
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      if (count > 1000) break;
    }
    return ((count * count) / 2).ceil();
  } else {
    var count = 0;
    var checkDate = yesterday;
    DateTime? startLimit;
    if (createdAt != null && createdAt.isNotEmpty) {
      final parsed = _parseLocalDateTime(createdAt);
      if (parsed != null) {
        startLimit = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    while (!isDateCompleted(completions, formatDate(checkDate))) {
      if (startLimit != null && checkDate.isBefore(startLimit)) break;
      count++;
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
      if (count > 1000) break;
    }

    if (count == 0 || count > 10) return 0;
    return -((count * (count + 1)) ~/ 2);
  }
}

int getStreakCount(List<String>? completions, {DateTime? nowOverride}) {
  if (completions == null || completions.isEmpty) return 0;
  final today = nowOverride ?? DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final todayStr = formatDate(todayStart);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final yesterdayStr = formatDate(yesterday);

  final todayCompleted = isDateCompleted(completions, todayStr);
  final yesterdayCompleted = isDateCompleted(completions, yesterdayStr);

  if (!todayCompleted && !yesterdayCompleted) return 0;

  var count = 0;
  var checkDate = todayCompleted ? todayStart : yesterday;
  while (isDateCompleted(completions, formatDate(checkDate))) {
    count++;
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day - 1);
    if (count > 2000) break;
  }
  return count;
}

const List<String> _weekdayInitials = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
const List<String> _monthInitials = [
  'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'
];

String formatShortTime(DateTime d) {
  var hours = d.hour;
  final ampm = hours >= 12 ? 'PM' : 'AM';
  hours = hours % 12;
  if (hours == 0) hours = 12;
  final minutes = d.minute.toString().padLeft(2, '0');
  return '$hours:$minutes $ampm';
}

List<ChartBarPoint> getHabitTimingChartData(
  String habitId,
  Map<String, List<String>> completions, {
  DateTime? nowOverride,
}) {
  final habitComps = completions[habitId] ?? const [];
  final now = nowOverride ?? DateTime.now();
  final todayStr = formatDate(now);
  final todayStart = DateTime(now.year, now.month, now.day);
  final sunday = DateTime(
    todayStart.year,
    todayStart.month,
    todayStart.day - (todayStart.weekday % 7),
  );

  return List.generate(7, (i) {
    final date = DateTime(sunday.year, sunday.month, sunday.day + i);
    final dateStr = formatDate(date);
    String? completionStr;
    for (final c in habitComps) {
      if (isDateCompleted([c], dateStr)) {
        completionStr = c;
        break;
      }
    }

    double timingValue = 0;
    String tooltipValue = '';
    bool isDone = false;

    if (completionStr != null) {
      isDone = true;
      final d = _parseLocalDateTime(completionStr);
      if (d != null) {
        timingValue = 24 - (d.hour + d.minute / 60.0);
        tooltipValue = formatShortTime(d);
      }
    }

    return ChartBarPoint(
      label: _weekdayInitials[i],
      value: timingValue,
      max: 24,
      isToday: dateStr == todayStr,
      isCompleted: isDone,
      tooltip: tooltipValue,
    );
  });
}

List<ChartBarPoint> getTotalWeeklyChartData(
  List<Habit> habits,
  List<Habit> completedHabits,
  Map<String, List<String>> completions, {
  DateTime? nowOverride,
}) {
  final now = nowOverride ?? DateTime.now();
  final todayStr = formatDate(now);
  final todayStart = DateTime(now.year, now.month, now.day);
  final sunday = DateTime(
    todayStart.year,
    todayStart.month,
    todayStart.day - (todayStart.weekday % 7),
  );

  final allHabitIds = [...habits, ...completedHabits].map((h) => h.id).toList();
  final totalCount = habits.length + completedHabits.length;

  return List.generate(7, (i) {
    final date = DateTime(sunday.year, sunday.month, sunday.day + i);
    final dateStr = formatDate(date);
    var sum = 0;
    for (final id in allHabitIds) {
      if (isDateCompleted(completions[id], dateStr)) {
        sum++;
      }
    }

    return ChartBarPoint(
      label: _weekdayInitials[i],
      value: sum.toDouble(),
      max: totalCount > 0 ? totalCount.toDouble() : 1,
      isToday: dateStr == todayStr,
      isCompleted: sum > 0,
    );
  });
}

List<HourlyBucket> getHourlyDistribution(
  Map<String, List<String>> completions, {
  DateTime? nowOverride,
}) {
  final dist = List<int>.filled(24, 0);
  final now = nowOverride ?? DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));

  for (final list in completions.values) {
    for (final iso in list) {
      final d = _parseLocalDateTime(iso);
      if (d != null && !d.isBefore(sevenDaysAgo)) {
        dist[d.hour]++;
      }
    }
  }

  final maxVal = dist.fold<int>(1, (prev, el) => el > prev ? el : prev);
  return List.generate(24, (hour) {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    return HourlyBucket(
      hour: hour,
      label: '$h12$suffix',
      value: dist[hour],
      max: maxVal,
    );
  });
}

String getPeakHour(List<HourlyBucket> buckets) {
  if (buckets.isEmpty) return 'N/A';
  var peak = buckets.first;
  for (final b in buckets) {
    if (b.value > peak.value) {
      peak = b;
    }
  }
  return peak.value > 0 ? peak.label : 'N/A';
}

int getTotalActivityTicks(
  ActivityTimeframe timeframe,
  List<Habit> habits,
  List<Habit> completedHabits,
  Map<String, List<String>> completions, {
  DateTime? nowOverride,
}) {
  final now = nowOverride ?? DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final allHabitIds = [...habits, ...completedHabits].map((h) => h.id).toList();
  var ticks = 0;

  if (timeframe == ActivityTimeframe.week) {
    final sunday = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day - (todayStart.weekday % 7),
    );
    for (final id in allHabitIds) {
      for (final c in completions[id] ?? const <String>[]) {
        final d = _parseLocalDateTime(c);
        if (d != null && !d.isBefore(sunday)) {
          ticks++;
        }
      }
    }
  } else if (timeframe == ActivityTimeframe.month) {
    for (final id in allHabitIds) {
      for (final c in completions[id] ?? const <String>[]) {
        final d = _parseLocalDateTime(c);
        if (d != null) {
          final dStart = DateTime(d.year, d.month, d.day);
          final diffDays = todayStart.difference(dStart).inDays;
          if (diffDays >= 0 && diffDays < 28) {
            ticks++;
          }
        }
      }
    }
  } else {
    final currentYear = now.year;
    for (final id in allHabitIds) {
      for (final c in completions[id] ?? const <String>[]) {
        final d = _parseLocalDateTime(c);
        if (d != null && d.year == currentYear) {
          ticks++;
        }
      }
    }
  }

  return ticks;
}

List<ChartBarPoint> getTotalTimingChartData(
  ActivityTimeframe timeframe,
  List<Habit> habits,
  List<Habit> completedHabits,
  Map<String, List<String>> completions, {
  DateTime? nowOverride,
}) {
  final now = nowOverride ?? DateTime.now();
  final todayStr = formatDate(now);
  final todayStart = DateTime(now.year, now.month, now.day);
  final allHabitIds = [...habits, ...completedHabits].map((h) => h.id).toList();

  if (timeframe == ActivityTimeframe.week) {
    final sunday = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day - (todayStart.weekday % 7),
    );

    return List.generate(7, (i) {
      final date = DateTime(sunday.year, sunday.month, sunday.day + i);
      final dateStr = formatDate(date);
      final times = <double>[];

      for (final id in allHabitIds) {
        final list = completions[id];
        if (list == null) continue;
        String? match;
        for (final c in list) {
          if (isDateCompleted([c], dateStr)) {
            match = c;
            break;
          }
        }
        if (match != null) {
          final d = _parseLocalDateTime(match);
          if (d != null) {
            times.add(24 - (d.hour + d.minute / 60.0));
          }
        }
      }

      final avgTime = times.isEmpty
          ? 0.0
          : times.reduce((a, b) => a + b) / times.length;
      var tooltipValue = '';
      if (avgTime > 0) {
        final originalHours = 24 - avgTime;
        var hr = originalHours.floor();
        var min = ((originalHours - hr) * 60).round();
        if (min == 60) {
          min = 0;
          hr = (hr + 1) % 24;
        }
        final ampm = hr >= 12 ? 'PM' : 'AM';
        hr = hr % 12;
        if (hr == 0) hr = 12;
        tooltipValue = 'Avg: $hr:${min.toString().padLeft(2, '0')} $ampm';
      }

      return ChartBarPoint(
        label: _weekdayInitials[i],
        value: avgTime,
        max: 24,
        isToday: dateStr == todayStr,
        isCompleted: avgTime > 0,
        tooltip: tooltipValue,
      );
    });
  } else if (timeframe == ActivityTimeframe.month) {
    const weeks = [3, 2, 1, 0];
    final maxMonthlyVal = math.max(10, allHabitIds.length * 7).toDouble();

    return List.generate(weeks.length, (index) {
      final weekOffset = weeks[index];
      var count = 0;
      for (final id in allHabitIds) {
        for (final c in completions[id] ?? const <String>[]) {
          final d = _parseLocalDateTime(c);
          if (d != null) {
            final dStart = DateTime(d.year, d.month, d.day);
            final diffDays = todayStart.difference(dStart).inDays;
            if (diffDays >= weekOffset * 7 && diffDays < (weekOffset + 1) * 7) {
              count++;
            }
          }
        }
      }
      return ChartBarPoint(
        label: 'W${index + 1}',
        value: count.toDouble(),
        max: maxMonthlyVal,
        isToday: weekOffset == 0,
        isCompleted: count > 0,
        tooltip: '$count Activities',
      );
    });
  } else {
    final currentYear = now.year;
    final maxYearlyVal = math.max(20, allHabitIds.length * 31).toDouble();

    return List.generate(12, (monthIndex) {
      var count = 0;
      for (final id in allHabitIds) {
        for (final c in completions[id] ?? const <String>[]) {
          final d = _parseLocalDateTime(c);
          if (d != null &&
              d.year == currentYear &&
              d.month == monthIndex + 1) {
            count++;
          }
        }
      }
      return ChartBarPoint(
        label: _monthInitials[monthIndex],
        value: count.toDouble(),
        max: maxYearlyVal,
        isToday: (monthIndex + 1) == now.month,
        isCompleted: count > 0,
        tooltip: '$count Activities',
      );
    });
  }
}

String getAverageStreak(
  List<Habit> habits,
  Map<String, List<String>> completions, {
  DateTime? nowOverride,
}) {
  final active = habits.where((h) => h.completedAt == null).toList();
  if (active.isEmpty) return '0';
  final sum = active.fold<int>(
    0,
    (acc, h) => acc + calculateStreak(completions[h.id], h.createdAt, nowOverride: nowOverride),
  );
  return (sum / active.length).toStringAsFixed(1);
}

UserStats computeStats(
  List<Habit> habits,
  List<Habit> completedHabits,
  Map<String, List<String>> completions, {
  DateTime? nowOverride,
}) {
  var totalCompletionsCount = 0;
  for (final list in completions.values) {
    totalCompletionsCount += list.length;
  }

  final basePoints = totalCompletionsCount * 10;
  final allHabits = [...habits, ...completedHabits];

  var maxStreakPoints = 0;
  var maxStreakDays = 0;

  for (final h in allHabits) {
    final sPts = calculateStreak(completions[h.id], h.createdAt, nowOverride: nowOverride);
    if (sPts > maxStreakPoints) maxStreakPoints = sPts;
    final sDays = getStreakCount(completions[h.id], nowOverride: nowOverride);
    if (sDays > maxStreakDays) maxStreakDays = sDays;
  }

  final rank = basePoints >= 1000
      ? 'Master'
      : basePoints >= 500
          ? 'Expert'
          : basePoints >= 100
              ? 'Achiever'
              : 'Beginner';

  return UserStats(
    totalCompletionsCount: totalCompletionsCount,
    totalPoints: basePoints + maxStreakPoints,
    maxStreakDays: maxStreakDays,
    rank: rank,
  );
}

List<IndividualHabitBadge> buildIndividualBadges(
  List<Habit> habits,
  List<Habit> completedHabits,
  Map<String, List<String>> completions,
) {
  final result = <IndividualHabitBadge>[];
  for (final habit in [...habits, ...completedHabits]) {
    final count = completions[habit.id]?.length ?? 0;
    var highestTierIndex = -1;

    for (var i = 0; i < habitMilestones.length; i++) {
      final m = habitMilestones[i];
      if (count >= m.req) {
        if (i > highestTierIndex) highestTierIndex = i;
        result.add(IndividualHabitBadge(
          id: 'habit_${habit.id}_${m.tier}',
          name: '${m.tier} for ${habit.name}',
          desc: '${m.req} completions',
          icon: m.icon,
          req: m.req,
          tier: m.tier,
          habitId: habit.id,
          habitColor: habit.color,
        ));
      }
    }

    if (habit.targetDays > 0 && count >= habit.targetDays && highestTierIndex == -1) {
      final m = habitMilestones[0];
      result.add(IndividualHabitBadge(
        id: 'habit_${habit.id}_completion_bronze',
        name: 'Bronze for ${habit.name}',
        desc: 'Completed target!',
        icon: m.icon,
        req: habit.targetDays,
        tier: m.tier,
        habitId: habit.id,
        habitColor: habit.color,
      ));
    }
  }
  return result;
}
