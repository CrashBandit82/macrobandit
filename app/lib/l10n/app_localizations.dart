import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('de'), Locale('en')];

  /// No description provided for @appName.
  ///
  /// In de, this message translates to:
  /// **'MacroBandit'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get close;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @retry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Etwas ist schiefgelaufen'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In de, this message translates to:
  /// **'Keine Internetverbindung'**
  String get errorOffline;

  /// No description provided for @greeting.
  ///
  /// In de, this message translates to:
  /// **'Hallo, {name}!'**
  String greeting(String name);

  /// No description provided for @tabNutrition.
  ///
  /// In de, this message translates to:
  /// **'Ernährung'**
  String get tabNutrition;

  /// No description provided for @tabWeight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get tabWeight;

  /// No description provided for @tabAccount.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get tabAccount;

  /// No description provided for @todayDate.
  ///
  /// In de, this message translates to:
  /// **'Heute, {date}'**
  String todayDate(String date);

  /// No description provided for @yesterdayDate.
  ///
  /// In de, this message translates to:
  /// **'Gestern, {date}'**
  String yesterdayDate(String date);

  /// No description provided for @today.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get today;

  /// No description provided for @previousDay.
  ///
  /// In de, this message translates to:
  /// **'Vorheriger Tag'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In de, this message translates to:
  /// **'Nächster Tag'**
  String get nextDay;

  /// No description provided for @calorieOverview.
  ///
  /// In de, this message translates to:
  /// **'Kalorienübersicht'**
  String get calorieOverview;

  /// No description provided for @ofGoalKcal.
  ///
  /// In de, this message translates to:
  /// **'/ {goal} kcal'**
  String ofGoalKcal(int goal);

  /// No description provided for @remaining.
  ///
  /// In de, this message translates to:
  /// **'übrig'**
  String get remaining;

  /// No description provided for @over.
  ///
  /// In de, this message translates to:
  /// **'drüber'**
  String get over;

  /// No description provided for @progressOfGoal.
  ///
  /// In de, this message translates to:
  /// **'{pct} % des Tagesziels'**
  String progressOfGoal(int pct);

  /// No description provided for @adjustGoals.
  ///
  /// In de, this message translates to:
  /// **'Ziele anpassen'**
  String get adjustGoals;

  /// No description provided for @macroProtein.
  ///
  /// In de, this message translates to:
  /// **'Eiweiß'**
  String get macroProtein;

  /// No description provided for @macroCarbs.
  ///
  /// In de, this message translates to:
  /// **'Kohlenhydrate'**
  String get macroCarbs;

  /// No description provided for @macroFat.
  ///
  /// In de, this message translates to:
  /// **'Fett'**
  String get macroFat;

  /// No description provided for @macroFiber.
  ///
  /// In de, this message translates to:
  /// **'Ballaststoffe'**
  String get macroFiber;

  /// No description provided for @tabWeek.
  ///
  /// In de, this message translates to:
  /// **'Woche'**
  String get tabWeek;

  /// No description provided for @tabMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get tabMonth;

  /// No description provided for @foodDatabase.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel'**
  String get foodDatabase;

  /// No description provided for @scanBarcode.
  ///
  /// In de, this message translates to:
  /// **'Barcode scannen'**
  String get scanBarcode;

  /// No description provided for @todayConsumed.
  ///
  /// In de, this message translates to:
  /// **'Heute verzehrt'**
  String get todayConsumed;

  /// No description provided for @meals.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeiten'**
  String get meals;

  /// No description provided for @noEntries.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Einträge.'**
  String get noEntries;

  /// No description provided for @entryCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Eintrag} other{{count} Einträge}}'**
  String entryCount(int count);

  /// No description provided for @addMeal.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit eintragen'**
  String get addMeal;

  /// No description provided for @deleteLogConfirm.
  ///
  /// In de, this message translates to:
  /// **'Eintrag „{name}“ löschen?'**
  String deleteLogConfirm(String name);

  /// No description provided for @itemAdded.
  ///
  /// In de, this message translates to:
  /// **'{name} hinzugefügt'**
  String itemAdded(String name);

  /// No description provided for @itemUpdated.
  ///
  /// In de, this message translates to:
  /// **'{name} aktualisiert'**
  String itemUpdated(String name);

  /// No description provided for @itemDeleted.
  ///
  /// In de, this message translates to:
  /// **'{name} gelöscht'**
  String itemDeleted(String name);

  /// No description provided for @editAmountTitle.
  ///
  /// In de, this message translates to:
  /// **'Menge ändern'**
  String get editAmountTitle;

  /// No description provided for @currentAmount.
  ///
  /// In de, this message translates to:
  /// **'Aktuell: {grams} g · {kcal} kcal'**
  String currentAmount(String grams, int kcal);

  /// No description provided for @productNotFound.
  ///
  /// In de, this message translates to:
  /// **'Produkt nicht gefunden. Bitte frei eintragen.'**
  String get productNotFound;

  /// No description provided for @goalsTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Ziele'**
  String get goalsTitle;

  /// No description provided for @calorieGoalLabel.
  ///
  /// In de, this message translates to:
  /// **'Kalorienziel (kcal)'**
  String get calorieGoalLabel;

  /// No description provided for @gramsLabel.
  ///
  /// In de, this message translates to:
  /// **'{name} (g)'**
  String gramsLabel(String name);

  /// No description provided for @goalsSaved.
  ///
  /// In de, this message translates to:
  /// **'Ziele gespeichert'**
  String get goalsSaved;

  /// No description provided for @tabSearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get tabSearch;

  /// No description provided for @tabCustom.
  ///
  /// In de, this message translates to:
  /// **'Frei eintragen'**
  String get tabCustom;

  /// No description provided for @tabTemplates.
  ///
  /// In de, this message translates to:
  /// **'Vorlagen'**
  String get tabTemplates;

  /// No description provided for @searchLabel.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel, gern mit Menge'**
  String get searchLabel;

  /// No description provided for @searchHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. 200g Milch 3,5 oder Rinderfilet'**
  String get searchHint;

  /// No description provided for @quickAmount.
  ///
  /// In de, this message translates to:
  /// **'Menge erkannt: {grams} g · gesucht wird „{term}“'**
  String quickAmount(String grams, String term);

  /// No description provided for @onlineSearch.
  ///
  /// In de, this message translates to:
  /// **'Online suchen: „{term}“'**
  String onlineSearch(String term);

  /// No description provided for @onlineSearching.
  ///
  /// In de, this message translates to:
  /// **'Suche online …'**
  String get onlineSearching;

  /// No description provided for @onlineSection.
  ///
  /// In de, this message translates to:
  /// **'Online (Open Food Facts)'**
  String get onlineSection;

  /// No description provided for @onlineNone.
  ///
  /// In de, this message translates to:
  /// **'Online nichts gefunden'**
  String get onlineNone;

  /// No description provided for @onlineError.
  ///
  /// In de, this message translates to:
  /// **'Online-Suche gerade nicht erreichbar'**
  String get onlineError;

  /// No description provided for @onlineHide.
  ///
  /// In de, this message translates to:
  /// **'Ausblenden'**
  String get onlineHide;

  /// No description provided for @myFoodsSection.
  ///
  /// In de, this message translates to:
  /// **'Meine Lebensmittel'**
  String get myFoodsSection;

  /// No description provided for @blsSection.
  ///
  /// In de, this message translates to:
  /// **'Grundlebensmittel (BLS)'**
  String get blsSection;

  /// No description provided for @blsSource.
  ///
  /// In de, this message translates to:
  /// **'Quelle: Bundeslebensmittelschlüssel 4.0, Max Rubner-Institut'**
  String get blsSource;

  /// No description provided for @noResults.
  ///
  /// In de, this message translates to:
  /// **'Kein Treffer – versuch den freien Eintrag'**
  String get noResults;

  /// No description provided for @sourceScanned.
  ///
  /// In de, this message translates to:
  /// **'gescannt'**
  String get sourceScanned;

  /// No description provided for @kcalPer100.
  ///
  /// In de, this message translates to:
  /// **'{kcal} kcal / 100 g'**
  String kcalPer100(int kcal);

  /// No description provided for @amountGrams.
  ///
  /// In de, this message translates to:
  /// **'Menge in Gramm'**
  String get amountGrams;

  /// No description provided for @addButton.
  ///
  /// In de, this message translates to:
  /// **'Eintragen'**
  String get addButton;

  /// No description provided for @shortCarbs.
  ///
  /// In de, this message translates to:
  /// **'KH'**
  String get shortCarbs;

  /// No description provided for @mealName.
  ///
  /// In de, this message translates to:
  /// **'Name der Mahlzeit'**
  String get mealName;

  /// No description provided for @portionWeight.
  ///
  /// In de, this message translates to:
  /// **'Portion (g)'**
  String get portionWeight;

  /// No description provided for @kcalPortion.
  ///
  /// In de, this message translates to:
  /// **'Kalorien (kcal)'**
  String get kcalPortion;

  /// No description provided for @customHint.
  ///
  /// In de, this message translates to:
  /// **'Werte für die ganze Portion. Die Mahlzeit wird als eigenes Lebensmittel gespeichert.'**
  String get customHint;

  /// No description provided for @saveAndLog.
  ///
  /// In de, this message translates to:
  /// **'Speichern & eintragen'**
  String get saveAndLog;

  /// No description provided for @mealLogged.
  ///
  /// In de, this message translates to:
  /// **'Mahlzeit eingetragen'**
  String get mealLogged;

  /// No description provided for @requiredField.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine Zahl über 0 eingeben'**
  String get invalidNumber;

  /// No description provided for @foodDbTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Lebensmittel'**
  String get foodDbTitle;

  /// No description provided for @foodDbInfo.
  ///
  /// In de, this message translates to:
  /// **'Deine gespeicherten Lebensmittel – auch übernommene BLS- und Open-Food-Facts-Einträge.'**
  String get foodDbInfo;

  /// No description provided for @noOwnFoods.
  ///
  /// In de, this message translates to:
  /// **'Noch keine eigenen Lebensmittel.'**
  String get noOwnFoods;

  /// No description provided for @editFoodTitle.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel bearbeiten'**
  String get editFoodTitle;

  /// No description provided for @nameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @brandOptional.
  ///
  /// In de, this message translates to:
  /// **'Marke (optional)'**
  String get brandOptional;

  /// No description provided for @kcalPer100Label.
  ///
  /// In de, this message translates to:
  /// **'kcal / 100 g'**
  String get kcalPer100Label;

  /// No description provided for @per100Label.
  ///
  /// In de, this message translates to:
  /// **'{name} / 100 g'**
  String per100Label(String name);

  /// No description provided for @portionLabel.
  ///
  /// In de, this message translates to:
  /// **'Portion (Bezeichnung)'**
  String get portionLabel;

  /// No description provided for @portionLabelHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. 1 Stück'**
  String get portionLabelHint;

  /// No description provided for @portionGrams.
  ///
  /// In de, this message translates to:
  /// **'Portion (g)'**
  String get portionGrams;

  /// No description provided for @deleteFoodConfirm.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ aus deiner Datenbank löschen?'**
  String deleteFoodConfirm(String name);

  /// No description provided for @foodSaved.
  ///
  /// In de, this message translates to:
  /// **'{name} gespeichert'**
  String foodSaved(String name);

  /// No description provided for @templatesEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Vorlagen. Erstelle deine erste!'**
  String get templatesEmpty;

  /// No description provided for @templateKcal.
  ///
  /// In de, this message translates to:
  /// **'{kcal} kcal gesamt'**
  String templateKcal(int kcal);

  /// No description provided for @templateNew.
  ///
  /// In de, this message translates to:
  /// **'Neue Vorlage'**
  String get templateNew;

  /// No description provided for @templateEdit.
  ///
  /// In de, this message translates to:
  /// **'Vorlage bearbeiten'**
  String get templateEdit;

  /// No description provided for @templateName.
  ///
  /// In de, this message translates to:
  /// **'Name (z. B. Frühstück Standard)'**
  String get templateName;

  /// No description provided for @templateAddFood.
  ///
  /// In de, this message translates to:
  /// **'Lebensmittel hinzufügen …'**
  String get templateAddFood;

  /// No description provided for @templateNotFound.
  ///
  /// In de, this message translates to:
  /// **'Nicht gefunden'**
  String get templateNotFound;

  /// No description provided for @templateDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Vorlage „{name}“ löschen?'**
  String templateDeleteConfirm(String name);

  /// No description provided for @templateSaved.
  ///
  /// In de, this message translates to:
  /// **'Vorlage gespeichert'**
  String get templateSaved;

  /// No description provided for @templateApplied.
  ///
  /// In de, this message translates to:
  /// **'„{name}“ eingetragen'**
  String templateApplied(String name);

  /// No description provided for @templateAmountError.
  ///
  /// In de, this message translates to:
  /// **'Bitte bei jedem Lebensmittel eine Menge über 0 g eingeben'**
  String get templateAmountError;

  /// No description provided for @templateNeedsItems.
  ///
  /// In de, this message translates to:
  /// **'Name und mindestens ein Lebensmittel nötig'**
  String get templateNeedsItems;

  /// No description provided for @weekTitle.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get weekTitle;

  /// No description provided for @weekAvg.
  ///
  /// In de, this message translates to:
  /// **'Ø {avg} kcal/Tag'**
  String weekAvg(String avg);

  /// No description provided for @weekGoalReached.
  ///
  /// In de, this message translates to:
  /// **'Ziel erreicht'**
  String get weekGoalReached;

  /// No description provided for @weekOver.
  ///
  /// In de, this message translates to:
  /// **'Über Ziel'**
  String get weekOver;

  /// No description provided for @monthNoData.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten für diesen Monat'**
  String get monthNoData;

  /// No description provided for @monthDaysTracked.
  ///
  /// In de, this message translates to:
  /// **'Tage getrackt'**
  String get monthDaysTracked;

  /// No description provided for @monthGoalDays.
  ///
  /// In de, this message translates to:
  /// **'Ziel erreicht'**
  String get monthGoalDays;

  /// No description provided for @monthDays.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Tag} other{{count} Tage}}'**
  String monthDays(int count);

  /// No description provided for @monthAvgKcal.
  ///
  /// In de, this message translates to:
  /// **'Ø Kalorien/Tag'**
  String get monthAvgKcal;

  /// No description provided for @monthAvgProtein.
  ///
  /// In de, this message translates to:
  /// **'Ø Eiweiß/Tag'**
  String get monthAvgProtein;

  /// No description provided for @monthAvgCarbs.
  ///
  /// In de, this message translates to:
  /// **'Ø Kohlenhydrate/Tag'**
  String get monthAvgCarbs;

  /// No description provided for @monthAvgFat.
  ///
  /// In de, this message translates to:
  /// **'Ø Fett/Tag'**
  String get monthAvgFat;

  /// No description provided for @monthBest.
  ///
  /// In de, this message translates to:
  /// **'Bester Tag'**
  String get monthBest;

  /// No description provided for @monthLowest.
  ///
  /// In de, this message translates to:
  /// **'Niedrigster Tag'**
  String get monthLowest;

  /// No description provided for @monthDaily.
  ///
  /// In de, this message translates to:
  /// **'Tagesverlauf'**
  String get monthDaily;

  /// No description provided for @monthGoalNotReached.
  ///
  /// In de, this message translates to:
  /// **'Ziel nicht erreicht'**
  String get monthGoalNotReached;

  /// No description provided for @weightToday.
  ///
  /// In de, this message translates to:
  /// **'Gewicht heute'**
  String get weightToday;

  /// No description provided for @weightKg.
  ///
  /// In de, this message translates to:
  /// **'Gewicht (kg)'**
  String get weightKg;

  /// No description provided for @weightCurrent.
  ///
  /// In de, this message translates to:
  /// **'Aktuell'**
  String get weightCurrent;

  /// No description provided for @weightStart.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get weightStart;

  /// No description provided for @weightTrend.
  ///
  /// In de, this message translates to:
  /// **'7 Tage'**
  String get weightTrend;

  /// No description provided for @weightSaved.
  ///
  /// In de, this message translates to:
  /// **'Gewicht gespeichert'**
  String get weightSaved;

  /// No description provided for @weightChartTitle.
  ///
  /// In de, this message translates to:
  /// **'Verlauf (60 Tage)'**
  String get weightChartTitle;

  /// No description provided for @weightChartMin.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 2 Einträge für den Verlauf'**
  String get weightChartMin;

  /// No description provided for @weightEntries.
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get weightEntries;

  /// No description provided for @weightDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'Eintrag vom {date} löschen?'**
  String weightDeleteConfirm(String date);

  /// No description provided for @tdeeTitle.
  ///
  /// In de, this message translates to:
  /// **'TDEE-Rechner'**
  String get tdeeTitle;

  /// No description provided for @tdeeFormula.
  ///
  /// In de, this message translates to:
  /// **'Mifflin-St-Jeor-Formel'**
  String get tdeeFormula;

  /// No description provided for @male.
  ///
  /// In de, this message translates to:
  /// **'Mann'**
  String get male;

  /// No description provided for @female.
  ///
  /// In de, this message translates to:
  /// **'Frau'**
  String get female;

  /// No description provided for @ageLabel.
  ///
  /// In de, this message translates to:
  /// **'Alter (Jahre)'**
  String get ageLabel;

  /// No description provided for @heightLabel.
  ///
  /// In de, this message translates to:
  /// **'Größe (cm)'**
  String get heightLabel;

  /// No description provided for @activityLabel.
  ///
  /// In de, this message translates to:
  /// **'Aktivitätslevel'**
  String get activityLabel;

  /// No description provided for @activitySedentary.
  ///
  /// In de, this message translates to:
  /// **'Kaum Bewegung (Bürojob)'**
  String get activitySedentary;

  /// No description provided for @activityLight.
  ///
  /// In de, this message translates to:
  /// **'Leicht aktiv (1–3× Sport/Woche)'**
  String get activityLight;

  /// No description provided for @activityModerate.
  ///
  /// In de, this message translates to:
  /// **'Moderat aktiv (3–5× Sport/Woche)'**
  String get activityModerate;

  /// No description provided for @activityActive.
  ///
  /// In de, this message translates to:
  /// **'Sehr aktiv (6–7× Sport/Woche)'**
  String get activityActive;

  /// No description provided for @activityVeryActive.
  ///
  /// In de, this message translates to:
  /// **'Extrem aktiv (2× täglich)'**
  String get activityVeryActive;

  /// No description provided for @goalLabel.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get goalLabel;

  /// No description provided for @goalLose.
  ///
  /// In de, this message translates to:
  /// **'Abnehmen'**
  String get goalLose;

  /// No description provided for @goalMaintain.
  ///
  /// In de, this message translates to:
  /// **'Halten'**
  String get goalMaintain;

  /// No description provided for @goalGain.
  ///
  /// In de, this message translates to:
  /// **'Zunehmen'**
  String get goalGain;

  /// No description provided for @calcButton.
  ///
  /// In de, this message translates to:
  /// **'TDEE berechnen'**
  String get calcButton;

  /// No description provided for @tdeeResult.
  ///
  /// In de, this message translates to:
  /// **'Dein täglicher Kalorienbedarf'**
  String get tdeeResult;

  /// No description provided for @tdeeUnit.
  ///
  /// In de, this message translates to:
  /// **'kcal / Tag'**
  String get tdeeUnit;

  /// No description provided for @applyGoal.
  ///
  /// In de, this message translates to:
  /// **'Als Kalorienziel übernehmen ({kcal} kcal)'**
  String applyGoal(int kcal);

  /// No description provided for @fillAllFields.
  ///
  /// In de, this message translates to:
  /// **'Bitte Alter, Größe und Gewicht eintragen'**
  String get fillAllFields;

  /// No description provided for @goalSet.
  ///
  /// In de, this message translates to:
  /// **'Kalorienziel auf {kcal} kcal gesetzt'**
  String goalSet(int kcal);

  /// No description provided for @changeAvatar.
  ///
  /// In de, this message translates to:
  /// **'Profilbild ändern'**
  String get changeAvatar;

  /// No description provided for @removeAvatar.
  ///
  /// In de, this message translates to:
  /// **'Profilbild entfernen'**
  String get removeAvatar;

  /// No description provided for @avatarUpdated.
  ///
  /// In de, this message translates to:
  /// **'Profilbild aktualisiert'**
  String get avatarUpdated;

  /// No description provided for @avatarTooBig.
  ///
  /// In de, this message translates to:
  /// **'Bild zu groß (max. 5 MB)'**
  String get avatarTooBig;

  /// No description provided for @changeUsername.
  ///
  /// In de, this message translates to:
  /// **'Name ändern'**
  String get changeUsername;

  /// No description provided for @newUsername.
  ///
  /// In de, this message translates to:
  /// **'Dein Name'**
  String get newUsername;

  /// No description provided for @usernameChanged.
  ///
  /// In de, this message translates to:
  /// **'Name gespeichert'**
  String get usernameChanged;

  /// No description provided for @exportTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten exportieren'**
  String get exportTitle;

  /// No description provided for @exportSub.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch und Gewicht als CSV speichern'**
  String get exportSub;

  /// No description provided for @exportSaved.
  ///
  /// In de, this message translates to:
  /// **'Export gespeichert'**
  String get exportSaved;

  /// No description provided for @deleteWarning.
  ///
  /// In de, this message translates to:
  /// **'Diese Aktion ist unwiderruflich. Alle Einträge, Lebensmittel, Vorlagen und Gewichte auf diesem Gerät werden gelöscht. Speichere vorher eine Sicherung, wenn du sie behalten willst.'**
  String get deleteWarning;

  /// No description provided for @deleteConfirmWord.
  ///
  /// In de, this message translates to:
  /// **'LÖSCHEN'**
  String get deleteConfirmWord;

  /// No description provided for @deleteConfirmLabel.
  ///
  /// In de, this message translates to:
  /// **'Zur Bestätigung {word} eingeben'**
  String deleteConfirmLabel(String word);

  /// No description provided for @deleteFinal.
  ///
  /// In de, this message translates to:
  /// **'Endgültig löschen'**
  String get deleteFinal;

  /// No description provided for @themeTitle.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get themeTitle;

  /// No description provided for @themeSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// No description provided for @greetingNoName.
  ///
  /// In de, this message translates to:
  /// **'Hallo!'**
  String get greetingNoName;

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'Mein Profil'**
  String get profileTitle;

  /// No description provided for @localDataInfo.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten bleiben auf diesem Gerät'**
  String get localDataInfo;

  /// No description provided for @backupTitle.
  ///
  /// In de, this message translates to:
  /// **'Sicherung speichern'**
  String get backupTitle;

  /// No description provided for @backupSub.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten als Datei sichern'**
  String get backupSub;

  /// No description provided for @backupSaved.
  ///
  /// In de, this message translates to:
  /// **'Sicherung gespeichert'**
  String get backupSaved;

  /// No description provided for @restoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Sicherung wiederherstellen'**
  String get restoreTitle;

  /// No description provided for @restoreSub.
  ///
  /// In de, this message translates to:
  /// **'Daten aus einer Sicherungsdatei laden'**
  String get restoreSub;

  /// No description provided for @restoreConfirm.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten auf diesem Gerät durch die Sicherung{date} ersetzen?'**
  String restoreConfirm(String date);

  /// No description provided for @restoreAction.
  ///
  /// In de, this message translates to:
  /// **'Ersetzen'**
  String get restoreAction;

  /// No description provided for @restoreDone.
  ///
  /// In de, this message translates to:
  /// **'Sicherung wiederhergestellt'**
  String get restoreDone;

  /// No description provided for @backupInvalid.
  ///
  /// In de, this message translates to:
  /// **'Die Datei ist keine MacroBandit-Sicherung.'**
  String get backupInvalid;

  /// No description provided for @backupTooNew.
  ///
  /// In de, this message translates to:
  /// **'Die Sicherung stammt aus einer neueren App-Version. Bitte aktualisiere die App.'**
  String get backupTooNew;

  /// No description provided for @deleteAllData.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten löschen'**
  String get deleteAllData;

  /// No description provided for @deleteAllDataSub.
  ///
  /// In de, this message translates to:
  /// **'Tagebuch, Lebensmittel, Vorlagen und Gewicht löschen'**
  String get deleteAllDataSub;

  /// No description provided for @allDataDeleted.
  ///
  /// In de, this message translates to:
  /// **'Alle Daten gelöscht'**
  String get allDataDeleted;

  /// No description provided for @dataSources.
  ///
  /// In de, this message translates to:
  /// **'Nährwerte: Bundeslebensmittelschlüssel 4.0 (Max Rubner-Institut) und Open Food Facts (ODbL)'**
  String get dataSources;

  /// No description provided for @backupFrom.
  ///
  /// In de, this message translates to:
  /// **'vom {date}'**
  String backupFrom(String date);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
