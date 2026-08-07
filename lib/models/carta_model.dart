class PlatoEnCartaModel {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? categoria;
  final String? fotoUrl;

  PlatoEnCartaModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.categoria,
    this.fotoUrl,
  });

  factory PlatoEnCartaModel.fromJson(Map<String, dynamic> json) {
    return PlatoEnCartaModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      precio: (json['precio'] as num).toDouble(),
      categoria: json['categoria'],
      fotoUrl: json['foto_url'],
    );
  }
}

class CartaModel {
  final int id;
  final int restauranteId;
  final String nombre;
  final String tipo; // 'diaria' | 'semanal'
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? fotoUrl;
  final bool activa;
  final List<PlatoEnCartaModel> platos;

  CartaModel({
    required this.id,
    required this.restauranteId,
    required this.nombre,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    this.fotoUrl,
    required this.activa,
    required this.platos,
  });

  factory CartaModel.fromJson(Map<String, dynamic> json) {
    return CartaModel(
      id: json['id'],
      restauranteId: json['restaurante_id'],
      nombre: json['nombre'],
      tipo: json['tipo'],
      fechaInicio: DateTime.parse(json['fecha_inicio']),
      fechaFin: DateTime.parse(json['fecha_fin']),
      fotoUrl: json['foto_url'],
      activa: json['activa'],
      platos: (json['platos'] as List<dynamic>? ?? [])
          .map((p) => PlatoEnCartaModel.fromJson(p))
          .toList(),
    );
  }
}
