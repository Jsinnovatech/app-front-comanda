import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/mesa_model.dart';

/// Plano rapido del salon: cada mesa como ficha, ocupada en verde botella,
/// libre en papel. Es el unico dato del dashboard que es "ahora mismo".
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
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ocupada ? AppColors.pine : AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ocupada ? AppColors.pineDark : AppColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mesa.numeroONombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTypography.mono,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ocupada ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ocupada ? 'ocupada' : 'libre',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 0.4,
                  color: ocupada ? AppColors.brassSoft : AppColors.textDim,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
