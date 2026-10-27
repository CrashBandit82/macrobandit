import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Schema of the local database. Bump [schemaVersion] and add a step to
/// [_migrate] for every change.
const schemaVersion = 1;

const _schemaV1 = [
  '''CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )''',
  '''CREATE TABLE foods (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    brand TEXT,
    kcal REAL,
    protein REAL,
    carbs REAL,
    fat REAL,
    fiber REAL,
    portion_label TEXT,
    portion_size REAL,
    barcode TEXT,
    use_count INTEGER NOT NULL DEFAULT 0
  )''',
  'CREATE INDEX foods_barcode ON foods (barcode)',
  '''CREATE TABLE logs (
    id INTEGER PRIMARY KEY,
    day TEXT NOT NULL,
    food_id INTEGER REFERENCES foods (id) ON DELETE SET NULL,
    food_name TEXT NOT NULL,
    grams REAL NOT NULL,
    kcal REAL NOT NULL,
    protein REAL NOT NULL,
    carbs REAL NOT NULL,
    fat REAL NOT NULL,
    fiber REAL NOT NULL
  )''',
  'CREATE INDEX logs_day ON logs (day)',
  '''CREATE TABLE templates (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL
  )''',
  '''CREATE TABLE template_items (
    id INTEGER PRIMARY KEY,
    template_id INTEGER NOT NULL REFERENCES templates (id) ON DELETE CASCADE,
    food_id INTEGER NOT NULL REFERENCES foods (id) ON DELETE CASCADE,
    grams REAL NOT NULL
  )''',
  '''CREATE TABLE weights (
    id INTEGER PRIMARY KEY,
    day TEXT NOT NULL UNIQUE,
    kg REAL NOT NULL
  )''',
];

/// Opens (and creates or migrates) the app database in the app's private
/// directory.
Future<Database> openAppDatabase() async {
  final dir = await getApplicationSupportDirectory();
  return prepare(sqlite3.open('${dir.path}/macrobandit.db'));
}

/// Enables foreign keys and brings the schema to [schemaVersion].
Database prepare(Database db) {
  db.execute('PRAGMA foreign_keys = ON');
  _migrate(db);
  return db;
}

void _migrate(Database db) {
  final from = db.userVersion;
  if (from == schemaVersion) return;
  db.execute('BEGIN');
  try {
    if (from < 1) _schemaV1.forEach(db.execute);
    db.userVersion = schemaVersion;
    db.execute('COMMIT');
  } on Object {
    db.execute('ROLLBACK');
    rethrow;
  }
}
