class ComprobanteModel {
  final int id;
  final int comandaId;
  final String tipo; // boleta | factura | nota_venta (lo decide el backend, no el frontend)
  final String? serie;
  final String? numero;
  final double montoTotal;
  final DateTime fechaEmision;
  final String estadoImpresion; // pendiente | impreso | error_impresora

  ComprobanteModel({
    required this.id,
    required this.comandaId,
    required this.tipo,
    this.serie,
    this.numero,
    required this.montoTotal,
    required this.fechaEmision,
    required this.estadoImpresion,
  });

  factory ComprobanteModel.fromJson(Map<String, dynamic> json) {
    return ComprobanteModel(
      id: json['id'],
      comandaId: json['comanda_id'],
      tipo: json['tipo'],
      serie: json['serie'],
      numero: json['numero'],
      montoTotal: (json['monto_total'] as num).toDouble(),
      fechaEmision: DateTime.parse(json['fecha_emision']),
      estadoImpresion: json['estado_impresion'],
    );
  }
}
