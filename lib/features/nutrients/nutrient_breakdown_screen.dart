import 'package:caltrack/app/nutrition_display_controller.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/widgets/nutrient_display.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final _nfInt = NumberFormat.decimalPattern();
final _fmtDate = DateFormat.yMMMEd();

class NutrientBreakdownScreen extends StatefulWidget {
  const NutrientBreakdownScreen({super.key});

  @override
  State<NutrientBreakdownScreen> createState() =>
      _NutrientBreakdownScreenState();
}

enum _TimeRange { today, monthly, yearly }

class _NutrientBreakdownScreenState extends State<NutrientBreakdownScreen> {
  _TimeRange _range = _TimeRange.today;

  @override
  Widget build(BuildContext context) {
    final displayCtl = context.watch<NutritionDisplayController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrient Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Customize tracked nutrients',
            onPressed: () => _openCustomSelector(context, displayCtl),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: switch (_range) {
            _TimeRange.today => _buildTodayTab(displayCtl, key: const ValueKey('today')),
            _TimeRange.monthly => _buildRangeTab(
                displayCtl: displayCtl,
                key: const ValueKey('monthly'),
                periodLabel: 'Monthly average',
                days: 30,
                start: DateTime.now().subtract(const Duration(days: 30)),
                endExclusive: DateTime.now().add(const Duration(days: 1)),
              ),
            _TimeRange.yearly => _buildRangeTab(
                displayCtl: displayCtl,
                key: const ValueKey('yearly'),
                periodLabel: 'Yearly average',
                days: 365,
                start: DateTime.now().subtract(const Duration(days: 365)),
                endExclusive: DateTime.now().add(const Duration(days: 1)),
              ),
          },
        ),
      ),
    );
  }

  Widget _buildTodayTab(NutritionDisplayController displayCtl, {Key? key}) {
    final repo = context.read<CalTrackRepository>();
    final today = DateTime.now();

    return StreamBuilder<DailyIntakeTotals>(
      key: key,
      stream: repo.watchIntakeForDay(today),
      builder: (context, snap) {
        final intake = snap.data ?? DailyIntakeTotals.zero;
        return _buildBody(
          context,
          header: _IntakeHeaderCard(
            title: 'Today',
            subtitle: _fmtDate.format(today),
            intake: intake,
          ),
          trailing: [
            DetailedNutrientBreakdown(
              intake: intake,
              customSelection: displayCtl.customSelection,
            ),
          ],
        );
      },
    );
  }

  void _openCustomSelector(
    BuildContext context,
    NutritionDisplayController ctl,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomNutrientSelector(
        selection: ctl.customSelection,
        onChanged: (keys) => ctl.setCustomSelection(keys),
      ),
    );
  }

  Widget _buildRangeTab({
    required NutritionDisplayController displayCtl,
    Key? key,
    required String periodLabel,
    required int days,
    required DateTime start,
    required DateTime endExclusive,
  }) {
    final repo = context.read<CalTrackRepository>();
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<({DailyIntakeTotals totals, int distinctDays})>(
      key: key,
      future: repo.intakeForRange(start, endExclusive),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: scheme.primary,
            ),
          );
        }

        final result = snap.data!;
        final logged = result.distinctDays;

        if (logged == 0) {
          return _buildBody(
            context,
            header: null,
            trailing: [_EmptyState(periodLabel: periodLabel)],
          );
        }

        final avg = DailyIntakeTotals(
          kcal: result.totals.kcal / logged,
          proteinG: result.totals.proteinG / logged,
          carbsG: result.totals.carbsG / logged,
          sugarG: result.totals.sugarG / logged,
          fiberG: result.totals.fiberG / logged,
          fatG: result.totals.fatG / logged,
          extra: result.totals.extra.map((k, v) => MapEntry(k, v / logged)),
        );

        return _buildBody(
          context,
          header: _IntakeHeaderCard(
            title: periodLabel,
            subtitle: '$logged of $days days tracked',
            footerNote:
                '${_nfInt.format(result.totals.kcal.round())} kcal total in period',
            intake: avg,
          ),
          trailing: [
            DetailedNutrientBreakdown(
              intake: avg,
              customSelection: displayCtl.customSelection,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.xs,
      ),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<_TimeRange>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: _TimeRange.today,
              label: Text('Today'),
            ),
            ButtonSegment(
              value: _TimeRange.monthly,
              label: Text('Monthly'),
            ),
            ButtonSegment(
              value: _TimeRange.yearly,
              label: Text('Yearly'),
            ),
          ],
          selected: {_range},
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) {
              setState(() => _range = selected.first);
            }
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    _IntakeHeaderCard? header,
    required List<Widget> trailing,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        0,
        Spacing.md,
        Spacing.xl,
      ),
      children: [
        _buildPeriodSelector(context),
        if (header != null) ...[
          header,
          const SizedBox(height: Spacing.md),
        ],
        ...trailing,
      ],
    );
  }
}

// ─── Unified header card ──────────────────────────────────────────────────────

class _IntakeHeaderCard extends StatelessWidget {
  const _IntakeHeaderCard({
    required this.title,
    required this.intake,
    this.subtitle,
    this.footerNote,
  });

  final String title;
  final DailyIntakeTotals intake;
  final String? subtitle;
  final String? footerNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onCard = scheme.onPrimaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(Corners.xl),
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Period label + date ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onCard.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onCard.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.sm),

          // ── Calories – big number ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _nfInt.format(intake.kcal.round()),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: onCard,
                  height: 1,
                ),
              ),
              const SizedBox(width: Spacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  'kcal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onCard.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (footerNote != null) ...[
            const SizedBox(height: 3),
            Text(
              footerNote!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: onCard.withValues(alpha: 0.45),
              ),
            ),
          ],

          const SizedBox(height: Spacing.md),
          Divider(
            height: 1,
            thickness: 0.5,
            color: onCard.withValues(alpha: 0.15),
          ),
          const SizedBox(height: Spacing.md),

          // ── Three macros ──
          Row(
            children: [
              _MacroColumn(
                label: 'Protein',
                value: intake.proteinG,
                color: onCard,
                accent: scheme.primary,
              ),
              _MacroColumn(
                label: 'Carbs',
                value: intake.carbsG,
                color: onCard,
                accent: scheme.secondary,
              ),
              _MacroColumn(
                label: 'Fat',
                value: intake.fatG,
                color: onCard,
                accent: scheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroColumn extends StatelessWidget {
  const _MacroColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.accent,
  });

  final String label;
  final double value;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(Corners.pill),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: color.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${value.round()} g',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.periodLabel});

  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 56,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Nothing logged yet',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Log some food and your $periodLabel\nwill appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
