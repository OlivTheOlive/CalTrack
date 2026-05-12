import 'dart:convert';
import 'dart:io';

import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class DataToolsScreen extends StatefulWidget {
  const DataToolsScreen({super.key});

  @override
  State<DataToolsScreen> createState() => _DataToolsScreenState();
}

class _DataToolsScreenState extends State<DataToolsScreen> {
  bool _busy = false;

  static bool get _isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _export() async {
    final repo = context.read<CalTrackRepository>();
    setState(() => _busy = true);
    try {
      final data = await repo.exportJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final fileName = 'caltrack-backup-$ts.json';

      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CalTrack backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        // file_picker requires bytes on Android/iOS and rejects them on macOS.
        bytes: _isMobile ? bytes : null,
      );

      if (!mounted || outputPath == null) return;

      // On desktop, the picker only returns a path — write the file ourselves.
      if (!_isMobile) {
        await File(outputPath).writeAsBytes(bytes, flush: true);
      }

      if (!mounted) return;
      context.showAppSnackBar(
        'Saved backup to ${p.basename(outputPath)}',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import({required bool overwrite}) async {
    final repo = context.read<CalTrackRepository>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (!mounted || result == null) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      AppSnackBar.showError(context, 'Could not read file.');
      return;
    }

    Map<String, Object?> parsed;
    try {
      final raw = utf8.decode(bytes);
      final obj = jsonDecode(raw);
      if (obj is! Map) throw const FormatException('not a JSON object');
      parsed = obj.cast<String, Object?>();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Invalid backup file.');
      return;
    }

    setState(() => _busy = true);
    try {
      await repo.importJson(parsed, overwrite: overwrite);
      if (!mounted) return;
      context.showAppSnackBar(
        overwrite
            ? 'Imported backup (overwrote existing data).'
            : 'Imported backup (merged).',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmImport() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import backup'),
        content: const Text(
          'Choose how to import the file. Overwrite clears your current '
          'data first (safest). Merge keeps current data and upserts by id.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('merge'),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('overwrite'),
            child: const Text('Overwrite'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'overwrite') {
      await _import(overwrite: true);
    } else {
      await _import(overwrite: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data tools')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Backup',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Export a JSON backup file you can store in your cloud drive, '
            'or import a previous backup to restore your data.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Export backup (JSON)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _confirmImport,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('Import backup'),
          ),
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

