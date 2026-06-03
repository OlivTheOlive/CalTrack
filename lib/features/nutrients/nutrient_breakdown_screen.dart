import 'package:caltrack/app/nutrition_display_controller.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/widgets/nutrient_display.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final _nfInt = NumberFormat.decimalPattern();

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
    final scheme = Theme.of(context).colorScheme;
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorColor: Colors.transparent,
                labelColor: scheme.onPrimaryContainer,
                unselectedLabelColor: scheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'Monthly'),
                  Tab(text: 'Yearly'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTab(displayCtl: displayCtl),
          _RangeTab(
            rangeLabel: 'Last 30 day average',
            start: DateTime.now().subtract(const Duration(days: 30)),
            endExclusive: DateTime.now().add(const Duration(days: 1)),
          ),
          _RangeTab(
            rangeLabel: 'Last 365 day average',
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
        return ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            _MacroSummaryCard(intake: intake),
            const SizedBox(height: Spacing.md),
            DetailedNutrientBreakdown(
              intake: intake,
              mode: displayCtl.mode,
              customSelection: displayCtl.customSelection,
            ),
          ],
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
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<({DailyIntakeTotals totals, int distinctDays})>(
      future: repo.intakeForRange(start, endExclusive),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: scheme.primary,
            ),
          );
        }
        final result = snap.data!;
        final days = result.distinctDays;
        if (days == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: Spacing.md),
                  Text(
                    'No entries logged yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          );
        }
        final avgIntake = DailyIntakeTotals(
          kcal: result.totals.kcal / days,
          proteinG: result.totals.proteinG / days,
          carbsG: result.totals.carbsG / days,
          sugarG: result.totals.sugarG / days,
          fiberG: result.totals.fiberG / days,
          fatG: result.totals.fatG / days,
          extra: result.totals.extra.map((k, v) => MapEntry(k, v / days)),
        );

        return ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            _RangeHeader(
              rangeLabel: rangeLabel,
              days: days,
              kcalTotal: result.totals.kcal.round(),
            ),
            const SizedBox(height: Spacing.md),
            _MacroSummaryCard(intake: avgIntake),
            const SizedBox(height: Spacing.md),
            DetailedNutrientBreakdown(
              intake: avgIntake,
              mode: displayCtl.mode,
              customSelection: displayCtl.customSelection,
            ),
          ],
        );
      },
    );
  }
}

class _RangeHeader extends StatelessWidget {
  const _RangeHeader({
    required this.rangeLabel,
    required this.days,
    required this.kcalTotal,
  });

  final String rangeLabel;
  final int days;
  final int kcalTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rangeLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$days day${days == 1 ? '' : 's'} · $_nfInt($kcalTotal) kcal total',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _MacroSummaryCard extends StatelessWidget {
  const _MacroSummaryCard({required this.intake});

  final DailyIntakeTotals intake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.outlineVariant,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Row(
        children: [
          _MiniValue(
            color: scheme.primary,
            label: 'Cal',
            value: '${intake.kcal.round()}',
            sub: 'kcal',
          ),
          _Divider(height: 32, color: scheme.outlineVariant),
          _MiniValue(
            color: scheme.primary,
            label: 'P',
            value: '${intake.proteinG.round()}',
            sub: 'g',
          ),
          _Divider(height: 32, color: scheme.outlineVariant),
          _MiniValue(
            color: scheme.tertiary,
            label: 'C',
            value: '${intake.carbsG.round()}',
            sub: 'g',
          ),
          _Divider(height: 32, color: scheme.outlineVariant),
          _MiniValue(
            color: scheme.secondary,
            label: 'F',
            value: '${intake.fatG.round()}',
            sub: 'g',
          ),
        ],
      ),
    );
  }
}

class _MiniValue extends StatelessWidget {
  const _MiniValue({
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  final Color color;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            sub,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: VerticalDivider(width: 1, thickness: 1, color: color),
    );
  }
}
