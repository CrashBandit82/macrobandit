import 'dart:ui';

/// Quick entry "200g Milch 3,5" / "Milch 3,5 200 g" / "200 Rinderfilet" / "0,5 l Milch":
/// splits amount (grams) and search term like the web app. kg and l become grams
/// (1 l ≈ 1000 g). A trailing number only counts as amount WITH a unit – otherwise
/// "Milch 3,5" would mean 3.5 g.
class QuickEntry {
  const QuickEntry(this.grams, this.term);

  /// null = no amount recognised.
  final double? grams;
  final String term;

  static const _unit = '(g|gr|gramm|ml|kg|l|liter)';
  static final _leading = RegExp('^(\\d+(?:[.,]\\d+)?)\\s*$_unit?\\s+(.+)\$', caseSensitive: false);
  static final _trailing = RegExp('^(.+?)\\s+(\\d+(?:[.,]\\d+)?)\\s*$_unit\$', caseSensitive: false);

  static double _grams(String number, String? unit) {
    final factor = RegExp(r'^(kg|l|liter)$', caseSensitive: false).hasMatch(unit ?? '') ? 1000 : 1;
    final v = double.parse(number.replaceAll(',', '.')) * factor;
    return (v * 10).round() / 10;
  }

  static QuickEntry parse(String text) {
    final t = text.trim();
    var m = _leading.firstMatch(t);
    if (m != null) {
      // without unit only from 10 on as grams – "2 Eier" / "1 Apfel" are pieces
      final number = double.parse(m[1]!.replaceAll(',', '.'));
      if (m[2] != null || number >= 10) return QuickEntry(_grams(m[1]!, m[2]), m[3]!.trim());
      return QuickEntry(null, m[3]!.trim()); // don't search for the piece count
    }
    m = _trailing.firstMatch(t);
    if (m != null) return QuickEntry(_grams(m[2]!, m[3]), m[1]!.trim());
    return QuickEntry(null, t);
  }
}

/// Nutrient amount for [grams] from the value per 100 g.
double? forAmount(double? per100, double? grams) => per100 == null || grams == null ? null : per100 * grams / 100;

/// Calorie color by progress towards the daily goal (percent):
/// 0–75 [low] (white in dark mode) → yellow, 75–100 yellow → green, 100–105 green, > 105 red.
const kcalWhite = Color(0xFFFFFFFF);
const kcalYellow = Color(0xFFFACC15);
const kcalGreen = Color(0xFF22C55E);
const kcalRed = Color(0xFFEF4444);

Color kcalColor(double percent, {Color low = kcalWhite}) {
  if (percent <= 75) return Color.lerp(low, kcalYellow, (percent / 75).clamp(0, 1))!;
  if (percent <= 100) return Color.lerp(kcalYellow, kcalGreen, ((percent - 75) / 25).clamp(0, 1))!;
  if (percent <= 105) return kcalGreen;
  return kcalRed;
}

enum Activity {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  const Activity(this.factor);
  final double factor;
}

enum WeightGoal {
  lose(-500),
  maintain(0),
  gain(300);

  const WeightGoal(this.offset);
  final int offset;
}

/// Daily calorie need after Mifflin-St Jeor, plus goal offset.
int? calcTdee({
  required bool male,
  required int? age,
  required int? heightCm,
  required double? weightKg,
  required Activity activity,
  required WeightGoal goal,
}) {
  if (age == null || heightCm == null || weightKg == null || age <= 0 || heightCm <= 0) return null;
  final bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + (male ? 5 : -161);
  return (bmr * activity.factor + goal.offset).round();
}
