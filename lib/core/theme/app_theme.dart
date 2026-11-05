
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  // =========================
  // Light Theme
  // =========================
  static ThemeData get light {
    return _buildTheme(
      brightness: Brightness.light,
      background: AppColors.lightBackground,
      surface: AppColors.lightSurface,
      text: AppColors.lightText,
      secondaryText: AppColors.lightTextSecondary,
      border: AppColors.lightBorder,
    );
  }

  // =========================
  // Dark Theme
  // =========================
  static ThemeData get dark {
    return _buildTheme(
      brightness: Brightness.dark,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      text: AppColors.darkText,
      secondaryText: AppColors.darkTextSecondary,
      border: AppColors.darkBorder,
    );
  }

  // =========================
  // Shared Theme Builder
  // =========================
  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color text,
    required Color secondaryText,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.gold,
      onPrimary: AppColors.navy,
      secondary: AppColors.goldDark,
      onSecondary: Colors.white,
      error: const Color(0xFFE45B64),
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      // Supporting colors for Material components.
      primaryContainer: isDark
          ? const Color(0xFF493B25)
          : const Color(0xFFFFE8B8),
      onPrimaryContainer: isDark
          ? const Color(0xFFFFE8B8)
          : const Color(0xFF493B25),
      secondaryContainer: isDark
          ? const Color(0xFF303B50)
          : const Color(0xFFE8EDF5),
      onSecondaryContainer: text,
      tertiary: isDark
          ? const Color(0xFF8DB8F5)
          : const Color(0xFF356FB8),
      onTertiary: Colors.white,
      errorContainer: isDark
          ? const Color(0xFF542B32)
          : const Color(0xFFFFDAD9),
      onErrorContainer: isDark
          ? const Color(0xFFFFDAD9)
          : const Color(0xFF410E0B),
      outline: border,
      outlineVariant: border,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: isDark
          ? AppColors.lightSurface
          : AppColors.darkSurface,
      onInverseSurface: isDark
          ? AppColors.lightText
          : AppColors.darkText,
      inversePrimary: AppColors.goldDark,
      surfaceTint: AppColors.gold,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: text),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: isDark ? 1 : 0,
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: border,
            width: 1,
          ),
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Text
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: text,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: secondaryText,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: secondaryText,
          fontSize: 12,
        ),
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: secondaryText),
        labelStyle: TextStyle(color: secondaryText),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.gold,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE45B64)),
        ),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
        elevation: 2,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: secondaryText,
          fontSize: 14,
        ),
      ),

      // Snackbars
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF26334A)
            : const Color(0xFF26334A),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Icons
      iconTheme: IconThemeData(color: secondaryText),

      // List Tiles
      listTileTheme: ListTileThemeData(
        iconColor: secondaryText,
        textColor: text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}