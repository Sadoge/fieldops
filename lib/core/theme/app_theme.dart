import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Primary
  static const navy = Color(0xFF0D1B2A);
  static const navyLight = Color(0xFF1A2E42);
  // Accent
  static const orange = Color(0xFFF57C00);
  static const orangeLight = Color(0xFFFF9800);
  // Surfaces
  static const concrete = Color(0xFFF5F5F0);
  static const concreteVariant = Color(0xFFE8E8E2);
  // Status
  static const statusNew = Color(0xFF1565C0);
  static const statusInProgress = Color(0xFFE65100);
  static const statusCompleted = Color(0xFF2E7D32);
  static const statusVerified = Color(0xFF00695C);
}

// ── Theme ─────────────────────────────────────────────────────────────────────

abstract final class AppTheme {
  static ThemeData light() {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      primaryContainer: AppColors.navyLight,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.orange,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFE0B2),
      onSecondaryContainer: Color(0xFF4A1A00),
      tertiary: AppColors.statusVerified,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFB2DFDB),
      onTertiaryContainer: Color(0xFF003731),
      error: Color(0xFFB00020),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A),
      surfaceContainerHighest: AppColors.concreteVariant,
      onSurfaceVariant: Color(0xFF44474F),
      outline: Color(0xFF74777F),
      outlineVariant: Color(0xFFC4C6D0),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF2F3033),
      onInverseSurface: Color(0xFFF1F0F4),
      inversePrimary: Color(0xFFB0C4DE),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: AppColors.concrete,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.zero,
        shadowColor: Color(0x28000000),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.concreteVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.navy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFB00020), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: const TextStyle(color: Color(0xFF555555)),
        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.orange,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontWeight: FontWeight.w600),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontWeight: FontWeight.w400),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0DA),
        thickness: 0.5,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFB0C4DE),
      onPrimary: Color(0xFF001E3C),
      primaryContainer: AppColors.navyLight,
      onPrimaryContainer: Color(0xFFD6E4FF),
      secondary: AppColors.orangeLight,
      onSecondary: Color(0xFF4A1A00),
      secondaryContainer: Color(0xFF6B3800),
      onSecondaryContainer: Color(0xFFFFDCBE),
      tertiary: Color(0xFF80CBC4),
      onTertiary: Color(0xFF003731),
      tertiaryContainer: Color(0xFF004D45),
      onTertiaryContainer: Color(0xFFB2DFDB),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF121212),
      onSurface: Color(0xFFE6E1E5),
      surfaceContainerHighest: Color(0xFF2A2A2A),
      onSurfaceVariant: Color(0xFFCAC4D0),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE6E1E5),
      onInverseSurface: Color(0xFF313033),
      inversePrimary: AppColors.navy,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A1520),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orangeLight,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(0, 48),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.orangeLight,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.orangeLight, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.orangeLight,
        secondaryLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        titleSmall: TextStyle(fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
