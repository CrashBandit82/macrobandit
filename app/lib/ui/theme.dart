import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// MacroBandit palette (Tailwind slate/emerald like the web app), one set per
/// brightness. Every text color reaches 4.5:1 on page and card.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.page,
    required this.card,
    required this.track,
    required this.border,
    required this.text,
    required this.soft,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.primary,
    required this.navIndicator,
    required this.today,
    required this.protein,
    required this.proteinText,
    required this.carbs,
    required this.carbsText,
    required this.fat,
    required this.fatText,
    required this.fiber,
    required this.fiberText,
    required this.online,
    required this.onlineText,
    required this.error,
    required this.warn,
    required this.warnBg,
    required this.kcalLow,
    required this.idle,
    required this.navBar,
  });

  final Color page, card, track, border;

  /// Text: [text] primary, [soft] secondary, [muted] tertiary, [faint] captions.
  final Color text, soft, muted, faint;

  /// [accent] for text/icons, [primary] for filled surfaces.
  final Color accent, primary, navIndicator, today;

  /// Macro colors: fill for bars and dots, *Text for text on page/card.
  final Color protein, proteinText, carbs, carbsText, fat, fatText, fiber, fiberText;
  final Color online, onlineText, error, warn, warnBg;

  /// Start of the calorie color scale (0 % of goal) and bars without data.
  final Color kcalLow, idle;
  final Color navBar;

  static const dark = Palette(
    page: Color(0xFF0F172A),
    card: Color(0xFF1E293B),
    track: Color(0xFF0F172A),
    border: Color(0xFF334155),
    text: Color(0xFFF1F5F9),
    soft: Color(0xFFCBD5E1),
    muted: Color(0xFF94A3B8),
    faint: Color(0xFF8B9AB0),
    accent: Color(0xFF34D399),
    primary: Color(0xFF10B981),
    navIndicator: Color(0xFF047857),
    today: Color(0xFF22D3EE),
    protein: Color(0xFF3B82F6),
    proteinText: Color(0xFF60A5FA),
    carbs: Color(0xFFF59E0B),
    carbsText: Color(0xFFFBBF24),
    fat: Color(0xFFF43F5E),
    fatText: Color(0xFFFB7185),
    fiber: Color(0xFF84CC16),
    fiberText: Color(0xFFA3E635),
    online: Color(0xFF0369A1),
    onlineText: Color(0xFF7DD3FC),
    error: Color(0xFFE11D48),
    warn: Color(0xFFFBBF24),
    warnBg: Color(0x6678350F),
    kcalLow: Color(0xFFFFFFFF),
    idle: Color(0xFF475569),
    navBar: Color(0xFF0B1222),
  );

  static const light = Palette(
    page: Color(0xFFF8FAFC),
    card: Color(0xFFFFFFFF),
    track: Color(0xFFE2E8F0),
    border: Color(0xFFE2E8F0),
    text: Color(0xFF0F172A),
    soft: Color(0xFF334155),
    muted: Color(0xFF475569),
    faint: Color(0xFF5B6B80),
    accent: Color(0xFF047857),
    primary: Color(0xFF059669),
    navIndicator: Color(0xFF047857),
    today: Color(0xFF0E7490),
    protein: Color(0xFF3B82F6),
    proteinText: Color(0xFF1D4ED8),
    carbs: Color(0xFFF59E0B),
    carbsText: Color(0xFFB45309),
    fat: Color(0xFFF43F5E),
    fatText: Color(0xFFBE123C),
    fiber: Color(0xFF84CC16),
    fiberText: Color(0xFF4D7C0F),
    online: Color(0xFF0369A1),
    onlineText: Color(0xFF0369A1),
    error: Color(0xFFE11D48),
    warn: Color(0xFFB45309),
    warnBg: Color(0xFFFEF3C7),
    kcalLow: Color(0xFFCBD5E1),
    idle: Color(0xFFCBD5E1),
    navBar: Color(0xFFFFFFFF),
  );

  /// Per-user button gradient like the web app (USER_COLORS by user id), in
  /// 700 shades so white text stays above 4.5:1.
  static const _userGradients = [
    [Color(0xFFBE185D), Color(0xFFBE123C)],
    [Color(0xFF0F766E), Color(0xFF065F46)],
    [Color(0xFF1D4ED8), Color(0xFF0E7490)],
    [Color(0xFF0F766E), Color(0xFF047857)],
    [Color(0xFF15803D), Color(0xFF3F6212)],
    [Color(0xFFA16207), Color(0xFFB45309)],
    [Color(0xFFC2410C), Color(0xFFB91C1C)],
    [Color(0xFFA21CAF), Color(0xFFBE185D)],
    [Color(0xFFB45309), Color(0xFF9A3412)],
    [Color(0xFF0369A1), Color(0xFF1D4ED8)],
  ];

  static const brandGradient = LinearGradient(colors: [Color(0xFF047857), Color(0xFF0E7490)]);

  static LinearGradient userGradient(int userId) =>
      LinearGradient(colors: _userGradients[(userId - 1) % _userGradients.length]);

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) => other == null || t < 0.5 ? this : other;
}

