import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:macrobandit/data/api.dart';
import 'package:macrobandit/data/db.dart';
import 'package:macrobandit/data/models.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Api api;
  late Directory dir;
  final requests = <Uri>[];

  Api newApi() => Api(
    prepare(sqlite3.openInMemory()),
    filesDir: dir.path,
    loadBls: () => File('assets/bls.tsv').readAsString(),
    client: MockClient((req) async {
      requests.add(req.url);
      if (req.url.path == '/api/v2/product/4000000000001.json') {
        return http.Response(
          jsonEncode({
            'status': 1,
            'product': {
              'product_name': 'Testmüsli',
              'brands': 'Bandit, Andere',
              'nutriments': {'energy-kcal_100g': 380, 'proteins_100g': '9.5'},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('{"status": 0}', 404);
    }),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('mb');
    requests.clear();
    api = newApi();
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<Food> milk() =>
      api.createFood({'name': 'Milch', 'calories_per_100g': 64, 'protein_per_100g': 3.4, 'fat_per_100g': 3.5});

  test('profile defaults and goals', () async {
    var u = await api.me();
    expect(u.username, '');
    expect(u.goals.kcal, 2000);
    u = await api.updateGoals(const Goals(kcal: 1800, protein: 120, carbs: 200, fat: 60, fiber: 25));
    expect(u.goals.kcal, 1800);
    expect((await api.changeUsername('  Geri ')).username, 'Geri');
    expect((await api.changeUsername(' ')).username, '');
  });

  test('diary: add, totals, update, delete, use count', () async {
    final m = await milk();
    await api.addLog(m.id, 250);
    await api.addLog(m.id, 100);
    var t = await api.totals(null);
    expect(t.kcal, 224);
    expect(t.entries, 2);
    final logs = await api.logs(null);
    expect(logs.first.kcal, 160);
    await api.updateLogAmount(logs.first.id, 50);
    t = await api.totals(null);
    expect(t.kcal, 96);
    await api.deleteLog(logs.last.id);
    expect((await api.totals(null)).kcal, 32);
    expect((await api.foods()).single.useCount, 2);
  });

  test('deleting a food keeps diary entries', () async {
    final m = await milk();
    await api.addLog(m.id, 100);
    await api.deleteFood(m.id);
    final log = (await api.logs(null)).single;
    expect(log.foodId, isNull);
    expect(log.foodName, 'Milch');
  });

  test('weekly and monthly stats', () async {
    final m = await milk();
    await api.addLog(m.id, 1000);
    final w = await api.weekly(2000);
    expect(w.days, hasLength(7));
    expect(w.days.first.date.weekday, DateTime.monday);
    expect(w.total, 640);
    expect(w.avg, 640);
    final now = DateTime.now();
    final mo = await api.monthly(now.year, now.month);
    expect(mo.daysTracked, 1);
    expect(mo.avgKcal, 640);
    expect(mo.goalDays, 0);
    expect(mo.best!.kcal, 640);
    expect(mo.daily.single.label, '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.');
  });

  test('templates: save, list, apply as one entry, edit', () async {
    final m = await milk();
    final oats = await api.createFood({'name': 'Hafer', 'calories_per_100g': 370});
    await api.saveTemplate(null, 'Frühstück', [(m.id, 200), (oats.id, 50)]);
    var list = await api.templates();
    expect(list.single.totalKcal, 313);
    await api.applyTemplate(list.single.id);
    final log = (await api.logs(null)).single;
    expect(log.foodName, '📋 Frühstück');
    expect(log.kcal, 313);
    expect(log.grams, 250);
    await api.saveTemplate(list.single.id, 'Klein', [(oats.id, 100)]);
    list = await api.templates();
    expect(list.single.name, 'Klein');
    expect(list.single.items.single.kcal, 370);
    await api.deleteTemplate(list.single.id);
    expect(await api.templates(), isEmpty);
  });

  test('weight: one value per day, history', () async {
    await api.logWeight(80.5);
    await api.logWeight(80.1);
    final h = await api.weightHistory();
    expect(h.entries.single.kg, 80.1);
    expect(h.latest, 80.1);
    expect(h.trend, isNull);
  });

  test('BLS search and copy into own foods', () async {
    final hits = await api.referenceFoods('vollmilch 3,5');
    expect(hits, isNotEmpty);
    expect(hits.first.name, contains('Vollmilch'));
    final copy = await api.useReference(hits.first.code);
    expect(copy.brand, 'BLS 4.0');
    expect((await api.useReference(hits.first.code)).id, copy.id);
    expect(await api.referenceFoods('kartoffeln'), isNotEmpty);
    expect((await api.referenceFoods('haehnchen brust')).first.name, startsWith('Hähnchen'));
  });

  test('barcode: Open Food Facts, then own saved food', () async {
    final off = await api.barcode('4000000000001');
    expect(off.id, 0);
    expect(off.name, 'Testmüsli');
    expect(off.brand, 'Bandit');
    expect(off.protein, 9.5);
    final saved = await api.saveBarcodeFood('4000000000001', off.toCreateJson());
    requests.clear();
    expect((await api.barcode('4000000000001')).id, saved.id);
    expect(requests, isEmpty);
    expect(() => api.barcode('4000000000002'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)));
    expect(() => api.barcode('abc'), throwsA(isA<ApiException>()));
  });

  test('backup round trip replaces all data', () async {
    final m = await milk();
    await api.addLog(m.id, 100);
    await api.saveTemplate(null, 'T', [(m.id, 50)]);
    await api.logWeight(75);
    await api.changeUsername('Geri');
    final backup = await api.exportBackup();
    expect(api.checkBackup(backup), isNotNull);

    final other = newApi();
    await other.createFood({'name': 'Wird ersetzt'});
    await other.importBackup(backup);
    expect((await other.foods()).single.name, 'Milch');
    expect((await other.logs(null)).single.kcal, 64);
    expect((await other.templates()).single.items.single.grams, 50);
    expect((await other.weightHistory()).latest, 75);
    expect((await other.me()).username, 'Geri');

    expect(() => other.checkBackup(utf8.encode('{"format": "x"}')), throwsA(isA<ApiException>()));
    expect(() => other.importBackup(utf8.encode('kaputt')), throwsA(isA<ApiException>()));
    expect((await other.foods()).single.name, 'Milch');
  });

  test('CSV export and delete all', () async {
    final m = await api.createFood({'name': '=Formel, "x"'});
    await api.addLog(m.id, 10);
    final csv = utf8.decode(await api.exportCsv());
    expect(csv, contains('"\'=Formel, ""x"""'));
    await api.deleteAllData();
    expect(await api.foods(), isEmpty);
    expect((await api.me()).goals.kcal, 2000);
  });
}
