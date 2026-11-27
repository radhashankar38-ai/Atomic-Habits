import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import '../constants/app_constants.dart';
import '../models/habit.dart';

class AddEditHabitSheet extends StatefulWidget {
  final Habit? editingHabit;
  final void Function({
    required String name,
    required int targetDays,
    required String category,
    required String colorHex,
    required String notes,
  }) onSave;

  const AddEditHabitSheet({
    super.key,
    this.editingHabit,
    required this.onSave,
  });

  @override
  State<AddEditHabitSheet> createState() => _AddEditHabitSheetState();
}

class _AddEditHabitSheetState extends State<AddEditHabitSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _notesController;
  late String _category;
  late HabitColorOption _color;

  @override
  void initState() {
    super.initState();
    final h = widget.editingHabit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _targetController = TextEditingController(
      text: h != null && h.targetDays > 0 ? '${h.targetDays}' : '',
    );
    _notesController = TextEditingController(text: h?.notes ?? '');
    _category = h?.category ?? habitCategories.first.value;
    _color = h != null ? findHabitColor(h.color) : habitColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;
    final parsedTarget = int.tryParse(_targetController.text.trim()) ?? 0;
    widget.onSave(
      name: _nameController.text.trim(),
      targetDays: parsedTarget,
      category: _category,
      colorHex: _color.hex,
      notes: _notesController.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingHabit != null;
    final canSubmit = _nameController.text.trim().isNotEmpty;
    final topPad = MediaQuery.of(context).padding.top;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withValues(alpha: 0.72),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.fromLTRB(24, topPad + 20, 24, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                      Text(
                        isEditing ? 'Edit Habit' : 'New Habit',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: canSubmit ? _submit : null,
                        child: Opacity(
                          opacity: canSubmit ? 1.0 : 0.45,
                          child: Text(
                            isEditing ? 'Save' : 'Add',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      MediaQuery.of(context).viewInsets.bottom + 96,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _FieldLabel('NAME'),
                        const SizedBox(height: 10),
                        _GlassTextField(
                          controller: _nameController,
                          hintText: 'Habit Name',
                          autofocus: !isEditing,
                          fontSize: 20,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 36),

                        const _FieldLabel('GOAL (DAYS)'),
                        const SizedBox(height: 10),
                        _GlassTextField(
                          controller: _targetController,
                          hintText: '0',
                          keyboardType: TextInputType.number,
                          fontSize: 20,
                        ),
                        const SizedBox(height: 36),

                        const _FieldLabel('CATEGORY'),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: habitCategories.map((cat) {
                              final selected = _category == cat.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _category = cat.value),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.blue
                                          : AppColors.cardSecondary,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: selected
                                            ? AppColors.blue
                                            : AppColors.borderSubtle,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.blue
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 12,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          cat.icon,
                                          size: 16,
                                          color: selected
                                              ? Colors.white
                                              : AppColors.zinc400,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          cat.label,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: selected
                                                ? Colors.white
                                                : AppColors.zinc400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 36),

                        const _FieldLabel('COLOR ACCENT'),
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: habitColors.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (context, i) {
                            final c = habitColors[i];
                            final selected = c.name == _color.name;
                            return GestureDetector(
                              onTap: () => setState(() => _color = c),
                              child: AnimatedScale(
                                scale: selected ? 1.1 : 1.0,
                                duration: const Duration(milliseconds: 140),
                                child: Opacity(
                                  opacity: selected ? 1.0 : 0.6,
                                  child: Container(
                                    padding: selected
                                        ? const EdgeInsets.all(2.5)
                                        : EdgeInsets.zero,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: selected
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: c.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 36),

                        const _FieldLabel('NOTES (INSTRUCTIONS/DETAILS)'),
                        const SizedBox(height: 10),
                        _GlassTextField(
                          controller: _notesController,
                          hintText:
                              'What are the rules? Any specific details to remember...',
                          maxLines: 5,
                          fontSize: 14,
                        ),
                      ],
                    ),
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool autofocus;
  final double fontSize;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _GlassTextField({
    required this.controller,
    required this.hintText,
    this.autofocus = false,
    this.fontSize = 16,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: fontSize,
          color: AppColors.zinc500,
        ),
        filled: true,
        fillColor: AppColors.cardSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.blue, width: 2),
        ),
      ),
    );
  }
}
