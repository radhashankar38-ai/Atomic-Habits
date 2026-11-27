import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/habit.dart';

class AppColors {
  static const Color bg = Color(0xFF000000);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF); // white @ 60%
  static const Color card = Color(0x0DFFFFFF); // white @ 5%
  static const Color cardSecondary = Color(0x14FFFFFF); // white @ 8%
  static const Color borderSubtle = Color(0x1AFFFFFF); // white @ 10%
  static const Color surfaceDark = Color(0xFF1C1C1E);

  static const Color blue = Color(0xFF0A84FF);
  static const Color red = Color(0xFFFA114F);
  static const Color green = Color(0xFF30D158);
  static const Color iosGreen = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color cyan = Color(0xFF00F2FF);
  static const Color lime = Color(0xFF92FF00);
  static const Color purple = Color(0xFFBF5AF2);
  static const Color indigo = Color(0xFF5E5CE6);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);

  static const Color zinc300 = Color(0xFFD4D4D8);
  static const Color zinc400 = Color(0xFFA1A1AA);
  static const Color zinc500 = Color(0xFF71717A);
  static const Color zinc600 = Color(0xFF52525B);
  static const Color zinc700 = Color(0xFF3F3F46);
  static const Color zinc800 = Color(0xFF27272A);
  static const Color zinc900 = Color(0xFF18181B);
}

const List<HabitCategoryOption> habitCategories = [
  HabitCategoryOption(value: 'health', label: 'Health', icon: LucideIcons.heartPulse),
  HabitCategoryOption(value: 'work', label: 'Work', icon: LucideIcons.briefcase),
  HabitCategoryOption(value: 'learning', label: 'Learning', icon: LucideIcons.bookOpen),
  HabitCategoryOption(value: 'productivity', label: 'Productivity', icon: LucideIcons.target),
  HabitCategoryOption(value: 'personal', label: 'Personal', icon: LucideIcons.user),
  HabitCategoryOption(value: 'fitness', label: 'Fitness', icon: LucideIcons.dumbbell),
  HabitCategoryOption(value: 'finance', label: 'Finance', icon: LucideIcons.wallet),
  HabitCategoryOption(value: 'social', label: 'Social', icon: LucideIcons.users),
  HabitCategoryOption(value: 'other', label: 'Others', icon: LucideIcons.moreHorizontal),
];

const List<HabitColorOption> habitColors = [
  HabitColorOption(name: 'Move', hex: '#fa114f', color: Color(0xFFFA114F)),
  HabitColorOption(name: 'Exercise', hex: '#92ff00', color: Color(0xFF92FF00)),
  HabitColorOption(name: 'Stand', hex: '#00f2ff', color: Color(0xFF00F2FF)),
  HabitColorOption(name: 'Mind', hex: '#bf5af2', color: Color(0xFFBF5AF2)),
  HabitColorOption(name: 'Hydrate', hex: '#0a84ff', color: Color(0xFF0A84FF)),
  HabitColorOption(name: 'Sleep', hex: '#5e5ce6', color: Color(0xFF5E5CE6)),
  HabitColorOption(name: 'Energy', hex: '#ff9500', color: Color(0xFFFF9500)),
  HabitColorOption(name: 'Focus', hex: '#ffd60a', color: Color(0xFFFFD60A)),
  HabitColorOption(name: 'Breathe', hex: '#64d2ff', color: Color(0xFF64D2FF)),
  HabitColorOption(name: 'Nature', hex: '#00d281', color: Color(0xFF00D281)),
  HabitColorOption(name: 'Passion', hex: '#ff2d55', color: Color(0xFFFF2D55)),
  HabitColorOption(name: 'Ground', hex: '#a2845e', color: Color(0xFFA2845E)),
  HabitColorOption(name: 'Aura', hex: '#ff00ff', color: Color(0xFFFF00FF)),
  HabitColorOption(name: 'Bolt', hex: '#ffff00', color: Color(0xFFFFFF00)),
  HabitColorOption(name: 'Glacier', hex: '#a0feff', color: Color(0xFFA0FEFF)),
  HabitColorOption(name: 'Zen', hex: '#d4ffea', color: Color(0xFFD4FFEA)),
  HabitColorOption(name: 'Spirit', hex: '#af52de', color: Color(0xFFAF52DE)),
  HabitColorOption(name: 'Mars', hex: '#ff4500', color: Color(0xFFFF4500)),
];

HabitColorOption findHabitColor(String? hex, {int fallbackIndex = 0}) {
  if (hex != null) {
    final lower = hex.toLowerCase();
    for (final c in habitColors) {
      if (c.hex.toLowerCase() == lower) return c;
    }
  }
  return habitColors[fallbackIndex % habitColors.length];
}

HabitCategoryOption? findHabitCategory(String? value) {
  if (value == null) return null;
  for (final cat in habitCategories) {
    if (cat.value == value) return cat;
  }
  return null;
}

