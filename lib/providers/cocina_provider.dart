import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/comanda_model.dart';
import '../services/comanda_service.dart';

/// Cola de cocina: items en `pendiente` y `en_preparacion` del restaurante.
/// Una vez que un item pasa a `listo` deja de ser responsabilidad de cocina,
/// pero se conserva en la lista hasta el siguiente refresco para que el
/// cocinero vea el aviso de "avisar mesero".
class CocinaProvider extends ChangeNotifier {
  List<ItemCocinaModel> _items = [];
  bool _cargando = false;
  String? _error;

  List<ItemCocinaModel> get items => _items;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarItemsPendientes() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _items = await ComandaService.itemsPendientesCocina();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// El PIN es el del cocinero que toma ESTE item, no el del dispositivo:
  /// el tablet esta logueado como "cocinero" generico y sin el PIN no se
  /// sabria quien se hizo cargo del plato.
  Future<bool> tomarItem(int itemId, String codigoAcceso) async {
    return _aplicarCambioDeEstado(itemId, () => ComandaService.tomarItem(itemId, codigoAcceso: codigoAcceso));
  }

  Future<bool> marcarListo(int itemId) async {
    return _aplicarCambioDeEstado(itemId, () => ComandaService.marcarListo(itemId));
  }

  Future<bool> _aplicarCambioDeEstado(int itemId, Future<ComandaItemModel> Function() accion) async {
    _error = null;
    try {
      final actualizado = await accion();
      _reemplazarItem(itemId, actualizado);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  /// El backend responde `ComandaItemModel` (sin `mesas`), asi que se copia
  /// el contexto de mesa que ya tenia la fila en vez de recargar toda la cola.
  void _reemplazarItem(int itemId, ComandaItemModel actualizado) {
    final indice = _items.indexWhere((i) => i.id == itemId);
    if (indice == -1) return;

    final anterior = _items[indice];
    _items[indice] = ItemCocinaModel(
      id: anterior.id,
      comandaId: anterior.comandaId,
      platoId: anterior.platoId,
      platoNombre: anterior.platoNombre,
      cantidad: anterior.cantidad,
      estado: actualizado.estado,
      cocineroId: actualizado.cocineroId,
      cocineroNombre: actualizado.cocineroNombre,
      horaTomado: actualizado.horaTomado ?? anterior.horaTomado,
      mesas: anterior.mesas,
    );
  }
}
