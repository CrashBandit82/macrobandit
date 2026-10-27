import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'api.dart';
import 'db.dart';
import 'models.dart';

/// Local profile and the data access; the app rebuilds on changes.
class Session extends ChangeNotifier {
  Api? _api;
  User? _user;

  /// Set when the database could not be opened.
  Object? error;

  bool get ready => _user != null;
  Api get api => _api!;
  User get user => _user!;

  /// Light/dark choice of this device.
  ThemeMode themeMode = ThemeMode.system;
  static const _prefs = FlutterSecureStorage();

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _prefs.write(key: 'theme_mode', value: mode.name);
  }

  Future<void> start() async {
    try {
      final mode = await _prefs.read(key: 'theme_mode');
      themeMode = ThemeMode.values.firstWhere((m) => m.name == mode, orElse: () => ThemeMode.system);
    } on Object {
      // keep the system theme
    }
    try {
      final dir = await getApplicationSupportDirectory();
      _api = Api(await openAppDatabase(), filesDir: dir.path, loadBls: () => rootBundle.loadString('assets/bls.tsv'));
      _user = await _api!.me();
    } on Object catch (e) {
      error = e;
    }
    notifyListeners();
  }

  /// Bumped when all data was replaced (backup restored, everything deleted),
  /// so the screens drop their loaded state.
  int dataRevision = 0;

  Future<void> dataReplaced() async {
    dataRevision++;
    await reloadUser();
  }

  void updateUser(User u) {
    _user = u;
    notifyListeners();
  }

  Future<void> reloadUser() async => updateUser(await api.me());
}

class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child}) : super(notifier: session);

  static Session of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;

  /// Without rebuild dependency (for callbacks).
  static Session read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<SessionScope>()!.widget as SessionScope).notifier!;
}
