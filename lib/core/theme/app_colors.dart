import 'package:flutter/material.dart';

/// Tokens de color del prototipo: verde botella + laton + tinta.
/// Nada de azul-SaaS generico ni gradientes cian-naranja (referencia
/// descartada explicitamente por el look "hecho por IA").
class AppColors {
  static const Color ink = Color(0xFF1C1917);
  static const Color paper = Color(0xFFF6F1E7);
  static const Color pine = Color(0xFF2C4438);
  static const Color pineDark = Color(0xFF1E332A);
  static const Color brass = Color(0xFFC79A44);
  static const Color brassSoft = Color(0xFFE4CD98);
  static const Color ember = Color(0xFFB5482F);
  static const Color sage = Color(0xFF6B8F71);

  static const Color textDim = Color(0xFF6B645C);
  static const Color line = Color(0x1F1C1917);

  // Estados de comanda/item (mismos nombres que el backend, sin traducir)
  static const Color pendiente = ember;
  static const Color enPreparacion = Color(0xFF9C7420);
  static const Color listo = sage;
  static const Color servido = textDim;
  static const Color abierta = pine;
  static const Color cerrada = textDim;
}
