import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class FilaRanking {
  final String etiqueta;
  final String detalle;
  final String valor;
  final double proporcion;

  FilaRanking({
    required this.etiqueta,
    required this.detalle,
    required this.valor,
    required this.proporcion,
  });
}

/// Lista ordenada con barra de proporcion detras del nombre. La usan tanto el
/// top de platos como el ranking de meseros: misma lectura, distinta fuente.
class TablaRanking extends StatelessWidget {
  final List<FilaRanking> filas;

  const TablaRanking({super.key, required this.filas});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(filas.length, (indice) {
        final fila = filas[indice];
        return Padding(
          padding: EdgeInsets.only(bottom: indice == filas.length - 1 ? 0 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Medalla(posicion: indice + 1),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fila.etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: fila.proporcion.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: AppColors.paper,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          indice == 0 ? AppColors.brass : AppColors.sage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fila.valor,
                    style: const TextStyle(
                      fontFamily: AppTypography.mono,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    fila.detalle,
                    style: const TextStyle(
                      fontFamily: AppTypography.mono,
                      fontSize: 10,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Medalla extends StatelessWidget {
  final int posicion;

  const _Medalla({required this.posicion});

  @override
  Widget build(BuildContext context) {
    final esPodio = posicion <= 3;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: esPodio ? AppColors.pine : AppColors.paper,
        shape: BoxShape.circle,
        border: Border.all(color: esPodio ? AppColors.pine : AppColors.line),
      ),
      child: Text(
        '$posicion',
        style: TextStyle(
          fontFamily: AppTypography.mono,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: esPodio ? AppColors.brassSoft : AppColors.textDim,
        ),
      ),
    );
  }
}
