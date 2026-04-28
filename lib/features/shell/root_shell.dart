import 'package:caltrack/features/dashboard/home_screen.dart';
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
    // Reserve space below content so the FAB and NavigationBar don't
    // cover the last item.
    final bottomInset = kFloatingActionButtonMargin + 72 + 80;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'About & shortcuts',
          icon: const Icon(Icons.info_outline),
          onPressed: () => showDashboardInfoSheet(context),
        ),
        title: const Text('CalTrack'),
        actions: [
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
                child: Container(
                  color: scheme.scrim.withValues(alpha: 0.32),
                ),
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