extension ThemeX on BuildContext {
  Palette get c => Theme.of(this).extension<Palette>()!;
  TextTheme get tt => Theme.of(this).textTheme;
}

/// Type scale (sp, follows the system font size). Screens pick roles, not sizes.
TextTheme _textTheme(Palette p) {
  TextStyle s(double size, FontWeight w, {Color? color, double? height, double? spacing}) =>
      TextStyle(fontSize: size, fontWeight: w, color: color ?? p.text, height: height, letterSpacing: spacing);
  return TextTheme(
    displaySmall: s(44, FontWeight.w800, height: 1),
    headlineSmall: s(28, FontWeight.w900),
    titleLarge: s(20, FontWeight.w800),
    titleMedium: s(17, FontWeight.w700),
    titleSmall: s(15, FontWeight.w600),
    bodyLarge: s(16, FontWeight.w400),
    bodyMedium: s(14, FontWeight.w400),
    bodySmall: s(12.5, FontWeight.w400, color: p.muted),
    labelLarge: s(15, FontWeight.w700),
    labelMedium: s(12, FontWeight.w600, color: p.muted),
    labelSmall: s(11, FontWeight.w700, color: p.faint, spacing: 0.8),
  );
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final p = dark ? Palette.dark : Palette.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: Colors.white,
    primaryContainer: p.navIndicator,
    onPrimaryContainer: Colors.white,
    secondary: p.today,
    onSecondary: Colors.white,
    secondaryContainer: p.navIndicator,
    onSecondaryContainer: Colors.white,
    error: p.error,
    onError: Colors.white,
    surface: p.page,
    onSurface: p.text,
    surfaceContainerLowest: p.page,
    surfaceContainerLow: p.card,
    surfaceContainer: p.card,
    surfaceContainerHigh: p.card,
    surfaceContainerHighest: dark ? const Color(0xFF273449) : const Color(0xFFF1F5F9),
    onSurfaceVariant: p.muted,
    outline: dark ? p.border : const Color(0xFFCBD5E1),
    outlineVariant: p.border,
  );
  final textTheme = _textTheme(p);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: scheme.outline),
  );
  final overlay = (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: p.navBar,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: p.page,
    textTheme: textTheme,
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: p.page,
      foregroundColor: p.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: overlay,
      titleTextStyle: textTheme.titleMedium,
    ),
    cardTheme: CardThemeData(
      color: p.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: p.border.withValues(alpha: dark ? 0.7 : 1)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: p.primary, width: 1.5)),
      labelStyle: TextStyle(color: p.muted),
      hintStyle: TextStyle(color: p.faint),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: p.soft,
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: p.accent)),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: p.card,
        selectedBackgroundColor: p.navIndicator,
        selectedForegroundColor: Colors.white,
        foregroundColor: p.muted,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.navBar,
      indicatorColor: p.navIndicator,
      // explicit colors: the scheme default for the selected icon is dark on dark
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Colors.white : p.muted),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700, color: p.text)
            : textTheme.labelMedium!,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(foregroundColor: Colors.white),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.page, showDragHandle: true),
    dialogTheme: DialogThemeData(backgroundColor: p.card),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: DividerThemeData(color: p.border.withValues(alpha: 0.6), space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: p.muted,
      titleTextStyle: textTheme.titleSmall,
      subtitleTextStyle: textTheme.bodySmall,
    ),
  );
}
