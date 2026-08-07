import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/comanda_model.dart';
import '../models/mesa_model.dart';
import '../models/plato_model.dart';
import '../services/comanda_service.dart';
import '../services/mantenimiento_service.dart';

/// Estado del salon para el mesero: que mesas hay, que comandas abiertas
/// cuelgan de cada una y cual esta viendo ahora. Las pantallas solo leen de
/// aca y disparan estos metodos: ninguna llama a un service por su cuenta.
class ComandaProvider extends ChangeNotifier {
  List<MesaModel> _mesas = [];
  List<ComandaModel> _comandasAbiertas = [];
  List<PlatoModel> _carta = [];
  ComandaModel? _comandaActiva;
  bool _cargando = false;
  String? _error;

  List<MesaModel> get mesas => _mesas;
  List<ComandaModel> get comandasAbiertas => _comandasAbiertas;
  List<PlatoModel> get carta => _carta;
  ComandaModel? get comandaActiva => _comandaActiva;
  bool get cargando => _cargando;
  String? get error => _error;

  /// Modo comodin: una misma mesa fisica puede tener varias comandas abiertas
  /// (familias distintas compartiendo mesa, cada una con su cuenta).
  List<ComandaModel> comandasDeMesa(int mesaId) {
    return _comandasAbiertas.where((c) => c.mesas.any((m) => m.id == mesaId)).toList();
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  /// Trae mesas y comandas abiertas juntas: sin las comandas no se sabe
  /// cuantas cuentas cuelgan de cada mesa, que es lo que pinta el tablero.
  Future<void> cargarMesas() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final mesas = await MantenimientoService.listarMesas();
      final comandas = await ComandaService.listarComandas(estado: 'abierta');
      _mesas = mesas;
      _comandasAbiertas = comandas;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo conectar con el servidor';
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> cargarCartaDisponible() async {
    if (_carta.isNotEmpty) return;
    try {
      _carta = await MantenimientoService.listarPlatos(disponible: true);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cargar la carta';
    }
    notifyListeners();
  }

  /// Devuelve la comanda creada, o null si el backend la rechazo (por ejemplo
  /// una segunda comanda sobre mesa ocupada en modo estricto). El mensaje del
  /// backend queda en [error] tal cual, sin reinterpretarlo.
  Future<ComandaModel?> abrirComanda(List<int> mesaIds, List<Map<String, dynamic>> items) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    ComandaModel? creada;
    try {
      creada = await ComandaService.abrirComanda(mesaIds: mesaIds, items: items);
      _comandaActiva = creada;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo abrir la comanda';
    }
    _cargando = false;
    notifyListeners();
    if (creada != null) await cargarMesas();
    return creada;
  }

  Future<void> cargarComanda(int comandaId) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _comandaActiva = await ComandaService.obtenerComanda(comandaId);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cargar la comanda';
    }
    _cargando = false;
    notifyListeners();
  }

  Future<bool> agregarItem(int comandaId, int platoId, int cantidad) async {
    _error = null;
    try {
      await ComandaService.agregarItem(comandaId, platoId: platoId, cantidad: cantidad);
      await cargarComanda(comandaId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo agregar el plato';
    }
    notifyListeners();
    return false;
  }

  Future<bool> marcarServido(int itemId) async {
    _error = null;
    try {
      final item = await ComandaService.marcarServido(itemId);
      await cargarComanda(item.comandaId);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo marcar como servido';
    }
    notifyListeners();
    return false;
  }

  Future<bool> cerrarComanda(int comandaId, String metodoPago) async {
    _error = null;
    try {
      _comandaActiva = await ComandaService.cerrarComanda(comandaId, metodoPago: metodoPago);
      await cargarMesas();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo cerrar la cuenta';
    }
    notifyListeners();
    return false;
  }
}
