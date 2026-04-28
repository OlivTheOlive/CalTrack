import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LogWeightScreen extends StatefulWidget {
  const LogWeightScreen({super.key});

  @override
  State<LogWeightScreen> createState() => _LogWeightScreenState();
}

class _LogWeightScreenState extends State<LogWeightScreen> {
  final _controller = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();
    final profile = await repo.requireProfile();
    if (!mounted) return;
    final unit = WeightUnit.fromStored(profile.weightUnit);
    final raw = _controller.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null || v <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight.')),
      );
      return;
    }
    final kg = unit == WeightUnit.kg ? v : lbToKg(v);
    await repo.addWeightEntry(
      weightKg: kg,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    await profileCtl.refresh();
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Log weight')),
      body: FutureBuilder(
        future: repo.requireProfile(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final unit = WeightUnit.fromStored(snap.data!.weightUnit);
          final suffix = unit.shortLabel;
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
                  onPressed: _submit,
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
