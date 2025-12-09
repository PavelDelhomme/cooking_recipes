import 'package:flutter/material.dart';

class AppTheme {
  // Typographie moderne et classique (similaire à Segoe UI)
  static const String _fontFamily = 'Roboto'; // Roboto est proche de Segoe UI sur Flutter
  
  // Couleurs orange améliorées avec gradients
  static const Color _orangePrimary = Color(0xFFFF6B35); // Orange vif
  static const Color _orangeSecondary = Color(0xFFFF8C42); // Orange clair
  static const Color _orangeDark = Color(0xFFE55A2B); // Orange foncé
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _orangePrimary,
      brightness: Brightness.light,
      primary: _orangePrimary,
      secondary: _orangeSecondary,
      tertiary: _orangeDark,
    ),
    // Typographie améliorée
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    ),
    cardTheme: CardTheme(
      elevation: 0, // Pas d'élévation par défaut, on utilisera des ombres personnalisées
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)), // Plus arrondi
        side: BorderSide(color: Colors.grey.shade200, width: 2), // Bordure subtile
      ),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: _orangePrimary,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: _orangePrimary,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: _orangePrimary),
      shape: const Border(
        bottom: BorderSide(color: Colors.transparent, width: 0),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 6,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Plus arrondi
      ),
      backgroundColor: _orangePrimary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16), // Plus arrondi
        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _orangePrimary, width: 2.5),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Plus arrondi
        ),
        elevation: 3,
        shadowColor: _orangePrimary.withOpacity(0.3),
        backgroundColor: _orangePrimary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Plus arrondi
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade800,
      ),
      selectedColor: _orangePrimary,
      checkmarkColor: Colors.white,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Plus arrondi
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      tileColor: Colors.white,
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Très arrondi
      ),
      elevation: 8,
      backgroundColor: Colors.white,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: _orangePrimary, // Orange vif même en mode sombre
      secondary: _orangeSecondary,
      tertiary: _orangeDark,
      surface: const Color(0xFF1E1E1E), // Surface légèrement plus claire
      background: const Color(0xFF121212),
      error: Colors.red.shade400,
      // Texte sur orange : blanc pour être visible
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.white,
      // Containers pour meilleur contraste
      primaryContainer: _orangeDark.withOpacity(0.2),
      secondaryContainer: _orangeSecondary.withOpacity(0.15),
      onPrimaryContainer: Colors.white,
      onSecondaryContainer: Colors.white,
      surfaceVariant: const Color(0xFF2C2C2C),
      onSurfaceVariant: Colors.grey[300]!,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    // Typographie améliorée (même que light)
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: Colors.white),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: Colors.white),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        side: BorderSide(color: Colors.grey.shade700.withOpacity(0.5), width: 2),
      ),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1E1E1E),
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: _orangePrimary,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: _orangePrimary),
      shape: const Border(
        bottom: BorderSide(color: Colors.transparent, width: 0),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 6,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: _orangePrimary,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade600, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _orangePrimary, width: 2.5),
      ),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 3,
        shadowColor: _orangePrimary.withOpacity(0.4),
        backgroundColor: _orangePrimary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      backgroundColor: const Color(0xFF2C2C2C),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      selectedColor: _orangePrimary,
      checkmarkColor: Colors.white,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      tileColor: const Color(0xFF1E1E1E),
      textColor: Colors.white,
      iconColor: Colors.white,
    ),
    dialogBackgroundColor: const Color(0xFF1E1E1E),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      backgroundColor: const Color(0xFF1E1E1E),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      elevation: 8,
      backgroundColor: const Color(0xFF1E1E1E),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: _orangePrimary,
      unselectedItemColor: Colors.grey[500],
      selectedLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        color: Colors.grey[500],
        fontWeight: FontWeight.normal,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      indicatorColor: _orangePrimary.withOpacity(0.3),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return TextStyle(color: _orangePrimary, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: Colors.grey[500]!, fontWeight: FontWeight.normal);
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return IconThemeData(color: _orangePrimary);
        }
        return IconThemeData(color: Colors.grey[500]!);
      }),
    ),
  );
}

