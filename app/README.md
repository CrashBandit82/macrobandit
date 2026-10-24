# MacroBandit – Android app

Native Flutter app for [macrobandit.at](https://macrobandit.at). It talks to the
FastAPI backend in `../backend` (`https://macrobandit.at/api`); no Google
services, no tracking.

## Build

Flutter 3.47 (stable), JDK 17, Android SDK 36.

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

Without `android/key.properties` (or the `MACROBANDIT_*` environment
variables, see `android/app/build.gradle.kts`) the release APK is unsigned,
as F-Droid expects.

## Layout

- `lib/data` – API client (token refresh), models, session
- `lib/core` – quick entry parser, calorie color scale, TDEE
- `lib/ui` – screens; colors and type scale in `ui/theme.dart`
- `lib/l10n` – German (template) and English strings
- `fastlane/` – store texts and changelogs
