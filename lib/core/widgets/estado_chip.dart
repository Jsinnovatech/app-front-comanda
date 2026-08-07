import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Chip de estado de comanda/item: mismo patron que ESTADO_CFG del
/// prototipo aprobado (pendiente=rojo, en_preparacion=amarillo, listo=verde).
class EstadoChip extends StatelessWidget {
  final String estado;

  const EstadoChip({super.key, required this.estado});

  static const _config = {
    'pendiente': (AppColors.red, Colors.white, '👨‍🍳 En Cocina'),
    'en_preparacion': (AppColors.yellow, AppColors.black, '🔥 Preparando'),
    'listo': (AppColors.green, Colors.white, '✅ ¡Listo!'),
    'servido': (AppColors.textDim, Colors.white, '🍽️ Servido'),
    'abierta': (AppColors.yellow, AppColors.black, 'Abierta'),
    'pagada': (AppColors.green, Colors.white, 'Pagada'),
    'cerrada': (AppColors.textDim, Colors.white, 'Cerrada'),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _config[estado] ?? (AppColors.textDim, Colors.white, estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

/// Badge circular rojo de conteo, como el numero de items en una mesa
/// ocupada del tablero.
class BadgeConteo extends StatelessWidget {
  final int cantidad;

  const BadgeConteo({super.key, required this.cantidad});

  @override
  Widget build(BuildContext context) {
    if (cantidad <= 0) return const SizedBox.shrink();
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$cantidad',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }
}
