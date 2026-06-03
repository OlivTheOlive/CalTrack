import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/features/dashboard/home_screen.dart';
import 'package:caltrack/features/food/quick_add_sheet.dart';
import 'package:caltrack/features/weight/weight_analytics_tab.dart';
import 'package:caltrack/widgets/log_fab_menu.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Top-level shell that hosts the bottom [NavigationBar] and the
/// global FAB menu, switching between [DashboardTab] and
/// [WeightAnalyticsTab].
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  bool _fabMenuOpen = false;
  late final AnimationController _fabMenuController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  @override
  void dispose() {
    _fabMenuController.dispose();
    super.dispose();
  }

  void _toggleFabMenu() {
    setState(() {
      _fabMenuOpen = !_fabMenuOpen;
      if (_fabMenuOpen) {
        _fabMenuController.forward();
      } else {
        _fabMenuController.reverse();
      }
    });
  }

  void _closeFabMenu() {
    if (!_fabMenuOpen) return;
    setState(() => _fabMenuOpen = false);
    _fabMenuController.reverse();
  }

  void _onTabChanged(int i) {
    if (i == _tab) return;
    _closeFabMenu();
    setState(() => _tab = i);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Reserve space below content so the NavBar and FAB don't obscure the
    // last list item. The NavigationBar is ~80 dp; the FAB floats ~16 dp
    // above it, so we need roughly 96–120 dp of clearance.
    final bottomInset = 60.0;

    return Scaffold(
      appBar: AppBar(
        // Subtle elevation tint as content scrolls under the bar.
        scrolledUnderElevation: 3,
        surfaceTintColor: scheme.surfaceTint,
        leading: IconButton(
          tooltip: 'About & shortcuts',
          icon: const Icon(Icons.info_outline),
          onPressed: () => showDashboardInfoSheet(context),
        ),
        title: const Text('CalTrack'),
        actions: [
          IconButton(
            tooltip: 'Calendar',
            onPressed: () => context.push('/calendar'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _tab,
            children: [
              DashboardTab(bottomInset: bottomInset),
              WeightAnalyticsTab(bottomInset: bottomInset),
            ],
          ),
          IgnorePointer(
            ignoring: !_fabMenuOpen,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _fabMenuOpen ? 1 : 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeFabMenu,
                child: Container(color: scheme.scrim.withValues(alpha: 0.32)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: LogFabMenu(
        controller: _fabMenuController,
        isOpen: _fabMenuOpen,
        onToggle: _toggleFabMenu,
        onLogFood: () {
          _closeFabMenu();
          context.push('/log-food');
        },
        onLogWeight: () {
          _closeFabMenu();
          context.push('/log-weight');
        },
        onQuickAdd: () async {
          _closeFabMenu();
          // FAB has no day context — always logs to now (today).
          final messenger = ScaffoldMessenger.of(context);
          final logged = await showQuickAddSheet(context);
          if (logged && mounted) {
            AppSnackBar.showDetached(messenger, message: 'Entry added');
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _onTabChanged,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_weight_outlined),
            selectedIcon: Icon(Icons.monitor_weight),
            label: 'Weight',
          ),
        ],
      ),
    );
  }
}
