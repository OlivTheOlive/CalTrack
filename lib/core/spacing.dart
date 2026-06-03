import 'package:flutter/widgets.dart';

/// 8px-grid spacing tokens used across the UI for consistent rhythm.
///
/// Use these instead of hard-coded magic numbers so padding and gaps stay
/// uniform as the design evolves.
abstract final class Spacing {
  Spacing._();

  /// 4px — tight inset between closely-related elements.
  static const double xs = 4;

  /// 8px — default gap between stacked controls.
  static const double sm = 8;

  /// 16px — standard content padding / card padding.
  static const double md = 16;

  /// 24px — section padding / screen margins.
  static const double lg = 24;

  /// 32px — large separations between sections.
  static const double xl = 32;

  /// 48px — hero spacing (empty states, headers).
  static const double xxl = 48;

  // Common pre-built gap widgets to cut boilerplate.
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);

  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);

  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
}

/// Standard corner radii used by cards, chips and badges.
abstract final class Corners {
  Corners._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
}
