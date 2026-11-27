import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../utils/habit_math.dart';
import '../widgets/charts.dart';
import '../widgets/glass.dart';
import 'home_tab.dart';

class ProgressTab extends StatelessWidget {
  final HabitStore store;
  final ScrollController scrollController;
  final ValueChanged<Habit> onToggleHabit;
  final ValueChanged<Habit> onRequestUndo;
  final ValueChanged<Habit> onOpenHabitDetail;

  const ProgressTab({
    super.key,
    required this.store,
    required this.scrollController,
    required this.onToggleHabit,
    required this.onRequestUndo,
    required this.onOpenHabitDetail,
  });

  @override
  Widget build(BuildContext context) {
    final todayStr = formatDate(DateTime.now());
    final activeHabits = store.activeHabits;
    final usedCategories = store.usedCategories;
    final filteredHabits = store.filteredActiveHabits;

    final hourlyBuckets = getHourlyDistribution(store.completions);
    final peakHour = getPeakHour(hourlyBuckets);
    final totalTicks = getTotalActivityTicks(
      store.totalActivityTimeframe,
      store.habits,
      store.completedHabits,
      store.completions,
    );
    final totalChartData = getTotalTimingChartData(
      store.totalActivityTimeframe,
      store.habits,
      store.completedHabits,
      store.completions,
    );

    final timeframeLabel = switch (store.totalActivityTimeframe) {
      ActivityTimeframe.week => 'WEEKLY',
      ActivityTimeframe.month => 'MONTHLY',
      ActivityTimeframe.year => 'YEARLY',
    };

    return SingleChildScrollView(
      controller: scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 132,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Total Activity Summary Card (Swipe left/right cycles week/month/year)
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  final v = details.primaryVelocity ?? 0;
                  if (v < -150) {
                    store.cycleTotalActivityTimeframe(1);
                  } else if (v > 150) {
                    store.cycleTotalActivityTimeframe(-1);
                  }
                },
                child: GlassCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Activity',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'DAILY PROGRESS & TIMING',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.zinc500,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$totalTicks',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blue,
                                  ),
                                ),
                                Text(
                                  '$timeframeLabel TICKS',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.zinc500,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Hourly Intensity Strip
                      HourlyIntensityStrip(
                        buckets: hourlyBuckets,
                        peakHour: peakHour,
                      ),
                      const SizedBox(height: 24),

                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      const SizedBox(height: 16),

                      // Average Timing / Overall Activity Header + Segmented Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                store.totalActivityTimeframe ==
                                        ActivityTimeframe.week
                                    ? 'AVERAGE TIMING'
                                    : 'OVERALL ACTIVITY',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.zinc500,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: ActivityTimeframe.values.map((tf) {
                                final isSelected =
                                    store.totalActivityTimeframe == tf;
                                final text = switch (tf) {
                                  ActivityTimeframe.week => 'WEEK',
                                  ActivityTimeframe.month => 'MONTH',
                                  ActivityTimeframe.year => 'YEAR',
                                };
                                return GestureDetector(
                                  onTap: () =>
                                      store.setTotalActivityTimeframe(tf),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.blue
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      text,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.zinc500,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TimingBarChart(
                        data: totalChartData,
                        barColor: AppColors.blue,
                        emptyBarColor: Colors.white.withValues(alpha: 0.05),
                        showYAxisLabels:
                            store.totalActivityTimeframe == ActivityTimeframe.week,
                        barGap:
                            store.totalActivityTimeframe == ActivityTimeframe.month
                                ? 16
                                : 5,
                        barTopRadius: 3,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              if (activeHabits.isNotEmpty && usedCategories.isNotEmpty) ...[
                CategoryFilterBar(
                  categories: usedCategories,
                  selected: store.selectedCategory,
                  onSelect: store.setSelectedCategory,
                ),
                const SizedBox(height: 28),
              ],

              if (filteredHabits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'No habits found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No habits match the selected category.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.zinc500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(filteredHabits.length, (i) {
                  final habit = filteredHabits[i];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i == filteredHabits.length - 1 ? 0 : 48,
                    ),
                    child: _HabitProgressCard(
                      habit: habit,
                      completions: store.completions[habit.id] ?? const [],
                      allCompletions: store.completions,
                      todayStr: todayStr,
                      onToggle: () => onToggleHabit(habit),
                      onUndo: () => onRequestUndo(habit),
                      onOpenDetails: () => onOpenHabitDetail(habit),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitProgressCard extends StatelessWidget {
  final Habit habit;
  final List<String> completions;
  final Map<String, List<String>> allCompletions;
  final String todayStr;
  final VoidCallback onToggle;
  final VoidCallback onUndo;
  final VoidCallback onOpenDetails;

  const _HabitProgressCard({
    required this.habit,
    required this.completions,
    required this.allCompletions,
    required this.todayStr,
    required this.onToggle,
    required this.onUndo,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    final cObj = findHabitColor(habit.color);
    final isDoneToday = isDateCompleted(completions, todayStr);
    final streakDays = getStreakCount(completions);
    final progressPercent = habit.targetDays > 0
        ? ((completions.length / habit.targetDays) * 100).round()
        : 0;
    final daysRemaining = math.max(0, habit.targetDays - completions.length);
    final currentStreakScore = calculateStreak(completions, habit.createdAt);
    final isLocked = currentStreakScore < 0 && !isDoneToday;
    final cat = (habit.category != null && habit.category != 'other')
        ? findHabitCategory(habit.category)
        : null;
    final chartData = getHabitTimingChartData(habit.id, allCompletions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Habit Header Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HabitCheckButton(
              isDoneToday: isDoneToday,
              isLocked: isLocked,
              color: cObj.color,
              onTap: () {
                if (isLocked) return;
                if (isDoneToday) {
                  onUndo();
                } else {
                  onToggle();
                }
              },
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cObj.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          habit.name.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cObj.color,
                            fontSize: streakDays >= 21 ? 14 : 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onOpenDetails,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            LucideIcons.info,
                            size: 14,
                            color: AppColors.zinc600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (cat != null || streakDays > 0) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (cat != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat.icon,
                                  size: 8,
                                  color: AppColors.zinc500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cat.label.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.zinc500,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (streakDays > 0) _StreakPill(streakDays: streakDays),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$progressPercent%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  'PROGRESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.zinc500,
                    letterSpacing: 1.4,
                  ),
                ),
                if (currentStreakScore != 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        currentStreakScore > 0
                            ? LucideIcons.flame
                            : LucideIcons.alertCircle,
                        size: 12,
                        color: currentStreakScore > 0
                            ? AppColors.orange
                            : AppColors.cyan,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentStreakScore > 0
                            ? '+$currentStreakScore pts'
                            : '$currentStreakScore pts',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: currentStreakScore > 0
                              ? AppColors.orange
                              : AppColors.cyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Activity Timing Bar Chart
        const Text(
          'ACTIVITY TIMING',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.zinc600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        TimingBarChart(
          data: chartData,
          barColor: cObj.color,
          emptyBarColor: AppColors.zinc800.withValues(alpha: 0.4),
          showYAxisLabels: true,
          barGap: 4,
          barTopRadius: 2,
        ),

        const SizedBox(height: 20),

        // Calendar + Remaining/Target 2-Column Grid
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'CALENDAR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.zinc500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                'This Month',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.zinc600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      HabitCalendarGrid(
                        habit: habit,
                        completions: completions,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'REMAINING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '$daysRemaining',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'TARGET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${habit.targetDays}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HabitCheckButton extends StatelessWidget {
  final bool isDoneToday;
  final bool isLocked;
  final Color color;
  final VoidCallback onTap;

  const _HabitCheckButton({
    required this.isDoneToday,
    required this.isLocked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      scaleDown: isLocked ? 1.0 : 0.9,
      onTap: isLocked ? null : onTap,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.smoothOut,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDoneToday
                ? color
                : isLocked
                    ? AppColors.zinc900.withValues(alpha: 0.3)
                    : AppColors.zinc900.withValues(alpha: 0.5),
            border: Border.all(
              color: isDoneToday
                  ? color
                  : isLocked
                      ? AppColors.zinc800.withValues(alpha: 0.5)
                      : AppColors.zinc800,
              width: 2,
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: isDoneToday
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('done'),
                      size: 30,
                      color: Colors.black,
                    )
                  : isLocked
                      ? const Icon(
                          LucideIcons.lock,
                          key: ValueKey('locked'),
                          size: 20,
                          color: AppColors.zinc600,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakPill extends StatefulWidget {
  final int streakDays;

  const _StreakPill({required this.streakDays});

  @override
  State<_StreakPill> createState() => _StreakPillState();
}

class _StreakPillState extends State<_StreakPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final ms = math.max(400, (1500 - (widget.streakDays * 50))).toInt();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.streakDays;
    final Color accent;
    final Color bg;
    final Color border;
    Color? glow;

    if (s >= 30) {
      accent = Colors.white;
      bg = Colors.white.withValues(alpha: 0.1);
      border = Colors.white.withValues(alpha: 0.4);
      glow = Colors.white.withValues(alpha: 0.4);
    } else if (s >= 21) {
      accent = const Color(0xFFC084FC);
      bg = const Color(0xFFA855F7).withValues(alpha: 0.1);
      border = const Color(0xFFA855F7).withValues(alpha: 0.3);
      glow = const Color(0xFFA855F7).withValues(alpha: 0.3);
    } else if (s >= 14) {
      accent = const Color(0xFF22D3EE);
      bg = const Color(0xFF06B6D4).withValues(alpha: 0.1);
      border = const Color(0xFF06B6D4).withValues(alpha: 0.3);
      glow = const Color(0xFF22D3EE).withValues(alpha: 0.2);
    } else if (s >= 7) {
      accent = const Color(0xFFFACC15);
      bg = const Color(0xFFEAB308).withValues(alpha: 0.1);
      border = const Color(0xFFEAB308).withValues(alpha: 0.3);
    } else {
      accent = const Color(0xFFF97316);
      bg = const Color(0xFFF97316).withValues(alpha: 0.1);
      border = const Color(0xFFF97316).withValues(alpha: 0.2);
    }

    final iconSize = 12.0 + math.min(s / 4.0, 12.0);
    final maxScale = 1.15 + math.min(s / 100.0, 0.25);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
            boxShadow: glow != null
                ? [BoxShadow(color: glow, blurRadius: 12)]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: maxScale).animate(
                  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                ),
                child: Icon(
                  LucideIcons.flame,
                  size: iconSize,
                  color: accent,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '${s}d',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: accent,
                  letterSpacing: -0.3,
                ),
              ),
              if (s >= 21) ...[
                const SizedBox(width: 6),
                Text(
                  'MASTER',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: s >= 21 ? 6 : 4,
              color: Colors.white.withValues(alpha: 0.05),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (s / 30.0).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: glow != null
                        ? [BoxShadow(color: glow, blurRadius: 8)]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
