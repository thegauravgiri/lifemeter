import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// LifeMeter design system: "Riso morning".
///
/// A two-ink risograph look: Riso cobalt and fluoro pink on cool paper, with
/// condensed poster numerals. Built around the Life Clock: it's still
/// morning, and the pink sun is rising.
///
/// Rules:
///  * Cobalt is the brand and the hero slab, in both themes. White text on
///    it is 6.7:1.
///  * Pink is a fill only: the sun, the "now" week, marked weeks and the
///    one-thing block. Never text on white or paper. Ink on pink is 6.6:1.
///  * No third hue. Success is cobalt plus a check; delete is ink.
///  * Sections are plain lists with hairlines. At most two contained cards
///    per screen.
///  * Radii: 2 for week cells, 4 for chips and rows, 10 for slabs and
///    sheets, pills only on primary buttons.
///  * Big Shoulders Display for numbers, Schibsted Grotesk for everything
///    else. Sentence case.
@immutable
class LMPalette extends ThemeExtension<LMPalette> {
  const LMPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceSunk,
    required this.line,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.brand,
    required this.brandPressed,
    required this.onBrand,
    required this.brandText,
    required this.accent,
    required this.onAccent,
    required this.pinkSoft,
    required this.weekLived,
    required this.weekFuture,
    required this.weekNow,
    required this.weekMarked,
    required this.nowRing,
  });

  final Brightness brightness;

  /// Page background ("paper").
  final Color bg;

  /// Inputs, answer rows and sheets.
  final Color surface;

  /// Recessed fills: chips and tracks.
  final Color surfaceSunk;

  /// Hairlines and outlines.
  final Color line;

  final Color ink;
  final Color inkMuted;

  /// Decorative only (never body text).
  final Color inkFaint;

  /// Riso cobalt: the hero slab, primary buttons, selection.
  final Color brand;
  final Color brandPressed;
  final Color onBrand;

  /// Cobalt for links and inline accents on the page background.
  final Color brandText;

  /// Fluoro pink. Fills only.
  final Color accent;

  /// Text on [accent].
  final Color onAccent;

  /// The one-thing block. Text on it is [ink].
  final Color pinkSoft;

  final Color weekLived;
  final Color weekFuture;
  final Color weekNow;
  final Color weekMarked;

  /// The gap ring around the "now" week.
  final Color nowRing;

  bool get isDark => brightness == Brightness.dark;

  /// Outlines of interactive controls (3:1 against bg in both themes).
  Color get control => inkMuted;

  /// Secondary text on the cobalt slab (white at 82%, about 5:1).
  Color get onBrandMuted => onBrand.withValues(alpha: 0.82);

  static const light = LMPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF7F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceSunk: Color(0xFFECEEF5),
    line: Color(0xFFD9DCE8),
    ink: Color(0xFF15161D),
    inkMuted: Color(0xFF555867),
    inkFaint: Color(0xFF8A8D9C),
    brand: Color(0xFF2340F5),
    brandPressed: Color(0xFF1A31C4),
    onBrand: Color(0xFFFFFFFF),
    brandText: Color(0xFF2340F5),
    accent: Color(0xFFFF48B0),
    onAccent: Color(0xFF15161D),
    pinkSoft: Color(0xFFFFD6EC),
    weekLived: Color(0xFF2340F5),
    weekFuture: Color(0xFFDDE1F3),
    weekNow: Color(0xFFFF48B0),
    weekMarked: Color(0xFFFF48B0),
    nowRing: Color(0xFFFFFFFF),
  );

  static const dark = LMPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0F1014),
    surface: Color(0xFF191A21),
    surfaceSunk: Color(0xFF22232C),
    line: Color(0xFF2E303B),
    ink: Color(0xFFF2F2F7),
    inkMuted: Color(0xFFA6A8B8),
    inkFaint: Color(0xFF6E7080),
    brand: Color(0xFF2340F5),
    brandPressed: Color(0xFF1A31C4),
    onBrand: Color(0xFFFFFFFF),
    brandText: Color(0xFF8B9BFF),
    accent: Color(0xFFFF5CB8),
    onAccent: Color(0xFF15161D),
    pinkSoft: Color(0xFF3A1A2E),
    weekLived: Color(0xFF4A63FF),
    weekFuture: Color(0xFF2A2C38),
    weekNow: Color(0xFFFF5CB8),
    weekMarked: Color(0xFFFF5CB8),
    nowRing: Color(0xFF0F1014),
  );

  @override
  LMPalette copyWith() => this;

  @override
  LMPalette lerp(LMPalette? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

abstract final class LMSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double section = 44;
  static const double xxl = 48;

  /// Horizontal page gutter.
  static const double gutter = 20;
}

abstract final class LMRadius {
  static const double cell = 2;
  static const double chip = 4;
  static const double slab = 10;
  static const double pill = 999;
}

