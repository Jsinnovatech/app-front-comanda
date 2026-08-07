class MesaModel {
  final int id;
  final int restauranteId;
  final String numeroONombre;
  final String estado; // 'libre' | 'ocupada'

  MesaModel({
    required this.id,
    required this.restauranteId,
    required this.numeroONombre,
    required this.estado,
  });

  factory MesaModel.fromJson(Map<String, dynamic> json) {
    return MesaModel(
      id: json['id'],
      restauranteId: json['restaurante_id'],
      numeroONombre: json['numero_o_nombre'],
      estado: json['estado'],
    );
  }
}
