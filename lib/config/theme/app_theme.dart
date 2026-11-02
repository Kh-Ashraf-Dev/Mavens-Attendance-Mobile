import 'package:flutter/material.dart';

class AppTheme {
  static const navy = Color(0xff131f46),
      blue = Color(0xff006cb7),
      ink = Color(0xff17253d),
      muted = Color(0xff6a7c86),
      background = Color(0xfff5f7fb);
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: 'Montserrat',
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      secondary: blue,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: ink,
      centerTitle: false,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: ink, height: 1.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xffe1e8f0)),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xffe1e8f0)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xffe2eef9),
    ),
  );
}
