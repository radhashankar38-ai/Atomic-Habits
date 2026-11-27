import 'dart:math' as math;
import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../utils/share_helper.dart';
import '../widgets/glass.dart';

class CertificateModal extends StatefulWidget {
  final Habit habit;
  final String userName;
  final VoidCallback onClose;

  const CertificateModal({
    super.key,
    required this.habit,
    required this.userName,
    required this.onClose,
  });

  @override
  State<CertificateModal> createState() => _CertificateModalState();
}

class _CertificateModalState extends State<CertificateModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  final GlobalKey _captureKey = GlobalKey();
  bool _isGenerating = false;
  bool _showSavedToast = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  HabitMilestone get _milestone {
    for (final m in habitMilestones.reversed) {
      if (widget.habit.targetDays >= m.req) return m;
    }
    return habitMilestones.first;
  }

  Future<void> _share4K() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final png = await ShareHelper.captureBoundaryPng(
        _captureKey,
        pixelRatio: 8.0, // ~3840px 4K resolution on ~448px card
      );
      final shareText =
          'I just mastered my "${widget.habit.name}" habit for ${widget.habit.targetDays} days! 🏆 #HabitTracker #Consistency';
      if (png != null) {
        await ShareHelper.sharePngBytes(
          bytes: png,
          filename: 'certificate-${widget.habit.name}.png',
          title: 'Habit Mastered!',
          text: shareText,
        );
        if (mounted) {
          setState(() => _showSavedToast = true);
          Future<void>.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showSavedToast = false);
          });
        }
      } else {
        await ShareHelper.shareText(title: 'Habit Mastered!', text: shareText);
      }
    } catch (_) {
      try {
        await ShareHelper.shareText(
          text:
              'I just mastered my "${widget.habit.name}" habit for ${widget.habit.targetDays} days! 🏆',
        );
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  IconData _filledMilestoneIcon(String tier) {
    return switch (tier) {
      'Bronze' => Icons.star_rounded,
      'Silver' => Icons.shield,
      'Gold' => Icons.emoji_events,
      'Platinum' => Icons.workspace_premium,
      _ => Icons.star_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cObj = findHabitColor(widget.habit.color);
    final milestone = _milestone;
    final completedDate = widget.habit.completedAt != null
        ? DateTime.tryParse(widget.habit.completedAt!)?.toLocal()
        : DateTime.now();
    final dateText = completedDate != null
        ? '${completedDate.month}/${completedDate.day}/${completedDate.year}'
        : '';

    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 48,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        // Capture Region (Pure Black Certificate Card)
                        RepaintBoundary(
                          key: _captureKey,
                          child: Container(
                            color: Colors.black,
                            child: Stack(
                              children: [
                                // Ambient glows inside certificate
                                Positioned(
                                  top: -120,
                                  left: -120,
                                  child: Container(
                                    width: 260,
                                    height: 260,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppColors.blue.withValues(alpha: 0.15),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: -120,
                                  right: -120,
                                  child: Container(
                                    width: 260,
                                    height: 260,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppColors.red.withValues(alpha: 0.15),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Top shimmer hairline
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withValues(alpha: 0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    64,
                                    32,
                                    32,
                                  ),
                                  child: Column(
                                    children: [
                                      // Emblem with rotating dashed border
                                      SizedBox(
                                        width: 128,
                                        height: 128,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 128,
                                              height: 128,
                                              decoration: BoxDecoration(
                                                color: cObj.color,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 50,
                                                  ),
                                                ],
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    _filledMilestoneIcon(
                                                      milestone.tier,
                                                    ),
                                                    size: 46,
                                                    color: Colors.black,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    milestone.tier.toUpperCase(),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.black,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            AnimatedBuilder(
                                              animation: _spinController,
                                              builder: (context, child) {
                                                return Transform.rotate(
                                                  angle: _spinController.value *
                                                      2 *
                                                      math.pi,
                                                  child: child,
                                                );
                                              },
                                              child: CustomPaint(
                                                size: const Size(112, 112),
                                                painter: _DashedCirclePainter(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 36),

                                      // Mastery Header
                                      const Text(
                                        'MASTERY',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                          height: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${milestone.tier.toUpperCase()} ACHIEVEMENT',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.zinc500,
                                          letterSpacing: 4.0,
                                        ),
                                      ),
                                      const SizedBox(height: 32),

                                      // Completed Section
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 28,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.symmetric(
                                            horizontal: BorderSide(
                                              color: Colors.white
                                                  .withValues(alpha: 0.1),
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'SUCCESSFULLY COMPLETED',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.8,
                                                color: AppColors.zinc400
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              widget.habit.name,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.w900,
                                                color: cObj.color,
                                                letterSpacing: -0.8,
                                                height: 1.05,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Text.rich(
                                              TextSpan(
                                                text: 'for a total of ',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.zinc400,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text:
                                                        '${widget.habit.targetDays} days',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 28),

                                      // Date & Verified By
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'DATE OF ACHIEVEMENT',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.zinc500
                                                        .withValues(alpha: 0.6),
                                                    letterSpacing: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  dateText,
                                                  style:
                                                      GoogleFonts.jetBrainsMono(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.zinc300,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'VERIFIED BY',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                    color: AppColors.zinc500
                                                        .withValues(alpha: 0.6),
                                                    letterSpacing: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  widget.userName.isNotEmpty
                                                      ? widget.userName
                                                      : 'User',
                                                  textAlign: TextAlign.right,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontFamily: 'serif',
                                                    fontStyle: FontStyle.italic,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFFE4E4E7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Opacity(
                                        opacity: 0.1,
                                        child: const Text(
                                          '4K ULTRA HD AUTHENTIC GENERATION',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 3.5,
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

                        // Floating Top Controls
                        Positioned(
                          top: 20,
                          left: 20,
                          right: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: _share4K,
                                    child: Opacity(
                                      opacity: _isGenerating ? 0.5 : 1.0,
                                      child: Container(
                                        height: 40,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_isGenerating)
                                              const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            else
                                              const Icon(
                                                LucideIcons.share2,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _isGenerating
                                                  ? 'GENERATING 4K...'
                                                  : 'SHARE 4K ACHIEVEMENT',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_showSavedToast)
                                    Positioned(
                                      top: -30,
                                      left: 0,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Saved!',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              GestureDetector(
                                onTap: widget.onClose,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Claim Achievement CTA
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                      child: BounceTap(
                        scaleDown: 0.95,
                        onTap: widget.onClose,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: cObj.color,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: cObj.color.withValues(alpha: 0.25),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Text(
                            'CLAIM ACHIEVEMENT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 32;
    const dashAngle = (2 * math.pi) / dashCount;

    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashAngle * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
