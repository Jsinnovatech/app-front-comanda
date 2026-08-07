import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pastilla "Salir" para el AppBar, mismo patron que el prototipo aprobado
/// (`<Btn small kind="dark">Salir</Btn>`) - reemplaza el IconButton pelado
/// que no se distinguia de cualquier otro icono de la barra.
class BotonSalir extends StatelessWidget {
  final VoidCallback onPressed;

  const BotonSalir({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.yellow,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
        child: const Text('Salir'),
      ),
    );
  }
}
