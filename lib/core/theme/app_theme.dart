import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Tipografia: serif con caracter de carta impresa para titulos, sans
/// del sistema para UI operativa, monoespaciada para datos de ticket
/// (precios, horas, numeros de comanda) - referencia directa a la
/// impresora termica de cocina, no decorativo.
class AppTypography {
  static const String display = 'Georgia';
  static const String mono = 'Courier New';
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.pine,
        onPrimary: Colors.white,
        secondary: AppColors.brass,
        surface: Colors.white,
        error: AppColors.ember,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: AppTypography.display, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(fontFamily: AppTypography.display, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontFamily: AppTypography.display, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pine,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pine,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
      ),
    );
  }
}
