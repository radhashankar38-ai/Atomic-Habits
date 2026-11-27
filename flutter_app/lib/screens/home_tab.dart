import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../utils/habit_math.dart';
import '../utils/share_helper.dart';
import '../widgets/activity_rings.dart';
import '../widgets/charts.dart';
import '../widgets/glass.dart';

class HomeTab extends StatefulWidget {
  final HabitStore store;
  final ScrollController scrollController;

  const HomeTab({
    super.key,
    required this.store,
    required this.scrollController,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final GlobalKey _motivationBoundaryKey = GlobalKey();
  bool _isGeneratingMotivation = false;
  bool _hideShareControls = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.store.userName;
    _nameFocusNode.addListener(_handleNameFocusChange);
  }

  @override
  void didUpdateWidget(covariant HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_nameController.text != widget.store.userName && !_nameFocusNode.hasFocus) {
      _nameController.text = widget.store.userName;
    }
  }

  void _handleNameFocusChange() {
    if (!_nameFocusNode.hasFocus && widget.store.userName.trim().isNotEmpty) {
      widget.store.setEditingName(false);
    }
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_handleNameFocusChange);
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _shareMotivation() async {
    final quote = widget.store.quote;
    if (quote == null || _isGeneratingMotivation) return;
    setState(() {
      _isGeneratingMotivation = true;
      _hideShareControls = true;
    });

    try {
      // Wait one frame so share header hides before capture
      await Future<void>.delayed(const Duration(milliseconds: 60));
      final png = await ShareHelper.captureBoundaryPng(
        _motivationBoundaryKey,
        pixelRatio: 3.0,
      );
      if (mounted) {
        setState(() {
          _hideShareControls = false;
        });
      }
      if (png != null) {
        final today = formatDate(DateTime.now());
        await ShareHelper.sharePngBytes(
          bytes: png,
          filename: 'motivation-$today.png',
          title: 'Daily Motivation',
          text: '"${quote.text}" — ${quote.author}',
        );
      } else {
        await ShareHelper.shareText(
          title: 'Daily Motivation',
          text: '"${quote.text}" — ${quote.author}',
        );
      }
    } catch (_) {
      try {
        await ShareHelper.shareText(
          title: 'Daily Motivation',
          text: '"${quote.text}" — ${quote.author}',
        );
      } catch (_) {}
    } finally {
      if (mounted) {
        setState(() {
          _hideShareControls = false;
          _isGeneratingMotivation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final todayStr = formatDate(DateTime.now());
    final chunks = store.chunkedHabits;
    final activeHabits = store.activeHabits;
    final usedCategories = store.usedCategories;
    final completedTodayCount = store.habits
        .where((h) => isDateCompleted(store.completions[h.id], todayStr))
        .length;
    final weeklyData = getTotalWeeklyChartData(
      store.habits,
      store.completedHabits,
      store.completions,
    );

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 88,
        bottom: 132,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting + Rings + Categories
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // User Greeting
                    if (store.isEditingName)
                      TextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        autofocus: store.userName.isEmpty,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: "What's your name?",
                          hintStyle: TextStyle(color: AppColors.zinc600),
                          isDense: true,
                          contentPadding: EdgeInsets.only(bottom: 6),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.blue, width: 2),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.blue, width: 2),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.blue, width: 2),
                          ),
                        ),
                        onChanged: store.setUserName,
                        onSubmitted: (_) {
                          if (store.userName.trim().isNotEmpty) {
                            store.setEditingName(false);
                          }
                        },
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          _nameController.text = store.userName;
                          store.setEditingName(true);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _nameFocusNode.requestFocus();
                          });
                        },
                        child: TypewriterText(
                          text: store.userName.isNotEmpty
                              ? 'Hello, ${store.userName}'
                              : 'Hello! Tap to add name',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to crush your goals today?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Rings Carousel
                    SizedBox(
                      height: 220,
                      child: chunks.isEmpty
                          ? Row(
                              children: [
                                ActivityRings(
                                  habits: const [],
                                  completions: store.completions,
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'NO HABITS YET',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.5,
                                        color: AppColors.zinc500.withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : PageView.builder(
                              itemCount: chunks.length,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, chunkIdx) {
                                final chunk = chunks[chunkIdx];
                                return BounceTap(
                                  scaleDown: 0.98,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      ActivityRings(
                                        habits: chunk,
                                        completions: store.completions,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: List.generate(chunk.length, (i) {
                                            final habit = chunk[i];
                                            final cObj = findHabitColor(
                                              habit.color,
                                              fallbackIndex: i,
                                            );
                                            final cat = (habit.category != null &&
                                                    habit.category != 'other')
                                                ? findHabitCategory(habit.category)
                                                : null;
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                bottom: i == chunk.length - 1 ? 0 : 14,
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: TypewriterText(
                                                          text: habit.name.toUpperCase(),
                                                          delay: Duration(
                                                            milliseconds: i * 200 + 300,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w700,
                                                            color: cObj.color,
                                                            letterSpacing: -0.2,
                                                          ),
                                                        ),
                                                      ),
                                                      if (habit.completedAt != null) ...[
                                                        const SizedBox(width: 4),
                                                        const Icon(
                                                          LucideIcons.trophy,
                                                          size: 10,
                                                          color: AppColors.yellow,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (cat != null) ...[
                                                    const SizedBox(height: 2),
                                                    Row(
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
                                                            fontWeight: FontWeight.w500,
                                                            color: AppColors.zinc500,
                                                            letterSpacing: 1.4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Category Filter Pills
                    if (activeHabits.isNotEmpty && usedCategories.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      CategoryFilterBar(
                        categories: usedCategories,
                        selected: store.selectedCategory,
                        onSelect: store.setSelectedCategory,
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Cards Column
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Daily Motivation
                    BounceTap(
                      scaleDown: 0.98,
                      child: RepaintBoundary(
                        key: _motivationBoundaryKey,
                        child: GlassCard(
                          borderRadius: 16,
                          backgroundColor: Colors.black,
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
                                        AppColors.blue.withValues(alpha: 0.16),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!_hideShareControls)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(
                                                  LucideIcons.activity,
                                                  size: 16,
                                                  color: AppColors.blue,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'DAILY MOTIVATION',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.blue,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (store.quote != null)
                                              GestureDetector(
                                                onTap: _shareMotivation,
                                                child: Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: AppColors.blue
                                                        .withValues(alpha: 0.1),
                                                  ),
                                                  child: Center(
                                                    child: _isGeneratingMotivation
                                                        ? const SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: AppColors.blue,
                                                            ),
                                                          )
                                                        : const Icon(
                                                            LucideIcons.share2,
                                                            size: 14,
                                                            color: AppColors.blue,
                                                          ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    if (store.quote != null) ...[
                                      TypewriterText(
                                        text: store.quote!.text,
                                        delay: const Duration(milliseconds: 600),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          fontStyle: FontStyle.italic,
                                          height: 1.35,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '— ${store.quote!.author.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.zinc500,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ] else ...[
                                      Container(
                                        height: 16,
                                        width: 220,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        height: 16,
                                        width: 140,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
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
                    ),
                    const SizedBox(height: 24),

                    // Today's Goals Summary
                    BounceTap(
                      scaleDown: 0.98,
                      child: GlassCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 4, right: 12),
                                child: Text(
                                  "Today's\nGoals",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  GlassPanel(
                                    borderRadius: 12,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            LucideIcons.flame,
                                            size: 14,
                                            color: AppColors.orange,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            store.averageStreak,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text(
                                            'AVG STREAK',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$completedTodayCount of ${store.habits.length} completed',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Weekly Activity Summary
                    GlassCard(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(24),
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
                                    'WEEKLY ACTIVITY',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'LAST 7 DAYS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          WeeklyActivityBarChart(data: weeklyData),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryFilterBar extends StatelessWidget {
  final List<HabitCategoryOption> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterPill(
            label: 'All Habits',
            isSelected: selected == 'all',
            onTap: () => onSelect('all'),
          ),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _FilterPill(
                label: cat.label,
                icon: cat.icon,
                isSelected: selected == cat.value,
                onTap: () => onSelect(cat.value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.smoothOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blue : AppColors.cardSecondary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.blue : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.zinc400,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.zinc400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
