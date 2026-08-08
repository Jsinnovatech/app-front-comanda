import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/restaurante_model.dart';
import '../models/personal_model.dart';
import '../models/mesa_model.dart';
import '../models/plato_model.dart';

/// Unico service para /api/v1/restaurantes, /personal, /mesas, /platos.
/// Cubre tanto lectura (mesero/cocinero necesitan ver mesas y platos) como
/// escritura (super_admin/admin, modulo Mantenimiento).
class MantenimientoService {
  // ---------------- Restaurante ----------------

  static Future<SesionActual> registrarRestaurante({
    required String nombre,
    String? fotoUrl,
    required String nombreSuperAdmin,
    required String emailSuperAdmin,
    required String passwordSuperAdmin,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.restaurantes,
      conAuth: false,
      body: {
        'nombre': nombre,
        'foto_url': fotoUrl,
        'nombre_super_admin': nombreSuperAdmin,
        'email_super_admin': emailSuperAdmin,
        'password_super_admin': passwordSuperAdmin,
      },
    );
    return SesionActual(
      accessToken: data['access_token'],
      personalId: data['personal_id'],
      restauranteId: data['restaurante']['id'],
      nombre: data['nombre'],
      tipoColaborador: data['tipo_colaborador'],
    );
  }

  /// Panel de plataforma (super_admin): todos los restaurantes activos.
  static Future<List<RestauranteModel>> listarRestaurantes() async {
    final data = await ApiClient.get(ApiConfig.restaurantes) as List<dynamic>;
    return data.map((r) => RestauranteModel.fromJson(r)).toList();
  }

  /// super_admin "entra" a operar un restaurante especifico: el backend
  /// mintea un token nuevo escaneado a ese restaurante_id. La sesion de
  /// plataforma original la conserva AuthProvider para poder volver.
  static Future<SesionActual> entrarARestaurante(int id) async {
    final data = await ApiClient.post('${ApiConfig.restaurantes}/$id/entrar');
    return SesionActual(
      accessToken: data['access_token'],
      personalId: data['personal_id'],
      restauranteId: data['restaurante_id'],
      nombre: data['nombre'],
      tipoColaborador: data['tipo_colaborador'],
    );
  }

  /// Soft delete: el backend desactiva, no borra (hay comprobantes fiscales
  /// ligados que deben conservarse).
  static Future<void> eliminarRestaurante(int id) async {
    await ApiClient.delete('${ApiConfig.restaurantes}/$id');
  }

  static Future<RestauranteModel> obtenerRestaurante(int id) async {
    final data = await ApiClient.get('${ApiConfig.restaurantes}/$id');
    return RestauranteModel.fromJson(data);
  }

  static Future<RestauranteModel> actualizarRestaurante(int id, Map<String, dynamic> cambios) async {
    final data = await ApiClient.put('${ApiConfig.restaurantes}/$id', body: cambios);
    return RestauranteModel.fromJson(data);
  }

  static Future<RestauranteModel> subirFotoRestaurante(int id, Uint8List bytes, String nombreArchivo) async {
    final token = await ApiClient.obtenerToken();
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.restaurantes}/$id/foto'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(http.MultipartFile.fromBytes('foto', bytes, filename: nombreArchivo));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return RestauranteModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error subiendo foto: ${response.statusCode}');
  }

  // ---------------- Personal ----------------

  static Future<PersonalModel> crearPersonal({
    required String nombre,
    required String tipoColaboradorCodigo,
    String? codigoAcceso,
    String? email,
    String? password,
  }) async {
    final data = await ApiClient.post(ApiConfig.personal, body: {
      'nombre': nombre,
      'tipo_colaborador_codigo': tipoColaboradorCodigo,
      if (codigoAcceso != null) 'codigo_acceso': codigoAcceso,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
    });
    return PersonalModel.fromJson(data);
  }

  static Future<List<PersonalModel>> listarPersonal() async {
    final data = await ApiClient.get(ApiConfig.personal) as List<dynamic>;
    return data.map((p) => PersonalModel.fromJson(p)).toList();
  }

  static Future<PersonalModel> actualizarPersonal(int id, Map<String, dynamic> cambios) async {
    final data = await ApiClient.put('${ApiConfig.personal}/$id', body: cambios);
    return PersonalModel.fromJson(data);
  }

  // ---------------- Mesas ----------------

  static Future<MesaModel> crearMesa(String numeroONombre) async {
    final data = await ApiClient.post(ApiConfig.mesas, body: {'numero_o_nombre': numeroONombre});
    return MesaModel.fromJson(data);
  }

  static Future<List<MesaModel>> listarMesas() async {
    final data = await ApiClient.get(ApiConfig.mesas) as List<dynamic>;
    return data.map((m) => MesaModel.fromJson(m)).toList();
  }

  static Future<MesaModel> actualizarMesa(int id, Map<String, dynamic> cambios) async {
    final data = await ApiClient.put('${ApiConfig.mesas}/$id', body: cambios);
    return MesaModel.fromJson(data);
  }

  // ---------------- Platos ----------------

  static Future<PlatoModel> crearPlato({
    required String nombre,
    String? descripcion,
    required double precio,
    String? categoria,
    bool disponible = true,
  }) async {
    final data = await ApiClient.post(ApiConfig.platos, body: {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'categoria': categoria,
      'disponible': disponible,
    });
    return PlatoModel.fromJson(data);
  }

  static Future<List<PlatoModel>> listarPlatos({bool? disponible}) async {
    final query = disponible != null ? '?disponible=$disponible' : '';
    final data = await ApiClient.get('${ApiConfig.platos}$query') as List<dynamic>;
    return data.map((p) => PlatoModel.fromJson(p)).toList();
  }

  static Future<PlatoModel> actualizarPlato(int id, Map<String, dynamic> cambios) async {
    final data = await ApiClient.put('${ApiConfig.platos}/$id', body: cambios);
    return PlatoModel.fromJson(data);
  }

  static Future<String> subirFotoPlato(int platoId, Uint8List bytes, String nombreArchivo) async {
    final token = await ApiClient.obtenerToken();
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.platos}/$platoId/foto'));
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
}
