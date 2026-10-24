import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api.dart';
import 'models.dart';

enum SessionState { starting, offline, signedOut, signedIn }

/// Signed-in user and the API client; the app rebuilds on changes.
class Session extends ChangeNotifier {
  Session(this.api) {
    api.onSessionExpired = () {
      if (state == SessionState.signedIn) expired = true;
      _set(SessionState.signedOut, null);
    };
  }

  final Api api;
  SessionState state = SessionState.starting;
  User? _user;

  /// true when the last sign-out came from an expired refresh token.
  bool expired = false;

  User get user => _user!;

  /// Light/dark choice of this device (not synced with the web app).
  ThemeMode themeMode = ThemeMode.system;
  static const _prefs = FlutterSecureStorage();

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _prefs.write(key: 'theme_mode', value: mode.name);
  }

  void _set(SessionState s, User? u) {
    state = s;
    _user = u;
    notifyListeners();
  }

  Future<void> restore() async {
    _set(SessionState.starting, null);
    final mode = await _prefs.read(key: 'theme_mode');
    themeMode = ThemeMode.values.firstWhere((m) => m.name == mode, orElse: () => ThemeMode.system);
    await api.loadTokens();
    if (!api.hasTokens) return _set(SessionState.signedOut, null);
    try {
      _set(SessionState.signedIn, await api.me());
    } on ApiException catch (e) {
      // 401 already signed out via onSessionExpired
      if (e.status != 401) _set(e.offline ? SessionState.offline : SessionState.signedOut, null);
    }
  }

  Future<void> login(String email, String password) async {
    await api.login(email.trim(), password);
    expired = false;
    _set(SessionState.signedIn, await api.me());
  }

  Future<void> logout() async {
    await api.clearTokens();
    _set(SessionState.signedOut, null);
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
