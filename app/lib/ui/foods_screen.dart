import 'package:flutter/material.dart';

import '../data/models.dart';
import 'theme.dart';
import 'widgets.dart';

/// The user's own foods: edit, delete.
class FoodsScreen extends StatefulWidget {
  const FoodsScreen({super.key});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  List<Food>? _foods;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final all = await context.api.foods();
      if (mounted) setState(() => _foods = all);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _delete(Food f) async {
    final t = context.t;
    if (!await confirm(context, t.deleteFoodConfirm(f.name)) || !mounted) return;
    try {
      await context.api.deleteFood(f.id);
      if (mounted) showMsg(context, t.itemDeleted(f.name));
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
    await _load();
  }

  Future<void> _edit(Food f) async {
    final saved = await showSheet<bool>(context, (_) => _FoodEditor(food: f));
    if (saved == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final foods = _foods;
    return Scaffold(
      appBar: AppBar(title: Text(t.foodDbTitle)),
      body: SafeArea(
        child: foods == null
            ? LoadState(error: _error, onRetry: _load)
            : RefreshIndicator(
                onRefresh: _load,
                // built lazily: the list of own foods can be long
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: foods.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return PageWidth(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(t.foodDbInfo, style: context.tt.bodySmall),
                              if (foods.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: Text(
                                    t.noOwnFoods,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: context.c.faint),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                    final f = foods[i - 1];
                    return PageWidth(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          child: ListTile(
                            title: Text(f.name),
                            subtitle: Text(
                              [
                                if (f.brand != null && f.brand!.isNotEmpty) f.brand!,
                                t.kcalPer100((f.kcal ?? 0).round()),
                              ].join(' · '),
                            ),
                            onTap: () => _edit(f),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: t.delete,
                                  onPressed: () => _delete(f),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _FoodEditor extends StatefulWidget {
  const _FoodEditor({required this.food});

  final Food food;

  @override
  State<_FoodEditor> createState() => _FoodEditorState();
}

class _FoodEditorState extends State<_FoodEditor> {
  final _form = GlobalKey<FormState>();
  late final Food f = widget.food;
  late final _name = TextEditingController(text: f.name);
  late final _brand = TextEditingController(text: f.brand ?? '');
  late final _portionLabel = TextEditingController(text: f.portionLabel ?? '');
  late final _nums = [
    f.kcal,
    f.protein,
    f.carbs,
    f.fat,
    f.fiber,
    f.portionSize,
  ].map((v) => TextEditingController(text: v == null ? '' : _fmt(v))).toList();
  var _busy = false;

  static String _fmt(double v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2).replaceAll('.', ',');

  @override
  void dispose() {
    for (final c in [_name, _brand, _portionLabel, ..._nums]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final v = _nums.map((c) => parseNum(c.text)).toList();
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    setState(() => _busy = true);
    try {
      final u = await context.api.updateFood(f.id, {
        'name': _name.text.trim(),
        'brand': text(_brand),
        'calories_per_100g': v[0],
        'protein_per_100g': v[1],
        'carbs_per_100g': v[2],
        'fat_per_100g': v[3],
        'fiber_per_100g': v[4],
        'portion_label': text(_portionLabel),
        'portion_size_g': v[5],
      });
      if (!mounted) return;
      showMsg(context, context.t.foodSaved(u.name));
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
    String? optionalNumber(String? v) => (v ?? '').trim().isEmpty || parseNum(v!) != null ? null : t.invalidNumber;
    Widget num(int i, String label) => TextFormField(
      controller: _nums[i],
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: optionalNumber,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.editFoodTitle, style: context.tt.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: t.nameLabel),
              validator: requiredText(context),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _brand,
              decoration: InputDecoration(labelText: t.brandOptional),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: num(0, t.kcalPer100Label)),
                const SizedBox(width: 10),
                Expanded(child: num(1, t.per100Label(t.macroProtein))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: num(2, t.per100Label(t.macroCarbs))),
                const SizedBox(width: 10),
                Expanded(child: num(3, t.per100Label(t.macroFat))),
              ],
            ),
            const SizedBox(height: 10),
            num(4, t.per100Label(t.macroFiber)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _portionLabel,
                    decoration: InputDecoration(labelText: t.portionLabel, hintText: t.portionLabelHint),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: num(5, t.portionGrams)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GradientButton(label: t.save, busy: _busy, onPressed: _save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
