// Plain data classes for the JSON of macrobandit.at/api (see backend/schemas.py).

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _dn(Object? v) => (v as num?)?.toDouble();

DateTime _day(Object? v) {
  final p = (v as String).split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

class Goals {
  const Goals({required this.kcal, required this.protein, required this.carbs, required this.fat, required this.fiber});

  final int kcal, protein, carbs, fat, fiber;

  Map<String, dynamic> toJson() => {
    'goal_kcal': kcal,
    'goal_protein': protein,
    'goal_carbs': carbs,
    'goal_fat': fat,
    'goal_fiber': fiber,
  };

  Goals copyWith({int? kcal}) => Goals(kcal: kcal ?? this.kcal, protein: protein, carbs: carbs, fat: fat, fiber: fiber);
}

class User {
  User({
    required this.id,
    required this.email,
    required this.username,
    required this.avatarPath,
    required this.goals,
    required this.isVerified,
    required this.isFamilyMember,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['id'] as int,
    email: j['email'] as String,
    username: j['username'] as String,
    avatarPath: j['avatar_path'] as String?,
    goals: Goals(
      kcal: j['goal_kcal'] as int,
      protein: j['goal_protein'] as int,
      carbs: j['goal_carbs'] as int,
      fat: j['goal_fat'] as int,
      fiber: j['goal_fiber'] as int,
    ),
    isVerified: j['is_verified'] as bool,
    isFamilyMember: j['is_family_member'] as bool? ?? false,
  );

  final int id;
  final String email;
  final String username;
  final String? avatarPath;
  final Goals goals;
  final bool isVerified;
  final bool isFamilyMember;
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
    required this.userId,
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
    this.isFamily = false,
  });

  factory Food.fromJson(Map<String, dynamic> j) => Food(
    id: j['id'] as int,
    userId: j['user_id'] as int?,
    name: j['name'] as String,
    brand: j['brand'] as String?,
    kcal: _dn(j['calories_per_100g']),
    protein: _dn(j['protein_per_100g']),
    carbs: _dn(j['carbs_per_100g']),
    fat: _dn(j['fat_per_100g']),
    fiber: _dn(j['fiber_per_100g']),
    portionLabel: j['portion_label'] as String?,
    portionSize: _dn(j['portion_size_g']),
    useCount: j['use_count'] as int? ?? 0,
    isFamily: j['is_family'] as bool? ?? false,
  );

  /// 0 = Open Food Facts product that is not saved yet.
  final int id;
  final int? userId;
  @override
  final String name;
  @override
  final String? brand;
  @override
  final double? kcal, protein, carbs, fat, fiber;
  final String? portionLabel;
  final double? portionSize;
  final int useCount;
  final bool isFamily;

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

  factory RefFood.fromJson(Map<String, dynamic> j) => RefFood(
    code: j['code'] as String,
    name: j['name'] as String,
    brand: j['brand'] as String?,
    kcal: _dn(j['calories_per_100g']),
    protein: _dn(j['protein_per_100g']),
    carbs: _dn(j['carbs_per_100g']),
    fat: _dn(j['fat_per_100g']),
    fiber: _dn(j['fiber_per_100g']),
    source: j['source'] as String,
  );

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

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
    id: j['id'] as int,
    foodId: j['food_item_id'] as int?,
    foodName: j['food_name'] as String,
    grams: _d(j['amount_grams']),
    kcal: _d(j['calories']),
    protein: _d(j['protein']),
    carbs: _d(j['carbs']),
    fat: _d(j['fat']),
    fiber: _d(j['fiber']),
  );

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

  factory DailyTotals.fromJson(Map<String, dynamic> j) => DailyTotals(
    kcal: _d(j['calories']),
    protein: _d(j['protein']),
    carbs: _d(j['carbs']),
    fat: _d(j['fat']),
    fiber: _d(j['fiber']),
    entries: j['entries'] as int,
  );

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

  factory WeeklyStats.fromJson(Map<String, dynamic> j) => WeeklyStats(
    days: [
      for (final d in (j['days'] as List<dynamic>).cast<Map<String, dynamic>>())
        DayCalories(_day(d['date']), _d(d['calories'])),
    ],
    total: _d(j['weekly_total']),
    goal: _d(j['weekly_goal']),
    avg: _d(j['avg_daily']),
  );

  final List<DayCalories> days;
  final double total, goal, avg;
}

class MonthDay {
  MonthDay(this.label, this.kcal, this.goalReached);

  /// "dd.mm." as delivered by the server.
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

  factory MonthlyStats.fromJson(Map<String, dynamic> j) {
    MonthDay? day(Object? v) {
      if (v is! Map<String, dynamic>) return null;
      return MonthDay(v['date'] as String, _d(v['calories']), false);
    }

    return MonthlyStats(
      daysTracked: j['days_tracked'] as int,
      daysInMonth: j['days_in_month'] as int,
      avgKcal: _d(j['avg_calories']),
      avgProtein: _d(j['avg_protein']),
      avgCarbs: _d(j['avg_carbs']),
      avgFat: _d(j['avg_fat']),
      goalDays: j['goal_reached_days'] as int,
      best: day(j['best_day']),
      worst: day(j['worst_day']),
      daily: [
        for (final d in (j['daily'] as List<dynamic>).cast<Map<String, dynamic>>())
          MonthDay(d['date'] as String, _d(d['calories']), d['goal_reached'] as bool),
      ],
    );
  }

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

  factory MealTemplate.fromJson(Map<String, dynamic> j) => MealTemplate(
    id: j['id'] as int,
    name: j['name'] as String,
    items: [
      for (final i in (j['items'] as List<dynamic>).cast<Map<String, dynamic>>())
        TemplateItem(i['food_item_id'] as int, i['food_name'] as String, _d(i['amount_grams']), _d(i['calories'])),
    ],
    totalKcal: _d(j['total_kcal']),
  );

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

  factory WeightHistory.fromJson(Map<String, dynamic> j) => WeightHistory(
    entries: [
      for (final e in (j['entries'] as List<dynamic>).cast<Map<String, dynamic>>())
        WeightEntry(e['id'] as int, _d(e['weight_kg']), _day(e['date'])),
    ],
    latest: _dn(j['latest']),
    start: _dn(j['start_weight']),
    trend: _dn(j['trend']),
  );

  final List<WeightEntry> entries;
  final double? latest, start;

  /// Difference to the last entry older than 7 days.
  final double? trend;
}
