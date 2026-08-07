import 'package:flutter/foundation.dart';

import '../models/comanda_model.dart';
import '../models/mesa_model.dart';
import '../models/personal_model.dart';
import '../services/comanda_service.dart';
import '../services/comprobante_service.dart';
import '../services/mantenimiento_service.dart';

/// Ventana de tiempo que el admin elige para leer sus numeros.
enum RangoDashboard { hoy, semana, mes, historico }

extension EtiquetaRango on RangoDashboard {
  String get etiqueta {
    switch (this) {
      case RangoDashboard.hoy:
        return 'Hoy';
      case RangoDashboard.semana:
        return '7 dias';
      case RangoDashboard.mes:
        return '30 dias';
      case RangoDashboard.historico:
        return 'Todo';
    }
  }
}

class VentaDelDia {
  final DateTime dia;
  final double total;
  final int pedidos;

  VentaDelDia({required this.dia, required this.total, required this.pedidos});
}

class PlatoVendido {
  final int platoId;
  final String nombre;
  final int unidades;
  final double ingresos;

  PlatoVendido({required this.platoId, required this.nombre, required this.unidades, required this.ingresos});
}

class MeseroDestacado {
  final int meseroId;
  final String nombre;
  final int comandasAtendidas;
  final double ingresos;

  MeseroDestacado({
    required this.meseroId,
    required this.nombre,
    required this.comandasAtendidas,
    required this.ingresos,
  });
}

/// Toda la analitica del restaurante se calcula aca, en el cliente: el backend
/// todavia no expone endpoints de reportes, asi que este provider baja las
/// comandas completas (con sus items), el personal y las mesas, y agrega.
/// Los widgets solo leen valores ya calculados, nunca recorren comandas.
class DashboardProvider extends ChangeNotifier {
  List<ComandaModel> _comandas = [];
  List<PersonalModel> _personal = [];
  List<MesaModel> _mesas = [];

  bool cargando = false;
  String? error;
  DateTime? ultimaActualizacion;

  RangoDashboard rango = RangoDashboard.semana;

  double ingresosTotales = 0;
  int pedidosFinalizados = 0;
  double ticketPromedio = 0;
  int unidadesVendidas = 0;
  int comandasAbiertas = 0;

  List<VentaDelDia> ventasPorDia = [];
  List<PlatoVendido> topPlatos = [];
  List<MeseroDestacado> rankingMeseros = [];

  /// Conteo de comprobantes por tipo (boleta/factura/nota_venta). Se llena solo
  /// bajo demanda: el backend no tiene "listar comprobantes", hay que preguntar
  /// comanda por comanda, y eso es caro con historial grande.
  Map<String, int>? conteoComprobantes;
  bool cargandoComprobantes = false;
  String? errorComprobantes;

  List<MesaModel> get mesas => List.unmodifiable(_mesas);
  int get mesasOcupadas => _mesas.where((m) => m.estado == 'ocupada').length;
  int get mesasLibres => _mesas.where((m) => m.estado == 'libre').length;
  bool get hayDatos => _comandas.isNotEmpty;

