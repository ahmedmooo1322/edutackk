import 'package:flutter/material.dart';

ThemeData appTheme() {
  const surface = Color(0xFF10161D);
  const primary = Color(0xFF5DE0B8);
  final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark, surface: surface);
  return ThemeData(
    useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: const Color(0xFF080C10),
    fontFamily: 'sans', appBarTheme: const AppBarTheme(centerTitle: true, backgroundColor: Colors.transparent),
    cardTheme: CardThemeData(color: const Color(0xFF141C24), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF141C24), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
  );
}

