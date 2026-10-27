import 'dart:async';

import 'package:flutter/material.dart';

import '../core/nutrition.dart';
import '../data/models.dart';
import 'templates_panel.dart';
import 'theme.dart';
import 'widgets.dart';

enum PickSource { own, bls, off }

/// A food chosen for logging: own food, BLS entry or Open Food Facts product.
class Pick {
  Pick._(this.n, this.source, {this.food, this.code, this.scanned = false});

  factory Pick.own(Food f) => Pick._(f, PickSource.own, food: f);
  factory Pick.bls(RefFood r) => Pick._(r, PickSource.bls, code: r.code);
  factory Pick.offProduct(Nutrients n, String barcode, {bool scanned = false}) =>
      Pick._(n, PickSource.off, code: barcode, scanned: scanned);

  final Nutrients n;
  final PickSource source;
  final Food? food;

  /// BLS key or barcode.
  final String? code;
  final bool scanned;
}

/// Bottom sheet "Mahlzeit eintragen". Pops true after something was logged.
class AddMealSheet extends StatefulWidget {
  const AddMealSheet({super.key, this.initialPick, this.startCustom = false});

  final Pick? initialPick;
  final bool startCustom;

  @override
  State<AddMealSheet> createState() => _AddMealSheetState();
}

enum _Tab { search, custom, templates }

class _AddMealSheetState extends State<AddMealSheet> {
  late var _tab = widget.startCustom ? _Tab.custom : _Tab.search;
  late Pick? _pick = widget.initialPick;
  final _amount = TextEditingController();
  final _search = TextEditingController();
  var _busy = false;

  // search
  Timer? _debounce;
  List<Food> _foods = const [];
  List<RefFood> _bls = const [];
  List<RefFood>? _online; // null = not searched
  var _onlineBusy = false;
  var _onlineError = false;
  var _searchSeq = 0;

  // custom entry
  final _customForm = GlobalKey<FormState>();
  final _cName = TextEditingController();
  final _cGrams = TextEditingController();
  final _cKcal = TextEditingController();
  final _cProtein = TextEditingController();
  final _cCarbs = TextEditingController();
  final _cFat = TextEditingController();
  final _cFiber = TextEditingController();

