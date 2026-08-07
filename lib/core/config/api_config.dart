/// Unica fuente de verdad de URLs del backend. Ningun service adivina rutas
/// ni prueba variantes - el bug real que encontramos en Casta de Gallos
/// (admin_service.dart probaba 5 URLs distintas por endpoint) no se repite aqui.
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';

  // Auth
  static const String loginPin = '$baseUrl/auth/login';
  static const String loginAdmin = '$baseUrl/auth/login-admin';
  static const String solicitarReset = '$baseUrl/auth/solicitar-reset';
  static const String resetearPassword = '$baseUrl/auth/resetear-password';

  // Mantenimiento
  static const String restaurantes = '$baseUrl/api/v1/restaurantes';
  static const String personal = '$baseUrl/api/v1/personal';
  static const String mesas = '$baseUrl/api/v1/mesas';
  static const String platos = '$baseUrl/api/v1/platos';

  // Cartas
  static const String cartas = '$baseUrl/api/v1/cartas';

  // Comandas
  static const String comandas = '$baseUrl/api/v1/comandas';
  static const String cocinaItemsPendientes = '$baseUrl/api/v1/cocina/items-pendientes';
  static const String comandaItems = '$baseUrl/api/v1/comanda-items';

  // Comprobantes
  static const String comprobantes = '$baseUrl/api/v1/comprobantes';

  // Publico (sin login)
  static const String publicoRestaurantes = '$baseUrl/api/v1/public/restaurantes';
}
