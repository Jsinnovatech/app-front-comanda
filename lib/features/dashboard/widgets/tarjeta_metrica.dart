import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Tarjeta grande de una sola cifra. El numero va en monoespaciada porque en
/// esta app todo dato duro se lee como impresion de ticket.
class TarjetaMetrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final String? detalle;
  final IconData icono;
  final Color acento;
  final bool destacada;

  const TarjetaMetrica({
    super.key,
    required this.titulo,
    required this.valor,
    this.detalle,
    required this.icono,
    this.acento = AppColors.pine,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    final fondo = destacada ? AppColors.pine : Colors.white;
    final colorTitulo = destacada ? AppColors.brassSoft : AppColors.textDim;
    final colorValor = destacada ? Colors.white : AppColors.ink;
    final colorDetalle = destacada ? AppColors.brassSoft : AppColors.textDim;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: destacada ? AppColors.pineDark : AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icono, size: 16, color: destacada ? AppColors.brass : acento),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  titulo.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                    color: colorTitulo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                fontFamily: AppTypography.mono,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: colorValor,
              ),
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 4),
            Text(
              detalle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colorDetalle),
            ),
          ],
        ],
      ),
    );
  }
}
