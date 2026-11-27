import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../widgets/glass.dart';

class BadgesTab extends StatelessWidget {
  final HabitStore store;
  final ScrollController scrollController;

  const BadgesTab({
    super.key,
    required this.store,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final stats = store.stats;
    final individual = store.individualBadges;
    final completedList = store.allCompletedHabits;
    final activeList = store.activeHabits;

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
              // Total Points Card
              BounceTap(
                scaleDown: 0.98,
                child: GlassCard(
                  borderRadius: 24,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -40,
                        child: Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.yellow.withValues(alpha: 0.16),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL POINTS',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.target,
                                        size: 24,
                                        color: AppColors.yellow,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '${stats.totalPoints}',
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.yellow,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'RANK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.zinc500,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stats.rank,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Global Achievements (3 columns)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'GLOBAL ACHIEVEMENTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: globalBadges.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.80,
                ),
                itemBuilder: (context, index) {
                  final badge = globalBadges[index];
                  final unlocked = badge.type == BadgeCriteriaType.streak
                      ? stats.maxStreakDays >= badge.req
                      : stats.totalCompletionsCount >= badge.req;
                  final progress = badge.type == BadgeCriteriaType.streak
                      ? (stats.maxStreakDays / badge.req).clamp(0.0, 1.0)
                      : (stats.totalCompletionsCount / badge.req).clamp(0.0, 1.0);
                  final style = tierStyles[badge.tier] ?? tierStyles['Bronze']!;

                  final card = GlassCard(
                    borderRadius: 16,
                    borderColor: unlocked ? style.borderColor : AppColors.borderSubtle,
                    gradient: unlocked
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [style.bgTop, style.bgBottom],
                          )
                        : null,
                    shadows: unlocked
                        ? [BoxShadow(color: style.shadowColor, blurRadius: 15)]
                        : null,
                    child: Stack(
                      children: [
                        if (unlocked)
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [style.glowColor, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                              Icon(
                                badge.icon,
                                size: 20,
                                color: unlocked ? style.textColor : AppColors.zinc500,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                badge.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                badge.tier.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: unlocked ? style.textColor : AppColors.zinc600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                badge.desc.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.zinc500,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              if (!unlocked) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    height: 4,
                                    width: double.infinity,
                                    color: AppColors.zinc800.withValues(alpha: 0.5),
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: progress,
                                      child: Container(
                                        color: AppColors.zinc600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      ],
                    ),
                  );

                  if (unlocked) {
                    return Transform.scale(scale: 1.02, child: card);
                  }
                  return Opacity(
                    opacity: 0.4,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0,      0,      0,      1, 0,
                      ]),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                        child: card,
                      ),
                    ),
                  );
                },
              ),

