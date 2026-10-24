import 'package:flutter/material.dart';

import '../data/models.dart';
import 'theme.dart';
import 'widgets.dart';

/// Edit daily goals (kcal + macros in g). Pops true when saved.
class GoalsSheet extends StatefulWidget {
  const GoalsSheet({super.key});

  @override
  State<GoalsSheet> createState() => _GoalsSheetState();
}

class _GoalsSheetState extends State<GoalsSheet> {
  final _form = GlobalKey<FormState>();
  late final Goals _g = context.session.user.goals;
  late final _ctrls = [
    _g.kcal,
    _g.protein,
    _g.carbs,
    _g.fat,
    _g.fiber,
  ].map((v) => TextEditingController(text: '$v')).toList();
  var _busy = false;

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final v = _ctrls.map((c) => parseNum(c.text)!.round()).toList();
    setState(() => _busy = true);
    try {
      final session = context.session;
      final user = await session.api.updateGoals(Goals(kcal: v[0], protein: v[1], carbs: v[2], fat: v[3], fiber: v[4]));
      session.updateUser(user);
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
    final macros = [
      (t.macroProtein, context.c.protein),
      (t.macroCarbs, context.c.carbs),
      (t.macroFat, context.c.fat),
      (t.macroFiber, context.c.fiber),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.goalsTitle, style: context.tt.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ctrls[0],
              decoration: InputDecoration(labelText: t.calorieGoalLabel),
              keyboardType: TextInputType.number,
              validator: positiveNumber(context),
            ),
            const SizedBox(height: 12),
            // fields stack instead of a fixed-aspect grid, so large system fonts never clip
            Column(
              children: [
                for (final (i, (label, color)) in macros.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _ctrls[i + 1],
                      decoration: InputDecoration(
                        labelText: t.gramsLabel(label),
                        prefixIcon: Icon(Icons.circle, size: 10, color: color),
                        prefixIconConstraints: const BoxConstraints(minWidth: 30),
                      ),
                      keyboardType: TextInputType.number,
                      validator: positiveNumber(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
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
