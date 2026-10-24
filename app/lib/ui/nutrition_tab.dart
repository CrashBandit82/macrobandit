import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/nutrition.dart';
import '../data/api.dart';
import '../data/models.dart';
import '../data/session.dart';
import 'add_meal_sheet.dart';
import 'foods_screen.dart';
import 'goals_sheet.dart';
import 'scan_screen.dart';
import 'stats.dart';
import 'theme.dart';
import 'widgets.dart';

class NutritionTab extends StatefulWidget {
  const NutritionTab({super.key});

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  /// null = today.
  DateTime? _day;
  DailyTotals? _totals;
  List<LogEntry> _logs = const [];
  Object? _error;
  var _loading = true;
  var _showMonth = false;

  /// Bumped after every change so week/month reload too.
  var _revision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final day = _day;
    try {
      final api = context.api;
      final r = await (api.totals(day), api.logs(day)).wait;
      if (!mounted || day != _day) return;
      setState(() {
        _totals = r.$1;
        _logs = r.$2;
        _loading = false;
      });
    } on ParallelWaitError<(DailyTotals?, List<LogEntry>?), (AsyncError?, AsyncError?)> catch (e) {
      if (mounted) setState(() => _error = e.errors.$1?.error ?? e.errors.$2?.error);
    }
  }

  void _changed() {
    _revision++;
    _load();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _shiftDay(int delta) {
    final next = (_day ?? _today).add(Duration(days: delta));
    setState(() => _day = next.isBefore(_today) ? next : null);
    _load();
  }

  String _dayLabel(BuildContext context) {
    final t = context.t;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final d = _day ?? _today;
    final short = DateFormat.MMMMd(locale).format(d);
    if (_day == null) return t.todayDate(short);
    if (d == _today.subtract(const Duration(days: 1))) return t.yesterdayDate(short);
    return DateFormat.MMMMEEEEd(locale).format(d);
  }

  Future<void> _openAddMeal({Pick? pick, bool custom = false}) async {
    final logged = await showSheet<bool>(context, (_) => AddMealSheet(initialPick: pick, startCustom: custom));
    if (logged == true) _changed();
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (code == null || !mounted) return;
    try {
      final food = await context.api.barcode(code);
      if (!mounted) return;
      await _openAddMeal(pick: food.id == 0 ? Pick.offProduct(food, code, scanned: true) : Pick.own(food));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status == 404 || e.status == 400) {
        showMsg(context, context.t.productNotFound, error: true);
        await _openAddMeal(custom: true);
      } else {
        showError(context, e);
      }
    }
  }

  Future<void> _editLog(LogEntry log) async {
    final t = context.t;
    final text = await showDialog<String>(
      context: context,
      builder: (_) => PromptDialog(
        title: t.editAmountTitle,
        label: t.amountGrams,
        initial: fmtNum(context, log.grams),
        numeric: true,
        suffix: 'g',
        header: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.foodName, style: context.tt.titleSmall),
              const SizedBox(height: 4),
              Text(t.currentAmount(fmtNum(context, log.grams), log.kcal.round()), style: context.tt.bodySmall),
            ],
          ),
        ),
      ),
    );
    final grams = text == null ? null : parseNum(text);
    if (grams == null || grams <= 0 || !mounted) return;
    try {
      // the server has no update: add the new entry first, then remove the old
      // one, so a failure never loses the entry
      final api = context.api;
      await api.addLog(log.foodId!, grams);
      await api.deleteLog(log.id);
      if (mounted) showMsg(context, t.itemUpdated(log.foodName));
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
    _changed();
  }

  Future<void> _deleteLog(LogEntry log) async {
    final t = context.t;
    if (!await confirm(context, t.deleteLogConfirm(log.foodName)) || !mounted) return;
    try {
      await context.api.deleteLog(log.id);
      if (mounted) showMsg(context, t.itemDeleted(log.foodName));
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
    _changed();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    final user = SessionScope.of(context).user;
    final isToday = _day == null;
    return Scaffold(
      floatingActionButton: isToday
          ? FloatingActionButton.extended(
              onPressed: _openAddMeal,
              backgroundColor: Palette.userGradient(user.id).colors.first,
              icon: const Icon(Icons.add),
              label: Text(t.addMeal, style: context.tt.labelLarge!.copyWith(color: Colors.white)),
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _changed(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              PageWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        UserAvatar(user: user, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(t.greeting(user.username), style: context.tt.titleLarge),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!user.isVerified) const _VerifyBanner(),
                    _dateRow(context, isToday),
                    const SizedBox(height: 16),
                    if (_error != null && _totals == null)
                      LoadState(error: _error, onRetry: _load)
                    else if (_totals == null)
                      const LoadState(onRetry: _noop)
                    else ...[
                      _CalorieCard(totals: _totals!, goals: user.goals, onEditGoals: _editGoals),
                      const SizedBox(height: 10),
                      _MacroGrid(totals: _totals!, goals: user.goals),
                    ],
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, label: Text(t.tabWeek)),
                        ButtonSegment(value: true, label: Text(t.tabMonth)),
                      ],
                      selected: {_showMonth},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setState(() => _showMonth = s.first),
                    ),
                    const SizedBox(height: 10),
                    if (_showMonth)
                      MonthlyCard(key: ValueKey('m$_revision'))
                    else
                      WeeklyCard(key: ValueKey('w$_revision-${user.goals.kcal}'), calorieGoal: user.goals.kcal),
                    const SizedBox(height: 24),
                    if (isToday) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.inventory_2_outlined, size: 18),
                              label: Text(t.foodDatabase),
                              onPressed: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(builder: (_) => const FoodsScreen()),
                                );
                                _changed();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: c.carbs,
                                foregroundColor: const Color(0xFF020617),
                              ),
                              icon: const Icon(Icons.qr_code_scanner, size: 18),
                              label: Text(t.scanBarcode),
                              onPressed: _scan,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(isToday ? t.todayConsumed : t.meals, style: context.tt.titleMedium),
                          ),
                        ),
                        if (_logs.isNotEmpty) Text(t.entryCount(_logs.length), style: context.tt.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loading && _logs.isEmpty)
                      const SizedBox.shrink()
                    else if (_logs.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                          child: Text(
                            t.noEntries,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.muted),
                          ),
                        ),
                      )
                    else
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            for (final (i, log) in _logs.indexed) ...[
                              if (i > 0) const Divider(),
                              _LogTile(
                                log: log,
                                onEdit: isToday && log.foodId != null ? () => _editLog(log) : null,
                                onDelete: isToday ? () => _deleteLog(log) : null,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _noop() {}

  Future<void> _editGoals() async {
    final saved = await showSheet<bool>(context, (_) => const GoalsSheet());
    if (saved == true && mounted) showMsg(context, context.t.goalsSaved);
  }

  Widget _dateRow(BuildContext context, bool isToday) {
    final t = context.t;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: t.previousDay,
          onPressed: () => _shiftDay(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            _dayLabel(context),
            textAlign: TextAlign.center,
            style: context.tt.titleSmall!.copyWith(color: context.c.soft, fontWeight: FontWeight.w700),
          ),
        ),
        if (!isToday)
          TextButton(
            onPressed: () {
              setState(() => _day = null);
              _load();
            },
            child: Text(t.today),
          ),
        IconButton.outlined(
          tooltip: t.nextDay,
          onPressed: isToday ? null : () => _shiftDay(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _VerifyBanner extends StatelessWidget {
  const _VerifyBanner();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: c.warnBg,
        border: Border.all(color: c.carbs.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.emailNotVerified,
                  style: context.tt.titleSmall!.copyWith(color: c.warn, fontWeight: FontWeight.w800),
                ),
                Text(t.emailNotVerifiedSub, style: context.tt.bodySmall!.copyWith(color: c.warn)),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: c.warn),
            onPressed: () async {
              try {
                await context.api.resendVerification();
                if (context.mounted) showMsg(context, t.verificationSent);
              } on Object catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            child: Text(t.resend),
          ),
        ],
      ),
    );
  }
}

