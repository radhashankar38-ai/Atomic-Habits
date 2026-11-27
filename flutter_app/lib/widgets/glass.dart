import 'dart:async';
import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import '../constants/app_constants.dart';

class AppMotion {
  static const Curve smoothOut = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve smoothInOut = Cubic(0.45, 0.0, 0.55, 1.0);
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration sheet = Duration(milliseconds: 340);
  static const Duration sheetReverse = Duration(milliseconds: 250);
}

class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cache static radial ambient glows on their own GPU layer.
          RepaintBoundary(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    top: -160,
                    right: -160,
                    child: Container(
                      width: 560,
                      height: 560,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.blue.withValues(alpha: 0.08),
                            AppColors.blue.withValues(alpha: 0.02),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -140,
                    left: -140,
                    child: Container(
                      width: 460,
                      height: 460,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.red.withValues(alpha: 0.04),
                            AppColors.red.withValues(alpha: 0.01),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final BorderRadius? customBorderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final double blurSigma;
  final bool enableBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.customBorderRadius,
    this.padding,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.shadows,
    this.blurSigma = 18,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = customBorderRadius ?? BorderRadius.circular(borderRadius);
    final effectiveGradient = gradient ??
        (backgroundColor == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.065),
                  Colors.white.withValues(alpha: 0.025),
                ],
              )
            : null);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveGradient == null
            ? (backgroundColor ?? AppColors.card)
            : null,
        gradient: effectiveGradient,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: child,
    );

    if (enableBlur && blurSigma > 0) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      child: content,
    );
  }
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;
  final bool enableBlur;

  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 14,
    this.enableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardSecondary,
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: child,
    );

    if (!enableBlur || blurSigma <= 0) {
      return panel;
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: panel,
      ),
    );
  }
}

class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final HitTestBehavior behavior;

  const BounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 210),
    );
    _rebuildScale();
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  void _rebuildScale() {
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: AppMotion.smoothOut,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant BounceTap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleDown != widget.scaleDown) {
      _rebuildScale();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (_controller.isAnimating) {
      _controller.forward().whenComplete(() {
        if (mounted) _controller.reverse();
      });
    } else {
      _controller.reverse();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: widget.onTap == null ? null : _handleTapDown,
      onTapUp: widget.onTap == null ? null : _handleTapUp,
      onTapCancel: widget.onTap == null ? null : _handleTapCancel,
      child: FadeTransition(
        opacity: _opacityAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: widget.child,
        ),
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration delay;
  final Duration charDuration;
  final int? maxLines;
  final TextOverflow? overflow;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.delay = Duration.zero,
    this.charDuration = const Duration(milliseconds: 22),
    this.maxLines,
    this.overflow,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;
  int _lastShownCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  void _startTyping() {
    _delayTimer?.cancel();
    _controller.stop();
    _controller.value = 0;
    _lastShownCount = 0;

    if (widget.text.isEmpty) return;

    final totalMs = (widget.text.length * widget.charDuration.inMilliseconds)
        .clamp(120, 1400);
    _controller.duration = Duration(milliseconds: totalMs);

    if (widget.delay == Duration.zero) {
      _controller.forward(from: 0);
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final len = widget.text.length;
        final count = (_controller.value * len).round().clamp(0, len);
        if (count != _lastShownCount) {
          _lastShownCount = count;
        }
        return Text(
          count >= len ? widget.text : widget.text.substring(0, count),
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, required this.color, this.size = 8});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