const List<GlobalBadge> globalBadges = [
  GlobalBadge(
    id: 'first_step',
    name: 'First Step',
    desc: '1 Habit',
    icon: LucideIcons.star,
    req: 1,
    type: BadgeCriteriaType.completions,
    tier: 'Bronze',
  ),
  GlobalBadge(
    id: 'streak_3',
    name: 'On Fire',
    desc: '3 Day Streak',
    icon: LucideIcons.flame,
    req: 3,
    type: BadgeCriteriaType.streak,
    tier: 'Bronze',
  ),
  GlobalBadge(
    id: 'steadfast',
    name: 'Steadfast',
    desc: '20 Habits',
    icon: LucideIcons.shield,
    req: 20,
    type: BadgeCriteriaType.completions,
    tier: 'Silver',
  ),
  GlobalBadge(
    id: 'streak_7',
    name: 'Unstoppable',
    desc: '7 Day Streak',
    icon: LucideIcons.zap,
    req: 7,
    type: BadgeCriteriaType.streak,
    tier: 'Silver',
  ),
  GlobalBadge(
    id: 'centurion',
    name: 'Centurion',
    desc: '100 Habits',
    icon: LucideIcons.award,
    req: 100,
    type: BadgeCriteriaType.completions,
    tier: 'Gold',
  ),
  GlobalBadge(
    id: 'streak_30',
    name: 'Legend',
    desc: '30 Day Streak',
    icon: LucideIcons.trophy,
    req: 30,
    type: BadgeCriteriaType.streak,
    tier: 'Gold',
  ),
  GlobalBadge(
    id: 'streak_90',
    name: 'Consistent Pro',
    desc: '90 Day Streak',
    icon: LucideIcons.crown,
    req: 90,
    type: BadgeCriteriaType.streak,
    tier: 'Gold',
  ),
  GlobalBadge(
    id: 'streak_365',
    name: 'Immortal',
    desc: '365 Day Streak',
    icon: LucideIcons.award,
    req: 365,
    type: BadgeCriteriaType.streak,
    tier: 'Diamond',
  ),
  GlobalBadge(
    id: 'master_builder',
    name: 'Master Builder',
    desc: '500 Habits',
    icon: LucideIcons.gem,
    req: 500,
    type: BadgeCriteriaType.completions,
    tier: 'Diamond',
  ),
];

const List<HabitMilestone> habitMilestones = [
  HabitMilestone(tier: 'Bronze', req: 3, icon: LucideIcons.star),
  HabitMilestone(tier: 'Silver', req: 10, icon: LucideIcons.shield),
  HabitMilestone(tier: 'Gold', req: 30, icon: LucideIcons.trophy),
  HabitMilestone(tier: 'Platinum', req: 100, icon: LucideIcons.crown),
];

const Map<String, TierStyle> tierStyles = {
  'Bronze': TierStyle(
    textColor: Color(0xFFF97316),
    borderColor: Color(0x66F97316),
    bgTop: Color(0x1AF97316),
    bgBottom: Color(0x0D7C2D12),
    shadowColor: Color(0x1AF97316),
    glowColor: Color(0x33F97316),
  ),
  'Silver': TierStyle(
    textColor: Color(0xFFD4D4D8),
    borderColor: Color(0x66D4D4D8),
    bgTop: Color(0x1AD4D4D8),
    bgBottom: Color(0x0D52525B),
    shadowColor: Color(0x1AD4D4D8),
    glowColor: Color(0x33D4D4D8),
  ),
  'Gold': TierStyle(
    textColor: Color(0xFFEAB308),
    borderColor: Color(0x66EAB308),
    bgTop: Color(0x1AEAB308),
    bgBottom: Color(0x0DA16207),
    shadowColor: Color(0x26EAB308),
    glowColor: Color(0x33EAB308),
  ),
  'Platinum': TierStyle(
    textColor: Color(0xFFF4F4F5),
    borderColor: Color(0x66FFFFFF),
    bgTop: Color(0x1AFFFFFF),
    bgBottom: Color(0x0D18181B),
    shadowColor: Color(0x1AFFFFFF),
    glowColor: Color(0x33FFFFFF),
  ),
  'Diamond': TierStyle(
    textColor: Color(0xFF22D3EE),
    borderColor: Color(0x6622D3EE),
    bgTop: Color(0x1A22D3EE),
    bgBottom: Color(0x0D6366F1),
    shadowColor: Color(0x3322D3EE),
    glowColor: Color(0x4D22D3EE),
  ),
};

const List<Color> confettiPalette = [
  Color(0xFFFA114F),
  Color(0xFF92FF00),
  Color(0xFF00F2FF),
  Color(0xFFBF5AF2),
  Color(0xFF0A84FF),
  Color(0xFF5E5CE6),
];
