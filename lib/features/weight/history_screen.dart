import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Weight history')),
      body: StreamBuilder<List<WeightEntry>>(
        stream: repo.watchWeightEntries(),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return const Center(child: Text('No entries yet.'));
          }

          return FutureBuilder(
            future: repo.requireProfile(),
            builder: (context, profileSnap) {
              final profile = profileSnap.data;
              final unit = profile != null
                  ? WeightUnit.fromStored(profile.weightUnit)
                  : WeightUnit.kg;

              double displayKg(double kg) =>
                  unit == WeightUnit.kg ? kg : kgToLb(kg);

              final spots = <FlSpot>[];
              final chronological = [...entries]
                ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
              for (var i = 0; i < chronological.length; i++) {
                spots.add(
                  FlSpot(i.toDouble(), displayKg(chronological[i].weightKg)),
                );
              }

              final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
              final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
              final pad = (maxY - minY).abs() < 0.5 ? 2.0 : (maxY - minY) * 0.1;

              return Column(
                children: [
                  SizedBox(
                    height: 220,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 24, 8),
                      child: LineChart(
                        LineChartData(
                          minY: minY - pad,
                          maxY: maxY + pad,
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  final i = value.round();
                                  if (i < 0 || i >= chronological.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final d = chronological[i].recordedAt;
                                  return Text(
                                    DateFormat.Md().format(d),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  );
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 44,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toStringAsFixed(0),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Units: ${unit.shortLabel}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        return ListTile(
                          title: Text(
                            '${displayKg(e.weightKg).toStringAsFixed(1)} ${unit.shortLabel}',
                          ),
                          subtitle: Text(
                            DateFormat.yMMMd().add_jm().format(e.recordedAt),
                          ),
                          trailing: e.note != null && e.note!.isNotEmpty
                              ? Icon(
                                  Icons.notes_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
