import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/api.dart';
import 'data/session.dart';
import 'l10n/app_localizations.dart';
import 'ui/auth_screen.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(Api())..restore();
  runApp(SessionScope(session: session, child: const MacroBanditApp()));
}

class MacroBanditApp extends StatelessWidget {
  const MacroBanditApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return MaterialApp(
      onGenerateTitle: (c) => c.t.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: session.themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // status/navigation bar icons follow the theme on screens without an app bar
      builder: (context, child) {
        final p = context.c;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: p.navBar,
          ),
          child: child!,
        );
      },
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    switch (session.state) {
      case SessionState.starting:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionState.offline:
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: LoadState(error: ApiException(0, null), onRetry: session.restore),
            ),
          ),
        );
      case SessionState.signedOut:
        return const AuthScreen();
      case SessionState.signedIn:
        // new key per user so no state of a previous account survives
        return HomeScreen(key: ValueKey(session.user.id));
    }
  }
}
