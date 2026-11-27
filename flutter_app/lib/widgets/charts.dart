import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../utils/habit_math.dart';

class WeeklyActivityBarChart extends StatelessWidget {
  final List<ChartBarPoint> data;

  const WeeklyActivityBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (i) {
          final item = data[i];
          final ratio = item.max > 0 ? (item.value / item.max).clamp(0.0, 1.0) : 0.0;
          final pct = math.max(ratio, 0.10);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == data.length - 1 ? 0 : 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 280 + i * 24),
                            curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                            width: double.infinity,
                            height: constraints.maxHeight * pct,
                            decoration: BoxDecoration(
                              color: item.value > 0
                                  ? AppColors.green
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              border: item.isToday
                                  ? Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 1,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: item.isToday ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class HourlyIntensityStrip extends StatefulWidget {
  final List<HourlyBucket> buckets;
  final String peakHour;

  const HourlyIntensityStrip({
    super.key,
    required this.buckets,
    required this.peakHour,
  });

  @override
  State<HourlyIntensityStrip> createState() => _HourlyIntensityStripState();
}

class _HourlyIntensityStripState extends State<HourlyIntensityStrip> {
  int? _selectedHour;

  @override
  Widget build(BuildContext context) {
    final selected = (_selectedHour != null && _selectedHour! < widget.buckets.length)
        ? widget.buckets[_selectedHour!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: 'HOURLY INTENSITY PEAK: ',
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.zinc500,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    children: [
                      TextSpan(
                        text: widget.peakHour,
                        style: const TextStyle(color: AppColors.orange),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.zinc800,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'LOW',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.zinc600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withValues(alpha: 0.5),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'HIGH',
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.zinc600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: const Cubic(0.22, 1.0, 0.36, 1.0),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(
              sizeFactor: anim,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
          child: selected == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(_selectedHour),
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.zinc900,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        '${selected.label}: ${selected.value} ticks',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Container(
          height: 14,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: List.generate(widget.buckets.length, (i) {
              final b = widget.buckets[i];
              final intensity = b.max > 0 ? (b.value / b.max) : 0.0;
              final active = b.value > 0;
              final isSelected = _selectedHour == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedHour = _selectedHour == i ? null : i;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: const Cubic(0.22, 1.0, 0.36, 1.0),
                    margin: const EdgeInsets.symmetric(horizontal: 0.75),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.orange
                              .withValues(alpha: math.max(intensity, 0.3))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 1)
                          : null,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.orange.withValues(alpha: 0.3),
                                blurRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '12AM',
                style: TextStyle(
                  fontSize: 7,
                  color: AppColors.zinc700,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '12PM',
                style: TextStyle(
                  fontSize: 7,
                  color: AppColors.zinc700,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '11PM',
                style: TextStyle(
                  fontSize: 7,
                  color: AppColors.zinc700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TimingBarChart extends StatefulWidget {
  final List<ChartBarPoint> data;
  final Color barColor;
  final Color emptyBarColor;
  final bool showYAxisLabels;
  final double barGap;
  final double barTopRadius;

  const TimingBarChart({
    super.key,
    required this.data,
    required this.barColor,
    this.emptyBarColor = const Color(0x0DFFFFFF),
    this.showYAxisLabels = true,
    this.barGap = 4,
    this.barTopRadius = 3,
  });

  @override
  State<TimingBarChart> createState() => _TimingBarChartState();
}

class _TimingBarChartState extends State<TimingBarChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant TimingBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.length != widget.data.length) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = (_selectedIndex != null &&
            _selectedIndex! < widget.data.length &&
            widget.data[_selectedIndex!].isCompleted &&
            widget.data[_selectedIndex!].tooltip.isNotEmpty)
        ? widget.data[_selectedIndex!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: const Cubic(0.22, 1.0, 0.36, 1.0),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SizeTransition(
              sizeFactor: anim,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
          child: selected == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(_selectedIndex),
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.zinc900,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        selected.tooltip,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        SizedBox(
          height: 96,
          child: Stack(
            children: [
              // Y-Axis Gridlines & Labels
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GridLineRow(label: widget.showYAxisLabels ? '12AM' : null),
                      _GridLineRow(label: widget.showYAxisLabels ? '12PM' : null),
                      _GridLineRow(label: widget.showYAxisLabels ? '11PM' : null),
                    ],
                  ),
                ),
              ),
              // Bars
              Padding(
                padding: EdgeInsets.only(left: widget.showYAxisLabels ? 30 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(widget.data.length, (i) {
                    final item = widget.data[i];
                    final ratio =
                        item.max > 0 ? (item.value / item.max).clamp(0.0, 1.0) : 0.0;
                    final heightFactor =
                        item.isCompleted ? math.max(ratio * 0.90, 0.05) : 0.05;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (!item.isCompleted) return;
                          setState(() {
                            _selectedIndex = _selectedIndex == i ? null : i;
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: widget.barGap / 2),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 220 + i * 10),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: constraints.maxHeight * heightFactor,
                                  decoration: BoxDecoration(
                                    color: item.isCompleted
                                        ? widget.barColor.withValues(alpha: 0.85)
                                        : widget.emptyBarColor,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(widget.barTopRadius),
                                    ),
                                    border: item.isToday
                                        ? Border.all(
                                            color: Colors.white.withValues(alpha: 0.25),
                                            width: 1,
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.only(left: widget.showYAxisLabels ? 30 : 0),
          child: Row(
            children: List.generate(widget.data.length, (i) {
              final item = widget.data[i];
              return Expanded(
                child: Center(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: item.isToday ? Colors.white : AppColors.zinc500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _GridLineRow extends StatelessWidget {
  final String? label;

  const _GridLineRow({this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (label != null)
          SizedBox(
            width: 26,
            child: Text(
              label!,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.zinc500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (label != null) const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
      ],
    );
  }
}

class HabitCalendarGrid extends StatefulWidget {
  final Habit habit;
  final List<String> completions;

  const HabitCalendarGrid({
    super.key,
    required this.habit,
    required this.completions,
  });

  @override
  State<HabitCalendarGrid> createState() => _HabitCalendarGridState();
}

class _HabitCalendarGridState extends State<HabitCalendarGrid> {
  late DateTime _currentMonth;

  static const _shortMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = findHabitColor(widget.habit.color).color;
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayWeekday = DateTime(year, month, 1).weekday % 7; // Sun=0..Sat=6
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final now = DateTime.now();
    final isCurrentMonth = now.year == year && now.month == month;
    final todayDay = now.day;

    const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _currentMonth = DateTime(year, month - 1, 1);
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_left,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              '${_shortMonths[month - 1]} $year',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _currentMonth = DateTime(year, month + 1, 1);
                });
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: weekDays
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        ..._buildCalendarRows(
          year: year,
          month: month,
          firstDayWeekday: firstDayWeekday,
          daysInMonth: daysInMonth,
          isCurrentMonth: isCurrentMonth,
          todayDay: todayDay,
          habitColor: habitColor,
        ),
      ],
    );
  }

  List<Widget> _buildCalendarRows({
    required int year,
    required int month,
    required int firstDayWeekday,
    required int daysInMonth,
    required bool isCurrentMonth,
    required int todayDay,
    required Color habitColor,
  }) {
    final totalCells = firstDayWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    return List.generate(rowCount, (row) {
      return Padding(
        padding: EdgeInsets.only(bottom: row == rowCount - 1 ? 0 : 4),
        child: Row(
          children: List.generate(7, (col) {
            final cellIdx = row * 7 + col;
            if (cellIdx < firstDayWeekday || cellIdx >= totalCells) {
              return const Expanded(child: SizedBox(height: 22));
            }
            final day = cellIdx - firstDayWeekday + 1;
            final isToday = isCurrentMonth && day == todayDay;
            final dateStr =
                '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            final completed = isDateCompleted(widget.completions, dateStr);

            return Expanded(
              child: SizedBox(
                height: 22,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed ? habitColor : Colors.transparent,
                      border: !completed && isToday
                          ? Border.all(color: AppColors.blue, width: 1)
                          : null,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: (completed || isToday)
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: completed
                            ? Colors.black
                            : isToday
                                ? AppColors.blue
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
    });
  }
}
