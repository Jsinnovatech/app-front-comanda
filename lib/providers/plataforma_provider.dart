import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/restaurante_model.dart';
import '../models/restaurante_resumen_model.dart';
import '../services/mantenimiento_service.dart';

/// Estado de la vista de plataforma del super_admin: la lista de todos los
/// restaurantes del sistema. "Entrar" a operar uno no vive aca - es una
/// accion de sesion (ver AuthProvider.entrarARestaurante), este provider
/// solo maneja la lista y su ciclo de vida (cargar/eliminar).
class PlataformaProvider extends ChangeNotifier {
  List<RestauranteModel> _restaurantes = [];
  bool _cargando = false;
  String? _error;

  // Resumen (admins + conteos) por restaurante_id: se pide solo al expandir
  // el acordeon de esa tarjeta, no de entrada para toda la lista.
  final Map<int, RestauranteResumenModel> _resumenes = {};
  final Set<int> _cargandoResumen = {};

  List<RestauranteModel> get restaurantes => _restaurantes;
  bool get cargando => _cargando;
  String? get error => _error;

  RestauranteResumenModel? resumenDe(int restauranteId) => _resumenes[restauranteId];
  bool cargandoResumenDe(int restauranteId) => _cargandoResumen.contains(restauranteId);

  Future<void> cargarResumen(int restauranteId) async {
    if (_resumenes.containsKey(restauranteId) || _cargandoResumen.contains(restauranteId)) return;
    _cargandoResumen.add(restauranteId);
    notifyListeners();
    try {
      _resumenes[restauranteId] = await MantenimientoService.obtenerResumenRestaurante(restauranteId);
    } catch (_) {
      // Sin resumen disponible: la tarjeta expandida muestra el aviso de
      // error, no hace falta un campo _error global para esto.
    }
    _cargandoResumen.remove(restauranteId);
    notifyListeners();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  Future<void> cargarRestaurantes() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _restaurantes = await MantenimientoService.listarRestaurantes();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo conectar con el servidor';
    }
    _cargando = false;
    notifyListeners();
  }

  Future<bool> eliminarRestaurante(int id) async {
    _error = null;
    try {
      await MantenimientoService.eliminarRestaurante(id);
      _restaurantes = _restaurantes.where((r) => r.id != id).toList();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo eliminar el restaurante';
    }
    notifyListeners();
    return false;
  }

  /// Crea un restaurante nuevo con su super_admin. Usa el mismo endpoint
  /// publico de registro (POST /restaurantes) que el auto-registro, pero el
  /// token que devuelve se descarta - quien crea esto ya esta logueado como
  /// super_admin de plataforma y debe seguir siendolo, no pasar a ser el
  /// super_admin del restaurante nuevo.
  Future<bool> crearRestaurante({
    required String nombre,
    required String nombreSuperAdmin,
    required String emailSuperAdmin,
    required String passwordSuperAdmin,
  }) async {
    _error = null;
    try {
      await MantenimientoService.registrarRestaurante(
        nombre: nombre,
        nombreSuperAdmin: nombreSuperAdmin,
        emailSuperAdmin: emailSuperAdmin,
        passwordSuperAdmin: passwordSuperAdmin,
      );
      await cargarRestaurantes();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo crear el restaurante';
    }
    notifyListeners();
    return false;
  }
}
