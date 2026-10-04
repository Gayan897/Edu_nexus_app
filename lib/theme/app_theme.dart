import 'package:flutter/material.dart';

// ─── SAMS Brand Colors ──────────────────────────────────────────────────────
class SAMSColors {
  // Primary Indigo/Deep Blue gradient
  static const Color primary        = Color(0xFF4F46E5);
  static const Color primaryDark    = Color(0xFF3730A3);
  static const Color primaryLight   = Color(0xFF818CF8);

  // Secondary Teal
  static const Color secondary      = Color(0xFF0F9488);
  static const Color secondaryLight = Color(0xFF5EEAD4);

  // Status Colors
  static const Color present  = Color(0xFF10B981); // green
  static const Color absent   = Color(0xFFEF4444); // red
  static const Color late     = Color(0xFFF59E0B); // amber
  static const Color excused  = Color(0xFF06B6D4); // cyan

  // Background & Surface
  static const Color bgDark        = Color(0xFF0F172A);
  static const Color bgDarkCard    = Color(0xFF1E293B);
  static const Color bgDarkSurface = Color(0xFF334155);
  static const Color bgLight       = Color(0xFFF1F5F9);
  static const Color bgLightCard   = Color(0xFFFFFFFF);
  static const Color bgLightSurface= Color(0xFFE2E8F0);

  // Text
  static const Color textDark      = Color(0xFFF8FAFC);
  static const Color textDarkSub   = Color(0xFF94A3B8);
  static const Color textLight     = Color(0xFF0F172A);
  static const Color textLightSub  = Color(0xFF64748B);

  // Alert / EWS
  static const Color ewsWarning    = Color(0xFFD97706);
  static const Color ewsAlert      = Color(0xFFDC2626);
  static const Color ewsSuccess    = Color(0xFF059669);

  // Gradient backgrounds
  static const List<Color> primaryGradient = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
  ];
  static const List<Color> heroGradient = [
    Color(0xFF0F172A),
    Color(0xFF1E293B),
    Color(0xFF4F46E5),
  ];
}

// ─── SAMS Text Styles ───────────────────────────────────────────────────────
class SAMSTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}

// ─── SAMS Theme Data ────────────────────────────────────────────────────────
class SAMSTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: SAMSColors.primary,
        secondary: SAMSColors.secondary,
        surface: SAMSColors.bgDarkCard,
        error: SAMSColors.absent,
      ),
      scaffoldBackgroundColor: SAMSColors.bgDark,
      cardColor: SAMSColors.bgDarkCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: SAMSColors.bgDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SAMSColors.textDark,
        ),
        iconTheme: IconThemeData(color: SAMSColors.textDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SAMSColors.bgDarkCard,
        selectedItemColor: SAMSColors.primaryLight,
        unselectedItemColor: SAMSColors.textDarkSub,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11),
      ),
      cardTheme: const CardThemeData(
        color: SAMSColors.bgDarkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SAMSColors.bgDarkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SAMSColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: SAMSColors.textDarkSub),
        hintStyle: const TextStyle(color: SAMSColors.textDarkSub),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SAMSColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          elevation: 0,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SAMSColors.bgDarkSurface,
        selectedColor: SAMSColors.primary,
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: SAMSColors.bgDarkSurface,
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: SAMSColors.textDark, fontFamily: 'Poppins', fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: SAMSColors.textDark, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: SAMSColors.textDark, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: SAMSColors.textDark, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: SAMSColors.textDark, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: SAMSColors.textDarkSub, fontFamily: 'Inter'),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: SAMSColors.primary,
        secondary: SAMSColors.secondary,
        surface: SAMSColors.bgLightCard,
        error: SAMSColors.absent,
      ),
      scaffoldBackgroundColor: SAMSColors.bgLight,
      cardColor: SAMSColors.bgLightCard,
      appBarTheme: const AppBarTheme(
        backgroundColor: SAMSColors.bgLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SAMSColors.textLight,
        ),
        iconTheme: IconThemeData(color: SAMSColors.textLight),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SAMSColors.bgLightCard,
        selectedItemColor: SAMSColors.primary,
        unselectedItemColor: SAMSColors.textLightSub,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11),
      ),
      cardTheme: const CardThemeData(
        color: SAMSColors.bgLightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SAMSColors.bgLightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SAMSColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: SAMSColors.textLightSub),
        hintStyle: const TextStyle(color: SAMSColors.textLightSub),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SAMSColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          elevation: 0,
        ),
      ),
      dividerColor: SAMSColors.bgLightSurface,
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: SAMSColors.textLight, fontFamily: 'Poppins', fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: SAMSColors.textLight, fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: SAMSColors.textLight, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: SAMSColors.textLight, fontFamily: 'Inter'),
        bodyMedium: TextStyle(color: SAMSColors.textLight, fontFamily: 'Inter'),
        bodySmall: TextStyle(color: SAMSColors.textLightSub, fontFamily: 'Inter'),
      ),
    );
  }
}
