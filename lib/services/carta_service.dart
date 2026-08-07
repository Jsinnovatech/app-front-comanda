import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/carta_model.dart';

class CartaService {
  static Future<CartaModel> crearCarta({
    required String nombre,
    required String tipo, // 'diaria' | 'semanal'
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required List<int> platoIds,
  }) async {
    final data = await ApiClient.post(ApiConfig.cartas, body: {
      'nombre': nombre,
      'tipo': tipo,
      'fecha_inicio': _fecha(fechaInicio),
      'fecha_fin': _fecha(fechaFin),
      'plato_ids': platoIds,
    });
    return CartaModel.fromJson(data);
  }

  static Future<List<CartaModel>> listarCartas() async {
    final data = await ApiClient.get(ApiConfig.cartas) as List<dynamic>;
    return data.map((c) => CartaModel.fromJson(c)).toList();
  }

  static Future<CartaModel> obtenerCarta(int id) async {
    final data = await ApiClient.get('${ApiConfig.cartas}/$id');
    return CartaModel.fromJson(data);
  }

  static Future<CartaModel> actualizarCarta(int id, Map<String, dynamic> cambios) async {
    final data = await ApiClient.put('${ApiConfig.cartas}/$id', body: cambios);
    return CartaModel.fromJson(data);
  }

  static Future<String> subirFotoCarta(int cartaId, Uint8List bytes, String nombreArchivo) async {
    final token = await ApiClient.obtenerToken();
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.cartas}/$cartaId/foto'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('foto', bytes, filename: nombreArchivo));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = response.body;
      return RegExp(r'"foto_url":"([^"]+)"').firstMatch(data)?.group(1) ?? '';
    }
    throw Exception('Error subiendo foto: ${response.statusCode}');
  }

  static String _fecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
