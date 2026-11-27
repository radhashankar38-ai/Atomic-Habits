import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../widgets/glass.dart';

Future<bool> showGlassConfirmDialog(
  BuildContext context, {
  required String title,
  required Widget body,
  required String confirmLabel,
  required Color confirmColor,
  Color confirmTextColor = Colors.white,
  bool showDangerIcon = false,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Material(
              color: Colors.transparent,
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDangerIcon) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 48,
                          height: 48,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.alertCircle,
                            size: 24,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    body,
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: BounceTap(
                            onTap: () => Navigator.of(context).pop(false),
                            child: GlassPanel(
                              borderRadius: 12,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              child: const Text(
                                'Cancel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BounceTap(
                            onTap: () => Navigator.of(context).pop(true),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: confirmColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                confirmLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: confirmTextColor,
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
      );
    },
    transitionBuilder: (context, anim, _, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(
            CurvedAnimation(
              parent: anim,
              curve: AppMotion.smoothOut,
              reverseCurve: AppMotion.smoothInOut,
            ),
          ),
          child: child,
        ),
      );
    },
  );
  return result == true;
}

Future<String?> showReflectionNoteDialog(
  BuildContext context, {
  required NoteDraft draft,
}) {
  final controller = TextEditingController(text: draft.content);
  final parsed = DateTime.tryParse(draft.date)?.toLocal();
  final formattedDate = parsed != null
      ? '${_weekday(parsed.weekday)}, ${_month(parsed.month)} ${parsed.day}'
      : draft.date;

  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Reflection Note',
    barrierColor: Colors.black.withValues(alpha: 0.74),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (context, anim, _, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(
              parent: anim,
              curve: AppMotion.smoothOut,
              reverseCurve: AppMotion.smoothInOut,
            ),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 384),
            child: Material(
              color: Colors.transparent,
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Reflection Note',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDate.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.zinc500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassPanel(
                      borderRadius: 16,
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        maxLines: 5,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'How did it go today?',
                          hintStyle: TextStyle(color: AppColors.zinc500),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: BounceTap(
                            onTap: () => Navigator.of(context).pop(),
                            child: GlassPanel(
                              borderRadius: 12,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: const Text(
                                'Cancel',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BounceTap(
                            onTap: () =>
                                Navigator.of(context).pop(controller.text),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        AppColors.blue.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Save',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
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
      );
    },
  );
}

String _weekday(int wd) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return days[(wd - 1).clamp(0, 6)];
}

String _month(int m) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[(m - 1).clamp(0, 11)];
}