abstract final class LMFont {
  static const display = 'BigShoulders';
  static const sans = 'Schibsted';
}

/// Text styles resolved against the active palette.
class LMText {
  LMText(this.p);

  final LMPalette p;

  static const tnum = [FontFeature.tabularFigures()];

  /// Poster numerals: the life clock and hero counts.
  TextStyle get display => TextStyle(
    fontFamily: LMFont.display,
    fontWeight: FontWeight.w900,
    fontSize: 128,
    height: 0.86,
    letterSpacing: -1.2,
    color: p.ink,
  );

  /// Secondary poster numbers (stats, week numbers).
  TextStyle get stat => TextStyle(
    fontFamily: LMFont.display,
    fontWeight: FontWeight.w800,
    fontSize: 40,
    height: 1.0,
    letterSpacing: -0.4,
    color: p.brandText,
  );

  /// Screen titles and question headlines.
  TextStyle get headline => TextStyle(
    fontFamily: LMFont.sans,
    fontWeight: FontWeight.w700,
    fontSize: 30,
    height: 1.12,
    letterSpacing: -0.6,
    color: p.ink,
  );

  /// Section titles.
  TextStyle get title => TextStyle(
    fontFamily: LMFont.sans,
    fontWeight: FontWeight.w700,
    fontSize: 21,
    height: 1.2,
    letterSpacing: -0.3,
    color: p.ink,
  );

  TextStyle get bodyLarge => TextStyle(
    fontFamily: LMFont.sans,
    fontSize: 17,
    height: 1.45,
    color: p.inkMuted,
  );

  TextStyle get body => TextStyle(
    fontFamily: LMFont.sans,
    fontSize: 16,
    height: 1.45,
    color: p.inkMuted,
  );

  /// Primary row text: answers, list items, settings labels.
  TextStyle get label => TextStyle(
    fontFamily: LMFont.sans,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.3,
    color: p.ink,
  );

  /// Secondary text.
  TextStyle get caption => TextStyle(
    fontFamily: LMFont.sans,
    fontSize: 14,
    height: 1.4,
    color: p.inkMuted,
  );

  /// Small sentence-case label for kickers and metadata.
  TextStyle get small => TextStyle(
    fontFamily: LMFont.sans,
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.25,
    color: p.inkMuted,
  );

  TextStyle get button => const TextStyle(
    fontFamily: LMFont.sans,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.2,
  );

  /// Small changing numbers (the optional live seconds).
  TextStyle get ticker => TextStyle(
    fontFamily: LMFont.sans,
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: p.inkMuted,
    fontFeatures: tnum,
  );
}

extension LMContext on BuildContext {
  LMPalette get lm => Theme.of(this).extension<LMPalette>()!;
  LMText get type => LMText(lm);
}

ThemeData buildTheme(LMPalette p) {
  final t = LMText(p);
  const slab = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(LMRadius.slab)),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    extensions: [p],
    colorScheme: ColorScheme(
      brightness: p.brightness,
      surface: p.bg,
      onSurface: p.ink,
      primary: p.brand,
      onPrimary: p.onBrand,
      secondary: p.accent,
      onSecondary: p.onAccent,
      error: p.ink,
      onError: p.bg,
      outline: p.line,
      surfaceContainerHighest: p.surface,
    ),
    scaffoldBackgroundColor: p.bg,
    fontFamily: LMFont.sans,
    splashFactory: InkRipple.splashFactory,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.brandText,
      selectionColor: p.brand.withValues(alpha: 0.25),
      selectionHandleColor: p.brand,
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: t.title.copyWith(fontSize: 19),
      systemOverlayStyle: overlayStyle(p),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.isDark ? p.surface : p.bg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: p.inkFaint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LMRadius.slab),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.isDark ? p.surface : p.bg,
      surfaceTintColor: Colors.transparent,
      shape: slab,
      titleTextStyle: t.title,
      contentTextStyle: t.body,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.isDark ? p.surface : p.bg,
      surfaceTintColor: Colors.transparent,
      shape: slab,
      headerBackgroundColor: p.brand,
      headerForegroundColor: p.onBrand,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.brandText,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(LMRadius.chip)),
        ),
        textStyle: t.button,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onBrand : p.inkMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.brand : p.surfaceSunk,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.brand : p.control,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.ink,
      contentTextStyle: t.label.copyWith(color: p.bg),
      actionTextColor: p.isDark ? p.brand : const Color(0xFFB7C1FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(LMRadius.slab)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    iconTheme: IconThemeData(color: p.ink, size: 24),
  );
}

SystemUiOverlayStyle overlayStyle(LMPalette p, {bool onBrand = false}) {
  final light = p.isDark || onBrand;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: light ? Brightness.light : Brightness.dark,
    statusBarBrightness: light ? Brightness.dark : Brightness.light,
    systemNavigationBarIconBrightness: light
        ? Brightness.light
        : Brightness.dark,
  );
}
