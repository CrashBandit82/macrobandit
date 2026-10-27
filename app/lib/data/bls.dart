import 'models.dart';

/// Search in the Bundeslebensmittelschlüssel BLS 4.0 (Max Rubner-Institut),
/// shipped as assets/bls.tsv (built by tool/bls_to_tsv.py). Basic foods like
/// "Rind, Filet, roh" or "Vollmilch 3,5 % Fett".
class Bls {
  Bls(String tsv) {
    for (final line in tsv.split('\n')) {
      final f = line.split('\t');
      if (f.length < 7) continue;
      final food = RefFood(
        code: f[0],
        name: f[1],
        kcal: double.tryParse(f[2]),
        protein: double.tryParse(f[3]),
        carbs: double.tryParse(f[4]),
        fat: double.tryParse(f[5]),
        fiber: double.tryParse(f[6]),
        source: source,
      );
      _entries.add((food, _norm(food.name), _words(food.name)));
      _byCode[food.code] = food;
    }
  }

  static const source = 'BLS 4.0';

  final _entries = <(RefFood, String, List<String>)>[];
  final _byCode = <String, RefFood>{};

  int get length => _entries.length;

  RefFood? byCode(String code) => _byCode[code];

  List<RefFood> search(String q, {int limit = 15}) {
    final tokens = _words(q);
    if (tokens.isEmpty) return const [];
    final hits = <(bool, double, int, RefFood)>[];
    for (final (food, name, words) in _entries) {
      final scores = [for (final t in tokens) _score(t, name, words)];
      final matched = scores.where((s) => s > 0).length;
      if (matched == 0) continue;
      hits.add((matched == tokens.length, scores.fold(0.0, (a, b) => a + b), -name.length, food));
    }
    // all search words matched first, then total score, then short (general) names
    hits.sort((a, b) {
      if (a.$1 != b.$1) return a.$1 ? -1 : 1;
      final s = b.$2.compareTo(a.$2);
      return s != 0 ? s : b.$3.compareTo(a.$3);
    });
    final all = hits.any((h) => h.$1);
    return [
      for (final h in hits)
        if (!all || h.$1) h.$4,
    ].take(limit).toList();
  }
}

String _norm(String text) {
  // "ä" and "ae" match each other (keyboards without umlauts)
  var t = text.toLowerCase().replaceAll('ß', 'ss').replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue');
  t = t.replaceAllMapped(RegExp(r'(\d)\.(\d)'), (m) => '${m[1]},${m[2]}'); // 3.5 -> 3,5 (BLS uses a decimal comma)
  t = t.replaceAll(RegExp(r'[^\wÀ-ɏ,%]+'), ' '); // \w is ASCII-only in Dart: keep accented letters
  t = t.replaceAll(RegExp(r'(?<!\d),|,(?!\d)'), ' '); // keep commas only between digits
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> _words(String text) => _norm(text).replaceAll('%', ' ').split(' ').where((w) => w.isNotEmpty).toList();

/// How well a search word fits a food name, 0 = not at all. Without a hit the
/// singular is tried ("eier" -> "ei", "kartoffeln" -> "kartoffel") for fewer points.
double _score(String token, String name, List<String> words) {
  final exact = _scoreExact(token, name, words);
  if (exact > 0 || RegExp(r'^\d+$').hasMatch(token)) return exact;
  for (final ending in const ['ern', 'en', 'er', 'n', 'e', 's']) {
    if (token.endsWith(ending) && token.length - ending.length >= 2) {
      final s = _scoreExact(token.substring(0, token.length - ending.length), name, words);
      if (s > 0) return s * 0.8;
    }
  }
  return 0;
}

double _scoreExact(String token, String name, List<String> words) {
  if (words.contains(token)) return 3;
  if (words.any((w) => w.startsWith(token))) return 2.5;
  if (name.contains(token)) return 1.5; // "milch" in "vollmilch"
  // compound search word: "rinderfilet" covers "rind" + "filet"
  final parts = words.where((w) => w.length >= 4 && token.contains(w));
  if (parts.isNotEmpty) {
    final covered = parts.fold(0, (a, w) => a + w.length) / token.length;
    return 1 + (covered < 1 ? covered : 1);
  }
  return 0;
}
