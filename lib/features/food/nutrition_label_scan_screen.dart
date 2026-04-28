import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:caltrack/core/nutrition_label_parser.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Draft values extracted from a nutrition label.
///
/// Returned from `NutritionLabelScanScreen` back to the add-food form.
class NutritionFactsDraft {
  const NutritionFactsDraft({
    this.servingSize,
    this.servingUnit,
    this.calories,
    this.fatG,
    this.carbsG,
    this.sugarG,
    this.fiberG,
    this.proteinG,
  });

  final double? servingSize;
  final ServingUnit? servingUnit;
  final double? calories;
  final double? fatG;
  final double? carbsG;
  final double? sugarG;
  final double? fiberG;
  final double? proteinG;
}

/// Nutrition label scan flow (OCR + highlight animation).
class NutritionLabelScanScreen extends StatefulWidget {
  const NutritionLabelScanScreen({super.key});

  @override
  State<NutritionLabelScanScreen> createState() => _NutritionLabelScanScreenState();
}

class _NutritionLabelScanScreenState extends State<NutritionLabelScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  bool _initializing = true;
  bool _capturing = false;

  Uint8List? _imageBytes;
  ui.Size? _imageSize;
  NutritionParseResult? _parse;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _anim.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final ctl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctl.initialize();
      if (!mounted) return;
      setState(() {
        _camera = ctl;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _initializing = false);
    }
  }

  Future<void> _captureAndRecognize() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await cam.takePicture();
      final bytes = await File(file.path).readAsBytes();
      final decoded = await _decodeImageSize(bytes);

      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final input = InputImage.fromFilePath(file.path);
        final recognized = await recognizer.processImage(input);
        final parsed = parseNutritionLabel(recognized);
        if (!mounted) return;
        setState(() {
          _imageBytes = bytes;
          _imageSize = decoded;
          _parse = parsed;
        });
        _anim
          ..reset()
          ..forward();
      } finally {
        recognizer.close();
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  static Future<ui.Size?> _decodeImageSize(Uint8List bytes) async {
    final c = Completer<ui.Size?>();
    try {
      ui.decodeImageFromList(bytes, (img) {
        if (c.isCompleted) return;
        c.complete(ui.Size(img.width.toDouble(), img.height.toDouble()));
      });
    } catch (_) {
      if (!c.isCompleted) c.complete(null);
    }
    return c.future;
  }

  void _finish() {
    final p = _parse;
    if (p == null) return;
    Navigator.of(context).pop(
      NutritionFactsDraft(
        servingSize: p.draft.servingSize,
        servingUnit: p.draft.servingUnit,
        calories: p.draft.calories,
        fatG: p.draft.fatG,
        carbsG: p.draft.carbsG,
        sugarG: p.draft.sugarG,
        fiberG: p.draft.fiberG,
        proteinG: p.draft.proteinG,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cam = _camera;
    final imgBytes = _imageBytes;
    final imgSize = _imageSize;
    final parse = _parse;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan nutrition label'),
        actions: [
          if (parse != null)
            TextButton(
              onPressed: _finish,
              child: const Text('Use'),
            ),
        ],
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
          : (imgBytes == null || imgSize == null)
              ? _CameraCaptureView(
                  cam: cam,
                  capturing: _capturing,
                  onCapture: _captureAndRecognize,
                )
              : _ReviewView(
                  bytes: imgBytes,
                  imageSize: imgSize,
                  parse: parse,
                  animation: _anim,
                  onRetake: () {
                    setState(() {
                      _imageBytes = null;
                      _imageSize = null;
                      _parse = null;
                    });
                  },
                  onUse: _finish,
                  capturing: _capturing,
                  theme: theme,
                ),
    );
  }
}

class _CameraCaptureView extends StatelessWidget {
  const _CameraCaptureView({
    required this.cam,
    required this.capturing,
    required this.onCapture,
  });

  final CameraController? cam;
  final bool capturing;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    if (cam == null || !cam!.value.isInitialized) {
      return const Center(child: Text('Camera unavailable.'));
    }
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CameraPreview(cam!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: FilledButton.icon(
              onPressed: capturing ? null : onCapture,
              icon: capturing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              label: Text(capturing ? 'Processing…' : 'Capture'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  const _ReviewView({
    required this.bytes,
    required this.imageSize,
    required this.parse,
    required this.animation,
    required this.onRetake,
    required this.onUse,
    required this.capturing,
    required this.theme,
  });

  final Uint8List bytes;
  final ui.Size imageSize;
  final NutritionParseResult? parse;
  final Animation<double> animation;
  final VoidCallback onRetake;
  final VoidCallback onUse;
  final bool capturing;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final fields = parse?.fields.values.toList() ?? const [];
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final maxW = c.maxWidth;
                final maxH = c.maxHeight;
                final fit = _fitSize(imageSize, ui.Size(maxW, maxH));

                return Center(
                  child: SizedBox(
                    width: fit.width,
                    height: fit.height,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(bytes, fit: BoxFit.contain),
                        IgnorePointer(
                          child: AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              return CustomPaint(
                                painter: _HighlightPainter(
                                  fields: fields,
                                  t: animation.value,
                                  imageSize: imageSize,
                                  displaySize: ui.Size(fit.width, fit.height),
                                  color: theme.colorScheme.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: capturing ? null : onRetake,
                    child: const Text('Retake'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: parse == null ? null : onUse,
                    child: const Text('Use values'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static ui.Size _fitSize(ui.Size input, ui.Size bounds) {
    if (input.width <= 0 || input.height <= 0) return bounds;
    final inRatio = input.width / input.height;
    final bRatio = bounds.width / bounds.height;
    if (inRatio > bRatio) {
      final w = bounds.width;
      return ui.Size(w, w / inRatio);
    } else {
      final h = bounds.height;
      return ui.Size(h * inRatio, h);
    }
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.fields,
    required this.t,
    required this.imageSize,
    required this.displaySize,
    required this.color,
  });

  final List<ExtractedField<double>> fields;
  final double t;
  final ui.Size imageSize;
  final ui.Size displaySize;
  final Color color;

  @override
  void paint(Canvas canvas, ui.Size size) {
    if (fields.isEmpty) return;
    final n = fields.length;
    final idx = (t * n).clamp(0.0, n - 0.0001).floor();
    final localT = (t * n) - idx;

    final box = fields[idx].box;
    final scaleX = displaySize.width / imageSize.width;
    final scaleY = displaySize.height / imageSize.height;
    final r = Rect.fromLTRB(
      box.left * scaleX,
      box.top * scaleY,
      box.right * scaleX,
      box.bottom * scaleY,
    );

    final eased = Curves.easeOut.transform(localT.clamp(0.0, 1.0));
    final paintFill = Paint()
      ..color = color.withValues(alpha: 0.18 * eased)
      ..style = PaintingStyle.fill;
    final paintStroke = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rr = RRect.fromRectAndRadius(r.inflate(6 * eased), const Radius.circular(10));
    canvas.drawRRect(rr, paintFill);
    canvas.drawRRect(rr, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.fields != fields ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.displaySize != displaySize ||
        oldDelegate.color != color;
  }
}

