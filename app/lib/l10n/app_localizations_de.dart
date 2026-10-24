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
  String get errorOffline => 'Keine Verbindung zu macrobandit.at';

  @override
  String get errorTooMany => 'Zu viele Versuche – bitte kurz warten';

  @override
  String get sessionExpired => 'Sitzung abgelaufen – bitte neu anmelden';

  @override
  String get authSubtitle => 'Dein persönlicher Makro-Tracker';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get passwordLabel => 'Passwort';

  @override
  String get usernameLabel => 'Benutzername';

  @override
  String get passwordRulesHint =>
      'Mind. 8 Zeichen, Groß- und Kleinbuchstabe und eine Zahl';

  @override
  String get loginButton => 'Anmelden';

  @override
  String get registerButton => 'Konto erstellen';

  @override
  String get loginTab => 'Anmelden';

  @override
  String get registerTab => 'Registrieren';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get forgotTitle => 'Passwort vergessen';

  @override
  String get forgotSubtitle =>
      'Wir schicken dir einen Link zum Zurücksetzen. Das neue Passwort setzt du auf macrobandit.at.';

  @override
  String get sendResetLink => 'Link senden';

  @override
  String get resetLinkSent =>
      'Falls die E-Mail existiert, wurde ein Link gesendet.';

  @override
  String get registeredTitle => 'Fast geschafft!';

  @override
  String registeredText(String email) {
    return 'Wir haben eine Bestätigungs-E-Mail an $email gesendet. Klicke auf „E-Mail bestätigen“ und melde dich danach hier an.';
  }

  @override
  String get registeredSpam =>
      'Keine E-Mail erhalten? Prüfe deinen Spam-Ordner.';

  @override
  String get toLogin => 'Zur Anmeldung';

  @override
  String get authFooter => 'macrobandit.at · Deine Daten bleiben bei dir';

  @override
  String greeting(String name) {
    return 'Hallo, $name!';
  }

  @override
  String get tabNutrition => 'Ernährung';

  @override
  String get tabWeight => 'Gewicht';

  @override
  String get tabAccount => 'Konto';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge',
      one: '1 Eintrag',
    );
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
  String get emailNotVerified => 'E-Mail nicht bestätigt';

  @override
  String get emailNotVerifiedSub => 'Bitte bestätige deine E-Mail-Adresse.';

  @override
  String get resend => 'Erneut senden';

  @override
  String get verificationSent => 'Bestätigungs-E-Mail gesendet';

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
  String get blsSource =>
      'Quelle: Bundeslebensmittelschlüssel 4.0, Max Rubner-Institut';

  @override
  String get familyTag => 'Familie';

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
  String get portionWeight => 'Gewicht der Portion (g)';

  @override
  String get kcalPortion => 'Kalorien (kcal)';

  @override
  String get customHint =>
      'Werte für die ganze Portion. Die Mahlzeit wird als eigenes Lebensmittel gespeichert.';

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
  String get foodDbInfo =>
      'Nur deine eigenen Einträge – globale Lebensmittel können nicht bearbeitet werden.';

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
  String get shareFamily => 'Mit Familie teilen';

  @override
  String get unshareFamily => 'Nicht mehr teilen';

  @override
  String sharedWithFamily(String name) {
    return '$name wird mit der Familie geteilt';
  }

  @override
  String notSharedWithFamily(String name) {
    return '$name wird nicht mehr geteilt';
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
  String get templateAmountError =>
      'Bitte bei jedem Lebensmittel eine Menge über 0 g eingeben';

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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
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
  String weightFromTracker(String kg) {
    return 'Gewicht (aus Tracker): $kg';
  }

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
  String get changeUsername => 'Benutzername ändern';

  @override
  String get newUsername => 'Neuer Benutzername';

  @override
  String get usernameChanged => 'Benutzername geändert';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmPassword => 'Neues Passwort wiederholen';

  @override
  String get passwordMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get passwordChanged => 'Passwort geändert';

  @override
  String get exportTitle => 'Daten exportieren';

  @override
  String get exportSub => 'Alle deine Daten als CSV speichern';

  @override
  String get exportSaved => 'Export gespeichert';

  @override
  String get feedbackTitle => 'Feedback an CrashBandit';

  @override
  String get feedbackSub => 'Lob, Wünsche oder Fehler melden';

  @override
  String get feedbackHint =>
      'Was gefällt dir? Was könnte besser sein? Fehler gefunden?';

  @override
  String get feedbackMin => 'Mindestens 5 Zeichen';

  @override
  String get feedbackThanks => 'Danke für dein Feedback!';

  @override
  String get send => 'Senden';

  @override
  String get logout => 'Abmelden';

  @override
  String get logoutSub => 'Von diesem Gerät abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountSub => 'Alle Daten unwiderruflich löschen';

  @override
  String get deleteWarning =>
      'Diese Aktion ist unwiderruflich. Alle deine Einträge, Lebensmittel und Gewichte werden gelöscht.';

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
}
