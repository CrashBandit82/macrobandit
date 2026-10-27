// Plain data classes, read from the local database (see db.dart).

class Goals {
  const Goals({required this.kcal, required this.protein, required this.carbs, required this.fat, required this.fiber});

  static const defaults = Goals(kcal: 2000, protein: 150, carbs: 250, fat: 65, fiber: 30);

  final int kcal, protein, carbs, fat, fiber;

  Goals copyWith({int? kcal}) => Goals(kcal: kcal ?? this.kcal, protein: protein, carbs: carbs, fat: fat, fiber: fiber);
}

/// The person using this device – there are no accounts.
class User {
  User({required this.username, required this.avatarPath, required this.goals});

  /// Picks the colour gradient; always 1 since there is only one profile.
  int get id => 1;

  /// Empty until the user sets a name.
  final String username;

  /// Absolute path of the profile picture in the app directory.
  final String? avatarPath;
  final Goals goals;
}

/// Nutrients per 100 g – shared by own foods and lookup results.
abstract class Nutrients {
  String get name;
  String? get brand;
  double? get kcal;
  double? get protein;
  double? get carbs;
  double? get fat;
  double? get fiber;
}

class Food implements Nutrients {
  Food({
    required this.id,
    required this.name,
    this.brand,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.portionLabel,
    this.portionSize,
    this.useCount = 0,
  });

  /// 0 = Open Food Facts product that is not saved yet.
  final int id;
  @override
  final String name;
  @override
  final String? brand;
  @override
  final double? kcal, protein, carbs, fat, fiber;
  final String? portionLabel;
  final double? portionSize;
  final int useCount;

  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'brand': brand,
    'calories_per_100g': kcal,
    'protein_per_100g': protein,
    'carbs_per_100g': carbs,
    'fat_per_100g': fat,
    'fiber_per_100g': fiber,
    'portion_label': portionLabel,
    'portion_size_g': portionSize,
  };
}

/// Hit from the BLS 4.0 (code = BLS key) or Open Food Facts (code = barcode).
class RefFood implements Nutrients {
  RefFood({
    required this.code,
    required this.name,
    this.brand,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    required this.source,
  });

  final String code;
  @override
  final String name;
  @override
  final String? brand;
  @override
  final double? kcal, protein, carbs, fat, fiber;
  final String source;

  Map<String, dynamic> toCreateJson() => {
    'name': name,
    'brand': brand,
    'calories_per_100g': kcal,
    'protein_per_100g': protein,
    'carbs_per_100g': carbs,
    'fat_per_100g': fat,
    'fiber_per_100g': fiber,
  };
}

class LogEntry {
  LogEntry({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  final int id;

  /// null for template entries and for foods deleted later.
  final int? foodId;
  final String foodName;
  final double grams, kcal, protein, carbs, fat, fiber;
}

class DailyTotals {
  DailyTotals({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.entries,
  });

  final double kcal, protein, carbs, fat, fiber;
  final int entries;
}

class DayCalories {
  DayCalories(this.date, this.kcal);

  final DateTime date;
  final double kcal;
}

class WeeklyStats {
  WeeklyStats({required this.days, required this.total, required this.goal, required this.avg});

  final List<DayCalories> days;
  final double total, goal, avg;
}

class MonthDay {
  MonthDay(this.label, this.kcal, this.goalReached);

  /// "dd.mm."
  final String label;
  final double kcal;
  final bool goalReached;
}

class MonthlyStats {
  MonthlyStats({
    required this.daysTracked,
    required this.daysInMonth,
    required this.avgKcal,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.goalDays,
    required this.best,
    required this.worst,
    required this.daily,
  });

  final int daysTracked, daysInMonth, goalDays;
  final double avgKcal, avgProtein, avgCarbs, avgFat;
  final MonthDay? best, worst;
  final List<MonthDay> daily;
}

class TemplateItem {
  TemplateItem(this.foodId, this.foodName, this.grams, this.kcal);

  final int foodId;
  final String foodName;
  final double grams, kcal;
}

class MealTemplate {
  MealTemplate({required this.id, required this.name, required this.items, required this.totalKcal});

  final int id;
  final String name;
  final List<TemplateItem> items;
  final double totalKcal;
}

class WeightEntry {
  WeightEntry(this.id, this.kg, this.date);

  final int id;
  final double kg;
  final DateTime date;
}

class WeightHistory {
  WeightHistory({required this.entries, this.latest, this.start, this.trend});

  final List<WeightEntry> entries;
  final double? latest, start;

  /// Difference to the last entry older than 7 days.
  final double? trend;
}
