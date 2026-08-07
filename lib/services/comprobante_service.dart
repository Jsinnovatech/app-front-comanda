import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/comprobante_model.dart';

class ComprobanteService {
  static Future<ComprobanteModel> emitir(
    int comandaId, {
    required String tipoSolicitado, // 'boleta' | 'factura'
    String? rucCliente,
  }) async {
    final data = await ApiClient.post(
      '${ApiConfig.comandas}/$comandaId/comprobante',
      body: {'tipo_solicitado': tipoSolicitado, if (rucCliente != null) 'ruc_cliente': rucCliente},
    );
    return ComprobanteModel.fromJson(data);
  }

  /// Devuelve null si la comanda todavia no tiene comprobante (404 esperado).
  static Future<ComprobanteModel?> obtenerPorComanda(int comandaId) async {
    try {
      final data = await ApiClient.get('${ApiConfig.comandas}/$comandaId/comprobante');
      return ComprobanteModel.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<ComprobanteModel> actualizarEstadoImpresion(int comprobanteId, String estadoImpresion) async {
    final data = await ApiClient.put(
      '${ApiConfig.comprobantes}/$comprobanteId/estado-impresion',
      body: {'estado_impresion': estadoImpresion},
    );
    return ComprobanteModel.fromJson(data);
  }
}
