import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../widgets/glass.dart';

class TimePickerResult {
  final String? time;
  final bool cleared;

  const TimePickerResult({this.time, this.cleared = false});
}

Future<TimePickerResult?> showGlassTimePicker({
  required BuildContext context,
  String? initialTime,
  String title = 'Set Reminder Time',
  String subtitle = 'Daily alert schedule',
  bool allowClear = true,
}) {
  return showGeneralDialog<TimePickerResult>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss time picker',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: AppMotion.medium,
    pageBuilder: (dialogContext, anim1, anim2) {
      return _GlassTimePickerDialog(
        initialTime: initialTime,
        title: title,
        subtitle: subtitle,
        allowClear: allowClear,
      );
    },
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppMotion.smoothOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _GlassTimePickerDialog extends StatefulWidget {
  final String? initialTime;
  final String title;
  final String subtitle;
  final bool allowClear;

  const _GlassTimePickerDialog({
    required this.initialTime,
    required this.title,
    required this.subtitle,
    required this.allowClear,
  });

  @override
  State<_GlassTimePickerDialog> createState() => _GlassTimePickerDialogState();
}

class _GlassTimePickerDialogState extends State<_GlassTimePickerDialog> {
  static const List<({String label, String value})> _presets = [
    (label: '8:00 AM', value: '08:00'),
    (label: '9:00 AM', value: '09:00'),
    (label: '12:30 PM', value: '12:30'),
    (label: '6:00 PM', value: '18:00'),
    (label: '9:00 PM', value: '21:00'),
  ];

  late int _hour12; // 1..12
  late int _minute; // 0..59
  late bool _isPm;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final parsed = TodoModel.parseReminderTime(widget.initialTime);
    final initialHour24 = parsed?.hour ?? 9;
    final initialMinute = parsed?.minute ?? 0;
    _isPm = initialHour24 >= 12;
    _hour12 = initialHour24 % 12 == 0 ? 12 : initialHour24 % 12;
    _minute = initialMinute;
    _hourController = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  String _to24HourString() {
    var hour24 = _hour12 % 12;
    if (_isPm) {
      hour24 += 12;
    }
    return '${hour24.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';
  }

  void _applyPreset(String hhmm) {
    final parsed = TodoModel.parseReminderTime(hhmm);
    if (parsed == null) return;
    final nextPm = parsed.hour >= 12;
    final nextHour12 = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final nextMin = parsed.minute;
    setState(() {
      _isPm = nextPm;
      _hour12 = nextHour12;
      _minute = nextMin;
    });
    _hourController.animateToItem(
      nextHour12 - 1,
      duration: AppMotion.fast,
      curve: AppMotion.smoothOut,
    );
    _minuteController.animateToItem(
      nextMin,
      duration: AppMotion.fast,
      curve: AppMotion.smoothOut,
    );
  }

  void _stepHour(int delta) {
    final next = ((_hour12 - 1 + delta) % 12 + 12) % 12 + 1;
    setState(() => _hour12 = next);
    _hourController.animateToItem(
      next - 1,
      duration: AppMotion.fast,
      curve: AppMotion.smoothOut,
    );
  }

  void _stepMinute(int delta) {
    final next = ((_minute + delta) % 60 + 60) % 60;
    setState(() => _minute = next);
    _minuteController.animateToItem(
      next,
      duration: AppMotion.fast,
      curve: AppMotion.smoothOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentHhmm = _to24HourString();
    final formatted = TodoModel.formatReminderTime(currentHhmm) ?? '9:00 AM';

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 368),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Material(
                  color: Colors.transparent,
                  child: GlassCard(
                    enableBlur: false,
                    borderRadius: 28,
                    backgroundColor:
                        const Color(0xFF141418).withValues(alpha: 0.96),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.blue.withValues(alpha: 0.35),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.alarmClock,
                                size: 18,
                                color: AppColors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    widget.subtitle,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Selected time hero preview
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatted,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'DAILY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.blue,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Wheel pickers + AM/PM toggle
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _WheelColumn(
                                  label: 'HOUR',
                                  controller: _hourController,
                                  itemCount: 12,
                                  selectedIndex: _hour12 - 1,
                                  labelBuilder: (i) => '${i + 1}',
                                  onChanged: (idx) =>
                                      setState(() => _hour12 = idx + 1),
                                  onIncrement: () => _stepHour(1),
                                  onDecrement: () => _stepHour(-1),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.zinc500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _WheelColumn(
                                  label: 'MIN',
                                  controller: _minuteController,
                                  itemCount: 60,
                                  selectedIndex: _minute,
                                  labelBuilder: (i) =>
                                      i.toString().padLeft(2, '0'),
                                  onChanged: (idx) =>
                                      setState(() => _minute = idx),
                                  onIncrement: () => _stepMinute(5),
                                  onDecrement: () => _stepMinute(-5),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'PERIOD',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.zinc500,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _PeriodPill(
                                    label: 'AM',
                                    active: !_isPm,
                                    onTap: () => setState(() => _isPm = false),
                                  ),
                                  const SizedBox(height: 8),
                                  _PeriodPill(
                                    label: 'PM',
                                    active: _isPm,
                                    onTap: () => setState(() => _isPm = true),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Quick presets
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _presets.map((preset) {
                            final active = currentHhmm == preset.value;
                            return BounceTap(
                              scaleDown: 0.95,
                              onTap: () => _applyPreset(preset.value),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.blue.withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.blue.withValues(alpha: 0.55)
                                        : AppColors.borderSubtle,
                                  ),
                                ),
                                child: Text(
                                  preset.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : AppColors.zinc400,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Actions
                        Row(
                          children: [
                            if (widget.allowClear) ...[
                              BounceTap(
                                onTap: () => Navigator.of(context).pop(
                                  const TimePickerResult(cleared: true),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.red.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: BounceTap(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.zinc300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: BounceTap(
                                onTap: () => Navigator.of(context).pop(
                                  TimePickerResult(time: _to24HourString()),
                                ),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.blue,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.blue
                                            .withValues(alpha: 0.28),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Set Time',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  final String label;
  final FixedExtentScrollController controller;
  final int itemCount;
  final int selectedIndex;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _WheelColumn({
    required this.label,
    required this.controller,
    required this.itemCount,
    required this.selectedIndex,
    required this.labelBuilder,
    required this.onChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.zinc500,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        BounceTap(
          onTap: onDecrement,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 18,
              color: AppColors.zinc400,
            ),
          ),
        ),
        SizedBox(
          height: 112,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.blue.withValues(alpha: 0.35),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 38,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                diameterRatio: 1.6,
                onSelectedItemChanged: onChanged,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: itemCount,
                  builder: (context, index) {
                    final selected = index == selectedIndex;
                    return Center(
                      child: Text(
                        labelBuilder(index),
                        style: TextStyle(
                          fontSize: selected ? 20 : 15,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected ? Colors.white : AppColors.zinc500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        BounceTap(
          onTap: onIncrement,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.zinc400,
            ),
          ),
        ),
      ],
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppColors.blue
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.blue
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : AppColors.zinc400,
          ),
        ),
      ),
    );
  }
}