  @override
  void initState() {
    super.initState();
    _runSearch();
    _search.addListener(_onSearchChanged);
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_amount, _search, _cName, _cGrams, _cKcal, _cProtein, _cCarbs, _cFat, _cFiber]) {
      c.dispose();
    }
    super.dispose();
  }

  QuickEntry get _quick => QuickEntry.parse(_search.text);

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _runSearch);
    setState(() {
      _online = null;
      _onlineError = false;
    });
  }

  Future<void> _runSearch() async {
    final seq = ++_searchSeq;
    final term = _quick.term;
    final api = context.api;
    try {
      final foods = await api.foods(term);
      final bls = term.length >= 2 ? await api.referenceFoods(term) : <RefFood>[];
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _foods = foods;
        _bls = bls;
      });
    } on Object catch (e) {
      if (mounted && seq == _searchSeq) showError(context, e);
    }
  }

  // Open Food Facts allows only a few text searches per minute → on tap only
  Future<void> _searchOnline() async {
    final term = _quick.term;
    if (term.length < 2) return;
    setState(() {
      _onlineBusy = true;
      _onlineError = false;
    });
    try {
      final r = await context.api.onlineFoods(term);
      if (mounted) setState(() => _online = r);
    } on Object {
      if (mounted) {
        setState(() {
          _online = const [];
          _onlineError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _onlineBusy = false);
    }
  }

  void _choose(Pick p) {
    final g = _quick.grams;
    setState(() {
      _pick = p;
      _amount.text = g == null ? '' : fmtNum(context, g);
    });
  }

  Future<void> _logPick() async {
    final pick = _pick!;
    final grams = parseNum(_amount.text);
    if (grams == null || grams <= 0) return;
    setState(() => _busy = true);
    final api = context.api;
    final t = context.t;
    try {
      final foodId = switch (pick.source) {
        PickSource.own => pick.food!.id,
        // BLS entry → own copy (new row, or the one taken over earlier)
        PickSource.bls => (await api.useReference(pick.code!)).id,
        PickSource.off => (await api.saveBarcodeFood(
          pick.code!,
          pick.n is RefFood ? (pick.n as RefFood).toCreateJson() : (pick.n as Food).toCreateJson(),
        )).id,
      };
      await api.addLog(foodId, grams);
      if (!mounted) return;
      showMsg(context, t.itemAdded(pick.n.name));
      Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _logCustom() async {
    if (!_customForm.currentState!.validate()) return;
    final grams = parseNum(_cGrams.text)!;
    final f = 100 / grams;
    double per100(TextEditingController c) => (parseNum(c.text) ?? 0) * f;
    setState(() => _busy = true);
    final api = context.api;
    final t = context.t;
    try {
      final food = await api.createFood({
        'name': _cName.text.trim(),
        'brand': 'Manuell',
        'calories_per_100g': per100(_cKcal),
        'protein_per_100g': per100(_cProtein),
        'carbs_per_100g': per100(_cCarbs),
        'fat_per_100g': per100(_cFat),
        'fiber_per_100g': per100(_cFiber),
      });
      await api.addLog(food.id, grams);
      if (!mounted) return;
      showMsg(context, t.mealLogged);
      Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    Widget box(List<Widget> children) => SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.list(children: children),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => CustomScrollView(
        controller: scroll,
        slivers: [
          box([
            Text(t.addMeal, style: context.tt.titleLarge),
            const SizedBox(height: 14),
            if (_pick == null) ...[
              SegmentedButton<_Tab>(
                segments: [
                  segment(_Tab.search, t.tabSearch),
                  segment(_Tab.custom, t.tabCustom),
                  segment(_Tab.templates, t.tabTemplates),
                ],
                selected: {_tab},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: 16),
            ],
          ]),
          if (_pick != null)
            box(_pickedView(context, _pick!))
          else
            ...switch (_tab) {
              _Tab.search => _searchSlivers(context, box),
              _Tab.custom => [
                box([_customView(context)]),
              ],
              _Tab.templates => [
                box([TemplatesPanel(onApplied: () => Navigator.pop(context, true))]),
              ],
            },
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  List<Widget> _pickedView(BuildContext context, Pick pick) {
    final t = context.t;
    final c = context.c;
    final n = pick.n;
    final grams = parseNum(_amount.text);
    final food = pick.food;
    String v(double? per100, int digits) {
      final x = forAmount(per100, grams);
      return x == null ? '–' : fmtNum(context, x, digits);
    }

    final small = context.tt.bodySmall!;
    final source = switch (pick.source) {
      PickSource.bls => ('BLS 4.0', c.accent),
      PickSource.off => pick.scanned ? (t.sourceScanned, c.accent) : ('Open Food Facts', c.onlineText),
      PickSource.own => null,
    };
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.name, style: context.tt.titleMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  if (n.brand != null && n.brand!.isNotEmpty) Text(n.brand!, style: small),
                  Text(
                    t.kcalPer100((n.kcal ?? 0).round()),
                    style: small.copyWith(color: c.carbsText, fontWeight: FontWeight.w600),
                  ),
                  if (source != null) Text(source.$1, style: small.copyWith(color: source.$2)),
                ],
              ),
              const Divider(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (value, label, color, labelColor) in [
                    (v(n.kcal, 0), 'kcal', c.carbsText, c.muted),
                    (v(n.protein, 1), '${t.macroProtein} g', c.text, c.proteinText),
                    (v(n.carbs, 1), '${t.shortCarbs} g', c.text, c.carbsText),
                    (v(n.fat, 1), '${t.macroFat} g', c.text, c.fatText),
                  ])
                    Expanded(
                      child: Column(
                        children: [
                          Text(value, style: context.tt.titleMedium!.copyWith(color: color)),
                          Text(
                            label,
                            textAlign: TextAlign.center,
                            style: context.tt.labelMedium!.copyWith(color: labelColor),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (food?.portionSize != null) ...[
        Align(
          alignment: Alignment.centerLeft,
          child: ActionChip(
            label: Text('${food!.portionLabel ?? ''} (${fmtNum(context, food.portionSize!)} g)'.trim()),
            onPressed: () => _amount.text = fmtNum(context, food.portionSize!),
          ),
        ),
        const SizedBox(height: 10),
      ],
      Row(
        children: [
          SizedBox(
            width: 140,
            child: TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: context.tt.titleMedium,
              decoration: InputDecoration(hintText: '0', suffixText: 'g', labelText: t.amountGrams),
              onSubmitted: (_) => _logPick(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GradientButton(
              label: t.addButton,
              height: 54,
              busy: _busy,
              onPressed: (grams ?? 0) > 0 ? _logPick : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (widget.initialPick == null) TextButton(onPressed: () => setState(() => _pick = null), child: Text(t.back)),
    ];
  }

  /// Search results as slivers – own foods are built lazily (the list can be long).
  List<Widget> _searchSlivers(BuildContext context, Widget Function(List<Widget>) box) {
    final t = context.t;
    final c = context.c;
    final q = _quick;
    final small = context.tt.bodySmall!;
    return [
      box([
        TextField(
          controller: _search,
          decoration: InputDecoration(
            labelText: t.searchLabel,
            hintText: t.searchHint,
            prefixIcon: Icon(Icons.search, color: c.muted),
          ),
          textInputAction: TextInputAction.search,
        ),
        if (q.grams != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              t.quickAmount(fmtNum(context, q.grams!), q.term),
              style: small.copyWith(color: c.accent, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 14),
        if (q.term.length >= 2) ...[
          if (_online == null)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: c.online, foregroundColor: Colors.white),
              onPressed: _onlineBusy ? null : _searchOnline,
              icon: const Icon(Icons.public, size: 18),
              label: Text(_onlineBusy ? t.onlineSearching : t.onlineSearch(q.term), overflow: TextOverflow.ellipsis),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.online.withValues(alpha: 0.06),
                border: Border.all(color: c.online.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: SectionLabel(t.onlineSection, color: c.onlineText)),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: c.muted),
                        onPressed: () => setState(() => _online = null),
                        child: Text(t.onlineHide),
                      ),
                    ],
                  ),
                  if (_onlineError)
                    Text(t.onlineError, style: small.copyWith(color: c.fatText))
                  else if (_online!.isEmpty)
                    Text(t.onlineNone, style: small),
                  for (final r in _online!)
                    _FoodRow(
                      name: r.name,
                      sub: r.brand,
                      kcal: r.kcal,
                      borderColor: c.online.withValues(alpha: 0.4),
                      onTap: () => _choose(Pick.offProduct(r, r.code)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
        if (_foods.isNotEmpty) SectionLabel(t.myFoodsSection),
      ]),
      if (_foods.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: _foods.length,
            itemBuilder: (context, i) {
              final f = _foods[i];
              return _FoodRow(
                name: f.name,
                sub: [
                  if (f.brand != null && f.brand!.isNotEmpty) f.brand!,
                  if (f.useCount > 0) '${f.useCount}×',
                ].join(' · '),
                kcal: f.kcal,
                onTap: () => _choose(Pick.own(f)),
              );
            },
          ),
        ),
      box([
        if (_foods.isNotEmpty) const SizedBox(height: 16),
        if (_bls.isNotEmpty) ...[
          SectionLabel(t.blsSection),
          for (final r in _bls)
            _FoodRow(
              name: r.name,
              kcal: r.kcal,
              borderColor: c.primary.withValues(alpha: 0.35),
              onTap: () => _choose(Pick.bls(r)),
            ),
          Text(t.blsSource, style: context.tt.labelMedium!.copyWith(fontWeight: FontWeight.w400)),
        ],
        if (_foods.isEmpty && _bls.isEmpty && (_online?.isEmpty ?? true))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              t.noResults,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.faint),
            ),
          ),
      ]),
    ];
  }

  Widget _customView(BuildContext context) {
    final t = context.t;
    Widget field(TextEditingController ctrl, String label, {bool required = false}) => TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: required
          ? positiveNumber(context)
          : (v) => (v ?? '').trim().isEmpty || parseNum(v!) != null ? null : t.invalidNumber,
    );
    // pairs wrap to one column under large system fonts
    Widget pair(Widget a, Widget b) => MediaQuery.textScalerOf(context).scale(1) > 1.3
        ? Column(children: [a, const SizedBox(height: 10), b])
        : Row(
            children: [
              Expanded(child: a),
              const SizedBox(width: 10),
              Expanded(child: b),
            ],
          );
    return Form(
      key: _customForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.customHint, style: context.tt.bodySmall),
          const SizedBox(height: 12),
          TextFormField(
            controller: _cName,
            decoration: InputDecoration(labelText: t.mealName),
            validator: requiredText(context),
          ),
          const SizedBox(height: 10),
          pair(field(_cGrams, t.portionWeight, required: true), field(_cKcal, t.kcalPortion, required: true)),
          const SizedBox(height: 10),
          pair(field(_cProtein, t.gramsLabel(t.macroProtein)), field(_cCarbs, t.gramsLabel(t.shortCarbs))),
          const SizedBox(height: 10),
          pair(field(_cFat, t.gramsLabel(t.macroFat)), field(_cFiber, t.gramsLabel(t.macroFiber))),
          const SizedBox(height: 18),
          GradientButton(label: t.saveAndLog, busy: _busy, onPressed: _logCustom),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.name, this.sub, required this.kcal, required this.onTap, this.borderColor});

  final String name;
  final String? sub;
  final double? kcal;
  final VoidCallback onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor ?? c.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: context.tt.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      if (sub != null && sub!.isNotEmpty)
                        Text(sub!, style: context.tt.bodySmall, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(kcal ?? 0).round()} kcal',
                  style: context.tt.labelMedium!.copyWith(color: c.carbsText, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
