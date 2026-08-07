import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/comanda_model.dart';

class ComandaService {
  static Future<ComandaModel> abrirComanda({
    required List<int> mesaIds,
    List<Map<String, dynamic>> items = const [],
  }) async {
    final data = await ApiClient.post(ApiConfig.comandas, body: {'mesa_ids': mesaIds, 'items': items});
    return ComandaModel.fromJson(data);
  }

  static Future<List<ComandaModel>> listarComandas({String? estado}) async {
    final query = estado != null ? '?estado=$estado' : '';
    final data = await ApiClient.get('${ApiConfig.comandas}$query') as List<dynamic>;
    return data.map((c) => ComandaModel.fromJson(c)).toList();
  }

  static Future<ComandaModel> obtenerComanda(int id) async {
    final data = await ApiClient.get('${ApiConfig.comandas}/$id');
    return ComandaModel.fromJson(data);
  }

  static Future<ComandaItemModel> agregarItem(int comandaId, {required int platoId, required int cantidad}) async {
    final data = await ApiClient.post(
      '${ApiConfig.comandas}/$comandaId/items',
      body: {'plato_id': platoId, 'cantidad': cantidad},
    );
    return ComandaItemModel.fromJson(data);
  }

  static Future<ComandaModel> cerrarComanda(int comandaId, {required String metodoPago}) async {
    final data = await ApiClient.post('${ApiConfig.comandas}/$comandaId/cerrar', body: {'metodo_pago': metodoPago});
    return ComandaModel.fromJson(data);
  }

  // ---------------- Cocina ----------------

  static Future<List<ItemCocinaModel>> itemsPendientesCocina() async {
    final data = await ApiClient.get(ApiConfig.cocinaItemsPendientes) as List<dynamic>;
    return data.map((i) => ItemCocinaModel.fromJson(i)).toList();
  }

  static Future<ComandaItemModel> tomarItem(int itemId, {required String codigoAcceso}) async {
    final data = await ApiClient.post(
      '${ApiConfig.comandaItems}/$itemId/tomar',
      body: {'codigo_acceso': codigoAcceso},
    );
    return ComandaItemModel.fromJson(data);
  }

  static Future<ComandaItemModel> marcarListo(int itemId) async {
    final data = await ApiClient.post('${ApiConfig.comandaItems}/$itemId/marcar-listo');
    return ComandaItemModel.fromJson(data);
  }

  static Future<ComandaItemModel> marcarServido(int itemId) async {
    final data = await ApiClient.post('${ApiConfig.comandaItems}/$itemId/marcar-servido');
    return ComandaItemModel.fromJson(data);
  }
}
