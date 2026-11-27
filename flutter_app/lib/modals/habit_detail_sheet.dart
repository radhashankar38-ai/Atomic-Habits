import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../utils/habit_math.dart';
import '../widgets/glass.dart';

class HabitDetailSheet extends StatelessWidget {
  final Habit habit;
  final HabitStore store;
  final VoidCallback onEdit;
  final VoidCallback onReset;
  final VoidCallback onDelete;
  final ValueChanged<NoteDraft> onEditReflection;

  const HabitDetailSheet({
    super.key,
    required this.habit,
    required this.store,
    required this.onEdit,
    required this.onReset,
    required this.onDelete,
    required this.onEditReflection,
  });

  @override
  Widget build(BuildContext context) {
    final comps = store.completions[habit.id] ?? const [];
    final streakScore = calculateStreak(comps, habit.createdAt);
    final habitRefs = store.reflections[habit.id] ?? const {};
    final sortedDates = habitRefs.keys.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.1,
        ),
        child: GlassCard(
          enableBlur: true,
          blurSigma: 16,
          customBorderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          backgroundColor: const Color(0xFF141416).withValues(alpha: 0.94),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.cardSecondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'DETAIL VIEW & REFLECTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.zinc500,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        borderColor: Colors.white.withValues(alpha: 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CURRENT STREAK',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.zinc500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '$streakScore',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  LucideIcons.flame,
                                  size: 20,
                                  color: Color(0xFFF97316),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassPanel(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(16),
                        borderColor: Colors.white.withValues(alpha: 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL TICKS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.zinc500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${comps.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  LucideIcons.checkCircle,
                                  size: 20,
                                  color: AppColors.lime,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Notes
                if (habit.notes != null && habit.notes!.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'INSTRUCTIONS / DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.zinc500,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassPanel(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    borderColor: Colors.white.withValues(alpha: 0.05),
                    child: Text(
                      habit.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFD4D4D8),
                      ),
                    ),
                  ),
                ],

                // Recent Reflections
                if (sortedDates.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'RECENT REFLECTIONS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.zinc500,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...sortedDates.take(5).map((dateStr) {
                    final parsed = DateTime.tryParse(dateStr)?.toLocal();
                    final label = parsed != null
                        ? '${_shortMonth(parsed.month)} ${parsed.day}'
                        : dateStr;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassPanel(
                        borderRadius: 12,
                        padding: const EdgeInsets.all(12),
                        borderColor: Colors.white.withValues(alpha: 0.05),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  label.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.blue,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => onEditReflection(
                                    NoteDraft(
                                      habitId: habit.id,
                                      date: dateStr,
                                      content: habitRefs[dateStr] ?? '',
                                    ),
                                  ),
                                  child: const Text(
                                    'EDIT',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.zinc600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              habitRefs[dateStr] ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.zinc400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'ACTIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.zinc500,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: BounceTap(
                        onTap: onEdit,
                        child: GlassPanel(
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.06),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.edit2, size: 14, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BounceTap(
                        onTap: onReset,
                        child: GlassPanel(
                          borderRadius: 12,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.06),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.rotateCcw,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                BounceTap(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.trash2, size: 14, color: AppColors.red),
                        SizedBox(width: 8),
                        Text(
                          'Delete Habit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _shortMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}
