import '../core/utils/json_parsers.dart';

class MesaResumenModel {
  final int id;
  final String numeroONombre;

  MesaResumenModel({required this.id, required this.numeroONombre});

  factory MesaResumenModel.fromJson(Map<String, dynamic> json) {
    return MesaResumenModel(id: json['id'], numeroONombre: json['numero_o_nombre']);
  }
}

class ComandaItemModel {
  final int id;
  final int comandaId;
  final int platoId;
  final String? platoNombre;
  final double? platoPrecio;
  final int cantidad;
  final String estado; // pendiente | en_preparacion | listo | servido
  final int? cocineroId;
  final String? cocineroNombre;
  final int? meseroIdEntrega;
  final DateTime? horaTomado;
  final DateTime? horaListo;
  final DateTime? horaServido;

  ComandaItemModel({
    required this.id,
    required this.comandaId,
    required this.platoId,
    this.platoNombre,
    this.platoPrecio,
    required this.cantidad,
    required this.estado,
    this.cocineroId,
    this.cocineroNombre,
    this.meseroIdEntrega,
    this.horaTomado,
    this.horaListo,
    this.horaServido,
  });

  factory ComandaItemModel.fromJson(Map<String, dynamic> json) {
    return ComandaItemModel(
      id: json['id'],
      comandaId: json['comanda_id'],
      platoId: json['plato_id'],
      platoNombre: json['plato_nombre'],
      platoPrecio: json['plato_precio'] != null ? aDouble(json['plato_precio']) : null,
      cantidad: json['cantidad'],
      estado: json['estado'],
      cocineroId: json['cocinero_id'],
      cocineroNombre: json['cocinero_nombre'],
      meseroIdEntrega: json['mesero_id_entrega'],
      horaTomado: json['hora_tomado'] != null ? DateTime.parse(json['hora_tomado']) : null,
      horaListo: json['hora_listo'] != null ? DateTime.parse(json['hora_listo']) : null,
      horaServido: json['hora_servido'] != null ? DateTime.parse(json['hora_servido']) : null,
    );
  }
}

class ComandaModel {
  final int id;
  final int restauranteId;
  final int meseroId;
  final String estado; // abierta | pagada | cerrada
  final int? calificacion;
  final DateTime fechaApertura;
  final DateTime? fechaCierre;
  final List<MesaResumenModel> mesas;
  final List<ComandaItemModel> items;
  final double total;

  ComandaModel({
    required this.id,
    required this.restauranteId,
    required this.meseroId,
    required this.estado,
    this.calificacion,
    required this.fechaApertura,
    this.fechaCierre,
    required this.mesas,
    required this.items,
    required this.total,
  });

  factory ComandaModel.fromJson(Map<String, dynamic> json) {
    return ComandaModel(
      id: json['id'],
      restauranteId: json['restaurante_id'],
      meseroId: json['mesero_id'],
      estado: json['estado'],
      calificacion: json['calificacion'],
      fechaApertura: DateTime.parse(json['fecha_apertura']),
      fechaCierre: json['fecha_cierre'] != null ? DateTime.parse(json['fecha_cierre']) : null,
      mesas: (json['mesas'] as List<dynamic>? ?? []).map((m) => MesaResumenModel.fromJson(m)).toList(),
      items: (json['items'] as List<dynamic>? ?? []).map((i) => ComandaItemModel.fromJson(i)).toList(),
      total: aDouble(json['total']),
    );
  }
}

/// Fila de la cola de cocina: el item mas el contexto de mesa (distinto shape
/// que ComandaItemModel - `mesas` aca es una lista de strings, no de objetos).
class ItemCocinaModel {
  final int id;
  final int comandaId;
  final int platoId;
  final String platoNombre;
  final int cantidad;
  final String estado;
  final int? cocineroId;
  final String? cocineroNombre;
  final DateTime? horaTomado;
  final List<String> mesas;

  ItemCocinaModel({
    required this.id,
    required this.comandaId,
    required this.platoId,
    required this.platoNombre,
    required this.cantidad,
    required this.estado,
    this.cocineroId,
    this.cocineroNombre,
    this.horaTomado,
    required this.mesas,
  });

  factory ItemCocinaModel.fromJson(Map<String, dynamic> json) {
    return ItemCocinaModel(
      id: json['id'],
      comandaId: json['comanda_id'],
      platoId: json['plato_id'],
      platoNombre: json['plato_nombre'],
      cantidad: json['cantidad'],
      estado: json['estado'],
      cocineroId: json['cocinero_id'],
      cocineroNombre: json['cocinero_nombre'],
      horaTomado: json['hora_tomado'] != null ? DateTime.parse(json['hora_tomado']) : null,
      mesas: (json['mesas'] as List<dynamic>? ?? []).map((m) => m.toString()).toList(),
    );
  }
}
