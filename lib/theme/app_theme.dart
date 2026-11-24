import 'package:material_ui/material_ui.dart';

import 'palette.dart';

ThemeData buildAppTheme() {
  const text = TextStyle(fontFamily: 'Manrope', color: Palette.ink);
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: Palette.canvas,
    colorScheme: const ColorScheme.light(
      primary: Palette.sageDeep,
      onPrimary: Colors.white,
      secondary: Palette.sage,
      onSecondary: Colors.white,
      surface: Palette.paper,
      onSurface: Palette.ink,
      error: Palette.danger,
      onError: Colors.white,
    ),
    dividerColor: Palette.line,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Palette.ink,
      displayColor: Palette.ink,
      fontFamily: 'Manrope',
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.canvas,
      foregroundColor: Palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.paper,
      indicatorColor: Palette.mist,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return text.copyWith(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Palette.sageDeep : Palette.inkSoft,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? Palette.sageDeep : Palette.inkSoft,
          size: 22,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.sageDeep,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        textStyle: text.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.ink,
        side: const BorderSide(color: Palette.line),
        textStyle: text.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Palette.paper,
      selectedColor: Palette.mist,
      disabledColor: Palette.paper,
      labelStyle: text.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
      secondaryLabelStyle: text.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Palette.sageDeep,
      ),
      side: const BorderSide(color: Palette.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: text.copyWith(color: Palette.inkSoft, fontWeight: FontWeight.w500),
      labelStyle: text.copyWith(color: Palette.inkSoft, fontWeight: FontWeight.w600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.sage, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.danger),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.ink,
      contentTextStyle: text.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Palette.sage),
  );
}
