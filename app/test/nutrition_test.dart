import 'package:flutter_test/flutter_test.dart';
import 'package:macrobandit/core/nutrition.dart';

void main() {
  group('QuickEntry', () {
    void expectParse(String input, double? grams, String term) {
      final q = QuickEntry.parse(input);
      expect(q.grams, grams, reason: input);
      expect(q.term, term, reason: input);
    }

    test('matches the web app', () {
      expectParse('200g Milch 3,5', 200, 'Milch 3,5');
      expectParse('Milch 3,5 200 g', 200, 'Milch 3,5');
      expectParse('200 Rinderfilet', 200, 'Rinderfilet');
      expectParse('0,5 l Milch', 500, 'Milch');
      expectParse('1.5kg Kartoffeln', 1500, 'Kartoffeln');
      expectParse('2 Eier', null, 'Eier');
      expectParse('Milch 3,5', null, 'Milch 3,5');
      expectParse('  Apfel ', null, 'Apfel');
      expectParse('12,34 g Nüsse', 12.3, 'Nüsse');
    });
  });

  test('kcalColor bands', () {
    expect(kcalColor(0), kcalWhite);
    expect(kcalColor(75), kcalYellow);
    expect(kcalColor(100), kcalGreen);
    expect(kcalColor(104), kcalGreen);
    expect(kcalColor(106), kcalRed);
  });

  test('calcTdee (Mifflin-St Jeor)', () {
    // 10*80 + 6.25*180 - 5*30 + 5 = 1780; * 1.55 = 2759
    expect(
      calcTdee(
        male: true,
        age: 30,
        heightCm: 180,
        weightKg: 80,
        activity: Activity.moderate,
        goal: WeightGoal.maintain,
      ),
      2759,
    );
    // 10*60 + 6.25*165 - 5*40 - 161 = 1270.25; * 1.2 - 500 = 1024
    expect(
      calcTdee(male: false, age: 40, heightCm: 165, weightKg: 60, activity: Activity.sedentary, goal: WeightGoal.lose),
      1024,
    );
    expect(
      calcTdee(male: true, age: null, heightCm: 180, weightKg: 80, activity: Activity.light, goal: WeightGoal.gain),
      isNull,
    );
  });
}
