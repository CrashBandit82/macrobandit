<p align="right"><b>English</b> · <a href="README.de.md">Deutsch</a></p>

<p align="center"><img src="logo.png" width="96" alt="MacroBandit"></p>

<h1 align="center">MacroBandit</h1>

<p align="center">
  Free, ad-free macro &amp; calorie tracker for Android.<br>
  Works offline, no account, all data stays on your phone.
</p>

<p align="center">
  <img src="app/fastlane/metadata/android/de-DE/images/phoneScreenshots/1.png" width="200" alt="Today">
  <img src="app/fastlane/metadata/android/de-DE/images/phoneScreenshots/4.png" width="200" alt="Search">
  <img src="app/fastlane/metadata/android/de-DE/images/phoneScreenshots/3.png" width="200" alt="Month">
  <img src="app/fastlane/metadata/android/de-DE/images/phoneScreenshots/6.png" width="200" alt="Weight">
</p>

---

## Features

- **No account, no server** – everything is stored on the device (SQLite)
- **Quick entry** like `200g milk 3.5` – amount detected, calories and macros calculated instantly
- **7,140 basic foods offline** from the German food database BLS 4.0 (Max Rubner-Institut)
- **Barcode scanner** (zxing, no Google services) and online search – product data from Open Food Facts; the only network access, on request only
- **Own foods & meal templates** – save favourites and whole meals, apply them with one tap
- **Weekly & monthly statistics** – totals, averages, goal achievement
- **Weight tracker** with history and 7-day trend
- **TDEE calculator** (Mifflin-St Jeor) – take the result as your calorie goal
- **Backup & restore** as a JSON file, CSV export
- German & English, light & dark theme

## Download

Signed APKs are on the [releases page](https://github.com/CrashBandit82/macrobandit/releases)
(`arm64-v8a` fits almost every current phone). An F-Droid release is in progress.

## Build

The app lives in [`app/`](app/) – see [app/README.md](app/README.md).

## Data sources

- Max Rubner-Institut (2025): Bundeslebensmittelschlüssel (BLS), Version 4.0 – Deutsche Nährstoffdatenbank. Karlsruhe. DOI: [10.25826/Data20251217-134202-0](https://doi.org/10.25826/Data20251217-134202-0) – free to use, also for app development.
- [Open Food Facts](https://world.openfoodfacts.org) – Open Database License (ODbL).

## License

[GNU AGPL-3.0](LICENSE) – © CrashBandit82
