import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/carta_model.dart';
import '../services/carta_service.dart';

/// Estado de las cartas del restaurante. Separado de `MantenimientoProvider`
/// porque una carta no es una maestra mas: agrupa platos ya existentes y
/// tiene vigencia (diaria/semanal), asi que se recarga con otra frecuencia.
class CartaProvider extends ChangeNotifier {
  List<CartaModel> _cartas = [];
  bool _cargando = false;
  String? _error;

  List<CartaModel> get cartas => _cartas;
  bool get cargando => _cargando;
  String? get error => _error;

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  Future<void> cargarCartas() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _cartas = await CartaService.listarCartas();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Devuelve la carta creada para que el formulario pueda subirle la foto
  /// de portada recien despues de conocer su `id`.
  Future<CartaModel?> crearCarta({
    required String nombre,
    required String tipo,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required List<int> platoIds,
  }) async {
    return _ejecutar(() async {
      final creada = await CartaService.crearCarta(
        nombre: nombre,
        tipo: tipo,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        platoIds: platoIds,
      );
      _cartas = [..._cartas, creada];
      return creada;
    });
  }

  Future<bool> actualizarCarta(int id, Map<String, dynamic> cambios) async {
    final actualizada = await _ejecutar(() async {
      final carta = await CartaService.actualizarCarta(id, cambios);
      _reemplazarCarta(carta);
      return carta;
    });
    return actualizada != null;
  }

  Future<bool> subirFotoCarta(int cartaId, Uint8List bytes, String nombreArchivo) async {
    final url = await _ejecutar(() => CartaService.subirFotoCarta(cartaId, bytes, nombreArchivo));
    if (url == null) return false;
    final actual = _cartas.firstWhere((c) => c.id == cartaId);
    _reemplazarCarta(CartaModel(
      id: actual.id,
      restauranteId: actual.restauranteId,
      nombre: actual.nombre,
      tipo: actual.tipo,
      fechaInicio: actual.fechaInicio,
      fechaFin: actual.fechaFin,
      fotoUrl: url,
      activa: actual.activa,
      platos: actual.platos,
    ));
    notifyListeners();
    return true;
  }

  void _reemplazarCarta(CartaModel carta) {
    final indice = _cartas.indexWhere((c) => c.id == carta.id);
    if (indice == -1) return;
    _cartas[indice] = carta;
  }

  Future<T?> _ejecutar<T>(Future<T> Function() accion) async {
    _error = null;
    try {
      final resultado = await accion();
      notifyListeners();
      return resultado;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
