import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/restaurante_model.dart';
import '../services/mantenimiento_service.dart';

/// Estado de la vista de plataforma del super_admin: la lista de todos los
/// restaurantes del sistema. "Entrar" a operar uno no vive aca - es una
/// accion de sesion (ver AuthProvider.entrarARestaurante), este provider
/// solo maneja la lista y su ciclo de vida (cargar/eliminar).
class PlataformaProvider extends ChangeNotifier {
  List<RestauranteModel> _restaurantes = [];
  bool _cargando = false;
  String? _error;

  List<RestauranteModel> get restaurantes => _restaurantes;
  bool get cargando => _cargando;
  String? get error => _error;

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
}
