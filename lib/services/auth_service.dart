import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/personal_model.dart';

/// Unico service que sabe de /auth/*. Los 4 flujos: login PIN (mesero/
/// cocinero/cajero), login admin (email+password), solicitar reset y
/// resetear password.
class AuthService {
  static Future<SesionActual> loginPin({required String codigoAcceso}) async {
    final data = await ApiClient.post(
      ApiConfig.loginPin,
      conAuth: false,
      body: {'codigo_acceso': codigoAcceso},
    );
    return _sesionDesdeLogin(data);
  }

  static Future<SesionActual> loginAdmin({required String email, required String password}) async {
    final data = await ApiClient.post(
      ApiConfig.loginAdmin,
      conAuth: false,
      body: {'email': email, 'password': password},
    );
    return _sesionDesdeLogin(data);
  }

  static Future<String> solicitarReset({required String email}) async {
    final data = await ApiClient.post(ApiConfig.solicitarReset, conAuth: false, body: {'email': email});
    return data['message'];
  }

  static Future<String> resetearPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.resetearPassword,
      conAuth: false,
      body: {'email': email, 'codigo': codigo, 'nueva_password': nuevaPassword},
    );
    return data['message'];
  }

  static SesionActual _sesionDesdeLogin(Map<String, dynamic> data) {
    return SesionActual(
      accessToken: data['access_token'],
      personalId: data['personal_id'],
      restauranteId: data['restaurante_id'],
      nombre: data['nombre'],
      tipoColaborador: data['tipo_colaborador'],
    );
  }
}
