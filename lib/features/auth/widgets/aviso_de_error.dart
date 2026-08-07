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
        color: AppColors.ember.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ember.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.ember, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(fontSize: 13, color: AppColors.ember, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
