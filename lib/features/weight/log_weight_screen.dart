import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/core/validation.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LogWeightScreen extends StatefulWidget {
  const LogWeightScreen({super.key, this.editingEntryId});

  /// When non-null, the screen prefills and updates the existing entry
  /// rather than creating a new one.
  final int? editingEntryId;

  @override
  State<LogWeightScreen> createState() => _LogWeightScreenState();
}

class _LogWeightScreenState extends State<LogWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _noteController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  WeightEntry? _editingEntry;
  late WeightUnit _unit;
  DateTime _recordedAt = DateTime.now();
  double? _lastWeightKg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = context.read<CalTrackRepository>();
    final profile = await repo.requireProfile();
    if (!mounted) return;
    _unit = WeightUnit.fromStored(profile.weightUnit);

    final recent = await repo.weightEntriesLimit(1);
    if (recent.isNotEmpty) _lastWeightKg = recent.first.weightKg;

    final id = widget.editingEntryId;
    if (id != null) {
      final existing = await repo.weightEntryById(id);
      if (!mounted) return;
      _editingEntry = existing;
      if (existing != null) {
        _recordedAt = existing.recordedAt;
        final shown = _toDisplay(existing.weightKg);
        _controller.text = shown.toStringAsFixed(1);
        _noteController.text = existing.note ?? '';
      }
    }
    setState(() => _loading = false);
  }

  double _toDisplay(double kg) =>
      _unit == WeightUnit.kg ? kg : kgToLb(kg);

  double? _parseWeightKg() {
    final v = parseDouble(_controller.text);
    if (v == null || v <= 0) return null;
    return _unit == WeightUnit.kg ? v : lbToKg(v);
  }

  String? _trimmedNote() {
    final n = _noteController.text.trim();
    return n.isEmpty ? null : n;
  }

  String? _validateWeight(String? raw) {
    final label = 'Weight (${_unit.shortLabel})';
    return validatePositiveDouble(
      raw ?? '',
      fieldLabel: label,
      min: _unit == WeightUnit.kg ? 20 : 44,
      max: _unit == WeightUnit.kg ? 500 : 1100,
    );
  }

  String? _validateNote(String? raw) =>
      validateOptionalNote(raw ?? '', maxLen: 140);

  /// Combine the user-picked calendar day with the current wall-clock time
  /// so multiple same-day weigh-ins still sort sensibly.
  DateTime _resolvedTimestamp() {
    final now = DateTime.now();
    final day = _recordedAt;
    if (day.year == now.year && day.month == now.month && day.day == now.day) {
      return now;
    }
    return DateTime(day.year, day.month, day.day, now.hour, now.minute);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _recordedAt = picked);
    }
  }

  void _applyQuickWeight(double kg) {
    _controller.text = _toDisplay(kg).toStringAsFixed(1);
    _formKey.currentState?.validate();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();
    final messenger = ScaffoldMessenger.of(context);
    final kg = _parseWeightKg();
    if (kg == null) {
      AppSnackBar.showError(context, 'Enter a valid weight.');
      return;
    }
    final note = _trimmedNote();
    final when = _resolvedTimestamp();

    setState(() => _saving = true);
    try {
      final editing = _editingEntry;
      if (editing != null) {
        await repo.updateWeightEntry(
          id: editing.id,
          weightKg: kg,
          note: note,
          recordedAt: when,
        );
      } else {
        final existing = await repo.weightEntryForDay(_recordedAt);
        if (existing != null) {
          if (!mounted) return;
          final replace = await _confirmReplaceTodaysEntry(existing);
          if (replace != true) {
            if (mounted) setState(() => _saving = false);
            return;
          }
          await repo.updateWeightEntry(
            id: existing.id,
            weightKg: kg,
            note: note,
            recordedAt: when,
          );
        } else {
          await repo.addWeightEntry(
            weightKg: kg,
            note: note,
            recordedAt: when,
          );
        }
      }
      if (!mounted) return;
      context.pop();
      AppSnackBar.showDetached(
        messenger,
        message: editing != null ? 'Weigh-in updated' : 'Weigh-in logged',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => profileCtl.refresh());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmReplaceTodaysEntry(WeightEntry existing) {
    final shown = _toDisplay(existing.weightKg);
    final label = '${shown.toStringAsFixed(1)} ${_unit.shortLabel}';
    final dayLabel =
        DateFormat.MMMd().format(existing.recordedAt);
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update existing weigh-in?'),
        content: Text(
          'You already logged $label on $dayLabel. Do you want to change '
          'that weigh-in?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final editing = _editingEntry;
    if (editing == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete weigh-in?'),
        content: const Text('This entry will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();
    setState(() => _saving = true);
    try {
      await repo.deleteWeightEntry(editing.id);
      if (!mounted) return;
      context.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) => profileCtl.refresh());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editingEntryId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit weigh-in' : 'Log weight'),
        actions: [
          if (isEdit)
            IconButton(
              tooltip: 'Delete',
              onPressed: _saving || _loading ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (isEdit && _editingEntry == null
              ? const Center(child: Text('Entry not found.'))
              : _buildForm(context)),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final suffix = _unit.shortLabel;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Spacing.lg,
                Spacing.lg,
                Spacing.lg,
                Spacing.lg + viewInsets,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _DateField(
                      date: _recordedAt,
                      onTap: _saving ? null : _pickDate,
                    ),
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Weight ($suffix)',
                        prefixIcon: const Icon(Icons.monitor_weight_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      validator: _validateWeight,
                    ),
                    if (_lastWeightKg != null) ...[
                      const SizedBox(height: Spacing.sm),
                      _QuickWeightChips(
                        lastKg: _lastWeightKg!,
                        unit: _unit,
                        onSelect: _saving ? null : _applyQuickWeight,
                      ),
                    ],
                    const SizedBox(height: Spacing.md),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      maxLines: 2,
                      validator: _validateNote,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              0,
              Spacing.lg,
              Spacing.md,
            ),
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_editingEntry != null ? 'Save changes' : 'Save',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = isToday ? 'Today' : DateFormat.yMMMEd().format(date);

    return InkWell(
      onTap: onTap,
      borderRadius: Corners.radiusMd,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.event_outlined),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            Icon(Icons.edit_calendar_outlined,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _QuickWeightChips extends StatelessWidget {
  const _QuickWeightChips({
    required this.lastKg,
    required this.unit,
    required this.onSelect,
  });

  final double lastKg;
  final WeightUnit unit;
  final void Function(double kg)? onSelect;

  @override
  Widget build(BuildContext context) {
    // Offer a few nudges around the last logged weight so quick daily
    // weigh-ins are a single tap.
    final stepKg = unit == WeightUnit.kg ? 0.5 : lbToKg(1);
    final offsets = <double>[-stepKg, 0, stepKg];

    return Wrap(
      spacing: Spacing.sm,
      children: [
        for (final off in offsets)
          ActionChip(
            label: Text(_fmt(lastKg + off)),
            onPressed: onSelect == null ? null : () => onSelect!(lastKg + off),
          ),
      ],
    );
  }

  String _fmt(double kg) {
    final v = unit == WeightUnit.kg ? kg : kgToLb(kg);
    return '${v.toStringAsFixed(1)} ${unit.shortLabel}';
  }
}
