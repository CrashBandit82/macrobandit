import 'package:flutter/material.dart';

import '../data/models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Meal templates: list, apply (one aggregated log entry), create, edit, delete.
class TemplatesPanel extends StatefulWidget {
  const TemplatesPanel({super.key, required this.onApplied});

  final VoidCallback onApplied;

  @override
  State<TemplatesPanel> createState() => _TemplatesPanelState();
}

class _TemplatesPanelState extends State<TemplatesPanel> {
  List<MealTemplate>? _templates;
  Object? _error;
  int? _applying;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await context.api.templates();
      if (mounted) setState(() => _templates = r);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _apply(MealTemplate tmpl) async {
    setState(() => _applying = tmpl.id);
    try {
      await context.api.applyTemplate(tmpl.id);
      if (!mounted) return;
      showMsg(context, context.t.templateApplied(tmpl.name));
      widget.onApplied();
    } on Object catch (e) {
      if (mounted) {
        showError(context, e);
        setState(() => _applying = null);
      }
    }
  }

  Future<void> _delete(MealTemplate tmpl) async {
    if (!await confirm(context, context.t.templateDeleteConfirm(tmpl.name)) || !mounted) return;
    try {
      await context.api.deleteTemplate(tmpl.id);
    } on Object catch (e) {
      if (mounted) showError(context, e);
    }
    await _load();
  }

  Future<void> _edit([MealTemplate? tmpl]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TemplateEditor(template: tmpl)),
    );
    if (saved == true) {
      if (mounted) showMsg(context, context.t.templateSaved);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final list = _templates;
    if (list == null) return LoadState(error: _error, onRetry: _load);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              t.templatesEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.muted),
            ),
          ),
        for (final tmpl in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tmpl.name, style: context.tt.titleSmall),
                              Text(
                                t.templateKcal(tmpl.totalKcal.round()),
                                style: context.tt.labelMedium!.copyWith(
                                  color: context.c.carbsText,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 104,
                          child: GradientButton(
                            label: t.addButton,
                            height: 38,
                            busy: _applying == tmpl.id,
                            onPressed: _applying == null ? () => _apply(tmpl) : null,
                          ),
                        ),
                        IconButton(
                          tooltip: t.edit,
                          onPressed: () => _edit(tmpl),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: t.delete,
                          onPressed: () => _delete(tmpl),
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final i in tmpl.items)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: context.c.page, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '${i.foodName} ${fmtNum(context, i.grams)} g',
                              style: context.tt.bodySmall!.copyWith(color: context.c.soft),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        OutlinedButton.icon(onPressed: _edit, icon: const Icon(Icons.add), label: Text(t.templateNew)),
      ],
    );
  }
}

class _Item {
  _Item(this.foodId, this.name, double grams, this.food) : grams = TextEditingController(text: _fmt(grams));

  final int foodId;
  final String name;
  final Food? food;
  final TextEditingController grams;

  static String _fmt(double g) => g == g.roundToDouble() ? '${g.round()}' : '$g'.replaceAll('.', ',');
}

/// Create or edit a template. Pops true when saved.
class TemplateEditor extends StatefulWidget {
  const TemplateEditor({super.key, this.template});

  final MealTemplate? template;

  @override
  State<TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<TemplateEditor> {
  late final _name = TextEditingController(text: widget.template?.name ?? '');
  final _search = TextEditingController();
  List<Food> _foods = const [];
  late final List<_Item> _items = [
    for (final i in widget.template?.items ?? const <TemplateItem>[]) _Item(i.foodId, i.foodName, i.grams, null),
  ];
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _name.addListener(() => setState(() {}));
    context.api.foods().then(
      (f) {
        if (mounted) setState(() => _foods = f);
      },
      onError: (Object e) {
        if (mounted) showError(context, e);
      },
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _search.dispose();
    for (final i in _items) {
      i.grams.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final t = context.t;
    if (_name.text.trim().isEmpty || _items.isEmpty) {
      showMsg(context, t.templateNeedsItems, error: true);
      return;
    }
    final items = <(int, double)>[];
    for (final i in _items) {
      final g = parseNum(i.grams.text);
      if (g == null || g <= 0) {
        showMsg(context, t.templateAmountError, error: true);
        return;
      }
      items.add((i.foodId, g));
    }
    setState(() => _busy = true);
    try {
      await context.api.saveTemplate(widget.template?.id, _name.text.trim(), items);
      if (mounted) Navigator.pop(context, true);
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
    final q = _search.text.trim().toLowerCase();
    final hits = q.isEmpty
        ? const <Food>[]
        : _foods
              .where((f) => f.name.toLowerCase().contains(q) && !_items.any((i) => i.foodId == f.id))
              .take(8)
              .toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.template == null ? t.templateNew : t.templateEdit)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: t.templateName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: InputDecoration(
                labelText: t.templateAddFood,
                prefixIcon: Icon(Icons.search, color: context.c.muted),
              ),
            ),
            if (q.isNotEmpty) ...[
              const SizedBox(height: 6),
              if (hits.isEmpty) Text(t.templateNotFound, style: context.tt.bodySmall),
              for (final f in hits)
                ListTile(
                  dense: true,
                  title: Text(f.name),
                  trailing: Text(t.kcalPer100((f.kcal ?? 0).round()), style: context.tt.bodySmall),
                  onTap: () => setState(() {
                    _items.add(_Item(f.id, f.name, f.portionSize ?? 100, f));
                    _search.clear();
                  }),
                ),
            ],
            const SizedBox(height: 16),
            for (final i in _items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(i.name, overflow: TextOverflow.ellipsis)),
                    if (i.food?.portionSize != null && i.food?.portionLabel != null)
                      TextButton(
                        onPressed: () => i.grams.text = _Item._fmt(i.food!.portionSize!),
                        child: Text(i.food!.portionLabel!),
                      ),
                    SizedBox(
                      width: 96,
                      child: TextField(
                        controller: i.grams,
                        textAlign: TextAlign.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(suffixText: 'g', isDense: true),
                      ),
                    ),
                    IconButton(
                      tooltip: t.delete,
                      onPressed: () => setState(() {
                        _items.remove(i);
                        i.grams.dispose();
                      }),
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            GradientButton(
              label: t.save,
              busy: _busy,
              onPressed: _name.text.trim().isNotEmpty && _items.isNotEmpty ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
