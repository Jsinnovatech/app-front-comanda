import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../formato_dashboard.dart';

/// Como se cobro la plata del periodo. Replica la vista de ventas del
/// prototipo aprobado: total en tarjeta negra y un desglose por medio de pago
/// con barra proporcional al medio que mas recaudo.
class VentasPorMedioPago extends StatelessWidget {
  /// Montos por medio de pago normalizado: efectivo | tarjeta | yape_plin | otro.
  final Map<String, double> montosPorMedio;
  final String periodo;

  const VentasPorMedioPago({super.key, required this.montosPorMedio, required this.periodo});

  static const List<_MedioDePago> _medios = [
    _MedioDePago(clave: 'yape_plin', etiqueta: 'Yape / Plin', icono: '📱', color: AppColors.yellow),
    _MedioDePago(clave: 'efectivo', etiqueta: 'Efectivo', icono: '💵', color: AppColors.green),
    _MedioDePago(clave: 'tarjeta', etiqueta: 'Tarjeta', icono: '💳', color: AppColors.blue),
    _MedioDePago(clave: 'otro', etiqueta: 'Otro', icono: '🧾', color: AppColors.textDim),
  ];

  @override
  Widget build(BuildContext context) {
    final montos = {for (final medio in _medios) medio.clave: montosPorMedio[medio.clave] ?? 0.0};
    final total = montos.values.fold(0.0, (suma, monto) => suma + monto);
    final mayor = montos.values.fold(0.0, (tope, monto) => monto > tope ? monto : tope);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TotalCobrado(total: total, periodo: periodo),
        const SizedBox(height: 16),
        const Text(
          'Por medio de pago',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        const SizedBox(height: 10),
        ..._medios.map((medio) {
          final monto = montos[medio.clave] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _FilaMedioDePago(
              medio: medio,
              monto: monto,
              proporcionDelMayor: mayor == 0 ? 0 : monto / mayor,
              porcentajeDelTotal: total == 0 ? 0 : monto / total * 100,
            ),
          );
        }),
      ],
    );
  }
}

class _TotalCobrado extends StatelessWidget {
  final double total;
  final String periodo;

  const _TotalCobrado({required this.total, required this.periodo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            periodo.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              FormatoDashboard.soles(total),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.yellow),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Los cobros del mozo se suman aca en tiempo real',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMedioDePago extends StatelessWidget {
  final _MedioDePago medio;
  final double monto;
  final double proporcionDelMayor;
  final double porcentajeDelTotal;

  const _FilaMedioDePago({
    required this.medio,
    required this.monto,
    required this.proporcionDelMayor,
    required this.porcentajeDelTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${medio.icono} ${medio.etiqueta}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.black),
                ),
              ),
              Text(
                FormatoDashboard.soles(monto),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: proporcionDelMayor.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.gray,
              valueColor: AlwaysStoppedAnimation<Color>(medio.color),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${porcentajeDelTotal.toStringAsFixed(0)}% del total',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _MedioDePago {
  final String clave;
  final String etiqueta;
  final String icono;
  final Color color;

  const _MedioDePago({
    required this.clave,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });
}
