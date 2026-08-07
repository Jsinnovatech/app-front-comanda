import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/mesa_model.dart';

/// Plano rapido del salon: cada mesa como ficha, ocupada en amarillo de marca,
/// libre en blanco con borde. Es el unico dato del dashboard que es "ahora mismo".
class PanelMesas extends StatelessWidget {
  final List<MesaModel> mesas;

  const PanelMesas({super.key, required this.mesas});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: mesas.map((mesa) {
        final ocupada = mesa.estado == 'ocupada';
        return Container(
          width: 64,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ocupada ? AppColors.yellow : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ocupada ? AppColors.yellow : AppColors.line, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mesa.numeroONombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ocupada ? 'ocupada' : 'libre',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: ocupada ? AppColors.black.withValues(alpha: 0.6) : AppColors.textDim,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
