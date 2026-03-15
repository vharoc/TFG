import 'package:flutter/material.dart';

class AppTheme{

  // COLORES
  static const Color ocre = Color(0xFFD4A843);
  static const Color piedra = Color(0xFFC49A6C);
  static const Color usal = Color(0xFFB5152B);
  static const Color fondo = Color(0xFFFAF3E0);

  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: ocre),
    scaffoldBackgroundColor: fondo,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );

}