              // Individual Badges
              if (individual.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'INDIVIDUAL BADGES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: individual.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemBuilder: (context, index) {
                    final badge = individual[index];
                    final style = tierStyles[badge.tier] ?? tierStyles['Bronze']!;
                    final habitColor = findHabitColor(badge.habitColor).color;

                    return GlassCard(
                      borderRadius: 16,
                      borderColor: habitColor.withValues(alpha: 0.4),
                      backgroundColor: habitColor.withValues(alpha: 0.1),
                      shadows: [BoxShadow(color: style.shadowColor, blurRadius: 15)],
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [style.glowColor, Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(badge.icon, size: 16, color: style.textColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    badge.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    badge.tier.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: style.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    badge.desc,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.zinc500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // Hall of Fame
              if (completedList.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'HALL OF FAME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...completedList.map((habit) {
                  final habitColor = findHabitColor(habit.color).color;
                  final totalComps = (store.completions[habit.id] ?? const []).length;
                  HabitMilestone? milestone;
                  for (final m in habitMilestones.reversed) {
                    if (totalComps >= m.req) {
                      milestone = m;
                      break;
                    }
                  }
                  if (milestone == null &&
                      (habit.completedAt != null ||
                          (habit.targetDays > 0 && totalComps >= habit.targetDays))) {
                    milestone = habitMilestones.first;
                  }
                  final style =
                      milestone != null ? tierStyles[milestone.tier] : null;
                  final completedDate = habit.completedAt != null
                      ? DateTime.tryParse(habit.completedAt!)?.toLocal()
                      : null;
                  final dateLabel = completedDate != null
                      ? '${completedDate.month}/${completedDate.day}/${completedDate.year}'
                      : 'ARCHIVED';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      borderRadius: 16,
                      borderColor: style?.borderColor ??
                          habitColor.withValues(alpha: 0.3),
                      gradient: style != null
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [style.bgTop, style.bgBottom],
                            )
                          : null,
                      backgroundColor:
                          style == null ? habitColor.withValues(alpha: 0.05) : null,
                      shadows: style != null
                          ? [BoxShadow(color: style.shadowColor, blurRadius: 15)]
                          : null,
                      child: Stack(
                        children: [
                          if (style != null)
                            Positioned(
                              left: -40,
                              top: -40,
                              child: Container(
                                width: 128,
                                height: 128,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      style.glowColor.withValues(alpha: 0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (milestone != null && style != null)
                            Positioned(
                              right: -8,
                              top: -8,
                              child: Transform.rotate(
                                angle: 0.21,
                                child: Opacity(
                                  opacity: 0.05,
                                  child: Icon(
                                    milestone.icon,
                                    size: 56,
                                    color: style.textColor,
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Transform.rotate(
                                  angle: 0.05,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: style != null
                                          ? Colors.black.withValues(alpha: 0.2)
                                          : habitColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      milestone?.icon ?? LucideIcons.award,
                                      size: 24,
                                      color: style?.textColor ?? Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        habit.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 2,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            '${(milestone?.tier ?? 'Initiate').toUpperCase()} MASTER',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.2,
                                              color: style?.textColor ??
                                                  AppColors.zinc500,
                                            ),
                                          ),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: AppColors.zinc700,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Text(
                                            dateLabel,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.zinc500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$totalComps',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: style != null
                                            ? Colors.white
                                            : AppColors.zinc400,
                                      ),
                                    ),
                                    const Text(
                                      'TOTAL SPRINTS',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.zinc500,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              // Next Milestones
              if (activeList.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'NEXT MILESTONES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...activeList.map((habit) {
                  final count = (store.completions[habit.id] ?? const []).length;
                  final habitColor = findHabitColor(habit.color).color;
                  HabitMilestone? currentMilestone;
                  for (final m in habitMilestones.reversed) {
                    if (count >= m.req) {
                      currentMilestone = m;
                      break;
                    }
                  }
                  if (currentMilestone == null &&
                      (habit.completedAt != null ||
                          (habit.targetDays > 0 && count >= habit.targetDays))) {
                    currentMilestone = habitMilestones.first;
                  }
                  final style = currentMilestone != null
                      ? tierStyles[currentMilestone.tier]
                      : null;

                  var nextMilestone = habitMilestones.last;
                  for (final m in habitMilestones) {
                    if (m.req > count) {
                      nextMilestone = m;
                      break;
                    }
                  }
                  final prevReq = currentMilestone?.req ?? 0;
                  final denom = nextMilestone.req - prevReq;
                  final progress = denom > 0
                      ? ((count - prevReq) / denom).clamp(0.0, 1.0)
                      : 1.0;
                  final isMaxed = count >= habitMilestones.last.req;
                  final icon = currentMilestone?.icon ?? LucideIcons.flame;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BounceTap(
                      scaleDown: 0.98,
                      child: GlassCard(
                        borderRadius: 16,
                        borderColor: style?.borderColor ??
                            habitColor.withValues(alpha: 0.4),
                        gradient: style != null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [style.bgTop, style.bgBottom],
                              )
                            : null,
                        backgroundColor:
                            style == null ? habitColor.withValues(alpha: 0.1) : null,
                        shadows: style != null
                            ? [BoxShadow(color: style.shadowColor, blurRadius: 15)]
                            : null,
                        child: Stack(
                          children: [
                            if (style != null)
                              Positioned(
                                right: -16,
                                top: -16,
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        style.glowColor.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: style != null
                                                    ? Colors.black.withValues(alpha: 0.2)
                                                    : habitColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                icon,
                                                size: 18,
                                                color: style?.textColor ?? Colors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    habit.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    isMaxed
                                                        ? 'ULTIMATE ${habitMilestones.last.tier.toUpperCase()} ACHIEVED!'
                                                        : '${nextMilestone.req - count} MORE TO ${nextMilestone.tier.toUpperCase()}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: style?.textColor ??
                                                          AppColors.zinc500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$count',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              color: style != null
                                                  ? Colors.white
                                                  : AppColors.zinc400,
                                            ),
                                          ),
                                          const Text(
                                            'TOTAL',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.zinc500,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (!isMaxed) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: Container(
                                        height: 6,
                                        width: double.infinity,
                                        color: Colors.black.withValues(alpha: 0.2),
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: progress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: style?.textColor ?? habitColor,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
