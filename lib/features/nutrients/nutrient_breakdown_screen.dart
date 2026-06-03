import 'package:caltrack/app/nutrition_display_controller.dart';
import 'package:caltrack/core/nutrients.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/widgets/nutrient_display.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NutrientBreakdownScreen extends StatefulWidget {
  const NutrientBreakdownScreen({super.key});

  @override
  State<NutrientBreakdownScreen> createState() =>
      _NutrientBreakdownScreenState();
}

class _NutrientBreakdownScreenState extends State<NutrientBreakdownScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayCtl = context.watch<NutritionDisplayController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrient Breakdown'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Customize tracked nutrients',
            onPressed: () => _openCustomSelector(context, displayCtl),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
          labelColor: scheme.primary,
          indicatorColor: scheme.primary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTab(displayCtl: displayCtl),
          _RangeTab(
            rangeLabel: 'Last 30 days avg',
            start: DateTime.now().subtract(const Duration(days: 30)),
            endExclusive: DateTime.now().add(const Duration(days: 1)),
          ),
          _RangeTab(
            rangeLabel: 'Last 365 days avg',
            start: DateTime.now().subtract(const Duration(days: 365)),
            endExclusive: DateTime.now().add(const Duration(days: 1)),
          ),
        ],
      ),
    );
  }

  void _openCustomSelector(BuildContext context, NutritionDisplayController ctl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomNutrientSelector(
        selection: ctl.customSelection,
        onChanged: (keys) => ctl.setCustomSelection(keys),
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.displayCtl});

  final NutritionDisplayController displayCtl;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();
    final today = DateTime.now();

    return StreamBuilder<DailyIntakeTotals>(
      stream: repo.watchIntakeForDay(today),
      builder: (context, snap) {
        final intake = snap.data ?? DailyIntakeTotals.zero;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: DetailedNutrientBreakdown(
            intake: intake,
            mode: displayCtl.mode,
            customSelection: displayCtl.customSelection,
          ),
        );
      },
    );
  }
}

class _RangeTab extends StatelessWidget {
  const _RangeTab({
    required this.rangeLabel,
    required this.start,
    required this.endExclusive,
  });

  final String rangeLabel;
  final DateTime start;
  final DateTime endExclusive;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();
    final displayCtl = context.watch<NutritionDisplayController>();

    return FutureBuilder<({DailyIntakeTotals totals, int distinctDays})>(
      future: repo.intakeForRange(start, endExclusive),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final result = snap.data!;
        final days = result.distinctDays;
        final avgIntake = DailyIntakeTotals(
          kcal: days > 0 ? result.totals.kcal / days : 0,
          proteinG: days > 0 ? result.totals.proteinG / days : 0,
          carbsG: days > 0 ? result.totals.carbsG / days : 0,
          sugarG: days > 0 ? result.totals.sugarG / days : 0,
          fiberG: days > 0 ? result.totals.fiberG / days : 0,
          fatG: days > 0 ? result.totals.fatG / days : 0,
          extra: _avgExtra(result.totals.extra, days),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rangeLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Based on $days day${days == 1 ? '' : 's'} with logged entries',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: Spacing.md),
              DetailedNutrientBreakdown(
                intake: avgIntake,
                mode: displayCtl.mode,
                customSelection: displayCtl.customSelection,
              ),
            ],
          ),
        );
      },
    );
  }

  Map<NutrientKey, double> _avgExtra(Map<NutrientKey, double> extra, int days) {
    if (days == 0) return {};
    return extra.map((k, v) => MapEntry(k, v / days));
  }
}
