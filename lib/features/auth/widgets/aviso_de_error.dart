import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Muestra el mensaje real que devolvio el backend (ApiException.message),
/// nunca un texto generico: si el backend dice "Codigo ya usado", eso lee
/// el usuario.
class AvisoDeError extends StatelessWidget {
  final String mensaje;

  const AvisoDeError({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 13, color: AppColors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
