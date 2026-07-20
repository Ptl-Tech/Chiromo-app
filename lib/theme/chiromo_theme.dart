import 'package:flutter/material.dart';
import 'chiromo_colors.dart';

/// Complete Light and Dark [ThemeData] for Chiromo Hospital Group.
/// Uses Material 3 with brand colours:
///   Primary  → Navy Blue (#1B4F72)
///   Secondary → Gold (#C4972A)
///   Tertiary → Crimson (#B71C1C)
class ChiromoTheme {
  ChiromoTheme._();

  // ─────────────────────── Typography ───────────────────────────
  static const String _fontFamily = 'Inter';

  // ─────────────────────── Border Radii ─────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ─────────────────────── Spacing ──────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ═══════════════════════ LIGHT THEME ══════════════════════════
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: ChiromoColors.primary,
      onPrimary: ChiromoColors.textOnPrimary,
      primaryContainer: ChiromoColors.primarySurface,
      onPrimaryContainer: ChiromoColors.primaryDark,
      secondary: ChiromoColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: ChiromoColors.goldSurface,
      onSecondaryContainer: ChiromoColors.goldDark,
      tertiary: ChiromoColors.crimson,
      onTertiary: Colors.white,
      tertiaryContainer: ChiromoColors.crimsonSurface,
      onTertiaryContainer: ChiromoColors.crimson,
      error: ChiromoColors.error,
      onError: Colors.white,
      errorContainer: ChiromoColors.errorLight,
      onErrorContainer: ChiromoColors.error,
      surface: ChiromoColors.surface,
      onSurface: ChiromoColors.textPrimary,
      surfaceContainerHighest: ChiromoColors.surfaceVariant,
      onSurfaceVariant: ChiromoColors.textSecondary,
      outline: ChiromoColors.border,
      outlineVariant: ChiromoColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: ChiromoColors.background,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: ChiromoColors.surface,
        foregroundColor: ChiromoColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ChiromoColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: ChiromoColors.textPrimary),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: ChiromoColors.primary.withValues(alpha: 0.15),
        color: ChiromoColors.surface.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: ChiromoColors.border.withValues(alpha: 0.5), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChiromoColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: ChiromoColors.primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ChiromoColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: ChiromoColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ChiromoColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── FAB ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ChiromoColors.gold,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      // ── Input ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ChiromoColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: ChiromoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: ChiromoColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: ChiromoColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: ChiromoColors.error, width: 2),
        ),
        hintStyle: const TextStyle(
          color: ChiromoColors.textTertiary,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: ChiromoColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: ChiromoColors.surfaceVariant,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Bottom Nav ──
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ChiromoColors.surface,
        selectedItemColor: ChiromoColors.primary,
        unselectedItemColor: ChiromoColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // ── Navigation Bar (M3) ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ChiromoColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        indicatorShape: const CircleBorder(),
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ChiromoColors.primary, size: 28);
          }
          return const IconThemeData(color: ChiromoColors.textTertiary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: ChiromoColors.primary,
              letterSpacing: 0.3,
            );
          }
          return const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: ChiromoColors.textTertiary,
          );
        }),
      ),

      // ── Navigation Rail ──
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: ChiromoColors.surface,
        selectedIconTheme: IconThemeData(color: ChiromoColors.primary),
        unselectedIconTheme: IconThemeData(color: ChiromoColors.textTertiary),
        indicatorColor: ChiromoColors.primarySurface,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        backgroundColor: ChiromoColors.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: ChiromoColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        backgroundColor: ChiromoColors.primaryDarkest,
      ),

      // ── Tab ──
      tabBarTheme: const TabBarThemeData(
        labelColor: ChiromoColors.primary,
        unselectedLabelColor: ChiromoColors.textSecondary,
        indicatorColor: ChiromoColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
      ),

      // ── Drawer ──
      drawerTheme: const DrawerThemeData(
        backgroundColor: ChiromoColors.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ChiromoColors.primaryDarkest,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: _fontFamily,
        ),
      ),
    );
  }

  // ═══════════════════════ DARK THEME ═══════════════════════════
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: ChiromoColors.primaryLight,
      onPrimary: ChiromoColors.primaryDarkest,
      primaryContainer: ChiromoColors.primaryDark,
      onPrimaryContainer: ChiromoColors.primaryLighter,
      secondary: ChiromoColors.goldLight,
      onSecondary: Colors.black,
      secondaryContainer: ChiromoColors.goldDark,
      onSecondaryContainer: ChiromoColors.goldLight,
      tertiary: ChiromoColors.crimsonLight,
      onTertiary: Colors.black,
      tertiaryContainer: ChiromoColors.crimson,
      onTertiaryContainer: ChiromoColors.crimsonLight,
      error: ChiromoColors.crimsonLight,
      onError: Colors.black,
      errorContainer: ChiromoColors.crimson,
      onErrorContainer: ChiromoColors.crimsonLight,
      surface: ChiromoColors.darkSurface,
      onSurface: ChiromoColors.darkTextPrimary,
      surfaceContainerHighest: ChiromoColors.darkSurfaceVariant,
      onSurfaceVariant: ChiromoColors.darkTextSecondary,
      outline: ChiromoColors.darkBorder,
      outlineVariant: ChiromoColors.darkBorder,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: ChiromoColors.darkBackground,

      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: ChiromoColors.darkSurface,
        foregroundColor: ChiromoColors.darkTextPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ChiromoColors.darkTextPrimary,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: ChiromoColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: ChiromoColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChiromoColors.primaryLight,
          foregroundColor: ChiromoColors.primaryDarkest,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ChiromoColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: ChiromoColors.darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ChiromoColors.primaryLight,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ChiromoColors.goldLight,
        foregroundColor: ChiromoColors.primaryDarkest,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ChiromoColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: ChiromoColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: ChiromoColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: ChiromoColors.crimsonLight),
        ),
        hintStyle: const TextStyle(color: ChiromoColors.darkTextSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: ChiromoColors.darkTextSecondary, fontSize: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: ChiromoColors.darkSurfaceVariant,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        side: BorderSide.none,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ChiromoColors.darkSurface,
        selectedItemColor: ChiromoColors.primaryLight,
        unselectedItemColor: ChiromoColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ChiromoColors.darkSurface,
        indicatorColor: ChiromoColors.primaryLight,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ChiromoColors.primaryDarkest, size: 26);
          }
          return const IconThemeData(color: ChiromoColors.darkTextSecondary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: _fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: ChiromoColors.primaryLight,
            );
          }
          return const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: ChiromoColors.darkTextSecondary,
          );
        }),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ChiromoColors.darkSurface,
        selectedIconTheme: const IconThemeData(color: ChiromoColors.primaryLight),
        unselectedIconTheme: const IconThemeData(color: ChiromoColors.darkTextSecondary),
        indicatorColor: ChiromoColors.primaryDark,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        backgroundColor: ChiromoColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),

      dividerTheme: const DividerThemeData(
        color: ChiromoColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        backgroundColor: ChiromoColors.darkSurfaceVariant,
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: ChiromoColors.darkSurface,
        surfaceTintColor: Colors.transparent,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: ChiromoColors.darkSurfaceVariant,
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        textStyle: const TextStyle(
          color: ChiromoColors.darkTextPrimary,
          fontSize: 12,
          fontFamily: _fontFamily,
        ),
      ),
    );
  }
}
