import 'package:flutter/material.dart';

/// Central place to show snack bars with default Material styling.
abstract final class AppSnackBar {
  AppSnackBar._();

  /// After `await`, verify `context.mounted` before calling.
  ///
  /// Default duration: **5s** when [actionLabel] / [onAction] are set, **3s**
  /// otherwise. Pass [duration] to override.
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool replaceCurrent = false,
  }) {
    showDetached(
      ScaffoldMessenger.of(context),
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    bool replaceCurrent = false,
  }) {
    show(
      context,
      message,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  /// Convenience for the common "X deleted — UNDO" pattern. Shows [message]
  /// with an UNDO action wired to [onUndo]. Pass [messenger] captured before
  /// a sheet/route closes when the originating context may be unmounted.
  static void showUndo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
    String actionLabel = 'UNDO',
    Duration duration = const Duration(seconds: 5),
    bool replaceCurrent = true,
  }) {
    show(
      context,
      message,
      actionLabel: actionLabel,
      onAction: onUndo,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  /// Detached variant of [showUndo] for use after [Navigator.pop].
  static void showUndoDetached(
    ScaffoldMessengerState messenger, {
    required String message,
    required VoidCallback onUndo,
    String actionLabel = 'UNDO',
    Duration duration = const Duration(seconds: 5),
    bool replaceCurrent = true,
  }) {
    showDetached(
      messenger,
      message: message,
      actionLabel: actionLabel,
      onAction: onUndo,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }

  /// Pass [messenger] captured before [Navigator.pop] or sheet close.
  ///
  /// Default duration: **5s** with an action, **3s** without. Pass [duration] to override.
  static void showDetached(
    ScaffoldMessengerState messenger, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool replaceCurrent = false,
  }) {
    assert(
      (actionLabel == null) == (onAction == null),
      'actionLabel and onAction must both be set or both null.',
    );

    if (replaceCurrent) messenger.hideCurrentSnackBar();

    final SnackBarAction? snackAction =
        (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
              )
            : null;

    final hasAction = snackAction != null;
    final resolvedDuration = duration ??
        (hasAction
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3));

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: snackAction,
        duration: resolvedDuration,
        // Without this, Flutter defaults persist to true when [action] is set,
        // so the timeout never calls hideCurrentSnackBar.
        persist: false,
      ),
    );
  }
}

extension AppSnackBarX on BuildContext {
  void showAppSnackBar(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool replaceCurrent = false,
  }) {
    AppSnackBar.show(
      this,
      message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      replaceCurrent: replaceCurrent,
    );
  }
}
