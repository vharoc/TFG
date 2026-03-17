import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme{

  // COLORES
  static const Color ocre = Color(0xFFD4A843);
  static const Color piedra = Color(0xFFC49A6C);
  static const Color usal = Color(0xFFB5152B);
  static const Color fondo = Color(0xFFFAF3E0);

  static final TextStyle titulo = GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.bold);
  static final TextStyle cuerpo = GoogleFonts.lato(fontSize: 15);

  static ThemeData get theme => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: ocre),
    scaffoldBackgroundColor: fondo,
    useMaterial3: true,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 1),
      ),
    ),
  );

}