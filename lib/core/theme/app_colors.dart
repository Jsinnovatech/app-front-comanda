import 'package:flutter/material.dart';

/// Paleta oficial del rediseno: extraida 1:1 del prototipo funcional
/// (comanda-app.jsx) que el usuario aprobo como contrato de diseno.
/// No inventar tonos nuevos - todo tono usado en la UI sale de aca.
class AppColors {
  static const Color yellow = Color(0xFFF5B800);
  static const Color yellowSoft = Color(0xFFFFF3D1);
  static const Color black = Color(0xFF141414);
  static const Color gray = Color(0xFFF5F5F2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF22A45D);
  static const Color greenSoft = Color(0xFFE8F6EE);
  static const Color red = Color(0xFFE5484D);
  static const Color redSoft = Color(0xFFFDE8E9);
  static const Color blue = Color(0xFF4A7CF7);

  static const Color textDim = Color(0xFF888888);
  static const Color line = Color(0xFFEEEEEE);

  // Estados de comanda/item (mismos nombres que el backend, sin traducir)
  static const Color pendiente = red;
  static const Color enPreparacion = yellow;
  static const Color listo = green;
  static const Color servido = textDim;
  static const Color abierta = yellow;
  static const Color cerrada = textDim;
}
