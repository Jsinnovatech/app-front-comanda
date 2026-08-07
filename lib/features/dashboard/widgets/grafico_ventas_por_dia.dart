import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/dashboard_provider.dart';
import '../formato_dashboard.dart';

/// Barras de venta diaria armadas con Containers: sin librerias de charts,
/// suficiente para leer la tendencia de la semana de un vistazo.
class GraficoVentasPorDia extends StatelessWidget {
  final List<VentaDelDia> ventas;

  const GraficoVentasPorDia({super.key, required this.ventas});

  @override
  Widget build(BuildContext context) {
    final maximo = ventas.fold(0.0, (mayor, v) => v.total > mayor ? v.total : mayor);
    final hoy = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Pico  ${FormatoDashboard.soles(maximo)}',
              style: const TextStyle(
                fontFamily: AppTypography.mono,
                fontSize: 11,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ventas.map((venta) {
              final esHoy = venta.dia.day == hoy.day && venta.dia.month == hoy.month && venta.dia.year == hoy.year;
              final proporcion = maximo == 0 ? 0.0 : venta.total / maximo;
              return Expanded(
                child: _ColumnaDia(venta: venta, proporcion: proporcion, esHoy: esHoy),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ColumnaDia extends StatelessWidget {
  final VentaDelDia venta;
  final double proporcion;
  final bool esHoy;

  const _ColumnaDia({required this.venta, required this.proporcion, required this.esHoy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            venta.pedidos == 0 ? '-' : FormatoDashboard.entero(venta.pedidos),
            style: TextStyle(
              fontFamily: AppTypography.mono,
              fontSize: 10,
              color: venta.pedidos == 0 ? AppColors.line : AppColors.textDim,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, restricciones) {
                final alturaBarra = (restricciones.maxHeight * proporcion).clamp(3.0, restricciones.maxHeight);
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: alturaBarra,
                    decoration: BoxDecoration(
                      color: proporcion == 0
                          ? AppColors.line
                          : (esHoy ? AppColors.brass : AppColors.pine),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            FormatoDashboard.diaDeSemana(venta.dia),
            style: TextStyle(
              fontSize: 10,
              fontWeight: esHoy ? FontWeight.w700 : FontWeight.w400,
              color: esHoy ? AppColors.pine : AppColors.textDim,
            ),
          ),
          Text(
            FormatoDashboard.diaYMes(venta.dia),
            style: const TextStyle(fontFamily: AppTypography.mono, fontSize: 9, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}
