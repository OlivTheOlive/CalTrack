import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/features/calendar/day_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      });

  bool get _canGoNext {
    final now = DateTime.now();
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
    return next.isBefore(DateTime(now.year, now.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.watch<ProfileController>();
    final target = profileCtl.profile?.dailyCalorieTarget;

    final monthStart = _currentMonth;
    final monthEnd = DateTime(_currentMonth.year, _currentMonth.month + 1);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
              tooltip: 'Previous month',
            ),
            Text(
              _monthLabel(_currentMonth),
              style: theme.textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _canGoNext ? _nextMonth : null,
              tooltip: 'Next month',
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<DateTime, double>>(
        stream: repo.watchDailyKcalTotals(
          start: monthStart,
          endExclusive: monthEnd,
        ),
        builder: (context, snap) {
          final kcalTotals = snap.data ?? const <DateTime, double>{};
          return _CalendarGrid(
            month: _currentMonth,
            kcalTotals: kcalTotals,
            dailyTarget: target,
            today: DateTime.now(),
            onDayTap: (day) => _showDayDetail(context, day),
          );
        },
      ),
    );
  }

  void _showDayDetail(BuildContext context, DateTime day) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => DayDetailSheet(day: day),
    );
  }

  String _monthLabel(DateTime m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[m.month - 1]} ${m.year}';
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.kcalTotals,
    required this.dailyTarget,
    required this.today,
    required this.onDayTap,
  });

  final DateTime month;
  final Map<DateTime, double> kcalTotals;
  final double? dailyTarget;
  final DateTime today;
  final void Function(DateTime day) onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final firstDay = DateTime(month.year, month.month);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final weekdayOffset = firstDay.weekday % 7; // Sunday = 0

    final totalCells = weekdayOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        const SizedBox(height: 8),
        _buildDayHeaders(theme),
        const Divider(indent: 16, endIndent: 16),
        ...List.generate(rows, (row) {
          final children = <Widget>[];
          for (var col = 0; col < 7; col++) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - weekdayOffset + 1;
            final isInMonth = dayNum >= 1 && dayNum <= lastDay.day;
            if (isInMonth) {
              final day = DateTime(month.year, month.month, dayNum);
              final kcal = kcalTotals[calendarDay(day)] ?? 0;
              final isToday = calendarDay(day) == calendarDay(today);
              children.add(_DayCell(
                day: dayNum,
                kcal: kcal,
                dailyTarget: dailyTarget,
                isToday: isToday,
                onTap: () => onDayTap(day),
              ));
            } else {
              children.add(const Expanded(child: SizedBox()));
            }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: children),
          );
        }),
        const Spacer(),
        _buildLegend(scheme, theme),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDayHeaders(ThemeData theme) {
    const headers = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: headers.map((h) {
          return Expanded(
            child: Center(
              child: Text(h,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegend(ColorScheme scheme, ThemeData theme) {
    final hasTarget = dailyTarget != null && dailyTarget! > 0;
    if (!hasTarget) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendDot(scheme, Colors.green, 'Full'),
          const SizedBox(width: 16),
          _legendDot(scheme, Colors.amber, 'Partial'),
          const SizedBox(width: 16),
          _legendDot(scheme, scheme.outlineVariant, 'None'),
        ],
      ),
    );
  }

  Widget _legendDot(ColorScheme scheme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurface)),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.kcal,
    required this.dailyTarget,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final double kcal;
  final double? dailyTarget;
  final bool isToday;
  final VoidCallback onTap;

  DayStatus get _status {
    final target = dailyTarget;
    if (target == null || target <= 0) return DayStatus.noLog;
    if (kcal <= 0) return DayStatus.noLog;
    if (kcal >= target * 0.80) return DayStatus.full;
    if (kcal >= target * 0.10) return DayStatus.partial;
    return DayStatus.noLog;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = _status;

    final dotColor = switch (status) {
      DayStatus.full => Colors.green,
      DayStatus.partial => Colors.amber,
      DayStatus.noLog => scheme.outlineVariant,
    };

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: isToday
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary, width: 2),
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: status == DayStatus.noLog
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum DayStatus { full, partial, noLog }
