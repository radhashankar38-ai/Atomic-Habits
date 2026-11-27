import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../utils/share_helper.dart';
import '../widgets/glass.dart';
import 'time_picker_dialog.dart';

class SettingsSheet extends StatefulWidget {
  final HabitStore store;
  final VoidCallback onClearDataRequest;

  const SettingsSheet({
    super.key,
    required this.store,
    required this.onClearDataRequest,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  Future<void> _editNotificationSlot(HabitStore store, int index) async {
    final result = await showGlassTimePicker(
      context: context,
      initialTime: store.notificationTimes[index],
      title: 'Notification Time #${index + 1}',
      subtitle: 'Customize when daily reminders fire',
      allowClear: false,
    );
    if (!mounted || result == null || result.time == null) return;
    store.setNotificationTime(index, result.time!);
  }

  Future<void> _sendTestNotification(HabitStore store) async {
    await store.requestNotificationPermission();
    final kind = store.notifyHabits ? 'habits' : 'todos';
    final sent = await store.sendTestNotification(kind: kind);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceDark,
        content: Text(
          sent
              ? 'Preview notification sent to your device!'
              : 'Notification schedule saved. Enable notifications on Android to preview.',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _importData() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final text = utf8.decode(bytes);

      final ok = widget.store.importBackupJson(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceDark,
            content: Text(
              ok ? 'Data imported successfully!' : 'Invalid backup JSON file.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _shareQr() async {
    try {
      final data = await rootBundle.load('assets/images/gpay_qr.png');
      await ShareHelper.sharePngBytes(
        bytes: data.buffer.asUint8List(),
        filename: 'support-developer-gpay-qr.png',
        title: 'Support Developer — GPay UPI QR',
        text: 'Scan with Google Pay or any UPI app to support the developer!',
      );
    } catch (_) {}
  }

  void _showSupportDeveloperDialog() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Support Developer',
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: AppMotion.medium,
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
      pageBuilder: (dialogCtx, _, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Material(
                color: Colors.transparent,
                child: GlassCard(
                  enableBlur: true,
                  blurSigma: 18,
                  borderRadius: 28,
                  backgroundColor: const Color(0xFF141418).withValues(alpha: 0.96),
                  borderColor: AppColors.yellow.withValues(alpha: 0.28),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.yellow.withValues(alpha: 0.14),
                              border: Border.all(
                                color: AppColors.yellow.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.heart,
                              size: 18,
                              color: AppColors.yellow,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Support Developer',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'GPAY / UPI SUPPORT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.yellow,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BounceTap(
                            scaleDown: 0.9,
                            onTap: () => Navigator.of(dialogCtx).pop(),
                            child: const GlassPanel(
                              borderRadius: 999,
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                LucideIcons.x,
                                size: 16,
                                color: AppColors.zinc400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/gpay_qr.png',
                            height: 250,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Thank you for supporting development! Scan with Google Pay or tap Share QR to pay on this device.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: BounceTap(
                              onTap: _shareQr,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.blue.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      LucideIcons.share2,
                                      size: 14,
                                      color: AppColors.blue,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Share QR',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BounceTap(
                              onTap: () => Navigator.of(dialogCtx).pop(),
                              child: const GlassPanel(
                                borderRadius: 14,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Done',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final store = widget.store;
        return Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: GlassCard(
              enableBlur: true,
              blurSigma: 16,
              customBorderRadius:
                  const BorderRadius.vertical(top: Radius.circular(40)),
              backgroundColor: const Color(0xFF141416).withValues(alpha: 0.94),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 32,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cardSecondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notifications & Haptics Panel
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        _SettingToggleRow(
                          icon: LucideIcons.bell,
                          label: 'Notifications',
                          value: store.notificationsEnabled,
                          onChanged: store.setNotificationsEnabled,
                          showBottomBorder: true,
                        ),
                        AnimatedSize(
                          duration: AppMotion.medium,
                          curve: AppMotion.smoothOut,
                          child: store.notificationsEnabled
                              ? _NotificationCustomizationSection(
                                  store: store,
                                  onEditTimeSlot: (idx) =>
                                      _editNotificationSlot(store, idx),
                                  onTestNotification: () =>
                                      _sendTestNotification(store),
                                )
                              : const SizedBox.shrink(),
                        ),
                        _SettingToggleRow(
                          icon: LucideIcons.smartphone,
                          label: 'Haptics',
                          value: store.hapticsEnabled,
                          onChanged: store.setHapticsEnabled,
                          showBottomBorder: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Import Data
                  BounceTap(
                    onTap: _importData,
                    child: GlassPanel(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.08),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.upload,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Import Data',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Support Developer (reveals hidden GPay QR)
                  BounceTap(
                    onTap: _showSupportDeveloperDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.yellow.withValues(alpha: 0.16),
                            AppColors.orange.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.yellow.withValues(alpha: 0.30),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.heart,
                            size: 16,
                            color: AppColors.yellow,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Support Developer',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.yellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Clear Data
                  BounceTap(
                    onTap: widget.onClearDataRequest,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.alertCircle,
                            size: 16,
                            color: AppColors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Clear Data',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Version & Developer Credit
                  const Text(
                    'VERSION 1.2.0',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'DEVELOPED BY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _gradientController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment(-1 + _gradientController.value * 2, 0),
                            end: Alignment(1 + _gradientController.value * 2, 0),
                            colors: const [
                              AppColors.blue,
                              AppColors.indigo,
                              AppColors.blue,
                            ],
                          ).createShader(bounds);
                        },
                        child: child,
                      );
                    },
                    child: const Text(
                      'saisriram Sr',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationCustomizationSection extends StatelessWidget {
  final HabitStore store;
  final ValueChanged<int> onEditTimeSlot;
  final VoidCallback onTestNotification;

  const _NotificationCustomizationSection({
    required this.store,
    required this.onEditTimeSlot,
    required this.onTestNotification,
  });

  @override
  Widget build(BuildContext context) {
    final activeTimes = store.activeNotificationTimes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0x33000000),
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAILY FREQUENCY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.zinc500,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${store.notificationsPerDay}× per day',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (i) {
              final count = i + 1;
              final active = store.notificationsPerDay == count;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                  child: BounceTap(
                    scaleDown: 0.95,
                    onTap: () => store.setNotificationsPerDay(count),
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.blue
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                              ? AppColors.blue
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '$count×',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : AppColors.zinc400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          const Text(
            'NOTIFICATION TIMINGS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.zinc500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final chipWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(activeTimes.length, (index) {
                  final formatted =
                      TodoModel.formatReminderTime(activeTimes[index]) ??
                          activeTimes[index];
                  return SizedBox(
                    width: chipWidth,
                    child: BounceTap(
                      scaleDown: 0.96,
                      onTap: () => onEditTimeSlot(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.blue.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.alarmClock,
                              size: 13,
                              color: AppColors.blue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formatted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              LucideIcons.edit2,
                              size: 11,
                              color: AppColors.zinc500,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _NotifyCategoryChip(
                icon: LucideIcons.flame,
                label: 'Habits',
                active: store.notifyHabits,
                onTap: () => store.setNotifyHabits(!store.notifyHabits),
              ),
              const SizedBox(width: 6),
              _NotifyCategoryChip(
                icon: LucideIcons.checkCircle,
                label: 'Tasks',
                active: store.notifyTodos,
                onTap: () => store.setNotifyTodos(!store.notifyTodos),
              ),
              const Spacer(),
              BounceTap(
                scaleDown: 0.95,
                onTap: onTestNotification,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.blue.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        size: 12,
                        color: AppColors.blue,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Test',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tasks with a reminder time also trigger a dedicated alert.',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.zinc500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifyCategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NotifyCategoryChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      scaleDown: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.iosGreen.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? AppColors.iosGreen.withValues(alpha: 0.45)
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: active ? AppColors.iosGreen : AppColors.zinc500,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.zinc500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showBottomBorder;

  const _SettingToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.showBottomBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: showBottomBorder
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderSubtle),
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.blue),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 40,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: value ? AppColors.iosGreen : AppColors.zinc600,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
