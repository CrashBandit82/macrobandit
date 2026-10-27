import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/nutrition.dart';
import '../data/models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Calories of the current week (Mon–Sun) as bars, colored by goal progress.
class WeeklyCard extends StatefulWidget {
  const WeeklyCard({super.key, required this.calorieGoal});

  final int calorieGoal;

  @override
  State<WeeklyCard> createState() => _WeeklyCardState();
}

class _WeeklyCardState extends State<WeeklyCard> {
  late Future<WeeklyStats> _future = context.api.weekly(widget.calorieGoal);

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return SizedBox(
                height: 150,
                child: LoadState(
                  error: snap.error,
                  onRetry: () => setState(() => _future = context.api.weekly(widget.calorieGoal)),
                ),
              );
            }
            final w = snap.data!;
            final goal = widget.calorieGoal;
            final maxKcal = math.max(w.days.map((d) => d.kcal).fold(0.0, math.max), goal.toDouble());
            final now = DateTime.now();
            final locale = Localizations.localeOf(context).toLanguageTag();
            bool isToday(DateTime d) => d.year == now.year && d.month == now.month && d.day == now.day;
            final dayName = DateFormat.E(locale);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  children: [
                    Text(t.weekTitle, style: context.tt.titleSmall),
                    Text(t.weekAvg(fmtNum(context, w.avg, 0)), style: context.tt.labelMedium),
                  ],
                ),
                const SizedBox(height: 14),
                Semantics(
                  label: [for (final d in w.days) '${dayName.format(d.date)} ${d.kcal.round()} kcal'].join(', '),
                  excludeSemantics: true,
                  child: SizedBox(
                    height: 84,
                    child: Stack(
                      children: [
                        // goal line
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 84 * (goal / maxKcal),
                          child: Container(height: 1, color: c.border),
                        ),
                        Positioned.fill(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final d in w.days)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: FractionallySizedBox(
                                      heightFactor: d.kcal > 0 ? math.max(d.kcal / maxKcal, 0.04) : 0.04,
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: d.kcal > 0 && goal > 0
                                              ? kcalColor(d.kcal / goal * 100, low: c.kcalLow)
                                              : c.idle,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                          border: isToday(d.date) ? Border.all(color: c.today, width: 2) : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // day names below the bars; their height follows the font size
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (final d in w.days)
                        Expanded(
                          child: Text(
                            dayName.format(d.date),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: context.tt.labelSmall!.copyWith(
                              letterSpacing: 0,
                              color: isToday(d.date) ? c.today : c.faint,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: fmtNum(context, w.total, 0),
                            style: TextStyle(color: c.text, fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: ' / ${fmtNum(context, w.goal, 0)} kcal'),
                        ],
                      ),
                      style: context.tt.labelMedium,
                    ),
                    Wrap(
                      spacing: 10,
                      children: [_legend(context, kcalGreen, t.weekGoalReached), _legend(context, kcalRed, t.weekOver)],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Widget _legend(BuildContext context, Color color, String text) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    ),
    const SizedBox(width: 4),
    Text(text, style: context.tt.labelMedium),
  ],
);

class MonthlyCard extends StatefulWidget {
  const MonthlyCard({super.key});

  @override
  State<MonthlyCard> createState() => _MonthlyCardState();
}

class _MonthlyCardState extends State<MonthlyCard> {
  late int _year = DateTime.now().year;
  late int _month = DateTime.now().month;
  late Future<MonthlyStats> _future = _fetch();

  Future<MonthlyStats> _fetch() => context.api.monthly(_year, _month);

  void _shift(int delta) {
    final d = DateTime(_year, _month + delta);
    setState(() {
      _year = d.year;
      _month = d.month;
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    final now = DateTime.now();
    final isCurrent = _year == now.year && _month == now.month;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final month = DateFormat.yMMMM(locale);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: month.format(DateTime(_year, _month - 1)),
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    month.format(DateTime(_year, _month)),
                    textAlign: TextAlign.center,
                    style: context.tt.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: month.format(DateTime(_year, _month + 1)),
                  onPressed: isCurrent ? null : () => _shift(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return LoadState(error: snap.error, onRetry: () => setState(() => _future = _fetch()));
                }
                final m = snap.data!;
                if (m.daysTracked == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      t.monthNoData,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.faint),
                    ),
                  );
                }
                final tiles = [
                  ('${m.daysTracked} / ${m.daysInMonth}', t.monthDaysTracked, c.today),
                  (t.monthDays(m.goalDays), t.monthGoalDays, c.accent),
                  ('${m.avgKcal.round()} kcal', t.monthAvgKcal, c.carbsText),
                  ('${fmtNum(context, m.avgProtein)} g', t.monthAvgProtein, c.proteinText),
                  ('${fmtNum(context, m.avgCarbs)} g', t.monthAvgCarbs, c.carbsText),
                  ('${fmtNum(context, m.avgFat)} g', t.monthAvgFat, c.fatText),
                  if (m.best != null) ('${m.best!.label}  ${m.best!.kcal.round()} kcal', t.monthBest, c.accent),
                  if (m.worst != null) ('${m.worst!.label}  ${m.worst!.kcal.round()} kcal', t.monthLowest, c.soft),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // pairs of intrinsic height instead of a fixed-aspect grid
                    for (var i = 0; i < tiles.length; i += 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: _tile(context, tiles[i])),
                              const SizedBox(width: 8),
                              Expanded(child: i + 1 < tiles.length ? _tile(context, tiles[i + 1]) : const SizedBox()),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    _dailyChart(context, m),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, (String, String, Color) tile) {
    final (value, label, color) = tile;
    return Container(
      decoration: BoxDecoration(color: context.c.page, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: context.tt.titleMedium!.copyWith(color: color, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: context.tt.labelMedium),
        ],
      ),
    );
  }

  Widget _dailyChart(BuildContext context, MonthlyStats m) {
    final t = context.t;
    final c = context.c;
    final maxKcal = m.daily.map((d) => d.kcal).fold(0.0, math.max);
    return Container(
      decoration: BoxDecoration(color: c.page, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.monthDaily, style: context.tt.labelMedium!.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Semantics(
            label: [for (final d in m.daily) '${d.label} ${d.kcal.round()} kcal'].join(', '),
            excludeSemantics: true,
            child: SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in m.daily)
                    Expanded(
                      child: Tooltip(
                        message: '${d.label}: ${d.kcal.round()} kcal',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: FractionallySizedBox(
                            heightFactor: maxKcal > 0 ? math.max(d.kcal / maxKcal, 0.05) : 0.05,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                color: d.goalReached ? c.primary : c.idle,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [_legend(context, c.primary, t.monthGoalDays), _legend(context, c.idle, t.monthGoalNotReached)],
          ),
        ],
      ),
    );
  }
}
