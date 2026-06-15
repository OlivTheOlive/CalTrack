import 'package:flutter/material.dart';

/// Material 3 expandable FAB menu: a primary FAB that reveals smaller
/// labeled FABs for quick-adding, adding food, and logging weight.
class LogFabMenu extends StatelessWidget {
  const LogFabMenu({
    super.key,
    required this.controller,
    required this.isOpen,
    required this.onToggle,
    required this.onLogFood,
    required this.onLogWeight,
    required this.onQuickAdd,
  });

  final AnimationController controller;
  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onLogFood;
  final VoidCallback onLogWeight;
  final VoidCallback onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final mainFab = FloatingActionButton(
      onPressed: onToggle,
      tooltip: isOpen ? 'Close menu' : 'Add entry',
      child: AnimatedRotation(
        turns: isOpen ? 0.125 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: const Icon(Icons.add),
      ),
    );

    // When closed, only the primary FAB is in the tree so [Scaffold]'s
    // `floatingActionButtonRect` stays at the bottom-right. A full [Column]
    // of (invisible) menu rows still laid out space above the FAB, which made
    // floating [SnackBar]s anchor to that tall rect — mid-screen by the list.
    if (!isOpen) {
      return mainFab;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _FabMenuItem(
          controller: controller,
          index: 2,
          icon: Icons.monitor_weight_outlined,
          label: 'Log weight',
          heroTag: 'fab_menu_weight',
          onPressed: onLogWeight,
        ),
        const SizedBox(height: 12),
        _FabMenuItem(
          controller: controller,
          index: 1,
          icon: Icons.restaurant_menu_outlined,
          label: 'Log food',
          heroTag: 'fab_menu_food',
          onPressed: onLogFood,
        ),
        const SizedBox(height: 12),
        _FabMenuItem(
          controller: controller,
          index: 0,
          icon: Icons.bolt_rounded,
          label: 'Quick add',
          heroTag: 'fab_menu_quick',
          onPressed: onQuickAdd,
        ),
        const SizedBox(height: 12),
        mainFab,
      ],
    );
  }
}

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.controller,
    required this.index,
    required this.icon,
    required this.label,
    required this.heroTag,
    required this.onPressed,
  });

  final AnimationController controller;
  final int index;
  final IconData icon;
  final String label;
  final String heroTag;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = Curves.easeOutCubic.transform(
          (controller.value * 1.6 - index * 0.15).clamp(0.0, 1.0),
        );
        return IgnorePointer(
          ignoring: t < 0.5,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: theme.colorScheme.inverseSurface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: heroTag,
                    onPressed: onPressed,
                    child: Icon(icon),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