class _CalorieCard extends StatelessWidget {
  const _CalorieCard({required this.totals, required this.goals, required this.onEditGoals});

  final DailyTotals totals;
  final Goals goals;
  final VoidCallback onEditGoals;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    final pct = goals.kcal > 0 ? totals.kcal / goals.kcal * 100 : 0.0;
    final rest = goals.kcal - totals.kcal;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.calorieOverview, style: context.tt.labelMedium),
            const SizedBox(height: 10),
            // wraps under large system fonts instead of overflowing
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${totals.kcal.round()}', style: context.tt.displaySmall),
                    const SizedBox(width: 8),
                    Text(t.ofGoalKcal(goals.kcal), style: context.tt.bodyLarge!.copyWith(color: c.muted)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${rest.abs().round()}',
                      style: context.tt.titleLarge!.copyWith(color: rest >= 0 ? c.accent : c.fatText),
                    ),
                    Text(rest >= 0 ? t.remaining : t.over, style: context.tt.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Bar(
              fraction: pct / 100,
              color: kcalColor(pct, low: c.kcalLow),
              height: 8,
              label: t.calorieOverview,
            ),
            Row(
              children: [
                Expanded(child: Text(t.progressOfGoal(pct.round()), style: context.tt.bodySmall)),
                TextButton(onPressed: onEditGoals, child: Text(t.adjustGoals)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroGrid extends StatelessWidget {
  const _MacroGrid({required this.totals, required this.goals});

  final DailyTotals totals;
  final Goals goals;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    final items = [
      (t.macroProtein, totals.protein, goals.protein, c.protein),
      (t.macroCarbs, totals.carbs, goals.carbs, c.carbs),
      (t.macroFat, totals.fat, goals.fat, c.fat),
      (t.macroFiber, totals.fiber, goals.fiber, c.fiber),
    ];
    Widget tile((String, double, int, Color) m) {
      final (label, value, goal, color) = m;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(label, style: context.tt.labelMedium!.copyWith(color: c.soft)),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: '${value.round()} ',
                  style: context.tt.titleLarge!.copyWith(fontWeight: FontWeight.w700),
                  children: [TextSpan(text: '/ $goal g', style: context.tt.bodySmall)],
                ),
              ),
              const SizedBox(height: 10),
              Bar(fraction: goal > 0 ? value / goal : 0, color: color, label: label),
            ],
          ),
        ),
      );
    }

    // rows of intrinsic height (no fixed aspect ratio) so large system fonts never clip
    Widget row(int a) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: tile(items[a])),
          const SizedBox(width: 10),
          Expanded(child: tile(items[a + 1])),
        ],
      ),
    );
    return Column(children: [row(0), const SizedBox(height: 10), row(2)]);
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, this.onEdit, this.onDelete});

  final LogEntry log;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = context.c;
    final small = context.tt.bodySmall!;
    Widget macro(String letter, Color color, double v) => Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: letter,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' ${fmtNum(context, v)}'),
        ],
      ),
      style: small,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(log.foodName, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${log.kcal.round()} kcal',
                      style: context.tt.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    Text(
                      '${fmtNum(context, log.grams)} g',
                      style: small.copyWith(color: c.carbsText, fontWeight: FontWeight.w600),
                    ),
                    macro('P', c.proteinText, log.protein),
                    macro('K', c.carbsText, log.carbs),
                    macro('F', c.fatText, log.fat),
                    macro('B', c.fiberText, log.fiber),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(tooltip: t.edit, onPressed: onEdit, icon: const Icon(Icons.edit_outlined, size: 20)),
          if (onDelete != null)
            IconButton(tooltip: t.delete, onPressed: onDelete, icon: const Icon(Icons.close, size: 20)),
          if (onEdit == null && onDelete == null) const SizedBox(width: 12),
        ],
      ),
    );
  }
}
