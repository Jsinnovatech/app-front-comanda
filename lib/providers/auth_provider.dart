import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/personal_model.dart';
import '../services/auth_service.dart';
import '../services/mantenimiento_service.dart';

const _sesionKey = 'sesion_actual';

/// Estado global de sesion: quien esta logueado, en que restaurante, con
/// que rol. Todas las pantallas leen esto via Provider.of/context.watch,
/// nunca guardan su propia copia de "quien soy".
class AuthProvider extends ChangeNotifier {
  SesionActual? _sesion;
  // Cuando un super_admin de plataforma "entra" a operar un restaurante
  // especifico, aca queda la sesion de plataforma original para poder
  // volver. Solo vive en memoria (no se persiste): un refresh de pagina
  // mientras se esta "dentro" de un restaurante no la recupera.
  SesionActual? _sesionPlataforma;
  bool _cargando = true;

  SesionActual? get sesion => _sesion;
  bool get cargando => _cargando;
  bool get autenticado => _sesion != null;
  bool get enModoPlataforma => _sesionPlataforma != null;

  AuthProvider() {
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final guardada = prefs.getString(_sesionKey);
    if (guardada != null) {
      final json = jsonDecode(guardada);
      _sesion = SesionActual(
        accessToken: json['access_token'],
        personalId: json['personal_id'],
        restauranteId: json['restaurante_id'],
        nombre: json['nombre'],
        tipoColaborador: json['tipo_colaborador'],
      );
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> _guardarSesionEnDisco(SesionActual sesion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sesionKey,
      jsonEncode({
        'access_token': sesion.accessToken,
        'personal_id': sesion.personalId,
        'restaurante_id': sesion.restauranteId,
        'nombre': sesion.nombre,
        'tipo_colaborador': sesion.tipoColaborador,
      }),
    );
  }

  Future<void> loginPin({required String codigoAcceso}) async {
    final sesion = await AuthService.loginPin(codigoAcceso: codigoAcceso);
    await ApiClient.guardarToken(sesion.accessToken);
    await _guardarSesionEnDisco(sesion);
    _sesion = sesion;
    notifyListeners();
  }

  /// [recordar] en false: el token igual se guarda (las llamadas de esta
  /// sesion necesitan Authorization), pero la sesion nunca se escribe en
  /// SharedPreferences - un refresh de pagina vuelve al login. Pensado para
  /// dispositivos compartidos donde el admin no quiere dejar su cuenta abierta.
  Future<void> loginAdmin({required String email, required String password, bool recordar = true}) async {
    final sesion = await AuthService.loginAdmin(email: email, password: password);
    await ApiClient.guardarToken(sesion.accessToken);
    if (recordar) await _guardarSesionEnDisco(sesion);
    _sesion = sesion;
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await ApiClient.limpiarToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sesionKey);
    _sesion = null;
    _sesionPlataforma = null;
    notifyListeners();
  }

  /// super_admin de plataforma entra a operar un restaurante: guarda la
  /// sesion actual como "de plataforma" y activa la nueva, escaneada a ese
  /// restaurante. El resto de la app (Mantenimiento/Dashboard) no cambia,
  /// sigue leyendo `sesion.restauranteId` como siempre.
  Future<void> entrarARestaurante(int restauranteId) async {
    final sesionEscaneada = await MantenimientoService.entrarARestaurante(restauranteId);
    _sesionPlataforma = _sesion;
    await ApiClient.guardarToken(sesionEscaneada.accessToken);
    await _guardarSesionEnDisco(sesionEscaneada);
    _sesion = sesionEscaneada;
    notifyListeners();
  }

  /// Vuelve de operar un restaurante especifico a la vista de plataforma.
  Future<void> volverAPlataforma() async {
    final plataforma = _sesionPlataforma;
    if (plataforma == null) return;
    await ApiClient.guardarToken(plataforma.accessToken);
    await _guardarSesionEnDisco(plataforma);
    _sesion = plataforma;
    _sesionPlataforma = null;
    notifyListeners();
  }
}
