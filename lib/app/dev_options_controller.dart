import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevOptionsController extends ChangeNotifier {
  DevOptionsController(this._prefs) {
    _enabled = _prefs.getBool(_keyEnabled) ?? false;
  }

  final SharedPreferences _prefs;
  static const _keyEnabled = 'dev_options_enabled';

  bool _enabled = false;
  bool get enabled => _enabled;

  int _tapCount = 0;
  DateTime? _lastTap;

  Future<void> setEnabled(bool val) async {
    if (_enabled == val) return;
    _enabled = val;
    await _prefs.setBool(_keyEnabled, val);
    notifyListeners();
  }

  /// Call this when the user taps an element they can use to unlock dev mode.
  /// (e.g. 7 rapid taps on the app version).
  void handleUnlockTap(BuildContext context) {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds > 500) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;

    if (_tapCount >= 7) {
      _tapCount = 0;
      if (!_enabled) {
        setEnabled(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Developer options enabled.')),
        );
      } else {
        setEnabled(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Developer options disabled.')),
        );
      }
    } else if (_tapCount >= 3 && !_enabled) {
      final remaining = 7 - _tapCount;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tap $remaining more times to enable dev options.'),
          duration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }
}
