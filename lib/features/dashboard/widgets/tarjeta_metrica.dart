import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tarjeta de una sola cifra: icono en cuadro suave, valor grande en peso 900
/// y etiqueta chica en gris. La variante `destacada` invierte a fondo negro
/// con el numero en amarillo, igual que la tarjeta de venta del dia.
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
    this.acento = AppColors.yellow,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    final fondo = destacada ? AppColors.black : AppColors.white;
    final fondoIcono = destacada ? AppColors.white.withValues(alpha: 0.12) : AppColors.yellowSoft;
    final colorIcono = destacada ? AppColors.yellow : acento;
    final colorTitulo = destacada ? AppColors.white.withValues(alpha: 0.6) : AppColors.textDim;
    final colorValor = destacada ? AppColors.yellow : AppColors.black;
    final colorDetalle = destacada ? AppColors.white.withValues(alpha: 0.7) : AppColors.textDim;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fondoIcono,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 18, color: colorIcono),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colorValor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colorTitulo,
            ),
          ),
          if (detalle != null) ...[
            const SizedBox(height: 2),
            Text(
              detalle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorDetalle),
            ),
          ],
        ],
      ),
    );
  }
}
