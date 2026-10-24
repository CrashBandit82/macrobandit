import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'models.dart';

const serverOrigin = 'https://macrobandit.at';
const _apiBase = '$serverOrigin/api';

/// Error from the MacroBandit API. [detail] is the server's message (German),
/// null for network errors.
class ApiException implements Exception {
  ApiException(this.status, this.detail);

  /// HTTP status, 0 = no connection.
  final int status;
  final String? detail;

  bool get offline => status == 0;

  @override
  String toString() => 'ApiException($status, $detail)';
}

/// Thin client for the FastAPI backend of macrobandit.at.
///
/// Access tokens live 60 min, refresh tokens 30 days. On 401 the client
/// refreshes once and repeats the request; if that fails [onSessionExpired]
/// fires.
class Api {
  Api({http.Client? client, FlutterSecureStorage? storage})
    : _http = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _http;
  final FlutterSecureStorage _storage;
  String? _access;
  String? _refresh;
  Future<bool>? _refreshing;
  void Function()? onSessionExpired;

  bool get hasTokens => _access != null;

  Future<void> loadTokens() async {
    _access = await _storage.read(key: 'access_token');
    _refresh = await _storage.read(key: 'refresh_token');
  }

  Future<void> _saveTokens(Map<String, dynamic> json) async {
    _access = json['access_token'] as String;
    _refresh = json['refresh_token'] as String;
    await _storage.write(key: 'access_token', value: _access);
    await _storage.write(key: 'refresh_token', value: _refresh);
  }

  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // ── Transport ──────────────────────────────────────────────────────────

  Future<http.Response> _send(String method, String path, {Object? body, bool auth = true}) async {
    Future<http.Response> once() async {
      final req = http.Request(method, Uri.parse('$_apiBase$path'));
      if (body != null) {
        req.headers['Content-Type'] = 'application/json';
        req.body = jsonEncode(body);
      }
      if (auth && _access != null) req.headers['Authorization'] = 'Bearer $_access';
      try {
        return await http.Response.fromStream(await _http.send(req).timeout(const Duration(seconds: 20)));
      } on Exception {
        throw ApiException(0, null);
      }
    }

    var res = await once();
    if (auth && res.statusCode == 401) {
      if (await _refreshTokens()) {
        res = await once();
      }
      if (res.statusCode == 401) {
        await clearTokens();
        onSessionExpired?.call();
      }
    }
    _check(res);
    return res;
  }

