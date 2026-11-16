import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ألوان البروفايلات (كل بروفايل ليه لون يميّزه) — ألوان ترابية هادية تمشي مع الهوية.
const profileColors = <Color>[
  Color(0xFFB8862F), // نحاس
  Color(0xFF2F6B4F), // ملكيت
  Color(0xFF2E4A7A), // لازورد
  Color(0xFFA33A2A), // عقيق
  Color(0xFF5B5346), // بازلت فاتح
  Color(0xFF7A5C8E), // جمشت
  Color(0xFF3F7A86), // فيروز
  Color(0xFF8A6A3B), // بردي غامق
];

Color profileColor(int index) => profileColors[index.abs() % profileColors.length];

/// ألوان التصميم: "حجر وختم" — حجر جيري / بازلت، حبر للأزرار، نحاس للعلامات المهمة بس.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.isDark,
    required this.ink,
    required this.onInk,
    required this.accent,
    required this.accentText,
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final bool isDark;

  /// الزرار الأساسي (حبر في الفاتح، نحاس في الغامق) واللي فوقه.
  final Color ink;
  final Color onInk;

  /// النحاس: الختم، التاب المختار، العلامات المهمة. [accentText] نسخة تنفع نص (تباين كفاية).
  final Color accent;
  final Color accentText;

  final Color bg;
  final Color surface;

  /// خلفية الخانات والأجزاء المميزة جوه الكروت.
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;

  /// ملكيت (سليم / متأكد منه)، نحاس غامق (تحذير)، عقيق (خطر).
  final Color success;
  final Color warning;
  final Color danger;

  /// لون نص مناسب فوق أي خلفية.
  static Color onColor(Color c) => c.computeLuminance() > 0.45 ? const Color(0xFF1C1B19) : const Color(0xFFFBF9F4);

  static const light = Palette(
    isDark: false,
    ink: Color(0xFF1C1B19),
    onInk: Color(0xFFF3EFE7),
    accent: Color(0xFFB8862F),
    accentText: Color(0xFF8A5E17),
    bg: Color(0xFFF3EFE7),
    surface: Color(0xFFFBF9F4),
    surfaceAlt: Color(0xFFEDE7DC),
    border: Color(0xFFDDD5C5),
    text: Color(0xFF1C1B19),
    textMuted: Color(0xFF6B655B),
    success: Color(0xFF2F6B4F),
    warning: Color(0xFF8A5E17),
    danger: Color(0xFFA33A2A),
  );

  static const dark = Palette(
    isDark: true,
    ink: Color(0xFFD4A657),
    onInk: Color(0xFF14130F),
    accent: Color(0xFFD4A657),
    accentText: Color(0xFFD4A657),
    bg: Color(0xFF14130F),
    surface: Color(0xFF1D1C18),
    surfaceAlt: Color(0xFF26241F),
    border: Color(0xFF34312A),
    text: Color(0xFFEDE7DA),
    textMuted: Color(0xFFA39C8C),
    success: Color(0xFF6FB08C),
    warning: Color(0xFFD4A657),
    danger: Color(0xFFE07A66),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      isDark: t < 0.5 ? isDark : other.isDark,
      ink: l(ink, other.ink),
      onInk: l(onInk, other.onInk),
      accent: l(accent, other.accent),
      accentText: l(accentText, other.accentText),
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      danger: l(danger, other.danger),
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Plex';

  /// للبصمات وأرقام المفاتيح.
  static const monoFamily = 'PlexMono';

  static const radius = 12.0;

  static ThemeData build(Brightness brightness) {
    final p = brightness == Brightness.dark ? Palette.dark : Palette.light;
    final scheme = ColorScheme.fromSeed(seedColor: p.accent, brightness: brightness).copyWith(
      primary: p.ink,
      onPrimary: p.onInk,
      secondary: p.accent,
      onSecondary: Palette.onColor(p.accent),
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.textMuted,
      surfaceContainerHighest: p.surfaceAlt,
      outline: p.border,
      outlineVariant: p.border,
      error: p.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: p.bg,
      splashFactory: InkRipple.splashFactory,
    );

    final r = BorderRadius.circular(radius);
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: r, borderSide: BorderSide(color: c, width: w));

    return base.copyWith(
      extensions: [p],
      textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text, fontFamily: fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: p.text,
        systemOverlayStyle: p.isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 19, fontWeight: FontWeight.w700, color: p.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(color: p.textMuted, fontWeight: FontWeight.w400),
        labelStyle: TextStyle(color: p.textMuted),
        floatingLabelStyle: TextStyle(color: p.text, fontWeight: FontWeight.w600),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        border: border(p.border),
        enabledBorder: border(p.border),
        disabledBorder: border(p.border),
        focusedBorder: border(p.text, 1.5),
        errorBorder: border(p.danger),
        focusedErrorBorder: border(p.danger, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.onInk,
          minimumSize: const Size(64, 50),
          shape: RoundedRectangleBorder(borderRadius: r),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: r),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.text,
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.textMuted,
          selectedBackgroundColor: p.ink,
          selectedForegroundColor: p.onInk,
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: r),
          textStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.onInk : p.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.surfaceAlt),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : Colors.transparent),
        checkColor: WidgetStatePropertyAll(p.onInk),
        side: BorderSide(color: p.textMuted, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.ink : p.textMuted),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.ink,
        side: BorderSide(color: p.border),
        labelStyle: TextStyle(fontFamily: fontFamily, color: p.text, fontWeight: FontWeight.w500),
        secondaryLabelStyle: TextStyle(fontFamily: fontFamily, color: p.onInk, fontWeight: FontWeight.w600),
        checkmarkColor: p.onInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.ink,
        foregroundColor: p.onInk,
        elevation: 1,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(borderRadius: r),
        extendedTextStyle: const TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? const Color(0xFF2B2924) : const Color(0xFF1C1B19),
        contentTextStyle: const TextStyle(fontFamily: fontFamily, color: Color(0xFFF3EFE7), fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: r),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: p.border)),
        titleTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w700, color: p.text),
        contentTextStyle: TextStyle(fontFamily: fontFamily, fontSize: 14.5, height: 1.6, color: p.textMuted),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.text,
        textColor: p.text,
        shape: RoundedRectangleBorder(borderRadius: r),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      tooltipTheme: TooltipThemeData(
        textStyle: const TextStyle(fontFamily: fontFamily, color: Color(0xFFF3EFE7)),
        decoration: BoxDecoration(color: const Color(0xFF1C1B19), borderRadius: BorderRadius.circular(8)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.text,
        selectionColor: p.accent.withValues(alpha: 0.3),
        selectionHandleColor: p.accent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
    );
  }
}
