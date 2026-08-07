import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/comanda_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cocina_provider.dart';

/// Superficies oscuras exclusivas de cocina: es la unica pantalla del rediseno
/// en modo oscuro (el tablet vive colgado frente a la plancha), por eso no
/// viven en AppColors, que solo guarda la paleta compartida.
const _fondoCola = Color(0xFF1A1A1A);
const _fondoTarjeta = Color(0xFF242424);
const _lineaOscura = Color(0xFF333333);

/// Pantalla tactil de cocina: la cola de platos por preparar como tickets.
/// El refresco es manual (boton en el header o desliz hacia abajo); no hay
/// polling con Timer para el MVP, se decidio no gastar bateria/red del tablet
/// mientras no haya una necesidad medida de tiempo real.
class CocinaScreen extends StatelessWidget {
  const CocinaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CocinaProvider()..cargarItemsPendientes(),
      child: const _VistaCocina(),
    );
  }
}

class _VistaCocina extends StatefulWidget {
  const _VistaCocina();

  @override
  State<_VistaCocina> createState() => _VistaCocinaState();
}

class _VistaCocinaState extends State<_VistaCocina> {
  Future<void> _empezarPreparacion(_GrupoComanda grupo) async {
    final codigoAcceso = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoPinCocinero(resumen: grupo.resumenPlatos),
    );
    if (codigoAcceso == null || !mounted) return;

    final cocina = context.read<CocinaProvider>();
    for (final item in grupo.items) {
      final exito = await cocina.tomarItem(item.id, codigoAcceso);
      if (!mounted) return;
      if (!exito) {
        _avisar(cocina.error ?? 'No se pudo tomar el plato');
        return;
      }
    }
  }

  Future<void> _marcarListo(_GrupoComanda grupo) async {
    final cocina = context.read<CocinaProvider>();
    for (final item in grupo.items) {
      final exito = await cocina.marcarListo(item.id);
      if (!mounted) return;
      if (!exito) {
        _avisar(cocina.error ?? 'No se pudo marcar como listo');
        return;
      }
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.red),
    );
  }

  Future<void> _cerrarSesion() async {
    await context.read<AuthProvider>().cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final cocina = context.watch<CocinaProvider>();
    final grupos = _agruparPorComanda(cocina.items);
    final enCola = cocina.items
        .where((i) => i.estado != 'listo')
        .map((i) => i.comandaId)
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: _fondoCola,
      body: Column(
        children: [
          _CabeceraCocina(
            comandasEnCola: enCola,
            cargando: cocina.cargando,
            alRefrescar: cocina.cargarItemsPendientes,
            alSalir: _cerrarSesion,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: cocina.cargarItemsPendientes,
              backgroundColor: _fondoTarjeta,
              color: AppColors.yellow,
              child: _contenido(cocina, grupos),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido(CocinaProvider cocina, List<_GrupoComanda> grupos) {
    if (cocina.cargando && cocina.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
    }
    if (cocina.error != null && cocina.items.isEmpty) {
      return _MensajeCentrado(
        emoji: '📡',
        titulo: 'No se pudo cargar la cola',
        detalle: cocina.error!,
        accion: ElevatedButton(
          onPressed: cocina.cargarItemsPendientes,
          child: const Text('Reintentar'),
        ),
      );
    }
    if (grupos.isEmpty) {
      return const _MensajeCentrado(
        emoji: '🍳',
        titulo: 'Sin comandas por ahora',
        detalle: 'Cuando el mozo envie un pedido aparecera aqui al toque.',
      );
    }

    return LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth >= 1100
            ? 3
            : restricciones.maxWidth >= 720
                ? 2
                : 1;
        final tarjetas = grupos
            .map((grupo) => _TarjetaComanda(
                  grupo: grupo,
                  alEmpezar: () => _empezarPreparacion(grupo),
                  alMarcarListo: () => _marcarListo(grupo),
                ))
            .toList();

        if (columnas == 1) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: tarjetas.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, indice) => tarjetas[indice],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: tarjetas.map((tarjeta) {
              final ancho = (restricciones.maxWidth - 28 - 12 * (columnas - 1)) / columnas;
              return SizedBox(width: ancho, child: tarjeta);
            }).toList(),
          ),
        );
      },
    );
  }
}

