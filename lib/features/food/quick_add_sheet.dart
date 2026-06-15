import 'package:caltrack/app/meal_time_controller.dart';
import 'package:caltrack/core/validation.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Opens the Quick Add bottom sheet. Returns `true` if an entry was saved.
///
/// Pass [editingEntry] to pre-fill the sheet and update an existing quick-add
/// log entry instead of creating a new one.
///
/// [loggedAt] sets the timestamp for new entries (null = now).
Future<bool> showQuickAddSheet(
  BuildContext context, {
  DateTime? loggedAt,
  FoodLogEntry? editingEntry,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _QuickAddSheet(
      loggedAt: loggedAt,
      editingEntry: editingEntry,
    ),
  );
  return result ?? false;
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet({this.loggedAt, this.editingEntry});

  final DateTime? loggedAt;
  final FoodLogEntry? editingEntry;

  bool get isEdit => editingEntry != null;

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  final _nameFocus = FocusNode();
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  bool _macrosExpanded = false;
  bool _busy = false;
  bool _submitted = false; // only show errors after first save attempt
  MealPeriod? _selectedPeriod;

@override
  void initState() {
    super.initState();
    final entry = widget.editingEntry;
    if (entry != null) {
      // Pre-fill from the existing log entry.
      _nameCtrl.text = entry.displayName;
      _kcalCtrl.text = _fmt(entry.kcal);
      _selectedPeriod = MealPeriod.fromDb(entry.mealPeriod);
      if (entry.proteinG > 0) {
        _proteinCtrl.text = _fmt(entry.proteinG);
        _macrosExpanded = true;
      }
      if (entry.carbsG > 0) {
        _carbsCtrl.text = _fmt(entry.carbsG);
        _macrosExpanded = true;
      }
      if (entry.fatG > 0) {
        _fatCtrl.text = _fmt(entry.fatG);
        _macrosExpanded = true;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyAutoMealPeriod();
      if (mounted) _nameFocus.requestFocus();
    });
  }

  void _applyAutoMealPeriod() {
    if (_selectedPeriod != null || widget.isEdit) return;
    final mealCtl = context.read<MealTimeController>();
    final suggested = mealCtl.suggestMealPeriod();
    if (suggested != null && mounted) {
      setState(() => _selectedPeriod = suggested);
    }
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  String? get _nameError {
    if (!_submitted) return null;
    return _nameCtrl.text.trim().isEmpty ? 'Enter a name.' : null;
  }

  String? get _kcalError {
    if (!_submitted) return null;
    return validatePositiveDouble(
      _kcalCtrl.text,
      fieldLabel: 'Calories',
      max: 10000,
    );
  }

  String? _optionalMacroError(String raw, String label) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null; // optional — blank is fine
    final v = parseDouble(trimmed);
    if (v == null) return '$label must be a number.';
    if (v < 0) return '$label must be 0 or more.';
    if (v > 1000) return '$label seems too high.';
    return null;
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _kcalCtrl.text.trim().isNotEmpty &&
      validatePositiveDouble(_kcalCtrl.text, fieldLabel: 'Calories', max: 10000) ==
          null;

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!_canSave) return;

    final repo = context.read<CalTrackRepository>();
    setState(() => _busy = true);
    try {
      final kcal = parseDouble(_kcalCtrl.text) ?? 0;
      final protein = parseDouble(_proteinCtrl.text) ?? 0;
      final carbs = parseDouble(_carbsCtrl.text) ?? 0;
      final fat = parseDouble(_fatCtrl.text) ?? 0;
      final name = _nameCtrl.text.trim();

      final editId = widget.editingEntry?.id;
      if (editId != null) {
        await repo.updateFoodLog(
          id: editId,
          grams: 100,
          kcal: kcal,
          proteinG: protein,
          carbsG: carbs,
          fatG: fat,
          mealPeriod: _selectedPeriod,
        );
        await repo.updateQuickAddName(id: editId, displayName: name);
      } else {
        await repo.addFoodLogReturnId(
          source: 'quick',
          displayName: name,
          grams: 100,
          kcal: kcal,
          proteinG: protein,
          carbsG: carbs,
          fatG: fat,
          loggedAt: widget.loggedAt,
          mealPeriod: _selectedPeriod,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.editingEntry?.id;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await context.read<CalTrackRepository>().deleteFoodLog(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        left: 20,
        right: 20,
        top: 4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Header --------------------------------------------------
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 20,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEdit ? 'Edit quick add' : 'Quick add',
                      style: theme.textTheme.titleLarge,
                    ),
                    Text(
                      'Estimate — fill in what you know.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ---- Name ----------------------------------------------------
            TextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Food name *',
                hintText: 'e.g. Pizza slice, Handful of nuts…',
                errorText: _nameError,
              ),
              onChanged: (_) {
                if (_submitted) setState(() {});
              },
            ),
            const SizedBox(height: 14),

            // ---- Calories ------------------------------------------------
            TextField(
              controller: _kcalCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction:
                  _macrosExpanded ? TextInputAction.next : TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: 'Calories *',
                suffixText: 'kcal',
                errorText: _kcalError,
              ),
              onChanged: (_) {
                if (_submitted) setState(() {});
              },
              onSubmitted: (_) {
                if (!_macrosExpanded) _save();
              },
            ),
            const SizedBox(height: 16),

            // ---- Optional macros toggle ----------------------------------
            InkWell(
              onTap: () => setState(() => _macrosExpanded = !_macrosExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _macrosExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _macrosExpanded
                          ? 'Hide macros'
                          : 'Add macros (optional)',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Macro fields (expandable) --------------------------------
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: _macrosExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Per serving — leave blank if unknown',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _MacroField(
                                  controller: _proteinCtrl,
                                  label: 'Protein',
                                  color: scheme.primary,
                                  errorText: _optionalMacroError(
                                      _proteinCtrl.text, 'Protein'),
                                  onChanged:
                                      _submitted ? (_) => setState(() {}) : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MacroField(
                                  controller: _carbsCtrl,
                                  label: 'Carbs',
                                  color: scheme.secondary,
                                  errorText: _optionalMacroError(
                                      _carbsCtrl.text, 'Carbs'),
                                  onChanged:
                                      _submitted ? (_) => setState(() {}) : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MacroField(
                                  controller: _fatCtrl,
                                  label: 'Fat',
                                  color: scheme.tertiary,
                                  errorText: _optionalMacroError(
                                      _fatCtrl.text, 'Fat'),
                                  onChanged:
                                      _submitted ? (_) => setState(() {}) : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 12),
            MealPeriodPicker(
              selected: _selectedPeriod,
              onChanged: (p) => setState(() => _selectedPeriod = p),
              enabled: !_busy,
            ),
            const SizedBox(height: 24),

            // ---- Action buttons -----------------------------------------
            if (widget.isEdit)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.error,
                        side: BorderSide(color: scheme.error),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: _busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_rounded),
                label: const Text('Add to diary'),
              ),
          ],
        ),
      ),
    );
  }
}

/// A compact labeled numeric field used for the optional macro row.
class _MacroField extends StatelessWidget {
  const _MacroField({
    required this.controller,
    required this.label,
    required this.color,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Color color;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            suffixText: 'g',
            isDense: true,
            errorText: errorText,
            errorMaxLines: 2,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
