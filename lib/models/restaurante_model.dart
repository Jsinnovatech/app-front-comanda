class RestauranteModel {
  final int id;
  final String nombre;
  final String? fotoUrl;
  final int? superAdminId;
  final String modoAsignacionMesas; // 'estricto' | 'comodin'
  final String? ruc;
  final bool puedeEmitirBoleta;
  final bool puedeEmitirFactura;

  RestauranteModel({
    required this.id,
    required this.nombre,
    this.fotoUrl,
    this.superAdminId,
    required this.modoAsignacionMesas,
    this.ruc,
    required this.puedeEmitirBoleta,
    required this.puedeEmitirFactura,
  });

  factory RestauranteModel.fromJson(Map<String, dynamic> json) {
    return RestauranteModel(
      id: json['id'],
      nombre: json['nombre'],
      fotoUrl: json['foto_url'],
      superAdminId: json['super_admin_id'],
      modoAsignacionMesas: json['modo_asignacion_mesas'],
      ruc: json['ruc'],
      puedeEmitirBoleta: json['puede_emitir_boleta'],
      puedeEmitirFactura: json['puede_emitir_factura'],
    );
  }
}
