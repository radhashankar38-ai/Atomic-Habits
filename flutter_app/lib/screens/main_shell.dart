import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../modals/add_edit_habit_sheet.dart';
import '../modals/certificate_modal.dart';
import '../modals/confirm_dialogs.dart';
import '../modals/habit_detail_sheet.dart';
import '../modals/settings_sheet.dart';
import '../models/habit.dart';
import '../screens/badges_tab.dart';
import '../screens/completed_tab.dart';
import '../screens/home_tab.dart';
import '../screens/progress_tab.dart';
import '../screens/todo_sheet.dart';
import '../state/habit_store.dart';
import '../utils/habit_math.dart';
import '../widgets/glass.dart';

class MainShell extends StatefulWidget {
  final HabitStore store;

  const MainShell({super.key, required this.store});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  final ScrollController _homeScroll = ScrollController();
  final ScrollController _progressScroll = ScrollController();
  final ScrollController _badgesScroll = ScrollController();
  final ScrollController _completedScroll = ScrollController();
  late final ConfettiController _confettiController;

  bool _showNav = true;
  bool _isTodoOpen = false;
  bool _isModalOverlayOpen = false;
  Habit? _certificateHabit;
  String? _pendingEditTodoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 1800));
    _homeScroll.addListener(() => _handleScroll(_homeScroll));
    _progressScroll.addListener(() => _handleScroll(_progressScroll));
    _badgesScroll.addListener(() => _handleScroll(_badgesScroll));
    _completedScroll.addListener(() => _handleScroll(_completedScroll));
    widget.store.addListener(_onStoreUpdate);
    _setupWidgetBridge();
  }

  void _setupWidgetBridge() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    HabitStore.widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'openTab' && mounted) {
        final args = call.arguments;
        final tab = args is Map ? args['tab']?.toString() : null;
        final editTodoId = args is Map ? args['editTodoId']?.toString() : null;
        _openRequestedTab(tab, editTodoId: editTodoId);
      }
      return null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        final launch = await HabitStore.widgetChannel
            .invokeMapMethod<String, dynamic>('consumePendingLaunch');
        if (mounted && launch != null) {
          _openRequestedTab(
            launch['tab']?.toString(),
            editTodoId: launch['editTodoId']?.toString(),
          );
          return;
        }
      } on MissingPluginException {
        return;
      } catch (_) {}

      try {
        final tab = await HabitStore.widgetChannel
            .invokeMethod<String>('consumePendingTab');
        if (mounted && tab != null && tab.isNotEmpty) {
          _openRequestedTab(tab);
        }
      } on MissingPluginException {
        // No host bridge in headless tests.
      } catch (_) {}
    });
  }

  void _openRequestedTab(String? tab, {String? editTodoId}) {
    final hasEditTodo = editTodoId != null && editTodoId.isNotEmpty;
    if (tab == 'todo' || hasEditTodo) {
      widget.store.setActiveTab(AppTab.home);
      setState(() {
        _isTodoOpen = true;
        if (hasEditTodo) {
          _pendingEditTodoId = editTodoId;
        }
      });
    } else if (tab == 'progress') {
      setState(() => _isTodoOpen = false);
      _switchTab(AppTab.progress);
    } else if (tab == 'home') {
      setState(() => _isTodoOpen = false);
      _switchTab(AppTab.home);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.store.reloadExternalChanges();
    }
  }

  void _onStoreUpdate() {
    final pendingCert = widget.store.pendingCertificateHabit;
    if (pendingCert != null && mounted) {
      widget.store.clearPendingCertificate();
      _confettiController.play();
      setState(() {
        _certificateHabit = pendingCert;
      });
    }
  }

  void _handleScroll(ScrollController controller) {
    if (!controller.hasClients) return;
    final nextShow = controller.offset <= 20;
    if (nextShow != _showNav) {
      setState(() => _showNav = nextShow);
    }
  }

  ScrollController _controllerFor(AppTab tab) {
    return switch (tab) {
      AppTab.home => _homeScroll,
      AppTab.progress => _progressScroll,
      AppTab.badges => _badgesScroll,
      AppTab.completed => _completedScroll,
    };
  }

  void _switchTab(AppTab nextTab) {
    if (widget.store.activeTab == nextTab) return;
    widget.store.setActiveTab(nextTab);
    final ctrl = _controllerFor(nextTab);
    final nextShow = !ctrl.hasClients || ctrl.offset <= 20;
    if (nextShow != _showNav) {
      setState(() => _showNav = nextShow);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      HabitStore.widgetChannel.setMethodCallHandler(null);
    }
    WidgetsBinding.instance.removeObserver(this);
    widget.store.removeListener(_onStoreUpdate);
    _confettiController.dispose();
    _homeScroll.dispose();
    _progressScroll.dispose();
    _badgesScroll.dispose();
    _completedScroll.dispose();
    super.dispose();
  }

  Future<void> _openAddEditHabit({Habit? editing}) async {
    setState(() => _isModalOverlayOpen = true);
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: AppMotion.medium,
      pageBuilder: (context, anim1, anim2) {
        return AddEditHabitSheet(
          editingHabit: editing,
          onSave: ({
            required name,
            required targetDays,
            required category,
            required colorHex,
            required notes,
          }) {
            if (editing != null) {
              widget.store.updateHabit(
                id: editing.id,
                name: name,
                colorHex: colorHex,
                targetDays: targetDays,
                category: category,
                notes: notes,
              );
            } else {
              widget.store.addHabit(
                name: name,
                colorHex: colorHex,
                targetDays: targetDays,
                category: category,
                notes: notes,
              );
            }
          },
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: AppMotion.smoothOut,
          reverseCurve: AppMotion.smoothInOut,
        );
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: anim,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.14),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (mounted) setState(() => _isModalOverlayOpen = false);
  }

  Future<void> _openSettings() async {
    setState(() => _isModalOverlayOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      sheetAnimationStyle: const AnimationStyle(
        duration: AppMotion.sheet,
        reverseDuration: AppMotion.sheetReverse,
        curve: AppMotion.smoothOut,
        reverseCurve: AppMotion.smoothInOut,
      ),
      builder: (sheetCtx) {
        return SettingsSheet(
          store: widget.store,
          onClearDataRequest: () async {
            final confirmed = await showGlassConfirmDialog(
              context,
              title: 'Clear All Data?',
              showDangerIcon: true,
              confirmLabel: 'Erase Data',
              confirmColor: const Color(0xFFEF4444),
              body: const Text.rich(
                TextSpan(
                  text:
                      'Are you sure you want to delete all habits, achievements, and history? ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: 'This action cannot be undone.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF87171),
                      ),
                    ),
                  ],
                ),
              ),
            );
            if (confirmed) {
              await widget.store.clearAllData();
              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
            }
          },
        );
      },
    );
    if (mounted) setState(() => _isModalOverlayOpen = false);
  }

  Future<void> _openHabitDetail(Habit habit) async {
    setState(() => _isModalOverlayOpen = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      sheetAnimationStyle: const AnimationStyle(
        duration: AppMotion.sheet,
        reverseDuration: AppMotion.sheetReverse,
        curve: AppMotion.smoothOut,
        reverseCurve: AppMotion.smoothInOut,
      ),
      builder: (sheetCtx) {
        return AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) {
            final latest = widget.store.habits.firstWhere(
              (h) => h.id == habit.id,
              orElse: () => habit,
            );
            return HabitDetailSheet(
              habit: latest,
              store: widget.store,
              onEdit: () {
                Navigator.of(sheetCtx).pop();
                _openAddEditHabit(editing: latest);
              },
              onReset: () async {
                final cObj = findHabitColor(latest.color);
                final ok = await showGlassConfirmDialog(
                  context,
                  title: 'Reset Progress?',
                  confirmLabel: 'Reset',
                  confirmColor: cObj.color,
                  confirmTextColor: Colors.black,
                  body: const Text(
                    'Are you sure you want to reset all progress for this habit? Your streak and stats for this will start from zero.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
                if (ok) {
                  widget.store.resetHabitProgress(latest.id);
                  if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
                }
              },
              onDelete: () async {
                Navigator.of(sheetCtx).pop();
                final ok = await showGlassConfirmDialog(
                  context,
                  title: 'Delete Habit?',
                  confirmLabel: 'Delete',
                  confirmColor: AppColors.red,
                  body: const Text(
                    'Are you sure you want to delete this habit? All your completion history for this habit will be permanently removed.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
                if (ok) {
                  widget.store.deleteHabit(latest.id);
                }
              },
              onEditReflection: (draft) async {
                final updated = await showReflectionNoteDialog(
                  context,
                  draft: draft,
                );
                if (updated != null) {
                  widget.store.saveReflection(draft.habitId, draft.date, updated);
                }
              },
            );
          },
        );
      },
    );
    if (mounted) setState(() => _isModalOverlayOpen = false);
  }

  Future<void> _requestUndo(Habit habit) async {
    final cObj = findHabitColor(habit.color);
    final ok = await showGlassConfirmDialog(
      context,
      title: 'Undo Habit?',
      confirmLabel: 'Undo',
      confirmColor: cObj.color,
      confirmTextColor: Colors.black,
      body: const Text(
        "Are you sure you want to undo your progress for today? This will remove today's completion and affect your streak.",
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
    if (ok) {
      widget.store.toggleCompletion(habit.id, formatDate(DateTime.now()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final topPad = MediaQuery.of(context).padding.top;
        final bottomPad = MediaQuery.of(context).padding.bottom;

        return PopScope(
          canPop: !_isTodoOpen && _certificateHabit == null,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_certificateHabit != null) {
              setState(() => _certificateHabit = null);
            } else if (_isTodoOpen) {
              setState(() => _isTodoOpen = false);
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.bg,
            resizeToAvoidBottomInset: false,
          body: AmbientBackground(
            child: Stack(
              children: [
                // Swipeable Main Tab Content
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() < 260) return;
                    const tabs = AppTab.values;
                    final cur = tabs.indexOf(store.activeTab);
                    if (velocity < 0 && cur < tabs.length - 1) {
                      _switchTab(tabs[cur + 1]);
                    } else if (velocity > 0 && cur > 0) {
                      _switchTab(tabs[cur - 1]);
                    }
                  },
                  child: _SmoothTabViewport(
                    activeTab: store.activeTab,
                    direction: store.tabDirection,
                    tabBuilder: (tab) => switch (tab) {
                      AppTab.home => HomeTab(
                          store: store,
                          scrollController: _homeScroll,
                        ),
                      AppTab.progress => ProgressTab(
                          store: store,
                          scrollController: _progressScroll,
                          onToggleHabit: (h) {
                            store.toggleCompletion(
                              h.id,
                              formatDate(DateTime.now()),
                            );
                          },
                          onRequestUndo: _requestUndo,
                          onOpenHabitDetail: _openHabitDetail,
                        ),
                      AppTab.badges => BadgesTab(
                          store: store,
                          scrollController: _badgesScroll,
                        ),
                      AppTab.completed => CompletedTab(
                          store: store,
                          scrollController: _completedScroll,
                          onOpenCertificate: (h) {
                            setState(() => _certificateHabit = h);
                          },
                        ),
                    },
                  ),
                ),

                // Fixed Top Header Navigation
                if (!_isModalOverlayOpen && !_isTodoOpen)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.smoothOut,
                      decoration: BoxDecoration(
                        gradient: _showNav
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.90),
                                  Colors.black.withValues(alpha: 0.65),
                                  Colors.transparent,
                                ],
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          topPad + 16,
                          24,
                          16,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 672),
                            child: SizedBox(
                              height: 44,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: AnimatedOpacity(
                                      duration: AppMotion.fast,
                                      curve: AppMotion.smoothOut,
                                      opacity: _showNav ? 1 : 0,
                                      child: AnimatedSlide(
                                        duration: AppMotion.medium,
                                        curve: AppMotion.smoothOut,
                                        offset: _showNav
                                            ? Offset.zero
                                            : const Offset(-0.08, 0),
                                        child: const Align(
                                          alignment: Alignment.centerLeft,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Atomic Habits',
                                              maxLines: 1,
                                              style: TextStyle(
                                                fontSize: 30,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  BounceTap(
                                    scaleDown: 0.9,
                                    onTap: () => _openAddEditHabit(),
                                    child: GlassPanel(
                                      enableBlur: true,
                                      blurSigma: 12,
                                      borderRadius: 999,
                                      padding: EdgeInsets.zero,
                                      child: const SizedBox(
                                        width: 44,
                                        height: 44,
                                        child: Icon(
                                          LucideIcons.plus,
                                          size: 22,
                                          color: AppColors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: AppMotion.medium,
                                    curve: AppMotion.smoothOut,
                                    alignment: Alignment.centerRight,
                                    child: _showNav
                                        ? Padding(
                                            padding:
                                                const EdgeInsets.only(left: 8),
                                            child: AnimatedOpacity(
                                              duration: AppMotion.fast,
                                              opacity: _showNav ? 1 : 0,
                                              child: BounceTap(
                                                scaleDown: 0.9,
                                                onTap: _openSettings,
                                                child: GlassPanel(
                                                  enableBlur: true,
                                                  blurSigma: 12,
                                                  borderRadius: 999,
                                                  child: const SizedBox(
                                                    width: 44,
                                                    height: 44,
                                                    child: Icon(
                                                      LucideIcons.settings,
                                                      size: 22,
                                                      color: AppColors.zinc400,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Floating Bottom Navigation Pill
                if (!_isModalOverlayOpen && !_isTodoOpen)
                  Positioned(
                    bottom: math.max(bottomPad + 12, 24),
                    left: 16,
                    right: 16,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: AnimatedSlide(
                          duration: AppMotion.medium,
                          curve: AppMotion.smoothOut,
                          offset:
                              _showNav ? Offset.zero : const Offset(0, 1.8),
                          child: AnimatedOpacity(
                            duration: AppMotion.fast,
                            opacity: _showNav ? 1 : 0,
                            child: IgnorePointer(
                              ignoring: !_showNav,
                              child: GestureDetector(
                                onHorizontalDragEnd: (details) {
                                  final v = details.primaryVelocity ?? 0;
                                  const tabs = AppTab.values;
                                  final idx = tabs.indexOf(store.activeTab);
                                  if (v < -180 && idx < tabs.length - 1) {
                                    _switchTab(tabs[idx + 1]);
                                  } else if (v > 180 && idx > 0) {
                                    _switchTab(tabs[idx - 1]);
                                  }
                                },
                                child: GlassCard(
                                  enableBlur: true,
                                  blurSigma: 16,
                                  borderRadius: 999,
                                  backgroundColor: const Color(0xCC0C0C0E),
                                  padding: const EdgeInsets.all(8),
                                  shadows: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.7),
                                      blurRadius: 50,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final totalW = constraints.maxWidth;
                                      final inactiveW =
                                          (totalW / 27.0 * 6.0).floorToDouble();
                                      final activeW =
                                          totalW - (inactiveW * 3.0);
                                      return Row(
                                        children: [
                                          _FloatingNavTab(
                                            width: store.activeTab == AppTab.home
                                                ? activeW
                                                : inactiveW,
                                            icon: LucideIcons.home,
                                            label: 'HOME',
                                            isActive:
                                                store.activeTab == AppTab.home,
                                            onTap: () {
                                              if (store.activeTab ==
                                                  AppTab.home) {
                                                setState(
                                                    () => _isTodoOpen = true);
                                              } else {
                                                _switchTab(AppTab.home);
                                              }
                                            },
                                            onSwipeDown: store.activeTab ==
                                                    AppTab.home
                                                ? () => setState(
                                                    () => _isTodoOpen = true)
                                                : null,
                                          ),
                                          _FloatingNavTab(
                                            width: store.activeTab ==
                                                    AppTab.progress
                                                ? activeW
                                                : inactiveW,
                                            icon: LucideIcons.activity,
                                            label: 'PROGRESS',
                                            flipIconY: true,
                                            isActive: store.activeTab ==
                                                AppTab.progress,
                                            onTap: () =>
                                                _switchTab(AppTab.progress),
                                          ),
                                          _FloatingNavTab(
                                            width:
                                                store.activeTab == AppTab.badges
                                                    ? activeW
                                                    : inactiveW,
                                            icon: LucideIcons.award,
                                            label: 'BADGES',
                                            isActive: store.activeTab ==
                                                AppTab.badges,
                                            onTap: () =>
                                                _switchTab(AppTab.badges),
                                          ),
                                          _FloatingNavTab(
                                            width: store.activeTab ==
                                                    AppTab.completed
                                                ? activeW
                                                : inactiveW,
                                            icon: LucideIcons.checkCircle,
                                            label: 'DONE',
                                            isActive: store.activeTab ==
                                                AppTab.completed,
                                            onTap: () =>
                                                _switchTab(AppTab.completed),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // To-Do Fullscreen Sheet
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !_isTodoOpen,
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.smoothOut,
                      switchOutCurve: AppMotion.smoothInOut,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _isTodoOpen
                          ? TodoOverlay(
                              key: const ValueKey('todo_overlay'),
                              store: store,
                              initialEditTodoId: _pendingEditTodoId,
                              onEditTodoHandled: () {
                                if (_pendingEditTodoId != null && mounted) {
                                  setState(() => _pendingEditTodoId = null);
                                }
                              },
                              onClose: () =>
                                  setState(() => _isTodoOpen = false),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('todo_empty'),
                            ),
                    ),
                  ),
                ),

                // Certificate Modal
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _certificateHabit == null,
                    child: AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.smoothOut,
                      switchOutCurve: AppMotion.smoothInOut,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.94, end: 1.0)
                              .animate(anim),
                          child: child,
                        ),
                      ),
                      child: _certificateHabit != null
                          ? CertificateModal(
                              key: ValueKey('cert_${_certificateHabit!.id}'),
                              habit: _certificateHabit!,
                              userName: store.userName,
                              onClose: () =>
                                  setState(() => _certificateHabit = null),
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('cert_empty'),
                            ),
                    ),
                  ),
                ),

                // Confetti Burst Layer
                Align(
                  alignment: const Alignment(0, 0.2),
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      numberOfParticles: 50,
                      maxBlastForce: 32,
                      minBlastForce: 10,
                      emissionFrequency: 0.06,
                      gravity: 0.25,
                      colors: confettiPalette,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}

class _SmoothTabViewport extends StatefulWidget {
  final AppTab activeTab;
  final int direction;
  final Widget Function(AppTab tab) tabBuilder;

  const _SmoothTabViewport({
    required this.activeTab,
    required this.direction,
    required this.tabBuilder,
  });

  @override
  State<_SmoothTabViewport> createState() => _SmoothTabViewportState();
}

class _SmoothTabViewportState extends State<_SmoothTabViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curved;
  final Set<AppTab> _visited = {};
  AppTab? _outgoingTab;

  @override
  void initState() {
    super.initState();
    _visited.add(widget.activeTab);
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
      value: 1.0,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _outgoingTab = null);
        }
      });
    _curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.smoothOut,
    );
  }

  @override
  void didUpdateWidget(covariant _SmoothTabViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    _visited.add(widget.activeTab);
    if (oldWidget.activeTab != widget.activeTab) {
      _outgoingTab = oldWidget.activeTab;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Build visited tabs once per parent rebuild, not on every transition tick.
    final cachedTabs = {
      for (final tab in _visited)
        tab: RepaintBoundary(
          key: ValueKey('tab_keepalive_${tab.name}'),
          child: widget.tabBuilder(tab),
        ),
    };

    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final t = _curved.value;
        final dir = widget.direction.toDouble();
        final isTransitioning = _outgoingTab != null &&
            _controller.status != AnimationStatus.completed;

        return Stack(
          fit: StackFit.expand,
          children: _visited.map((tab) {
            final isIncoming = tab == widget.activeTab;
            final isOutgoing = isTransitioning && tab == _outgoingTab;
            final isVisible = isIncoming || isOutgoing;

            Widget child = cachedTabs[tab]!;
            if (isTransitioning) {
              if (isIncoming) {
                child = FractionalTranslation(
                  translation: Offset((1.0 - t) * 0.06 * dir, 0),
                  child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
                );
              } else if (isOutgoing) {
                child = FractionalTranslation(
                  translation: Offset(-t * 0.06 * dir, 0),
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              }
            }

            return Offstage(
              key: ValueKey('tab_slot_${tab.name}'),
              offstage: !isVisible,
              child: TickerMode(
                enabled: isIncoming,
                child: IgnorePointer(
                  ignoring: !isIncoming,
                  child: child,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FloatingNavTab extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final bool isActive;
  final bool flipIconY;
  final VoidCallback onTap;
  final VoidCallback? onSwipeDown;

  const _FloatingNavTab({
    required this.width,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.flipIconY = false,
    this.onSwipeDown,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Icon(
      icon,
      size: 22,
      color: isActive ? Colors.white : AppColors.textSecondary,
    );
    if (flipIconY) {
      iconWidget = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(1, -1, 1),
        child: iconWidget,
      );
    }

    return AnimatedContainer(
      duration: AppMotion.medium,
      curve: AppMotion.smoothOut,
      width: width,
      child: GestureDetector(
        onVerticalDragEnd: onSwipeDown == null
            ? null
            : (details) {
                if ((details.primaryVelocity ?? 0) > 150) {
                  onSwipeDown?.call();
                }
              },
        child: BounceTap(
          scaleDown: 0.95,
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.smoothOut,
            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.11)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.08 : 1.0,
                  duration: AppMotion.medium,
                  curve: AppMotion.smoothOut,
                  child: iconWidget,
                ),
                Flexible(
                  child: AnimatedSize(
                    duration: AppMotion.medium,
                    curve: AppMotion.smoothOut,
                    alignment: Alignment.centerLeft,
                    child: isActive
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 8),
                                Text(
                                  label,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
