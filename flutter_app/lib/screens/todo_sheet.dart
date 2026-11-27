import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../constants/app_constants.dart';
import '../modals/time_picker_dialog.dart';
import '../models/habit.dart';
import '../state/habit_store.dart';
import '../widgets/glass.dart';

class TodoOverlay extends StatefulWidget {
  final HabitStore store;
  final VoidCallback onClose;
  final String? initialEditTodoId;
  final VoidCallback? onEditTodoHandled;

  const TodoOverlay({
    super.key,
    required this.store,
    required this.onClose,
    this.initialEditTodoId,
    this.onEditTodoHandled,
  });

  @override
  State<TodoOverlay> createState() => _TodoOverlayState();
}

class _TodoOverlayState extends State<TodoOverlay> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showTodoNav = true;
  bool _isAtTop = true;
  bool _isPullingDown = false;
  double _pullDownOffset = 0;
  String? _pendingReminderTime;
  String? _handledInitialEditId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _scheduleInitialEditCheck();
  }

  @override
  void didUpdateWidget(covariant TodoOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEditTodoId != oldWidget.initialEditTodoId) {
      _scheduleInitialEditCheck();
    }
  }

  void _scheduleInitialEditCheck() {
    final targetId = widget.initialEditTodoId;
    if (targetId == null ||
        targetId.isEmpty ||
        targetId == _handledInitialEditId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handledInitialEditId = targetId;
      widget.onEditTodoHandled?.call();
      TodoModel? match;
      for (final item in widget.store.todos) {
        if (item.id == targetId) {
          match = item;
          break;
        }
      }
      if (match != null) {
        _openEditTodoDialog(match);
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final y = _scrollController.offset;
    final nextAtTop = y <= 0;
    final nextShowNav = y <= 20;
    if (nextAtTop != _isAtTop || nextShowNav != _showTodoNav) {
      setState(() {
        _isAtTop = nextAtTop;
        _showTodoNav = nextShowNav;
      });
    }
  }

  Future<void> _pickPendingReminderTime() async {
    final result = await showGlassTimePicker(
      context: context,
      initialTime: _pendingReminderTime,
      title: 'Task Reminder Time',
      subtitle: 'Get alerted daily at this time',
      allowClear: _pendingReminderTime != null,
    );
    if (!mounted || result == null) return;
    setState(() {
      _pendingReminderTime = result.cleared ? null : result.time;
    });
  }

  Future<void> _openEditTodoDialog(TodoModel todo) async {
    widget.store.triggerHaptic();
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss edit task',
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: AppMotion.medium,
      pageBuilder: (dialogContext, _, _) {
        return _EditTodoDialog(
          todo: todo,
          onSave: (updatedText, updatedReminder) {
            widget.store.updateTodo(
              id: todo.id,
              text: updatedText,
              reminderTime: updatedReminder,
            );
          },
          onDelete: () => widget.store.removeTodo(todo.id),
        );
      },
      transitionBuilder: (context, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: AppMotion.smoothOut);
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

  void _submitTodo() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    widget.store.addTodo(text, reminderTime: _pendingReminderTime);
    _inputController.clear();
    if (_pendingReminderTime != null) {
      setState(() => _pendingReminderTime = null);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onVerticalDragStart: _isAtTop
          ? (_) => setState(() => _isPullingDown = true)
          : null,
      onVerticalDragUpdate: _isAtTop
          ? (details) {
              if (details.delta.dy > 0 || _pullDownOffset > 0) {
                setState(() {
                  _isPullingDown = true;
                  _pullDownOffset =
                      (_pullDownOffset + details.delta.dy).clamp(0.0, 200.0);
                });
              }
            }
          : null,
      onVerticalDragEnd: _isAtTop
          ? (details) {
              if (_pullDownOffset > 60 ||
                  (details.primaryVelocity ?? 0) > 450) {
                _isPullingDown = false;
                widget.onClose();
              } else {
                setState(() {
                  _isPullingDown = false;
                  _pullDownOffset = 0;
                });
              }
            }
          : null,
      onVerticalDragCancel: () {
        if (_isPullingDown || _pullDownOffset != 0) {
          setState(() {
            _isPullingDown = false;
            _pullDownOffset = 0;
          });
        }
      },
      child: AnimatedContainer(
        duration: _isPullingDown
            ? Duration.zero
            : const Duration(milliseconds: 260),
        curve: AppMotion.smoothOut,
        transform: Matrix4.translationValues(0, _pullDownOffset * 0.5, 0),
        child: Material(
          color: Colors.black,
          child: Stack(
            children: [
              // Main Scrollable Body + Sticky Bottom Input Bar
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: EdgeInsets.only(
                        top: topPad + 88,
                        bottom: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TypewriterText(
                                  text: store.userName.isNotEmpty
                                      ? 'Hello, ${store.userName}'
                                      : 'Hello, Friend',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ready to complete your checklists?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (store.todos.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 80),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.25,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.cardSecondary,
                                        border: Border.all(
                                          color: AppColors.borderSubtle,
                                        ),
                                      ),
                                      child: const Icon(
                                        LucideIcons.checkCircle,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Opacity(
                                    opacity: 0.4,
                                    child: const Text(
                                      'NO TASKS FOR TODAY',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.zinc500,
                                        letterSpacing: 2.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: store.todos
                                    .map(
                                      (todo) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: _SwipeableTodoItem(
                                          key: ValueKey(todo.id),
                                          todo: todo,
                                          onToggle: () => store.toggleTodo(todo.id),
                                          onDelete: () => store.removeTodo(todo.id),
                                          onEdit: () => _openEditTodoDialog(todo),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Frosted Input + TO-DO Pill
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          bottomInset > 0
                              ? bottomInset + 16
                              : MediaQuery.of(context).padding.bottom + 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.48),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Time Reminder Chip & Long-press Hint
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  BounceTap(
                                    scaleDown: 0.96,
                                    onTap: _pickPendingReminderTime,
                                    child: AnimatedContainer(
                                      duration: AppMotion.fast,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _pendingReminderTime != null
                                            ? AppColors.blue
                                                .withValues(alpha: 0.18)
                                            : Colors.white
                                                .withValues(alpha: 0.06),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: _pendingReminderTime != null
                                              ? AppColors.blue
                                                  .withValues(alpha: 0.45)
                                              : Colors.white
                                                  .withValues(alpha: 0.10),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            LucideIcons.alarmClock,
                                            size: 13,
                                            color: _pendingReminderTime != null
                                                ? AppColors.blue
                                                : AppColors.zinc400,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _pendingReminderTime != null
                                                ? 'Remind ${TodoModel.formatReminderTime(_pendingReminderTime)}'
                                                : 'Set Reminder',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  _pendingReminderTime != null
                                                      ? AppColors.blue
                                                      : AppColors.zinc400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_pendingReminderTime != null) ...[
                                    const SizedBox(width: 6),
                                    BounceTap(
                                      onTap: () => setState(
                                        () => _pendingReminderTime = null,
                                      ),
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.06),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.x,
                                          size: 12,
                                          color: AppColors.zinc400,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  if (store.todos.isNotEmpty)
                                    const Text(
                                      'HOLD TASK TO EDIT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.zinc600,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Input Form
                            Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                TextField(
                                  controller: _inputController,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  onSubmitted: (_) => _submitTodo(),
                                  decoration: InputDecoration(
                                    hintText: 'Add a new task...',
                                    hintStyle: const TextStyle(
                                      color: AppColors.zinc600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.card,
                                    contentPadding: const EdgeInsets.fromLTRB(
                                      20,
                                      18,
                                      96,
                                      18,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: AppColors.borderSubtle,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: AppColors.blue.withValues(alpha: 0.5),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: BounceTap(
                                    scaleDown: 0.95,
                                    onTap: _submitTodo,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 22,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.blue
                                                .withValues(alpha: 0.25),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'ADD',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Bottom Pill (slides down when scrolling)
                            AnimatedSize(
                              duration: AppMotion.medium,
                              curve: AppMotion.smoothOut,
                              child: _showTodoNav
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: BounceTap(
                                        scaleDown: 0.95,
                                        onTap: widget.onClose,
                                        child: const GlassPanel(
                                          borderRadius: 999,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                LucideIcons.checkCircle,
                                                size: 26,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'TO-DO',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 2.4,
                                                ),
                                              ),
                                            ],
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
                ],
              ),

              // Floating Top Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedSlide(
                  duration: AppMotion.medium,
                  curve: AppMotion.smoothOut,
                  offset: _showTodoNav ? Offset.zero : const Offset(0, -0.35),
                  child: AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: _showTodoNav ? 1 : 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.90),
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        topPad + 16,
                        24,
                        16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'To-Do',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          BounceTap(
                            scaleDown: 0.92,
                            onTap: widget.onClose,
                            child: GlassPanel(
                              enableBlur: true,
                              blurSigma: 12,
                              borderRadius: 999,
                              padding: const EdgeInsets.all(10),
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeableTodoItem extends StatefulWidget {
  final TodoModel todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SwipeableTodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_SwipeableTodoItem> createState() => _SwipeableTodoItemState();
}

class _SwipeableTodoItemState extends State<_SwipeableTodoItem> {
  double _offsetX = 0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final revealProgress = (-_offsetX / 80.0).clamp(0.0, 1.0);
    final binScale = 0.8 + (0.2 * revealProgress);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // Red Trash Layer underneath
          Positioned.fill(
            child: Container(
              color: Colors.black,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: AnimatedOpacity(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                opacity: revealProgress,
                child: AnimatedScale(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: AppMotion.smoothOut,
                  scale: binScale,
                  child: BounceTap(
                    scaleDown: 0.95,
                    onTap: widget.onDelete,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.trash2,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Todo Card Layer
          GestureDetector(
            onLongPress: widget.onEdit,
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                _isDragging = true;
                _offsetX = (_offsetX + details.delta.dx).clamp(-84.0, 0.0);
              });
            },
            onHorizontalDragEnd: (_) {
              setState(() {
                _isDragging = false;
                _offsetX = _offsetX < -40 ? -80.0 : 0.0;
              });
            },
            onHorizontalDragCancel: () {
              setState(() {
                _isDragging = false;
                _offsetX = _offsetX < -40 ? -80.0 : 0.0;
              });
            },
            child: AnimatedContainer(
              duration: _isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: AppMotion.smoothOut,
              transform: Matrix4.translationValues(_offsetX, 0, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: AnimatedOpacity(
                duration: AppMotion.fast,
                opacity: widget.todo.completed ? 0.4 : 1.0,
                child: Row(
                  children: [
                    BounceTap(
                      scaleDown: 0.88,
                      onTap: widget.onToggle,
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.smoothOut,
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: widget.todo.completed
                              ? AppColors.iosGreen
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.todo.completed
                                ? AppColors.iosGreen
                                : Colors.white.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOutBack,
                          transitionBuilder: (child, anim) => ScaleTransition(
                            scale: anim,
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: widget.todo.completed
                              ? const Icon(
                                  Icons.check_rounded,
                                  key: ValueKey('todo_checked'),
                                  size: 18,
                                  color: Colors.black,
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('todo_unchecked'),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.todo.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              decoration: widget.todo.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: widget.todo.completed
                                  ? AppColors.zinc500
                                  : const Color(0xFFE4E4E7),
                            ),
                          ),
                          if (TodoModel.formatReminderTime(
                                widget.todo.reminderTime,
                              ) !=
                              null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.blue.withValues(alpha: 0.30),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.alarmClock,
                                    size: 11,
                                    color: AppColors.blue,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    TodoModel.formatReminderTime(
                                      widget.todo.reminderTime,
                                    )!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.blue,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
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
        ],
      ),
    );
  }
}

class _EditTodoDialog extends StatefulWidget {
  final TodoModel todo;
  final void Function(String updatedText, String? updatedReminderTime) onSave;
  final VoidCallback onDelete;

  const _EditTodoDialog({
    required this.todo,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditTodoDialog> createState() => _EditTodoDialogState();
}

class _EditTodoDialogState extends State<_EditTodoDialog> {
  late final TextEditingController _controller;
  late String? _reminderTime;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.todo.text);
    _reminderTime = widget.todo.reminderTime;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final result = await showGlassTimePicker(
      context: context,
      initialTime: _reminderTime,
      title: 'Edit Task Reminder',
      subtitle: 'Notify daily at this time',
      allowClear: true,
    );
    if (!mounted || result == null) return;
    setState(() {
      _reminderTime = result.cleared ? null : result.time;
    });
  }

  void _save() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    widget.onSave(trimmed, _reminderTime);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final formatted = TodoModel.formatReminderTime(_reminderTime);

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
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
                    padding: const EdgeInsets.all(22),
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
                                LucideIcons.edit2,
                                size: 17,
                                color: AppColors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Task',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Update task text or daily reminder time',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            BounceTap(
                              onTap: () {
                                widget.onDelete();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.red.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  LucideIcons.trash2,
                                  size: 16,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Task name field
                        const Text(
                          'TASK',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.zinc500,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          minLines: 1,
                          maxLines: 3,
                          maxLength: 160,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: 'Enter task description...',
                            hintStyle: const TextStyle(
                              color: AppColors.zinc600,
                            ),
                            filled: true,
                            fillColor: Colors.black.withValues(alpha: 0.5),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.borderSubtle,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.blue.withValues(alpha: 0.65),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Reminder Time selector
                        const Text(
                          'TIME REMINDER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.zinc500,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: BounceTap(
                                scaleDown: 0.98,
                                onTap: _pickReminderTime,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: formatted != null
                                          ? AppColors.blue
                                              .withValues(alpha: 0.45)
                                          : AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.alarmClock,
                                        size: 17,
                                        color: formatted != null
                                            ? AppColors.blue
                                            : AppColors.zinc500,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          formatted ?? 'No reminder set',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: formatted != null
                                                ? Colors.white
                                                : AppColors.zinc500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        formatted != null ? 'CHANGE' : 'SET',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.blue,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_reminderTime != null) ...[
                              const SizedBox(width: 8),
                              BounceTap(
                                onTap: () =>
                                    setState(() => _reminderTime = null),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: AppColors.zinc400,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: BounceTap(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: BounceTap(
                                onTap: _save,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
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
                                    'Save Changes',
                                    maxLines: 1,
                                    softWrap: false,
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
