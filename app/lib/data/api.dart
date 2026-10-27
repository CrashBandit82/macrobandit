import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';

import 'bls.dart';
import 'db.dart';
import 'models.dart';

/// Error of an Open Food Facts lookup or a backup import. [detail] is a
/// message for the user, null for network errors.
class ApiException implements Exception {
  ApiException(this.status, this.detail);

  /// HTTP-like status, 0 = no connection.
  final int status;
  final String? detail;

  bool get offline => status == 0;

  @override
  String toString() => 'ApiException($status, $detail)';
}

const backupFormat = 'macrobandit-backup';
const backupVersion = 1;

/// All data of the app, stored on this device. The only network access is
/// the optional product lookup at Open Food Facts.
///
/// Methods are async so the UI does not care where the data comes from.
class Api {
  Api(this._db, {required this.filesDir, required this._loadBls, http.Client? client})
    : _http = client ?? http.Client();

  final Database _db;

  /// Private app directory for the profile picture.
  final String filesDir;
  final Future<String> Function() _loadBls;
  final http.Client _http;
  Future<Bls>? _bls;
  final _offCache = <String, (DateTime, List<RefFood>)>{};

  static const _userAgent = 'MacroBandit/3.0 (https://github.com/CrashBandit82/macrobandit)';

  Future<Bls> get bls => _bls ??= _loadBls().then(Bls.new);

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime _day(String s) {
    final p = s.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  static DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static double _round(double v, [int digits = 1]) {
    final f = digits == 0 ? 1 : (digits == 1 ? 10 : 100);
    return (v * f).round() / f;
  }

  static double? _dn(Object? v) => (v as num?)?.toDouble();

  // ── Profile ────────────────────────────────────────────────────────────

  String? _setting(String key) {
    final r = _db.select('SELECT value FROM settings WHERE key = ?', [key]);
    return r.isEmpty ? null : r.first['value'] as String;
  }

  void _setSetting(String key, String? value) {
    if (value == null) {
      _db.execute('DELETE FROM settings WHERE key = ?', [key]);
    } else {
      _db.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', [key, value]);
    }
  }

  int _goal(String key, int fallback) => int.tryParse(_setting(key) ?? '') ?? fallback;

  Future<User> me() async {
    const d = Goals.defaults;
    final avatar = _setting('avatar');
    return User(
      username: _setting('username') ?? '',
      avatarPath: avatar == null ? null : '$filesDir/$avatar',
      goals: Goals(
        kcal: _goal('goal_kcal', d.kcal),
        protein: _goal('goal_protein', d.protein),
        carbs: _goal('goal_carbs', d.carbs),
        fat: _goal('goal_fat', d.fat),
        fiber: _goal('goal_fiber', d.fiber),
      ),
    );
  }

  Future<User> updateGoals(Goals g) async {
    _setSetting('goal_kcal', '${g.kcal}');
    _setSetting('goal_protein', '${g.protein}');
    _setSetting('goal_carbs', '${g.carbs}');
    _setSetting('goal_fat', '${g.fat}');
    _setSetting('goal_fiber', '${g.fiber}');
    return me();
  }

  Future<User> changeUsername(String username) async {
    _setSetting('username', username.trim().isEmpty ? null : username.trim());
    return me();
  }

  /// Stores the picture under a new name, so image caches never show the old one.
  Future<User> setAvatar(Uint8List bytes, String extension) async {
    final name = 'avatar-${DateTime.now().millisecondsSinceEpoch}.$extension';
    await File('$filesDir/$name').writeAsBytes(bytes, flush: true);
    final old = _setting('avatar');
    _setSetting('avatar', name);
    if (old != null) await _deleteFile(old);
    return me();
  }

  Future<User> deleteAvatar() async {
    final old = _setting('avatar');
    _setSetting('avatar', null);
    if (old != null) await _deleteFile(old);
    return me();
  }

  Future<void> _deleteFile(String name) async {
    try {
      await File('$filesDir/$name').delete();
    } on FileSystemException {
      // already gone
    }
  }

  // ── Diary ──────────────────────────────────────────────────────────────

  static LogEntry _log(Row r) => LogEntry(
    id: r['id'] as int,
    foodId: r['food_id'] as int?,
    foodName: r['food_name'] as String,
    grams: _dn(r['grams'])!,
    kcal: _dn(r['kcal'])!,
    protein: _dn(r['protein'])!,
    carbs: _dn(r['carbs'])!,
    fat: _dn(r['fat'])!,
    fiber: _dn(r['fiber'])!,
  );

  static Map<String, double> _macros(Food f, double grams) {
    final m = grams / 100;
    return {
      'kcal': _round((f.kcal ?? 0) * m),
      'protein': _round((f.protein ?? 0) * m),
      'carbs': _round((f.carbs ?? 0) * m),
      'fat': _round((f.fat ?? 0) * m),
      'fiber': _round((f.fiber ?? 0) * m),
    };
  }

  /// [day] null = today.
  Future<DailyTotals> totals(DateTime? day) async {
    final r = _db.select(
      'SELECT COALESCE(SUM(kcal), 0) k, COALESCE(SUM(protein), 0) p, COALESCE(SUM(carbs), 0) c, '
      'COALESCE(SUM(fat), 0) f, COALESCE(SUM(fiber), 0) b, COUNT(*) n FROM logs WHERE day = ?',
      [_date(day ?? _today)],
    ).first;
    return DailyTotals(
      kcal: _round(_dn(r['k'])!),
      protein: _round(_dn(r['p'])!),
      carbs: _round(_dn(r['c'])!),
      fat: _round(_dn(r['f'])!),
      fiber: _round(_dn(r['b'])!),
      entries: r['n'] as int,
    );
  }

  Future<List<LogEntry>> logs(DateTime? day) async =>
      _db.select('SELECT * FROM logs WHERE day = ? ORDER BY id', [_date(day ?? _today)]).map(_log).toList();

  /// Logs always go to today.
  Future<void> addLog(int foodId, double grams) async {
    final food = _food(foodId);
    final m = _macros(food, grams);
    _db.execute(
      'INSERT INTO logs (day, food_id, food_name, grams, kcal, protein, carbs, fat, fiber) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [_date(_today), food.id, food.name, grams, m['kcal'], m['protein'], m['carbs'], m['fat'], m['fiber']],
    );
    _db.execute('UPDATE foods SET use_count = use_count + 1 WHERE id = ?', [food.id]);
  }

  /// New amount for an entry of a food; keeps the day of the entry.
  Future<void> updateLogAmount(int id, double grams) async {
    final r = _db.select('SELECT food_id FROM logs WHERE id = ?', [id]);
    final foodId = r.isEmpty ? null : r.first['food_id'] as int?;
    if (foodId == null) throw ApiException(404, null);
    final m = _macros(_food(foodId), grams);
    _db.execute('UPDATE logs SET grams = ?, kcal = ?, protein = ?, carbs = ?, fat = ?, fiber = ? WHERE id = ?', [
      grams,
      m['kcal'],
      m['protein'],
      m['carbs'],
      m['fat'],
      m['fiber'],
      id,
    ]);
  }

  Future<void> deleteLog(int id) async => _db.execute('DELETE FROM logs WHERE id = ?', [id]);

  /// kcal per day with entries, from [from] to [to] inclusive.
  Map<String, Map<String, double>> _dayTotals(DateTime from, DateTime to) => {
    for (final r in _db.select(
      'SELECT day, SUM(kcal) k, SUM(protein) p, SUM(carbs) c, SUM(fat) f FROM logs '
      'WHERE day BETWEEN ? AND ? GROUP BY day ORDER BY day',
      [_date(from), _date(to)],
    ))
      r['day'] as String: {'k': _dn(r['k'])!, 'p': _dn(r['p'])!, 'c': _dn(r['c'])!, 'f': _dn(r['f'])!},
  };

  /// Monday to Sunday of the current week.
  Future<WeeklyStats> weekly(int calorieGoal) async {
    final start = _today.subtract(Duration(days: _today.weekday - 1));
    final days = [for (var i = 0; i < 7; i++) DateTime(start.year, start.month, start.day + i)];
    final totals = _dayTotals(days.first, days.last);
    final kcal = [for (final d in days) _round(totals[_date(d)]?['k'] ?? 0)];
    final total = kcal.fold(0.0, (a, b) => a + b);
    final withData = kcal.where((k) => k > 0).length;
    return WeeklyStats(
      days: [for (var i = 0; i < 7; i++) DayCalories(days[i], kcal[i])],
      total: _round(total),
      goal: calorieGoal * 7.0,
      avg: withData == 0 ? 0 : _round(total / withData),
    );
  }

  Future<MonthlyStats> monthly(int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final totals = _dayTotals(DateTime(year, month), DateTime(year, month, daysInMonth));
    final goal = (await me()).goals.kcal;
    String label(String day) => '${day.substring(8)}.${day.substring(5, 7)}.';
    final rows = totals.entries.toList();
    final n = rows.length;
    double avg(String k) => n == 0 ? 0 : rows.fold(0.0, (a, r) => a + r.value[k]!) / n;
    MonthDay? pick(bool best) {
      if (n == 0) return null;
      var r = rows.first;
      for (final x in rows) {
        if (best ? x.value['k']! > r.value['k']! : x.value['k']! < r.value['k']!) r = x;
      }
      return MonthDay(label(r.key), _round(r.value['k']!, 0), false);
    }

    return MonthlyStats(
      daysTracked: n,
      daysInMonth: daysInMonth,
      avgKcal: _round(avg('k'), 0),
      avgProtein: _round(avg('p')),
      avgCarbs: _round(avg('c')),
      avgFat: _round(avg('f')),
      goalDays: rows.where((r) => r.value['k']! >= goal).length,
      best: pick(true),
      worst: pick(false),
      daily: [for (final r in rows) MonthDay(label(r.key), _round(r.value['k']!, 0), r.value['k']! >= goal)],
    );
  }

  // ── Foods ──────────────────────────────────────────────────────────────

  static Food _foodRow(Row r) => Food(
    id: r['id'] as int,
    name: r['name'] as String,
    brand: r['brand'] as String?,
    kcal: _dn(r['kcal']),
    protein: _dn(r['protein']),
    carbs: _dn(r['carbs']),
    fat: _dn(r['fat']),
    fiber: _dn(r['fiber']),
    portionLabel: r['portion_label'] as String?,
    portionSize: _dn(r['portion_size']),
    useCount: r['use_count'] as int,
  );

  Food _food(int id) {
    final r = _db.select('SELECT * FROM foods WHERE id = ?', [id]);
    if (r.isEmpty) throw ApiException(404, null);
    return _foodRow(r.first);
  }

  /// Most used first, then by name.
  Future<List<Food>> foods([String search = '']) async {
    // filtered in Dart: SQLite's lower() only knows ASCII ("Müsli")
    final q = search.toLowerCase();
    final list = _db.select('SELECT * FROM foods').map(_foodRow).where((f) => f.name.toLowerCase().contains(q)).toList()
      ..sort((a, b) {
        final c = b.useCount.compareTo(a.useCount);
        return c != 0 ? c : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return list;
  }

  /// [data] uses the keys of [Food.toCreateJson].
  Future<Food> createFood(Map<String, dynamic> data, {String? barcode}) async {
    _db.execute(
      'INSERT INTO foods (name, brand, kcal, protein, carbs, fat, fiber, portion_label, portion_size, barcode) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [..._foodValues(data), barcode],
    );
    return _food(_db.lastInsertRowId);
  }

  Future<Food> updateFood(int id, Map<String, dynamic> data) async {
    _db.execute(
      'UPDATE foods SET name = ?, brand = ?, kcal = ?, protein = ?, carbs = ?, fat = ?, fiber = ?, '
      'portion_label = ?, portion_size = ? WHERE id = ?',
      [..._foodValues(data), id],
    );
    return _food(id);
  }

  static List<Object?> _foodValues(Map<String, dynamic> d) => [
    (d['name'] as String).trim(),
    d['brand'] as String?,
    _dn(d['calories_per_100g']),
    _dn(d['protein_per_100g']),
    _dn(d['carbs_per_100g']),
    _dn(d['fat_per_100g']),
    _dn(d['fiber_per_100g']),
    d['portion_label'] as String?,
    _dn(d['portion_size_g']),
  ];

  /// Diary entries keep their values; template items with this food go.
  Future<void> deleteFood(int id) async => _db.execute('DELETE FROM foods WHERE id = ?', [id]);

  /// Own food with that barcode, or an unsaved Open Food Facts product (id 0).
  Future<Food> barcode(String code) async {
    if (!RegExp(r'^\d{6,20}$').hasMatch(code)) throw ApiException(400, null);
    final own = _db.select('SELECT * FROM foods WHERE barcode = ? ORDER BY id DESC LIMIT 1', [code]);
    if (own.isNotEmpty) return _foodRow(own.first);
    final json = await _getJson(
      Uri.https('world.openfoodfacts.org', '/api/v2/product/$code.json', {
        'fields': 'product_name,product_name_de,brands,nutriments',
      }),
      notFoundOk: true,
    );
    if (json == null || json['status'] != 1) throw ApiException(404, null);
    final p = json['product'] as Map<String, dynamic>;
    final n = (p['nutriments'] as Map<String, dynamic>?) ?? const {};
    final name = ((p['product_name_de'] as String?)?.trim().isNotEmpty ?? false)
        ? p['product_name_de'] as String
        : (p['product_name'] as String?) ?? '';
    return Food(
      id: 0,
      name: name.trim().isEmpty ? code : name.trim(),
      brand: _firstBrand(p['brands']),
      kcal: _num(n['energy-kcal_100g']),
      protein: _num(n['proteins_100g']),
      carbs: _num(n['carbohydrates_100g']),
      fat: _num(n['fat_100g']),
      fiber: _num(n['fiber_100g']),
    );
  }

  Future<Food> saveBarcodeFood(String code, Map<String, dynamic> data) => createFood(data, barcode: code);

  Future<List<RefFood>> referenceFoods(String q) async => (await bls).search(q);

  /// Copies a BLS entry into the own foods (or reuses an earlier copy).
  Future<Food> useReference(String code) async {
    final ref = (await bls).byCode(code);
    if (ref == null) throw ApiException(404, null);
    final copy = _db.select('SELECT id FROM foods WHERE brand = ? AND name = ? LIMIT 1', [Bls.source, ref.name]);
    if (copy.isNotEmpty) return _food(copy.first['id'] as int);
    return createFood(ref.toCreateJson()..['brand'] = Bls.source);
  }

  /// Text search at Open Food Facts (brand products). Only on request and
  /// cached for an hour: OFF allows few searches per minute.
  Future<List<RefFood>> onlineFoods(String q) async {
    final key = q.trim().toLowerCase();
    final cached = _offCache[key];
    if (cached != null && DateTime.now().difference(cached.$1) < const Duration(hours: 1)) return cached.$2;
    final json = await _getJson(
      Uri.https('search.openfoodfacts.org', '/search', {
        'q': q,
        'page_size': '25',
        'langs': 'de',
        'fields': 'code,product_name,product_name_de,brands,nutriments',
      }),
    );
    final result = <RefFood>[];
    for (final p in ((json?['hits'] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>()) {
      final n = (p['nutriments'] as Map<String, dynamic>?) ?? const {};
      final kcal = _num(n['energy-kcal_100g']);
      final name = ((p['product_name_de'] as String?)?.trim().isNotEmpty ?? false)
          ? (p['product_name_de'] as String).trim()
          : ((p['product_name'] as String?) ?? '').trim();
      final code = '${p['code'] ?? ''}';
      // without kcal or barcode not usable
      if (name.isEmpty || kcal == null || !RegExp(r'^\d+$').hasMatch(code)) continue;
      result.add(
        RefFood(
          code: code,
          name: name,
          brand: _firstBrand(p['brands']),
          kcal: kcal,
          protein: _num(n['proteins_100g']),
          carbs: _num(n['carbohydrates_100g']),
          fat: _num(n['fat_100g']),
          fiber: _num(n['fiber_100g']),
          source: 'Open Food Facts',
        ),
      );
      if (result.length == 15) break;
    }
    _offCache[key] = (DateTime.now(), result);
    return result;
  }

  static double? _num(Object? v) {
    final d = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    return d == null ? null : _round(d, 2);
  }

  static String? _firstBrand(Object? brands) {
    final b = (brands is List ? (brands.isEmpty ? '' : '${brands.first}') : '${brands ?? ''}').split(',').first.trim();
    return b.isEmpty ? null : b;
  }

  /// null for 404 when [notFoundOk].
  Future<Map<String, dynamic>?> _getJson(Uri uri, {bool notFoundOk = false}) async {
    final http.Response res;
    try {
      res = await _http.get(uri, headers: {'User-Agent': _userAgent}).timeout(const Duration(seconds: 15));
    } on Exception {
      throw ApiException(0, null);
    }
    if (res.statusCode == 404 && notFoundOk) return null;
    if (res.statusCode != 200) throw ApiException(502, null);
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(502, null);
    }
  }

  // ── Templates ──────────────────────────────────────────────────────────

  Future<List<MealTemplate>> templates() async {
    final items = <int, List<TemplateItem>>{};
    for (final r in _db.select(
      'SELECT i.template_id, i.food_id, i.grams, f.name, f.kcal FROM template_items i '
      'JOIN foods f ON f.id = i.food_id ORDER BY i.id',
    )) {
      final grams = _dn(r['grams'])!;
      items
          .putIfAbsent(r['template_id'] as int, () => [])
          .add(
            TemplateItem(r['food_id'] as int, r['name'] as String, grams, _round((_dn(r['kcal']) ?? 0) * grams / 100)),
          );
    }
    return [
      for (final r in _db.select('SELECT id, name FROM templates ORDER BY name COLLATE NOCASE'))
        MealTemplate(
          id: r['id'] as int,
          name: r['name'] as String,
          items: items[r['id']] ?? const [],
          totalKcal: _round((items[r['id']] ?? const <TemplateItem>[]).fold(0.0, (a, i) => a + i.kcal)),
        ),
    ];
  }

  Future<void> saveTemplate(int? id, String name, List<(int, double)> items) async {
    _transaction(() {
      if (id == null) {
        _db.execute('INSERT INTO templates (name) VALUES (?)', [name.trim()]);
        id = _db.lastInsertRowId;
      } else {
        _db.execute('UPDATE templates SET name = ? WHERE id = ?', [name.trim(), id]);
        _db.execute('DELETE FROM template_items WHERE template_id = ?', [id]);
      }
      for (final (foodId, grams) in items) {
        _db.execute('INSERT INTO template_items (template_id, food_id, grams) VALUES (?, ?, ?)', [id, foodId, grams]);
      }
    });
  }

  /// One diary entry with the template's name and summed values.
  Future<void> applyTemplate(int id) async {
    final t = _db.select('SELECT name FROM templates WHERE id = ?', [id]);
    if (t.isEmpty) throw ApiException(404, null);
    final sum = {'kcal': 0.0, 'protein': 0.0, 'carbs': 0.0, 'fat': 0.0, 'fiber': 0.0};
    var grams = 0.0;
    final items = _db.select('SELECT food_id, grams FROM template_items WHERE template_id = ?', [id]);
    _transaction(() {
      for (final i in items) {
        final g = _dn(i['grams'])!;
        _macros(_food(i['food_id'] as int), g).forEach((k, v) => sum[k] = sum[k]! + v);
        grams += g;
        _db.execute('UPDATE foods SET use_count = use_count + 1 WHERE id = ?', [i['food_id']]);
      }
      _db.execute(
        'INSERT INTO logs (day, food_id, food_name, grams, kcal, protein, carbs, fat, fiber) VALUES (?, NULL, ?, ?, ?, ?, ?, ?, ?)',
        [
          _date(_today),
          '📋 ${t.first['name']}',
          _round(grams),
          for (final k in ['kcal', 'protein', 'carbs', 'fat', 'fiber']) _round(sum[k]!),
        ],
      );
    });
  }

  Future<void> deleteTemplate(int id) async => _db.execute('DELETE FROM templates WHERE id = ?', [id]);

  // ── Weight ─────────────────────────────────────────────────────────────

  Future<WeightHistory> weightHistory({int days = 60}) async {
    final entries = [
      for (final r in _db.select('SELECT * FROM weights WHERE day >= ? ORDER BY day', [
        _date(_today.subtract(Duration(days: days))),
      ]))
        WeightEntry(r['id'] as int, _dn(r['kg'])!, _day(r['day'] as String)),
    ];
    double? trend;
    final weekAgo = _today.subtract(const Duration(days: 7));
    final recent = entries.where((e) => !e.date.isBefore(weekAgo)).toList();
    final older = entries.where((e) => e.date.isBefore(weekAgo)).toList();
    if (recent.isNotEmpty && older.isNotEmpty) trend = _round(recent.last.kg - older.last.kg);
    return WeightHistory(
      entries: entries,
      latest: entries.isEmpty ? null : entries.last.kg,
      start: entries.isEmpty ? null : entries.first.kg,
      trend: trend,
    );
  }

  /// One value per day: a second entry today replaces the first.
  Future<void> logWeight(double kg) async => _db.execute(
    'INSERT INTO weights (day, kg) VALUES (?, ?) ON CONFLICT (day) DO UPDATE SET kg = excluded.kg',
    [_date(_today), kg],
  );

  Future<void> deleteWeight(int id) async => _db.execute('DELETE FROM weights WHERE id = ?', [id]);

  // ── Export / backup ────────────────────────────────────────────────────

  static String _csv(Object? v) {
    var s = '${v ?? ''}';
    // no formulas when opened in a spreadsheet
    if (s.isNotEmpty && '=+-@'.contains(s[0]) && double.tryParse(s) == null) s = "'$s";
    return RegExp(r'[",\n\r]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  static String _de(String day) => '${day.substring(8)}.${day.substring(5, 7)}.${day.substring(0, 4)}';

  /// Goals, diary and weights as CSV (same layout as the web app's export).
  Future<Uint8List> exportCsv() async {
    final u = await me();
    final lines = <List<Object?>>[
      ['=== BENUTZERDATEN ==='],
      ['Benutzername', 'Kalorienziel', 'Proteinziel', 'KH-Ziel', 'Fettziel', 'Ballaststoffziel'],
      [u.username, u.goals.kcal, u.goals.protein, u.goals.carbs, u.goals.fat, u.goals.fiber],
      [],
      ['=== ERNAEHRUNGSTAGEBUCH ==='],
      [
        'Datum',
        'Lebensmittel',
        'Menge (g)',
        'Kalorien',
        'Protein (g)',
        'Kohlenhydrate (g)',
        'Fett (g)',
        'Ballaststoffe (g)',
      ],
      for (final r in _db.select('SELECT * FROM logs ORDER BY day DESC, id'))
        [
          _de(r['day'] as String),
          r['food_name'],
          r['grams'],
          r['kcal'],
          r['protein'],
          r['carbs'],
          r['fat'],
          r['fiber'],
        ],
      [],
      ['=== GEWICHTSVERLAUF ==='],
      ['Datum', 'Gewicht (kg)'],
      for (final r in _db.select('SELECT * FROM weights ORDER BY day DESC')) [_de(r['day'] as String), r['kg']],
    ];
    return utf8.encode(lines.map((l) => l.map(_csv).join(',')).join('\r\n'));
  }

  static const _tables = ['settings', 'foods', 'logs', 'templates', 'template_items', 'weights'];

  /// Whole database as JSON (without the profile picture).
  Future<Uint8List> exportBackup() async {
    final data = <String, Object?>{
      'format': backupFormat,
      'version': backupVersion,
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      for (final t in _tables)
        t: [
          for (final r in _db.select('SELECT * FROM $t ORDER BY 1'))
            if (t != 'settings' || r['key'] != 'avatar') Map<String, Object?>.of(r),
        ],
    };
    return utf8.encode(const JsonEncoder.withIndent(' ').convert(data));
  }

  /// Checks a backup and returns when it was made; throws [ApiException] 422.
  DateTime? checkBackup(Uint8List bytes) => _parseBackup(bytes).$2;

  (Map<String, dynamic>, DateTime?) _parseBackup(Uint8List bytes) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw ApiException(422, null);
    }
    if (json is! Map<String, dynamic> || json['format'] != backupFormat) throw ApiException(422, null);
    if ((json['schemaVersion'] as int? ?? 0) > schemaVersion) throw ApiException(426, null);
    return (json, DateTime.tryParse('${json['exportedAt']}'));
  }

  /// Replaces all data with the backup. All or nothing.
  Future<void> importBackup(Uint8List bytes) async {
    final (json, _) = _parseBackup(bytes);
    final avatar = _setting('avatar');
    try {
      _transaction(() {
        for (final t in _tables.reversed) {
          _db.execute('DELETE FROM $t');
        }
        for (final t in _tables) {
          final columns = {for (final r in _db.select('PRAGMA table_info($t)')) r['name'] as String};
          for (final row in ((json[t] as List<dynamic>?) ?? const []).cast<Map<String, dynamic>>()) {
            final keys = row.keys.where(columns.contains).toList();
            if (keys.isEmpty || (t == 'settings' && row['key'] == 'avatar')) continue;
            _db.execute('INSERT INTO $t (${keys.join(', ')}) VALUES (${List.filled(keys.length, '?').join(', ')})', [
              for (final k in keys) row[k],
            ]);
          }
        }
        if (avatar != null) _setSetting('avatar', avatar);
        if (_db.select('PRAGMA foreign_key_check').isNotEmpty) throw ApiException(422, null);
      });
    } on SqliteException {
      throw ApiException(422, null);
    }
  }

  /// Deletes everything on this device.
  Future<void> deleteAllData() async {
    final avatar = _setting('avatar');
    _transaction(() {
      for (final t in _tables.reversed) {
        _db.execute('DELETE FROM $t');
      }
    });
    if (avatar != null) await _deleteFile(avatar);
  }

  void _transaction(void Function() body) {
    _db.execute('BEGIN');
    try {
      body();
      _db.execute('COMMIT');
    } on Object {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }
}
