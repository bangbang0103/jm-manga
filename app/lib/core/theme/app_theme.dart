import 'package:flutter/material.dart';

/// 应用主题，基于 icon.png 的暖橙/奶油/珊瑚色系设计。
abstract class AppTheme {
  static const fontFamily = 'MapleMonoNormalCN';

  static ThemeData dark() => _buildTheme(brightness: Brightness.dark);

  static ThemeData light() => _buildTheme(brightness: Brightness.light);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    // 从 icon.png 提取的核心色板
    const primaryOrange = Color(0xFFF5922F);
    const primaryOrangeLight = Color(0xFFFFB85C);
    const primaryOrangeDark = Color(0xFFC25E00);
    const onPrimaryBrown = Color(0xFF3E1E00);

    const secondaryCoral = Color(0xFFE66A55);
    const secondaryCoralLight = Color(0xFFFF9E8C);
    const secondaryCoralDark = Color(0xFF8B3D2A);

    const tertiaryGold = Color(0xFFFFD166);
    const tertiaryGoldLight = Color(0xFFFFE08A);

    const cream = Color(0xFFFFF8ED);
    const creamDark = Color(0xFF1A1512);

    final surface = isDark ? creamDark : cream;
    final surfaceContainerLow = isDark
        ? const Color(0xFF221C18)
        : const Color(0xFFFFF1DE);
    final surfaceContainer = isDark
        ? const Color(0xFF2C241F)
        : const Color(0xFFFFE8D1);
    final surfaceContainerHigh = isDark
        ? const Color(0xFF3A2F28)
        : const Color(0xFFFFE0BF);
    final surfaceVariant = isDark
        ? const Color(0xFF4A3D35)
        : const Color(0xFFF5E0C8);

    final primary = isDark ? primaryOrangeLight : primaryOrange;
    final primaryContainer = isDark
        ? primaryOrangeDark
        : const Color(0xFFFFD8A8);
    final onPrimary = isDark ? const Color(0xFF2B1200) : onPrimaryBrown;

    final secondary = isDark ? secondaryCoralLight : secondaryCoral;
    final secondaryContainer = isDark
        ? secondaryCoralDark
        : const Color(0xFFFFD4CC);
    final onSecondary = isDark
        ? const Color(0xFF2B0A05)
        : const Color(0xFF5A1A10);

    final tertiary = isDark ? tertiaryGoldLight : tertiaryGold;
    final onTertiary = isDark
        ? const Color(0xFF3D2E00)
        : const Color(0xFF5A4500);

    final onSurface = isDark
        ? const Color(0xFFF5E6D3)
        : const Color(0xFF1A120B);
    final onSurfaceVariant = isDark
        ? const Color(0xFFC9A88F)
        : const Color(0xFF5A3E2E);
    final outline = isDark ? const Color(0xFF8A7260) : const Color(0xFF9A7A60);

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimary,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: const Color(0xFFFFF2F0),
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: const Color(0xFFFFE8B0),
        onTertiaryContainer: const Color(0xFF6B5300),
        error: const Color(0xFFFFB4AB),
        onError: const Color(0xFF690005),
        errorContainer: const Color(0xFF93000A),
        onErrorContainer: const Color(0xFFFFDAD6),
        surface: surface,
        onSurface: onSurface,
        surfaceContainer: surfaceContainer,
        surfaceContainerHighest: surfaceVariant,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: isDark
            ? const Color(0xFF5A4A40)
            : const Color(0xFFD4C2B0),
        inverseSurface: onSurface,
        onInverseSurface: isDark
            ? const Color(0xFF2A221E)
            : const Color(0xFFFFF8ED),
        inversePrimary: const Color(0xFF885200),
        surfaceTint: primary,
        shadow: Colors.black,
        scrim: Colors.black,
      ),
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: onSurface,
        ),
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: onSurface,
        ),
        labelLarge: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.0,
          color: onSurface,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.0,
          color: onSurface,
        ),
      ),
    );
  }
}