  Future<void> cargar() async {
    cargando = true;
    error = null;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        ComandaService.listarComandas(),
        MantenimientoService.listarPersonal(),
        MantenimientoService.listarMesas(),
      ]);
      _comandas = resultados[0] as List<ComandaModel>;
      _personal = resultados[1] as List<PersonalModel>;
      _mesas = resultados[2] as List<MesaModel>;
      conteoComprobantes = null;
      errorComprobantes = null;
      ultimaActualizacion = DateTime.now();
      _recalcular();
    } catch (e) {
      error = e.toString();
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void cambiarRango(RangoDashboard nuevo) {
    if (nuevo == rango) return;
    rango = nuevo;
    conteoComprobantes = null;
    errorComprobantes = null;
    _recalcular();
    notifyListeners();
  }

  /// Recorre las comandas finalizadas del rango preguntando su comprobante una
  /// por una (unica via disponible hoy). Se dispara solo si el admin lo pide.
  Future<void> cargarConteoComprobantes() async {
    final comandas = _comandasDelRango();
    cargandoComprobantes = true;
    errorComprobantes = null;
    notifyListeners();
    try {
      final conteo = <String, int>{};
      const tamanoLote = 8;
      for (var inicio = 0; inicio < comandas.length; inicio += tamanoLote) {
        final lote = comandas.skip(inicio).take(tamanoLote);
        final comprobantes = await Future.wait(
          lote.map((c) => ComprobanteService.obtenerPorComanda(c.id)),
        );
        for (final comprobante in comprobantes) {
          if (comprobante == null) continue;
          conteo[comprobante.tipo] = (conteo[comprobante.tipo] ?? 0) + 1;
        }
      }
      conteoComprobantes = conteo;
    } catch (e) {
      errorComprobantes = e.toString();
    } finally {
      cargandoComprobantes = false;
      notifyListeners();
    }
  }

  // ---------------- Agregacion ----------------

  void _recalcular() {
    final delRango = _comandasDelRango();

    ingresosTotales = delRango.fold(0.0, (suma, c) => suma + c.total);
    pedidosFinalizados = delRango.length;
    ticketPromedio = pedidosFinalizados == 0 ? 0 : ingresosTotales / pedidosFinalizados;
    unidadesVendidas = delRango.fold(
      0,
      (suma, c) => suma + c.items.fold(0, (s, i) => s + i.cantidad),
    );
    comandasAbiertas = _comandas.where((c) => c.estado == 'abierta').length;

    topPlatos = _calcularTopPlatos(delRango);
    rankingMeseros = _calcularRankingMeseros(delRango);
    ventasPorDia = _calcularVentasUltimosDias(7);
  }

  /// Una comanda cuenta como venta cuando ya se cobro: `pagada` o `cerrada`.
  bool _estaFinalizada(ComandaModel comanda) => comanda.estado == 'pagada' || comanda.estado == 'cerrada';

  /// La fecha con la que se ubica una venta en el tiempo es la de cierre; si
  /// aun no la tiene, la de apertura.
  DateTime _fechaDeVenta(ComandaModel comanda) => comanda.fechaCierre ?? comanda.fechaApertura;

  List<ComandaModel> _comandasDelRango() {
    final desde = _inicioDelRango();
    return _comandas
        .where((c) => _estaFinalizada(c) && (desde == null || !_fechaDeVenta(c).isBefore(desde)))
        .toList();
  }

  DateTime? _inicioDelRango() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    switch (rango) {
      case RangoDashboard.hoy:
        return hoy;
      case RangoDashboard.semana:
        return hoy.subtract(const Duration(days: 6));
      case RangoDashboard.mes:
        return hoy.subtract(const Duration(days: 29));
      case RangoDashboard.historico:
        return null;
    }
  }

  List<PlatoVendido> _calcularTopPlatos(List<ComandaModel> comandas) {
    final unidadesPorPlato = <int, int>{};
    final ingresosPorPlato = <int, double>{};
    final nombrePorPlato = <int, String>{};

    for (final comanda in comandas) {
      for (final item in comanda.items) {
        unidadesPorPlato[item.platoId] = (unidadesPorPlato[item.platoId] ?? 0) + item.cantidad;
        ingresosPorPlato[item.platoId] =
            (ingresosPorPlato[item.platoId] ?? 0) + item.cantidad * (item.platoPrecio ?? 0);
        nombrePorPlato[item.platoId] = item.platoNombre ?? 'Plato #${item.platoId}';
      }
    }

    final vendidos = unidadesPorPlato.entries
        .map((e) => PlatoVendido(
              platoId: e.key,
              nombre: nombrePorPlato[e.key] ?? 'Plato #${e.key}',
              unidades: e.value,
              ingresos: ingresosPorPlato[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.unidades.compareTo(a.unidades));

    return vendidos.take(5).toList();
  }

  List<MeseroDestacado> _calcularRankingMeseros(List<ComandaModel> comandas) {
    final comandasPorMesero = <int, int>{};
    final ingresosPorMesero = <int, double>{};

    for (final comanda in comandas) {
      comandasPorMesero[comanda.meseroId] = (comandasPorMesero[comanda.meseroId] ?? 0) + 1;
      ingresosPorMesero[comanda.meseroId] = (ingresosPorMesero[comanda.meseroId] ?? 0) + comanda.total;
    }

    final ranking = comandasPorMesero.entries
        .map((e) => MeseroDestacado(
              meseroId: e.key,
              nombre: _nombreDeMesero(e.key),
              comandasAtendidas: e.value,
              ingresos: ingresosPorMesero[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.comandasAtendidas.compareTo(a.comandasAtendidas));

    return ranking;
  }

  String _nombreDeMesero(int meseroId) {
    for (final persona in _personal) {
      if (persona.id == meseroId) return persona.nombre;
    }
    return 'Colaborador #$meseroId';
  }

  /// Serie diaria fija (independiente del filtro) para que la barra de tendencia
  /// siempre tenga contexto suficiente para leerse.
  List<VentaDelDia> _calcularVentasUltimosDias(int cantidadDias) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final totalPorDia = <DateTime, double>{};
    final pedidosPorDia = <DateTime, int>{};

    for (final comanda in _comandas.where(_estaFinalizada)) {
      final fecha = _fechaDeVenta(comanda);
      final dia = DateTime(fecha.year, fecha.month, fecha.day);
      totalPorDia[dia] = (totalPorDia[dia] ?? 0) + comanda.total;
      pedidosPorDia[dia] = (pedidosPorDia[dia] ?? 0) + 1;
    }

    return List.generate(cantidadDias, (indice) {
      final dia = hoy.subtract(Duration(days: cantidadDias - 1 - indice));
      return VentaDelDia(
        dia: dia,
        total: totalPorDia[dia] ?? 0,
        pedidos: pedidosPorDia[dia] ?? 0,
      );
    });
  }
}
