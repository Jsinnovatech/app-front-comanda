class PlatoModel {
  final int id;
  final int restauranteId;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? categoria;
  final bool disponible;
  final String? fotoUrl;

  PlatoModel({
    required this.id,
    required this.restauranteId,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.categoria,
    required this.disponible,
    this.fotoUrl,
  });

  factory PlatoModel.fromJson(Map<String, dynamic> json) {
    return PlatoModel(
      id: json['id'],
      restauranteId: json['restaurante_id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      precio: (json['precio'] as num).toDouble(),
      categoria: json['categoria'],
      disponible: json['disponible'],
      fotoUrl: json['foto_url'],
    );
  }
}