  /// One refresh at a time – parallel 401s wait for the same attempt.
  Future<bool> _refreshTokens() {
    return _refreshing ??= () async {
      try {
        if (_refresh == null) return false;
        final res = await _http
            .post(
              Uri.parse('$_apiBase/auth/refresh'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'refresh_token': _refresh}),
            )
            .timeout(const Duration(seconds: 20));
        if (res.statusCode != 200) return false;
        await _saveTokens(_json(res) as Map<String, dynamic>);
        return true;
      } on Exception {
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }

  static void _check(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? detail;
    try {
      final d = (jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>)['detail'];
      if (d is String) {
        detail = d;
      } else if (d is List) {
        // pydantic validation errors: [{msg: "Value error, Passwort muss …"}]
        detail = d
            .whereType<Map<String, dynamic>>()
            .map((e) => (e['msg'] ?? '').toString().replaceFirst('Value error, ', ''))
            .join('\n');
      }
    } on Object {
      detail = null;
    }
    throw ApiException(res.statusCode, detail);
  }

  static Object? _json(http.Response res) => res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));

  Future<Object?> _get(String path) async => _json(await _send('GET', path));
  Future<Object?> _post(String path, [Object? body]) async => _json(await _send('POST', path, body: body));
  Future<Object?> _put(String path, Object body) async => _json(await _send('PUT', path, body: body));
  Future<void> _delete(String path, [Object? body]) => _send('DELETE', path, body: body);

  static List<T> _list<T>(Object? json, T Function(Map<String, dynamic>) f) =>
      (json as List<dynamic>).cast<Map<String, dynamic>>().map(f).toList();

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Auth / account ─────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    final res = await _send('POST', '/auth/login', body: {'email': email, 'password': password}, auth: false);
    await _saveTokens(_json(res) as Map<String, dynamic>);
  }

  Future<void> register(String email, String username, String password) =>
      _send('POST', '/auth/register', body: {'email': email, 'username': username, 'password': password}, auth: false);

  Future<void> forgotPassword(String email) =>
      _send('POST', '/auth/forgot-password', body: {'email': email}, auth: false);

  Future<User> me() async => User.fromJson(await _get('/auth/me') as Map<String, dynamic>);

  Future<User> updateGoals(Goals g) async =>
      User.fromJson(await _put('/auth/goals', g.toJson()) as Map<String, dynamic>);

  Future<User> changeUsername(String username) async =>
      User.fromJson(await _put('/auth/username', {'username': username}) as Map<String, dynamic>);

  Future<void> changePassword(String current, String next) =>
      _put('/auth/password', {'current_password': current, 'new_password': next});

  Future<void> resendVerification() => _post('/auth/resend-verification');

  Future<void> sendFeedback(String message) => _post('/auth/feedback', {'message': message});

  Future<void> deleteAccount(String password) => _delete('/auth/account', {'password': password});

  Future<Uint8List> exportCsv() async => (await _send('GET', '/auth/export')).bodyBytes;

  Future<User> uploadAvatar(Uint8List bytes, String filename, String mimeType) async {
    Future<http.Response> once() async {
      final req = http.MultipartRequest('POST', Uri.parse('$_apiBase/auth/avatar'))
        ..headers['Authorization'] = 'Bearer $_access'
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: MediaType.parse(mimeType)),
        );
      try {
        return await http.Response.fromStream(await _http.send(req));
      } on Exception {
        throw ApiException(0, null);
      }
    }

    var res = await once();
    if (res.statusCode == 401 && await _refreshTokens()) res = await once();
    _check(res);
    return User.fromJson(_json(res) as Map<String, dynamic>);
  }

  Future<User> deleteAvatar() async {
    final res = await _send('DELETE', '/auth/avatar');
    return User.fromJson(_json(res) as Map<String, dynamic>);
  }

  // ── Diary ──────────────────────────────────────────────────────────────

  /// [day] null = today (server date).
  Future<DailyTotals> totals(DateTime? day) async => DailyTotals.fromJson(
    await _get(day == null ? '/totals/today' : '/totals/date/${_date(day)}') as Map<String, dynamic>,
  );

  Future<List<LogEntry>> logs(DateTime? day) async =>
      _list(await _get(day == null ? '/logs/today' : '/logs/date/${_date(day)}'), LogEntry.fromJson);

  /// Logs always go to today – the server has no date parameter.
  Future<void> addLog(int foodId, double grams) => _post('/logs', {'food_item_id': foodId, 'amount_grams': grams});

  Future<void> deleteLog(int id) => _delete('/logs/$id');

  Future<WeeklyStats> weekly(int calorieGoal) async =>
      WeeklyStats.fromJson(await _get('/weekly?calorie_goal=$calorieGoal') as Map<String, dynamic>);

  Future<MonthlyStats> monthly(int year, int month) async =>
      MonthlyStats.fromJson(await _get('/monthly?year=$year&month=$month') as Map<String, dynamic>);

  // ── Foods ──────────────────────────────────────────────────────────────

  Future<List<Food>> foods([String search = '']) async =>
      _list(await _get(search.isEmpty ? '/foods' : '/foods?search=${Uri.encodeQueryComponent(search)}'), Food.fromJson);

  Future<Food> createFood(Map<String, dynamic> data) async =>
      Food.fromJson(await _post('/foods', data) as Map<String, dynamic>);

  Future<Food> updateFood(int id, Map<String, dynamic> data) async =>
      Food.fromJson(await _put('/foods/$id', data) as Map<String, dynamic>);

  Future<void> deleteFood(int id) => _delete('/foods/$id');

  Future<Food> toggleFamily(int id) async =>
      Food.fromJson(await _post('/foods/$id/toggle-family') as Map<String, dynamic>);

  /// Own food with that barcode, or an unsaved Open Food Facts product (id 0).
  Future<Food> barcode(String code) async => Food.fromJson(await _get('/foods/barcode/$code') as Map<String, dynamic>);

  Future<Food> saveBarcodeFood(String code, Map<String, dynamic> data) async =>
      Food.fromJson(await _post('/foods/barcode/$code/save', data) as Map<String, dynamic>);

  Future<List<RefFood>> referenceFoods(String q) async =>
      _list(await _get('/reference-foods?q=${Uri.encodeQueryComponent(q)}'), RefFood.fromJson);

  /// Copies a BLS entry into the user's foods (or reuses an earlier copy).
  Future<Food> useReference(String code) async =>
      Food.fromJson(await _post('/reference-foods/${Uri.encodeComponent(code)}/use') as Map<String, dynamic>);

  Future<List<RefFood>> onlineFoods(String q) async =>
      _list(await _get('/online-foods?q=${Uri.encodeQueryComponent(q)}'), RefFood.fromJson);

  // ── Templates ──────────────────────────────────────────────────────────

  Future<List<MealTemplate>> templates() async => _list(await _get('/templates'), MealTemplate.fromJson);

  Future<void> saveTemplate(int? id, String name, List<(int, double)> items) {
    final body = {
      'name': name,
      'items': [
        for (final (foodId, grams) in items) {'food_item_id': foodId, 'amount_grams': grams},
      ],
    };
    return id == null ? _post('/templates', body) : _put('/templates/$id', body);
  }

  Future<void> applyTemplate(int id) => _post('/templates/$id/apply');

  Future<void> deleteTemplate(int id) => _delete('/templates/$id');

  // ── Weight ─────────────────────────────────────────────────────────────

  Future<WeightHistory> weightHistory({int days = 60}) async =>
      WeightHistory.fromJson(await _get('/weight/history?days=$days') as Map<String, dynamic>);

  Future<void> logWeight(double kg) => _post('/weight', {'weight_kg': kg});

  Future<void> deleteWeight(int id) => _delete('/weight/$id');

  Future<void> updateProfile(String gender, int age, int heightCm) =>
      _put('/weight/profile', {'gender': gender, 'age': age, 'height_cm': heightCm});
}
