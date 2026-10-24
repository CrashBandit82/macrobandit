import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrobandit/l10n/app_localizations.dart';
import 'package:macrobandit/ui/widgets.dart';

void main() {
  // Regression: the controller was disposed while the dialog was still closing
  // ("'_dependents.isEmpty': is not true" on the feedback dialog).
  testWidgets('PromptDialog returns the text and closes cleanly', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<String>(
                context: context,
                builder: (_) => const PromptDialog(title: 'Feedback', label: 'Text', multiline: true, action: 'Senden'),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tolle App!');
    await tester.tap(find.text('Senden'));
    await tester.pumpAndSettle();

    expect(result, 'Tolle App!');
    expect(find.byType(PromptDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
