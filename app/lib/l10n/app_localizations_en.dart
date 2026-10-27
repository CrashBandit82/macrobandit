// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MacroBandit';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get retry => 'Try again';

  @override
  String get errorGeneric => 'Something went wrong';

  @override
  String get errorOffline => 'No internet connection';

  @override
  String greeting(String name) {
    return 'Hi, $name!';
  }

  @override
  String get tabNutrition => 'Nutrition';

  @override
  String get tabWeight => 'Weight';

  @override
  String get tabAccount => 'Profile';

  @override
  String todayDate(String date) {
    return 'Today, $date';
  }

  @override
  String yesterdayDate(String date) {
    return 'Yesterday, $date';
  }

  @override
  String get today => 'Today';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get calorieOverview => 'Calorie overview';

  @override
  String ofGoalKcal(int goal) {
    return '/ $goal kcal';
  }

  @override
  String get remaining => 'left';

  @override
  String get over => 'over';

  @override
  String progressOfGoal(int pct) {
    return '$pct % of daily goal';
  }

  @override
  String get adjustGoals => 'Adjust goals';

  @override
  String get macroProtein => 'Protein';

  @override
  String get macroCarbs => 'Carbs';

  @override
  String get macroFat => 'Fat';

  @override
  String get macroFiber => 'Fibre';

  @override
  String get tabWeek => 'Week';

  @override
  String get tabMonth => 'Month';

  @override
  String get foodDatabase => 'Foods';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get todayConsumed => 'Eaten today';

  @override
  String get meals => 'Meals';

  @override
  String get noEntries => 'No entries yet.';

  @override
  String entryCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count entries', one: '1 entry');
    return '$_temp0';
  }

  @override
  String get addMeal => 'Log meal';

  @override
  String deleteLogConfirm(String name) {
    return 'Delete entry \"$name\"?';
  }

  @override
  String itemAdded(String name) {
    return '$name added';
  }

  @override
  String itemUpdated(String name) {
    return '$name updated';
  }

  @override
  String itemDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get editAmountTitle => 'Change amount';

  @override
  String currentAmount(String grams, int kcal) {
    return 'Currently: $grams g · $kcal kcal';
  }

  @override
  String get productNotFound => 'Product not found. Please enter it manually.';

  @override
  String get goalsTitle => 'Your goals';

  @override
  String get calorieGoalLabel => 'Calorie goal (kcal)';

  @override
  String gramsLabel(String name) {
    return '$name (g)';
  }

  @override
  String get goalsSaved => 'Goals saved';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabCustom => 'Custom';

  @override
  String get tabTemplates => 'Templates';

  @override
  String get searchLabel => 'Food, amount optional';

  @override
  String get searchHint => 'e.g. 200g milk or beef fillet';

  @override
  String quickAmount(String grams, String term) {
    return 'Amount detected: $grams g · searching \"$term\"';
  }

  @override
  String onlineSearch(String term) {
    return 'Search online: \"$term\"';
  }

  @override
  String get onlineSearching => 'Searching online …';

  @override
  String get onlineSection => 'Online (Open Food Facts)';

  @override
  String get onlineNone => 'Nothing found online';

  @override
  String get onlineError => 'Online search currently unavailable';

  @override
  String get onlineHide => 'Hide';

  @override
  String get myFoodsSection => 'My foods';

  @override
  String get blsSection => 'Basic foods (BLS)';

  @override
  String get blsSource => 'Source: Bundeslebensmittelschlüssel 4.0, Max Rubner-Institut';

  @override
  String get noResults => 'No match – try a custom entry';

  @override
  String get sourceScanned => 'scanned';

  @override
  String kcalPer100(int kcal) {
    return '$kcal kcal / 100 g';
  }

  @override
  String get amountGrams => 'Amount in grams';

  @override
  String get addButton => 'Log';

  @override
  String get shortCarbs => 'Carbs';

  @override
  String get mealName => 'Meal name';

  @override
  String get portionWeight => 'Portion (g)';

  @override
  String get kcalPortion => 'Calories (kcal)';

  @override
  String get customHint => 'Values for the whole portion. The meal is saved as your own food.';

  @override
  String get saveAndLog => 'Save & log';

  @override
  String get mealLogged => 'Meal logged';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidNumber => 'Please enter a number above 0';

  @override
  String get foodDbTitle => 'My foods';

  @override
  String get foodDbInfo => 'Your saved foods – including entries taken from the BLS and Open Food Facts.';

  @override
  String get noOwnFoods => 'No own foods yet.';

  @override
  String get editFoodTitle => 'Edit food';

  @override
  String get nameLabel => 'Name';

  @override
  String get brandOptional => 'Brand (optional)';

  @override
  String get kcalPer100Label => 'kcal / 100 g';

  @override
  String per100Label(String name) {
    return '$name / 100 g';
  }

  @override
  String get portionLabel => 'Portion (label)';

  @override
  String get portionLabelHint => 'e.g. 1 piece';

  @override
  String get portionGrams => 'Portion (g)';

  @override
  String deleteFoodConfirm(String name) {
    return 'Delete \"$name\" from your database?';
  }

  @override
  String foodSaved(String name) {
    return '$name saved';
  }

  @override
  String get templatesEmpty => 'No templates yet. Create your first one!';

  @override
  String templateKcal(int kcal) {
    return '$kcal kcal total';
  }

  @override
  String get templateNew => 'New template';

  @override
  String get templateEdit => 'Edit template';

  @override
  String get templateName => 'Name (e.g. usual breakfast)';

  @override
  String get templateAddFood => 'Add food …';

  @override
  String get templateNotFound => 'Not found';

  @override
  String templateDeleteConfirm(String name) {
    return 'Delete template \"$name\"?';
  }

  @override
  String get templateSaved => 'Template saved';

  @override
  String templateApplied(String name) {
    return '\"$name\" logged';
  }

  @override
  String get templateAmountError => 'Please enter an amount above 0 g for every food';

  @override
  String get templateNeedsItems => 'Name and at least one food required';

  @override
  String get weekTitle => 'This week';

  @override
  String weekAvg(String avg) {
    return 'Ø $avg kcal/day';
  }

  @override
  String get weekGoalReached => 'Goal reached';

  @override
  String get weekOver => 'Over goal';

  @override
  String get monthNoData => 'No data for this month';

  @override
  String get monthDaysTracked => 'Days tracked';

  @override
  String get monthGoalDays => 'Goal reached';

  @override
  String monthDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get monthAvgKcal => 'Ø calories/day';

  @override
  String get monthAvgProtein => 'Ø protein/day';

  @override
  String get monthAvgCarbs => 'Ø carbs/day';

  @override
  String get monthAvgFat => 'Ø fat/day';

  @override
  String get monthBest => 'Best day';

  @override
  String get monthLowest => 'Lowest day';

  @override
  String get monthDaily => 'Daily calories';

  @override
  String get monthGoalNotReached => 'Goal not reached';

  @override
  String get weightToday => 'Weight today';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get weightCurrent => 'Current';

  @override
  String get weightStart => 'Start';

  @override
  String get weightTrend => '7 days';

  @override
  String get weightSaved => 'Weight saved';

  @override
  String get weightChartTitle => 'History (60 days)';

  @override
  String get weightChartMin => 'At least 2 entries for the chart';

  @override
  String get weightEntries => 'Entries';

  @override
  String weightDeleteConfirm(String date) {
    return 'Delete entry from $date?';
  }

  @override
  String get tdeeTitle => 'TDEE calculator';

  @override
  String get tdeeFormula => 'Mifflin-St Jeor formula';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get ageLabel => 'Age (years)';

  @override
  String get heightLabel => 'Height (cm)';

  @override
  String get activityLabel => 'Activity level';

  @override
  String get activitySedentary => 'Sedentary (office job)';

  @override
  String get activityLight => 'Lightly active (1–3× sport/week)';

  @override
  String get activityModerate => 'Moderately active (3–5× sport/week)';

  @override
  String get activityActive => 'Very active (6–7× sport/week)';

  @override
  String get activityVeryActive => 'Extremely active (2× daily)';

  @override
  String get goalLabel => 'Goal';

  @override
  String get goalLose => 'Lose';

  @override
  String get goalMaintain => 'Maintain';

  @override
  String get goalGain => 'Gain';

  @override
  String get calcButton => 'Calculate TDEE';

  @override
  String get tdeeResult => 'Your daily calorie need';

  @override
  String get tdeeUnit => 'kcal / day';

  @override
  String applyGoal(int kcal) {
    return 'Use as calorie goal ($kcal kcal)';
  }

  @override
  String get fillAllFields => 'Please enter age, height and weight';

  @override
  String goalSet(int kcal) {
    return 'Calorie goal set to $kcal kcal';
  }

  @override
  String get changeAvatar => 'Change picture';

  @override
  String get removeAvatar => 'Remove picture';

  @override
  String get avatarUpdated => 'Picture updated';

  @override
  String get avatarTooBig => 'Image too large (max. 5 MB)';

  @override
  String get changeUsername => 'Change name';

  @override
  String get newUsername => 'Your name';

  @override
  String get usernameChanged => 'Name saved';

  @override
  String get exportTitle => 'Export data';

  @override
  String get exportSub => 'Save diary and weight as CSV';

  @override
  String get exportSaved => 'Export saved';

  @override
  String get deleteWarning =>
      'This cannot be undone. All entries, foods, templates and weights on this device will be deleted. Save a backup first if you want to keep them.';

  @override
  String get deleteConfirmWord => 'DELETE';

  @override
  String deleteConfirmLabel(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get deleteFinal => 'Delete permanently';

  @override
  String get themeTitle => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get greetingNoName => 'Hello!';

  @override
  String get profileTitle => 'My profile';

  @override
  String get localDataInfo => 'All data stays on this device';

  @override
  String get backupTitle => 'Save backup';

  @override
  String get backupSub => 'Save all data as a file';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get restoreTitle => 'Restore backup';

  @override
  String get restoreSub => 'Load data from a backup file';

  @override
  String restoreConfirm(String date) {
    return 'Replace all data on this device with the backup$date?';
  }

  @override
  String get restoreAction => 'Replace';

  @override
  String get restoreDone => 'Backup restored';

  @override
  String get backupInvalid => 'This file is not a MacroBandit backup.';

  @override
  String get backupTooNew => 'This backup is from a newer app version. Please update the app.';

  @override
  String get deleteAllData => 'Delete all data';

  @override
  String get deleteAllDataSub => 'Delete diary, foods, templates and weight';

  @override
  String get allDataDeleted => 'All data deleted';

  @override
  String get dataSources =>
      'Nutrition data: Bundeslebensmittelschlüssel 4.0 (Max Rubner-Institut) and Open Food Facts (ODbL)';

  @override
  String backupFrom(String date) {
    return 'from $date';
  }
}
