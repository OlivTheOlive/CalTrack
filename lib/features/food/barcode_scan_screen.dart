import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

/// Scans barcodes and returns either a [CatalogFood] or a [CustomFood] via
/// [Navigator.pop], or redirects to the add-food form if not found.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcode(String? raw) async {
    if (_handled || raw == null || raw.isEmpty) return;
    final catalog = context.read<OpenNutritionCatalog>();
    final repo = context.read<CalTrackRepository>();
    final normalized = OpenNutritionCatalog.normalizeEan(raw);
    if (normalized == null) return;

    setState(() => _handled = true);
    await _controller.stop();

    final custom = await repo.customFoodByBarcode(normalized);
    if (!mounted) return;
    if (custom != null) {
      Navigator.of(context).pop(custom);
      return;
    }

    final foods = await catalog.byEan(normalized);
    if (!mounted) return;

    if (foods.isEmpty) {
      context.pushReplacement(
        '/add-custom-food',
        extra: {'barcode': normalized},
      );
      return;
    }

    if (foods.length == 1) {
      Navigator.of(context).pop(foods.first);
      return;
    }

    final picked = await showModalBottomSheet<CatalogFood>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.45;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Multiple foods share this barcode',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              SizedBox(
                height: maxH.clamp(120.0, 360.0),
                child: ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (ctx, i) {
                    final f = foods[i];
                    return ListTile(
                      title: Text(f.name),
                      subtitle: Text(f.id),
                      onTap: () => Navigator.pop(ctx, f),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: OpenNutritionAttribution(),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;
    if (picked != null) {
      Navigator.of(context).pop(picked);
    } else {
      setState(() => _handled = false);
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan barcode'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    for (final b in capture.barcodes) {
                      final v = b.rawValue;
                      if (v != null) {
                        _onBarcode(v);
                        break;
                      }
                    }
                  },
                ),
                if (_handled)
                  const ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: OpenNutritionAttribution(),
          ),
        ],
      ),
    );
  }
}
