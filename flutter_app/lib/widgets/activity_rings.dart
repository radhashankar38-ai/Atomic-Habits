import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';

class ActivityRings extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, List<String>> completions;
  final double size;

  const ActivityRings({
    super.key,
    required this.habits,
    required this.completions,
    this.size = 208,
  });

  @override
  Widget build(BuildContext context) {
    final visible = habits.take(3).toList();
    final specs = <_RingSpec>[];

    for (var i = 0; i < visible.length; i++) {
      final habit = visible[i];
      final color = findHabitColor(habit.color, fallbackIndex: i).color;
      final habitComps = completions[habit.id] ?? const [];
      final double progress;
      if (habit.targetDays > 0) {
        progress = (habitComps.length / habit.targetDays).clamp(0.0, 1.0);
      } else {
        progress = habitComps.isNotEmpty ? 1.0 : 0.0;
      }
      specs.add(_RingSpec(
        radiusRatio: (44.0 - (i * 10.0)) / 100.0,
        color: color,
        progress: progress,
      ));
    }

    return SizedBox(
      width: size,
      height: size,
      child: _AnimatedRingsPainterWidget(specs: specs),
    );
  }
}

class _RingSpec {
  final double radiusRatio;
  final Color color;
  final double progress;

  const _RingSpec({
    required this.radiusRatio,
    required this.color,
    required this.progress,
  });
}

class _AnimatedRingsPainterWidget extends StatefulWidget {
  final List<_RingSpec> specs;

  const _AnimatedRingsPainterWidget({required this.specs});

  @override
  State<_AnimatedRingsPainterWidget> createState() =>
      _AnimatedRingsPainterWidgetState();
}

class _AnimatedRingsPainterWidgetState
    extends State<_AnimatedRingsPainterWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<double> _oldProgresses = [];
  List<double> _newProgresses = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _oldProgresses = List.filled(widget.specs.length, 0.0);
    _newProgresses = widget.specs.map((s) => s.progress).toList();
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _AnimatedRingsPainterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLen = _newProgresses.length;
    _oldProgresses = List.generate(widget.specs.length, (i) {
      if (i < oldLen) {
        final t = Curves.easeOutBack.transform(_controller.value).clamp(0.0, 1.15);
        final prevOld = i < _oldProgresses.length ? _oldProgresses[i] : 0.0;
        return prevOld + (_newProgresses[i] - prevOld) * t;
      }
      return 0.0;
    });
    _newProgresses = widget.specs.map((s) => s.progress).toList();
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = const Cubic(0.22, 1.0, 0.36, 1.0).transform(_controller.value);
        final current = List.generate(widget.specs.length, (i) {
          final start = i < _oldProgresses.length ? _oldProgresses[i] : 0.0;
          final end = _newProgresses[i];
          return (start + (end - start) * t).clamp(0.0, 1.0);
        });
        return RepaintBoundary(
          child: CustomPaint(
            painter: _ActivityRingsPainter(
              specs: widget.specs,
              progresses: current,
            ),
          ),
        );
      },
    );
  }
}

class _ActivityRingsPainter extends CustomPainter {
  final List<_RingSpec> specs;
  final List<double> progresses;

  const _ActivityRingsPainter({
    required this.specs,
    required this.progresses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.08;

    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      final radius = size.width * spec.radiusRatio;
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Background Track (opacity 0.1)
      final trackPaint = Paint()
        ..color = spec.color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, trackPaint);

      final p = i < progresses.length ? progresses[i] : 0.0;
      if (p > 0.001) {
        final sweepAngle = 2 * math.pi * p;

        // Subtle outer glow
        final glowPaint = Paint()
          ..color = spec.color.withValues(alpha: 0.27)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, glowPaint);

        // Foreground progress ring
        final progressPaint = Paint()
          ..color = spec.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityRingsPainter oldDelegate) {
    return oldDelegate.specs != specs || oldDelegate.progresses != progresses;
  }
}