/// La cola llega plana (un item por fila) pero el cocinero razona por comanda:
/// se agrupa por comanda + estado para que cada tarjeta tenga un solo boton de
/// avance sin estados mezclados adentro.
List<_GrupoComanda> _agruparPorComanda(List<ItemCocinaModel> items) {
  final porClave = <String, List<ItemCocinaModel>>{};
  for (final item in items) {
    porClave.putIfAbsent('${item.comandaId}|${item.estado}', () => []).add(item);
  }

  final grupos = porClave.values.map(_GrupoComanda.desdeItems).toList();
  grupos.sort((a, b) {
    final porEstado = a.prioridadEstado.compareTo(b.prioridadEstado);
    return porEstado != 0 ? porEstado : a.comandaId.compareTo(b.comandaId);
  });
  return grupos;
}

class _GrupoComanda {
  final int comandaId;
  final String estado;
  final List<String> mesas;
  final DateTime? horaTomado;
  final List<ItemCocinaModel> items;

  _GrupoComanda({
    required this.comandaId,
    required this.estado,
    required this.mesas,
    required this.horaTomado,
    required this.items,
  });

  factory _GrupoComanda.desdeItems(List<ItemCocinaModel> items) {
    final primero = items.first;
    DateTime? masAntigua;
    for (final item in items) {
      final hora = item.horaTomado;
      if (hora != null && (masAntigua == null || hora.isBefore(masAntigua))) {
        masAntigua = hora;
      }
    }
    return _GrupoComanda(
      comandaId: primero.comandaId,
      estado: primero.estado,
      mesas: primero.mesas,
      horaTomado: masAntigua,
      items: items,
    );
  }

  int get prioridadEstado => switch (estado) {
        'pendiente' => 0,
        'en_preparacion' => 1,
        'listo' => 2,
        _ => 3,
      };

  String get etiquetaMesa => mesas.isEmpty ? 'SIN MESA' : 'MESA ${mesas.join(' + ')}';

  String get resumenPlatos => items.map((i) => '${i.cantidad}x ${i.platoNombre}').join(', ');
}

class _CabeceraCocina extends StatelessWidget {
  final int comandasEnCola;
  final bool cargando;
  final Future<void> Function() alRefrescar;
  final VoidCallback alSalir;

  const _CabeceraCocina({
    required this.comandasEnCola,
    required this.cargando,
    required this.alRefrescar,
    required this.alSalir,
  });

