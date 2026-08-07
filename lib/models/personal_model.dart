class PersonalModel {
  final int id;
  final int restauranteId;
  final String nombre;
  final int tipoColaboradorId;
  final String tipoColaboradorCodigo;
  final bool activo;

  PersonalModel({
    required this.id,
    required this.restauranteId,
    required this.nombre,
    required this.tipoColaboradorId,
    required this.tipoColaboradorCodigo,
    required this.activo,
  });

  factory PersonalModel.fromJson(Map<String, dynamic> json) {
    return PersonalModel(
      id: json['id'],
      restauranteId: json['restaurante_id'],
      nombre: json['nombre'],
      tipoColaboradorId: json['tipo_colaborador_id'],
      tipoColaboradorCodigo: json['tipo_colaborador_codigo'],
      activo: json['activo'],
    );
  }
}

/// Sesion actual: lo que guarda AuthProvider tras un login exitoso (PIN o admin).
class SesionActual {
  final String accessToken;
  final int personalId;
  final String nombre;
  final String tipoColaborador;
  final int restauranteId;

  SesionActual({
    required this.accessToken,
    required this.personalId,
    required this.nombre,
    required this.tipoColaborador,
    required this.restauranteId,
  });

  bool get esAdmin => tipoColaborador == 'super_admin' || tipoColaborador == 'admin';
}
