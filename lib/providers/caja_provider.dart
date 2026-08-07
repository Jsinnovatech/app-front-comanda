import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/comanda_model.dart';
import '../models/comprobante_model.dart';
import '../models/restaurante_model.dart';
import '../services/comanda_service.dart';
import '../services/comprobante_service.dart';
import '../services/mantenimiento_service.dart';

/// Caja: cierra la cuenta de una comanda y emite su comprobante.
///
/// El orden importa y no es negociable: primero se cierra la comanda, recien
/// despues se emite. El backend solo acepta emitir sobre una comanda `pagada`
/// o `cerrada`, nunca sobre una `abierta`.
class CajaProvider extends ChangeNotifier {
  List<ComandaModel> _comandasAbiertas = [];
  ComandaModel? _comandaSeleccionada;
  ComprobanteModel? _comprobanteEmitido;
  RestauranteModel? _restaurante;
  bool _cargando = false;
  String? _error;

  List<ComandaModel> get comandasAbiertas => _comandasAbiertas;
  ComandaModel? get comandaSeleccionada => _comandaSeleccionada;
  ComprobanteModel? get comprobanteEmitido => _comprobanteEmitido;
  RestauranteModel? get restaurante => _restaurante;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarComandasAbiertas() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _comandasAbiertas = await ComandaService.listarComandas(estado: 'abierta');
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Carga el detalle de la comanda a cobrar y, si el cajero vuelve a entrar
  /// a una cuenta que ya se cerro, tambien su comprobante ya emitido.
  Future<void> seleccionarComanda(int comandaId) async {
    _cargando = true;
    _error = null;
    _comandaSeleccionada = null;
    _comprobanteEmitido = null;
    notifyListeners();

    try {
      _comandaSeleccionada = await ComandaService.obtenerComanda(comandaId);
      _comprobanteEmitido = await ComprobanteService.obtenerPorComanda(comandaId);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Los permisos SUNAT del restaurante deciden si una boleta/factura pedida
  /// terminara siendo una nota de venta. Se consultan solo para adelantarle
  /// el aviso al cajero: la palabra final siempre la tiene el backend.
  Future<void> cargarPermisosSunat(int restauranteId) async {
    try {
      _restaurante = await MantenimientoService.obtenerRestaurante(restauranteId);
      notifyListeners();
    } on ApiException {
      _restaurante = null;
    }
  }

  /// Que tipo se emitira segun los permisos ya conocidos. Devuelve null si
  /// todavia no se sabe (permisos sin cargar) para que la UI no afirme nada.
  String? tipoPrevistoPara(String tipoSolicitado) {
    final permisos = _restaurante;
    if (permisos == null) return null;

    final habilitado = tipoSolicitado == 'factura' ? permisos.puedeEmitirFactura : permisos.puedeEmitirBoleta;
    return habilitado ? tipoSolicitado : 'nota_venta';
  }

  bool get degradaANotaDeVenta => _comprobanteEmitido != null && _comprobanteEmitido!.tipo == 'nota_venta';

  /// Cierra la cuenta y emite el comprobante. `tarjeta` deja la comanda en
  /// `pagada` y `efectivo` la deja en `cerrada`: esa transicion la resuelve
  /// el backend, aca solo se refleja el estado que devuelva.
  ///
  /// Si la comanda ya estaba cerrada (reintento tras una emision fallida) no
  /// se vuelve a cobrar, solo se emite.
  Future<bool> cerrarYEmitir({
    required String metodoPago,
    required String tipoSolicitado,
    String? rucCliente,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      if (_comandaSeleccionada!.estado == 'abierta') {
        _comandaSeleccionada = await ComandaService.cerrarComanda(
          _comandaSeleccionada!.id,
          metodoPago: metodoPago,
        );
        notifyListeners();
      }

      _comprobanteEmitido = await ComprobanteService.emitir(
        _comandaSeleccionada!.id,
        tipoSolicitado: tipoSolicitado,
        rucCliente: (rucCliente != null && rucCliente.isNotEmpty) ? rucCliente : null,
      );
      _comandasAbiertas.removeWhere((c) => c.id == _comandaSeleccionada!.id);
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> marcarImpreso(int comprobanteId) => _registrarImpresion(comprobanteId, 'impreso');

  Future<bool> marcarErrorImpresora(int comprobanteId) => _registrarImpresion(comprobanteId, 'error_impresora');

  /// La impresora termica es fisica y falla (sin papel, desconectada). El
  /// cobro ya ocurrio, asi que un fallo aca se registra pero nunca revierte
  /// ni bloquea el cierre de la cuenta.
  Future<bool> _registrarImpresion(int comprobanteId, String estadoImpresion) async {
    _error = null;
    try {
      _comprobanteEmitido = await ComprobanteService.actualizarEstadoImpresion(comprobanteId, estadoImpresion);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void limpiarSeleccion() {
    _comandaSeleccionada = null;
    _comprobanteEmitido = null;
    _error = null;
    notifyListeners();
  }
}
