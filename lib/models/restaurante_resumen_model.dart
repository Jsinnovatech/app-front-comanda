class AdminResumenModel {
  final String nombre;
  final String? email;

  AdminResumenModel({required this.nombre, this.email});

  factory AdminResumenModel.fromJson(Map<String, dynamic> json) {
    return AdminResumenModel(nombre: json['nombre'], email: json['email']);
  }
}

/// Panel de plataforma: quien administra un restaurante y cuanto personal
/// operativo tiene. Se carga solo al expandir su acordeon, no de entrada.
class RestauranteResumenModel {
  final List<AdminResumenModel> admins;
  final int mesas;
  final int meseros;
  final int cocineros;
  final int cajeros;

  RestauranteResumenModel({
    required this.admins,
    required this.mesas,
    required this.meseros,
    required this.cocineros,
    required this.cajeros,
  });

  factory RestauranteResumenModel.fromJson(Map<String, dynamic> json) {
    return RestauranteResumenModel(
      admins: (json['admins'] as List<dynamic>? ?? [])
          .map((a) => AdminResumenModel.fromJson(a))
          .toList(),
      mesas: json['mesas'] ?? 0,
      meseros: json['meseros'] ?? 0,
      cocineros: json['cocineros'] ?? 0,
      cajeros: json['cajeros'] ?? 0,
    );
  }
}
