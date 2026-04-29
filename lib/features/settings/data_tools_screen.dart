import 'dart:convert';
import 'dart:io';

import 'package:caltrack/data/caltrack_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class DataToolsScreen extends StatefulWidget {
  const DataToolsScreen({super.key});

  @override
  State<DataToolsScreen> createState() => _DataToolsScreenState();
}

class _DataToolsScreenState extends State<DataToolsScreen> {
  bool _busy = false;

  Future<File> _writeExportFile(String jsonString) async {
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final path = p.join(dir.path, 'caltrack-backup-$ts.json');
    final file = File(path);
    await file.writeAsString(jsonString, flush: true);
    return file;
  }

  Future<void> _export() async {
    final repo = context.read<CalTrackRepository>();
    setState(() => _busy = true);
    try {
      final data = await repo.exportJson();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final file = await _writeExportFile(jsonString);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'CalTrack backup',
        subject: 'CalTrack backup',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to ${p.basename(file.path)}')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read file.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid backup file.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await repo.importJson(parsed, overwrite: overwrite);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(overwrite
              ? 'Imported backup (overwrote existing data).'
              : 'Imported backup (merged).'),
        ),
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