  @override
  Widget build(BuildContext context) {
    final plural = comandasEnCola == 1 ? 'comanda' : 'comandas';

    return Container(
      color: AppColors.black,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👨‍🍳 COCINA',
                      style: TextStyle(
                        fontFamily: AppTypography.display,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.yellow,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$comandasEnCola $plural en cola',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar cola',
                onPressed: cargando ? null : alRefrescar,
                icon: const Icon(Icons.refresh),
                color: AppColors.yellow,
                disabledColor: AppColors.textDim,
              ),
              ElevatedButton(
                onPressed: alSalir,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                child: const Text('Salir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaComanda extends StatelessWidget {
  final _GrupoComanda grupo;
  final VoidCallback alEmpezar;
  final VoidCallback alMarcarListo;

  const _TarjetaComanda({
    required this.grupo,
    required this.alEmpezar,
    required this.alMarcarListo,
  });

  static const _estilos = {
    'pendiente': (AppColors.red, '🔥 NUEVO', Colors.white),
    'en_preparacion': (AppColors.yellow, '👨‍🍳 EN PREPARACIÓN', AppColors.black),
    'listo': (AppColors.green, '✅ LISTO — avisado al mozo', Colors.white),
  };

  @override
  Widget build(BuildContext context) {
    final (color, etiqueta, textoFranja) =
        _estilos[grupo.estado] ?? (AppColors.textDim, grupo.estado.toUpperCase(), Colors.white);
    final estaListo = grupo.estado == 'listo';

    final tarjeta = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _fondoTarjeta,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2),
        boxShadow: grupo.estado == 'pendiente'
            ? [BoxShadow(color: AppColors.red.withValues(alpha: 0.33), blurRadius: 18)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _franja(color, etiqueta, textoFranja),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _encabezadoMesa(),
                const SizedBox(height: 10),
                ...grupo.items.map(_filaItem),
                _accion(estaListo),
              ],
            ),
          ),
        ],
      ),
    );

    return estaListo ? Opacity(opacity: 0.65, child: tarjeta) : tarjeta;
  }

  Widget _franja(Color color, String etiqueta, Color textoFranja) {
    final estilo = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: textoFranja);
    final transcurrido = _minutosTranscurridos();

    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: estilo, overflow: TextOverflow.ellipsis)),
          if (transcurrido != null) Text('⏱ $transcurrido min', style: estilo),
        ],
      ),
    );
  }

  Widget _encabezadoMesa() {
    final hora = grupo.horaTomado;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.table_restaurant, size: 16, color: Colors.white),
                ),
                TextSpan(text: ' ${grupo.etiquetaMesa} '),
                TextSpan(
                  text: '#${grupo.comandaId}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
              ],
            ),
            style: const TextStyle(
              fontFamily: AppTypography.display,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hora != null)
          Text(
            DateFormat('HH:mm').format(hora.toLocal()),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim),
          ),
      ],
    );
  }

  Widget _filaItem(ItemCocinaModel item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _lineaOscura)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${item.cantidad}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.platoNombre,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accion(bool estaListo) {
    if (estaListo) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(
          child: Text(
            'El mozo lo ve en verde y cobra la mesa 💰',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.green),
          ),
        ),
      );
    }

    final esPendiente = grupo.estado == 'pendiente';
    if (!esPendiente && grupo.estado != 'en_preparacion') return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: esPendiente ? alEmpezar : alMarcarListo,
          style: ElevatedButton.styleFrom(
            backgroundColor: esPendiente ? AppColors.black : AppColors.green,
            foregroundColor: esPendiente ? AppColors.yellow : AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          child: Text(esPendiente ? 'Empezar preparación' : 'Marcar listo ✓'),
        ),
      ),
    );
  }

  /// Solo hay marca de tiempo desde que el cocinero toma el plato, asi que las
  /// comandas nuevas todavia no muestran cronometro.
  int? _minutosTranscurridos() {
    final hora = grupo.horaTomado;
    if (hora == null) return null;
    final minutos = DateTime.now().difference(hora.toLocal()).inMinutes;
    return minutos < 0 ? 0 : minutos;
  }
}

/// El tablet esta logueado como "cocinero" generico, asi que cada cocinero
/// escribe su propio PIN al tomar una comanda: es lo unico que permite
/// registrar quien se hizo cargo.
class _DialogoPinCocinero extends StatefulWidget {
  final String resumen;
  const _DialogoPinCocinero({required this.resumen});

  @override
  State<_DialogoPinCocinero> createState() => _DialogoPinCocineroState();
}

class _DialogoPinCocineroState extends State<_DialogoPinCocinero> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _confirmar() {
    final codigo = _controlador.text.trim();
    if (codigo.isEmpty) return;
    Navigator.of(context).pop(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      title: const Text('Tu codigo de acceso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vas a preparar: ${widget.resumen}. Ingresa tu PIN para que quede registrado a tu nombre.',
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controlador,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: AppTypography.mono, fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(hintText: '····'),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _confirmar, child: const Text('Empezar')),
      ],
    );
  }
}

class _MensajeCentrado extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String detalle;
  final Widget? accion;

  const _MensajeCentrado({
    required this.emoji,
    required this.titulo,
    required this.detalle,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 90, 32, 32),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textDim),
              ),
              if (accion != null) ...[const SizedBox(height: 20), accion!],
            ],
          ),
        ),
      ],
    );
  }
}
