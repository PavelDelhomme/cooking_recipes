import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.orange,
      brightness: Brightness.light,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      shape: const Border(
        bottom: BorderSide(color: Colors.transparent, width: 0),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.orange.shade700, // Orange plus foncé pour mode sombre
      secondary: Colors.orangeAccent.shade400,
      tertiary: Colors.orange.shade300, // Pour les accents
      surface: const Color(0xFF121212),
      background: const Color(0xFF121212),
      error: Colors.red,
      // Texte sur orange : blanc pour être visible
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.black87, // Texte sombre sur orange clair
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
      // Containers pour meilleur contraste
      primaryContainer: Colors.orange.shade900,
      secondaryContainer: Colors.orange.shade800,
      onPrimaryContainer: Colors.white,
      onSecondaryContainer: Colors.white,
      surfaceVariant: const Color(0xFF2C2C2C),
      onSurfaceVariant: Colors.grey[300]!,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color(0xFF1E1E1E),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      shape: const Border(
        bottom: BorderSide(color: Colors.transparent, width: 0),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: Colors.orange.shade700, // Orange plus foncé
      foregroundColor: Colors.white, // Texte blanc pour contraste
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        backgroundColor: Colors.orange.shade700, // Orange plus foncé
        foregroundColor: Colors.white, // Texte blanc pour contraste
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: const Color(0xFF2C2C2C),
      labelStyle: const TextStyle(color: Colors.white),
      // Pour les chips avec couleur primaire (orange)
      selectedColor: Colors.orange.shade700,
      checkmarkColor: Colors.white, // Texte blanc sur orange
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: const Color(0xFF1E1E1E),
      textColor: Colors.white,
      iconColor: Colors.white,
    ),
    dialogBackgroundColor: const Color(0xFF1E1E1E),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: Colors.orange.shade400, // Orange plus clair pour être visible
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(color: Colors.white), // Texte blanc sur sélection
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      indicatorColor: Colors.orange.shade700.withOpacity(0.3),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: Colors.grey[400]!);
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: Colors.white); // Icône blanche sur orange
        }
        return IconThemeData(color: Colors.grey[400]!);
      }),
    ),
  );
}

