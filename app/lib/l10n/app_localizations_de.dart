// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'MacroBandit';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get close => 'Schließen';

  @override
  String get back => 'Zurück';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get errorGeneric => 'Etwas ist schiefgelaufen';

  @override
  String get errorOffline => 'Keine Internetverbindung';

  @override
  String greeting(String name) {
    return 'Hallo, $name!';
  }

  @override
  String get tabNutrition => 'Ernährung';

  @override
  String get tabWeight => 'Gewicht';

  @override
  String get tabAccount => 'Profil';

  @override
  String todayDate(String date) {
    return 'Heute, $date';
  }

  @override
  String yesterdayDate(String date) {
    return 'Gestern, $date';
  }

  @override
  String get today => 'Heute';

  @override
  String get previousDay => 'Vorheriger Tag';

  @override
  String get nextDay => 'Nächster Tag';

  @override
  String get calorieOverview => 'Kalorienübersicht';

  @override
  String ofGoalKcal(int goal) {
    return '/ $goal kcal';
  }

  @override
  String get remaining => 'übrig';

  @override
  String get over => 'drüber';

  @override
  String progressOfGoal(int pct) {
    return '$pct % des Tagesziels';
  }

  @override
  String get adjustGoals => 'Ziele anpassen';

  @override
  String get macroProtein => 'Eiweiß';

  @override
  String get macroCarbs => 'Kohlenhydrate';

  @override
  String get macroFat => 'Fett';

  @override
  String get macroFiber => 'Ballaststoffe';

  @override
  String get tabWeek => 'Woche';

  @override
  String get tabMonth => 'Monat';

  @override
  String get foodDatabase => 'Lebensmittel';

  @override
  String get scanBarcode => 'Barcode scannen';

  @override
  String get todayConsumed => 'Heute verzehrt';

  @override
  String get meals => 'Mahlzeiten';

  @override
  String get noEntries => 'Noch keine Einträge.';

  @override
  String entryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Einträge', one: '1 Eintrag');
    return '$_temp0';
  }

  @override
  String get addMeal => 'Mahlzeit eintragen';

  @override
  String deleteLogConfirm(String name) {
    return 'Eintrag „$name“ löschen?';
  }

  @override
  String itemAdded(String name) {
    return '$name hinzugefügt';
  }

  @override
  String itemUpdated(String name) {
    return '$name aktualisiert';
  }

  @override
  String itemDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String get editAmountTitle => 'Menge ändern';

  @override
  String currentAmount(String grams, int kcal) {
    return 'Aktuell: $grams g · $kcal kcal';
  }

  @override
  String get productNotFound => 'Produkt nicht gefunden. Bitte frei eintragen.';

  @override
  String get goalsTitle => 'Deine Ziele';

  @override
  String get calorieGoalLabel => 'Kalorienziel (kcal)';

  @override
  String gramsLabel(String name) {
    return '$name (g)';
  }

  @override
  String get goalsSaved => 'Ziele gespeichert';

  @override
  String get tabSearch => 'Suchen';

  @override
  String get tabCustom => 'Frei eintragen';

  @override
  String get tabTemplates => 'Vorlagen';

  @override
  String get searchLabel => 'Lebensmittel, gern mit Menge';

  @override
  String get searchHint => 'z. B. 200g Milch 3,5 oder Rinderfilet';

  @override
  String quickAmount(String grams, String term) {
    return 'Menge erkannt: $grams g · gesucht wird „$term“';
  }

  @override
  String onlineSearch(String term) {
    return 'Online suchen: „$term“';
  }

  @override
  String get onlineSearching => 'Suche online …';

  @override
  String get onlineSection => 'Online (Open Food Facts)';

  @override
  String get onlineNone => 'Online nichts gefunden';

  @override
  String get onlineError => 'Online-Suche gerade nicht erreichbar';

  @override
  String get onlineHide => 'Ausblenden';

  @override
  String get myFoodsSection => 'Meine Lebensmittel';

  @override
  String get blsSection => 'Grundlebensmittel (BLS)';

  @override
  String get blsSource => 'Quelle: Bundeslebensmittelschlüssel 4.0, Max Rubner-Institut';

  @override
  String get noResults => 'Kein Treffer – versuch den freien Eintrag';

  @override
  String get sourceScanned => 'gescannt';

  @override
  String kcalPer100(int kcal) {
    return '$kcal kcal / 100 g';
  }

  @override
  String get amountGrams => 'Menge in Gramm';

  @override
  String get addButton => 'Eintragen';

  @override
  String get shortCarbs => 'KH';

  @override
  String get mealName => 'Name der Mahlzeit';

  @override
  String get portionWeight => 'Portion (g)';

  @override
  String get kcalPortion => 'Kalorien (kcal)';

  @override
  String get customHint => 'Werte für die ganze Portion. Die Mahlzeit wird als eigenes Lebensmittel gespeichert.';

  @override
  String get saveAndLog => 'Speichern & eintragen';

  @override
  String get mealLogged => 'Mahlzeit eingetragen';

  @override
  String get requiredField => 'Pflichtfeld';

  @override
  String get invalidNumber => 'Bitte eine Zahl über 0 eingeben';

  @override
  String get foodDbTitle => 'Meine Lebensmittel';

  @override
  String get foodDbInfo => 'Deine gespeicherten Lebensmittel – auch übernommene BLS- und Open-Food-Facts-Einträge.';

  @override
  String get noOwnFoods => 'Noch keine eigenen Lebensmittel.';

  @override
  String get editFoodTitle => 'Lebensmittel bearbeiten';

  @override
  String get nameLabel => 'Name';

  @override
  String get brandOptional => 'Marke (optional)';

  @override
  String get kcalPer100Label => 'kcal / 100 g';

  @override
  String per100Label(String name) {
    return '$name / 100 g';
  }

  @override
  String get portionLabel => 'Portion (Bezeichnung)';

  @override
  String get portionLabelHint => 'z. B. 1 Stück';

  @override
  String get portionGrams => 'Portion (g)';

  @override
  String deleteFoodConfirm(String name) {
    return '„$name“ aus deiner Datenbank löschen?';
  }

  @override
  String foodSaved(String name) {
    return '$name gespeichert';
  }

  @override
  String get templatesEmpty => 'Noch keine Vorlagen. Erstelle deine erste!';

  @override
  String templateKcal(int kcal) {
    return '$kcal kcal gesamt';
  }

  @override
  String get templateNew => 'Neue Vorlage';

  @override
  String get templateEdit => 'Vorlage bearbeiten';

  @override
  String get templateName => 'Name (z. B. Frühstück Standard)';

  @override
  String get templateAddFood => 'Lebensmittel hinzufügen …';

  @override
  String get templateNotFound => 'Nicht gefunden';

  @override
  String templateDeleteConfirm(String name) {
    return 'Vorlage „$name“ löschen?';
  }

  @override
  String get templateSaved => 'Vorlage gespeichert';

  @override
  String templateApplied(String name) {
    return '„$name“ eingetragen';
  }

  @override
  String get templateAmountError => 'Bitte bei jedem Lebensmittel eine Menge über 0 g eingeben';

  @override
  String get templateNeedsItems => 'Name und mindestens ein Lebensmittel nötig';

  @override
  String get weekTitle => 'Diese Woche';

  @override
  String weekAvg(String avg) {
    return 'Ø $avg kcal/Tag';
  }

  @override
  String get weekGoalReached => 'Ziel erreicht';

  @override
  String get weekOver => 'Über Ziel';

  @override
  String get monthNoData => 'Keine Daten für diesen Monat';

  @override
  String get monthDaysTracked => 'Tage getrackt';

  @override
  String get monthGoalDays => 'Ziel erreicht';

  @override
  String monthDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count Tage', one: '1 Tag');
    return '$_temp0';
  }

  @override
  String get monthAvgKcal => 'Ø Kalorien/Tag';

  @override
  String get monthAvgProtein => 'Ø Eiweiß/Tag';

  @override
  String get monthAvgCarbs => 'Ø Kohlenhydrate/Tag';

  @override
  String get monthAvgFat => 'Ø Fett/Tag';

  @override
  String get monthBest => 'Bester Tag';

  @override
  String get monthLowest => 'Niedrigster Tag';

  @override
  String get monthDaily => 'Tagesverlauf';

  @override
  String get monthGoalNotReached => 'Ziel nicht erreicht';

  @override
  String get weightToday => 'Gewicht heute';

  @override
  String get weightKg => 'Gewicht (kg)';

  @override
  String get weightCurrent => 'Aktuell';

  @override
  String get weightStart => 'Start';

  @override
  String get weightTrend => '7 Tage';

  @override
  String get weightSaved => 'Gewicht gespeichert';

  @override
  String get weightChartTitle => 'Verlauf (60 Tage)';

  @override
  String get weightChartMin => 'Mindestens 2 Einträge für den Verlauf';

  @override
  String get weightEntries => 'Einträge';

  @override
  String weightDeleteConfirm(String date) {
    return 'Eintrag vom $date löschen?';
  }

  @override
  String get tdeeTitle => 'TDEE-Rechner';

  @override
  String get tdeeFormula => 'Mifflin-St-Jeor-Formel';

  @override
  String get male => 'Mann';

  @override
  String get female => 'Frau';

  @override
  String get ageLabel => 'Alter (Jahre)';

  @override
  String get heightLabel => 'Größe (cm)';

  @override
  String get activityLabel => 'Aktivitätslevel';

  @override
  String get activitySedentary => 'Kaum Bewegung (Bürojob)';

  @override
  String get activityLight => 'Leicht aktiv (1–3× Sport/Woche)';

  @override
  String get activityModerate => 'Moderat aktiv (3–5× Sport/Woche)';

  @override
  String get activityActive => 'Sehr aktiv (6–7× Sport/Woche)';

  @override
  String get activityVeryActive => 'Extrem aktiv (2× täglich)';

  @override
  String get goalLabel => 'Ziel';

  @override
  String get goalLose => 'Abnehmen';

  @override
  String get goalMaintain => 'Halten';

  @override
  String get goalGain => 'Zunehmen';

  @override
  String get calcButton => 'TDEE berechnen';

  @override
  String get tdeeResult => 'Dein täglicher Kalorienbedarf';

  @override
  String get tdeeUnit => 'kcal / Tag';

  @override
  String applyGoal(int kcal) {
    return 'Als Kalorienziel übernehmen ($kcal kcal)';
  }

  @override
  String get fillAllFields => 'Bitte Alter, Größe und Gewicht eintragen';

  @override
  String goalSet(int kcal) {
    return 'Kalorienziel auf $kcal kcal gesetzt';
  }

  @override
  String get changeAvatar => 'Profilbild ändern';

  @override
  String get removeAvatar => 'Profilbild entfernen';

  @override
  String get avatarUpdated => 'Profilbild aktualisiert';

  @override
  String get avatarTooBig => 'Bild zu groß (max. 5 MB)';

  @override
  String get changeUsername => 'Name ändern';

  @override
  String get newUsername => 'Dein Name';

  @override
  String get usernameChanged => 'Name gespeichert';

  @override
  String get exportTitle => 'Daten exportieren';

  @override
  String get exportSub => 'Tagebuch und Gewicht als CSV speichern';

  @override
  String get exportSaved => 'Export gespeichert';

  @override
  String get deleteWarning =>
      'Diese Aktion ist unwiderruflich. Alle Einträge, Lebensmittel, Vorlagen und Gewichte auf diesem Gerät werden gelöscht. Speichere vorher eine Sicherung, wenn du sie behalten willst.';

  @override
  String get deleteConfirmWord => 'LÖSCHEN';

  @override
  String deleteConfirmLabel(String word) {
    return 'Zur Bestätigung $word eingeben';
  }

  @override
  String get deleteFinal => 'Endgültig löschen';

  @override
  String get themeTitle => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get greetingNoName => 'Hallo!';

  @override
  String get profileTitle => 'Mein Profil';

  @override
  String get localDataInfo => 'Alle Daten bleiben auf diesem Gerät';

  @override
  String get backupTitle => 'Sicherung speichern';

  @override
  String get backupSub => 'Alle Daten als Datei sichern';

  @override
  String get backupSaved => 'Sicherung gespeichert';

  @override
  String get restoreTitle => 'Sicherung wiederherstellen';

  @override
  String get restoreSub => 'Daten aus einer Sicherungsdatei laden';

  @override
  String restoreConfirm(String date) {
    return 'Alle Daten auf diesem Gerät durch die Sicherung$date ersetzen?';
  }

  @override
  String get restoreAction => 'Ersetzen';

  @override
  String get restoreDone => 'Sicherung wiederhergestellt';

  @override
  String get backupInvalid => 'Die Datei ist keine MacroBandit-Sicherung.';

  @override
  String get backupTooNew => 'Die Sicherung stammt aus einer neueren App-Version. Bitte aktualisiere die App.';

  @override
  String get deleteAllData => 'Alle Daten löschen';

  @override
  String get deleteAllDataSub => 'Tagebuch, Lebensmittel, Vorlagen und Gewicht löschen';

  @override
  String get allDataDeleted => 'Alle Daten gelöscht';

  @override
  String get dataSources =>
      'Nährwerte: Bundeslebensmittelschlüssel 4.0 (Max Rubner-Institut) und Open Food Facts (ODbL)';

  @override
  String backupFrom(String date) {
    return 'vom $date';
  }
}
