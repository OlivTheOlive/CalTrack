import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
  final _controller = TextEditingController();
  final _noteController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  WeightEntry? _editingEntry;
  late WeightUnit _unit;

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

    final id = widget.editingEntryId;
    if (id != null) {
      final existing = await repo.weightEntryById(id);
      if (!mounted) return;
      _editingEntry = existing;
      if (existing != null) {
        final shown = _unit == WeightUnit.kg
            ? existing.weightKg
            : kgToLb(existing.weightKg);
        _controller.text = _formatWeight(shown);
        _noteController.text = existing.note ?? '';
      }
    }
    setState(() => _loading = false);
  }

  static String _formatWeight(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toStringAsFixed(1);

  double? _parseWeightKg() {
    final raw = _controller.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return null;
    return _unit == WeightUnit.kg ? v : lbToKg(v);
  }

  String? _trimmedNote() {
    final n = _noteController.text.trim();
    return n.isEmpty ? null : n;
  }

  Future<void> _submit() async {
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();
    final kg = _parseWeightKg();
    if (kg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight.')),
      );
      return;
    }
    final note = _trimmedNote();

    setState(() => _saving = true);
    try {
      final editing = _editingEntry;
      if (editing != null) {
        await repo.updateWeightEntry(id: editing.id, weightKg: kg, note: note);
      } else {
        final today = await repo.weightEntryForDay(DateTime.now());
        if (today != null) {
          if (!mounted) return;
          final replace = await _confirmReplaceTodaysEntry(today);
          if (replace != true) {
            return;
          }
          await repo.updateWeightEntry(
            id: today.id,
            weightKg: kg,
            note: note,
          );
        } else {
          await repo.addWeightEntry(weightKg: kg, note: note);
        }
      }
      await profileCtl.refresh();
      if (!mounted) return;
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmReplaceTodaysEntry(WeightEntry today) {
    final shown = _unit == WeightUnit.kg
        ? today.weightKg
        : kgToLb(today.weightKg);
    final label = '${shown.toStringAsFixed(1)} ${_unit.shortLabel}';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update today\'s weigh-in?'),
        content: Text(
          'You already logged $label today. Do you want to change your '
          'weigh-in for today?',
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
      await profileCtl.refresh();
      if (!mounted) return;
      context.pop();
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
    final suffix = _unit.shortLabel;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Weight ($suffix)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
            ),
            maxLines: 2,
          ),
          const Spacer(),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: Text(_editingEntry != null ? 'Save changes' : 'Save'),
          ),
        ],
      ),
    );
  }
}
