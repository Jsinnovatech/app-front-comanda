import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/boton_salir.dart';
import '../../../core/widgets/estado_chip.dart';
import '../../../models/comanda_model.dart';
import '../../../models/mesa_model.dart';
import '../../../models/plato_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/comanda_provider.dart';
import '../../mantenimiento/widgets/selector_imagen.dart';
import 'detalle_comanda_screen.dart';
import 'nueva_comanda_screen.dart';

/// Pantalla principal del mesero: pestanas Mesas (tablero del salon) y Carta
/// (menu de hoy + QR publico). Monta el ComandaProvider para todo el modulo:
/// las pantallas hijas lo reciben con .value al navegar, para que mesas y
/// comandas sean el mismo estado en todo el flujo.
class MeseroHomeScreen extends StatelessWidget {
  const MeseroHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ComandaProvider()..cargarMesas(),
      child: const _SalonMesero(),
    );
  }
}

class _SalonMesero extends StatefulWidget {
  const _SalonMesero();

  @override
  State<_SalonMesero> createState() => _SalonMeseroState();
}

class _SalonMeseroState extends State<_SalonMesero> with SingleTickerProviderStateMixin {
  late final TabController _pestanas = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));
  final Set<int> _mesasAgrupadas = {};

  @override
  void dispose() {
    _pestanas.dispose();
    super.dispose();
  }

  void _alternarAgrupada(MesaModel mesa) {
    setState(() {
      if (!_mesasAgrupadas.remove(mesa.id)) _mesasAgrupadas.add(mesa.id);
    });
  }

  Future<void> _irANuevaComanda(List<MesaModel> mesas) async {
    final provider = context.read<ComandaProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: NuevaComandaScreen(mesas: mesas),
        ),
      ),
    );
    if (!mounted) return;
    setState(_mesasAgrupadas.clear);
    provider.cargarMesas();
  }

  Future<void> _irADetalle(int comandaId) async {
    final provider = context.read<ComandaProvider>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: DetalleComandaScreen(comandaId: comandaId),
        ),
      ),
    );
    if (mounted) provider.cargarMesas();
  }

  void _tocarMesa(MesaModel mesa) {
    final comandas = context.read<ComandaProvider>().comandasDeMesa(mesa.id);
    if (comandas.isEmpty) {
      _irANuevaComanda([mesa]);
    } else if (comandas.length == 1) {
      _irADetalle(comandas.first.id);
    } else {
      _mostrarComandasDeMesa(mesa, comandas);
    }
  }

  /// Modo comodin: la mesa tiene varias cuentas a la vez, hay que elegir cual.
  void _mostrarComandasDeMesa(MesaModel mesa, List<ComandaModel> comandas) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.table_restaurant, size: 20, color: AppColors.black),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mesa ${mesa.numeroONombre} · ${comandas.length} cuentas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            ...comandas.map(
              (comanda) => ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.black),
                title: Text('Comanda #${comanda.id}'),
                subtitle: Text('${comanda.items.length} platos'),
                trailing: Text(
                  'S/ ${comanda.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: AppTypography.mono, fontWeight: FontWeight.w900),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _irADetalle(comanda.id);
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppColors.yellow),
              title: const Text('Abrir otra cuenta en esta mesa'),
              onTap: () {
                Navigator.pop(context);
                _irANuevaComanda([mesa]);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sesion = context.read<AuthProvider>().sesion;
    final agrupadas =
        context.watch<ComandaProvider>().mesas.where((m) => _mesasAgrupadas.contains(m.id)).toList();
    final enTabMesas = _pestanas.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(sesion == null ? 'Mesero' : 'Mesero · ${sesion.nombre}'),
        actions: [
          BotonSalir(onPressed: () => context.read<AuthProvider>().cerrarSesion()),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: AppColors.white,
            child: TabBar(
              controller: _pestanas,
              tabs: const [Tab(text: 'Mesas'), Tab(text: 'Carta')],
            ),
          ),
        ),
      ),
      floatingActionButton: enTabMesas && agrupadas.length > 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.yellow,
              icon: const Icon(Icons.link),
              label: Text('Comanda para ${agrupadas.length} mesas'),
              onPressed: () => _irANuevaComanda(agrupadas),
            )
          : null,
      body: TabBarView(
        controller: _pestanas,
        children: [
          _TabMesas(
            agrupadas: _mesasAgrupadas,
            onTocarMesa: _tocarMesa,
            onAlternarAgrupada: _alternarAgrupada,
            onVerComanda: _irADetalle,
          ),
          const _TabCarta(),
        ],
      ),
    );
  }
}

// ---------- TAB MESAS ----------

class _TabMesas extends StatelessWidget {
  final Set<int> agrupadas;
  final void Function(MesaModel) onTocarMesa;
  final void Function(MesaModel) onAlternarAgrupada;
  final void Function(int) onVerComanda;

  const _TabMesas({
    required this.agrupadas,
    required this.onTocarMesa,
    required this.onAlternarAgrupada,
    required this.onVerComanda,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComandaProvider>();

    if (provider.cargando && provider.mesas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final pedidos = [...provider.comandasAbiertas]..sort((a, b) => a.id.compareTo(b.id));

    return RefreshIndicator(
      onRefresh: provider.cargarMesas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (provider.error != null) ...[
            _AvisoError(mensaje: provider.error!),
            const SizedBox(height: 12),
          ],
          _TituloSeccion(
            texto: 'Mesas',
            accion: FilledButton.icon(
              onPressed: provider.cargarMesas,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.black,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Actualizar'),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              childAspectRatio: 0.95,
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
            ),
            itemCount: provider.mesas.length,
            itemBuilder: (_, i) {
              final mesa = provider.mesas[i];
              return _TarjetaMesa(
                mesa: mesa,
                comandas: provider.comandasDeMesa(mesa.id),
                agrupada: agrupadas.contains(mesa.id),
                onTap: () => onTocarMesa(mesa),
                onLongPress: () => onAlternarAgrupada(mesa),
              );
            },
          ),
          const SizedBox(height: 20),
          const _TituloSeccion(
            texto: 'Pedidos en Curso',
            accion: Text(
              '⚡ en vivo',
              style: TextStyle(color: AppColors.textDim, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          if (pedidos.isEmpty)
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Sin pedidos activos. Toca una mesa disponible para iniciar uno.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textDim, fontSize: 13),
              ),
            ),
          ...pedidos.map(
            (comanda) => _TarjetaPedido(
              comanda: comanda,
              onVer: () => onVerComanda(comanda.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// Blanca cuando esta libre, amarilla cuando tiene cuentas abiertas.
/// Mantener presionada una mesa libre la marca para una comanda combinada.
class _TarjetaMesa extends StatelessWidget {
  final MesaModel mesa;
  final List<ComandaModel> comandas;
  final bool agrupada;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _TarjetaMesa({
    required this.mesa,
    required this.comandas,
    required this.agrupada,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final ocupada = comandas.isNotEmpty;
    final comodin = comandas.length > 1;
    final platos = comandas.fold<int>(
      0,
      (suma, c) => suma + c.items.fold<int>(0, (t, i) => t + i.cantidad),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: ocupada ? AppColors.yellow : AppColors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            onLongPress: ocupada ? null : onLongPress,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: agrupada ? Border.all(color: AppColors.black, width: 3) : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.table_restaurant, size: 24, color: ocupada ? AppColors.black : AppColors.yellow),
                  const SizedBox(height: 5),
                  Text(
                    'Mesa ${mesa.numeroONombre}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: ocupada ? AppColors.red : AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ocupada
                            ? 'Ocupada'
                            : agrupada
                                ? 'Seleccionada'
                                : 'Disponible',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  if (comodin)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '${comandas.length} cuentas',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (ocupada)
          Positioned(top: -6, right: -4, child: BadgeConteo(cantidad: platos)),
      ],
    );
  }
}

class _TarjetaPedido extends StatelessWidget {
  final ComandaModel comanda;
  final VoidCallback onVer;

  const _TarjetaPedido({required this.comanda, required this.onVer});

  @override
  Widget build(BuildContext context) {
    final estado = _estadoDominante(comanda.items);
    final listo = estado == 'listo';
    final minutos = DateTime.now().difference(comanda.fechaApertura).inMinutes;
    final mesas = comanda.mesas.map((m) => m.numeroONombre).join(' + ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: listo ? AppColors.green : Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mesa $mesas',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '#${comanda.id}',
                style: const TextStyle(
                  fontFamily: AppTypography.mono,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.textDim,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🕐 $minutos min',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...comanda.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.cantidad}x ${item.platoNombre ?? 'Plato #${item.platoId}'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    'S/ ${((item.platoPrecio ?? 0) * item.cantidad).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: AppTypography.mono,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              EstadoChip(estado: estado),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: listo ? AppColors.green : AppColors.black,
                  foregroundColor: listo ? AppColors.white : AppColors.yellow,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                onPressed: onVer,
                child: const Text('Ver cuenta'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Estado que resume la comanda entera: lo que el mesero necesita saber es si
/// ya hay algo listo para llevar, no el estado de cada plato por separado.
String _estadoDominante(List<ComandaItemModel> items) {
  if (items.isEmpty) return 'pendiente';
  if (items.every((i) => i.estado == 'servido')) return 'servido';
  if (items.any((i) => i.estado == 'listo')) return 'listo';
  if (items.any((i) => i.estado == 'en_preparacion')) return 'en_preparacion';
  return 'pendiente';
}

// ---------- TAB CARTA ----------

class _TabCarta extends StatefulWidget {
  const _TabCarta();

  @override
  State<_TabCarta> createState() => _TabCartaState();
}

class _TabCartaState extends State<_TabCarta> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ComandaProvider>().cargarCartaDisponible();
    });
  }

  @override
  Widget build(BuildContext context) {
    final carta = context.watch<ComandaProvider>().carta;
    final restauranteId = context.read<AuthProvider>().sesion?.restauranteId;

    if (carta.isEmpty) return const Center(child: CircularProgressIndicator());

    final porCategoria = <String, List<PlatoModel>>{};
    for (final plato in carta) {
      porCategoria.putIfAbsent(plato.categoria ?? 'Otros', () => []).add(plato);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (restauranteId != null) ...[
          _TarjetaQr(restauranteId: restauranteId),
          const SizedBox(height: 16),
        ],
        Text(
          'Carta de hoy · ${carta.length} platos disponibles',
          style: const TextStyle(color: AppColors.textDim, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        for (final categoria in porCategoria.entries) ...[
          Text(
            categoria.key.toUpperCase(),
            style: const TextStyle(color: AppColors.textDim, fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ...categoria.value.map((plato) => _FilaCarta(plato: plato)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// El QR es publico: apunta a la carta que el cliente ve desde su mesa,
/// por eso se carga sin token.
class _TarjetaQr extends StatelessWidget {
  final int restauranteId;

  const _TarjetaQr({required this.restauranteId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('Carta digital', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'El cliente escanea este QR desde su mesa y ve la carta',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.network(
              ApiConfig.qrCarta(restauranteId),
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              loadingBuilder: (_, hijo, progreso) => progreso == null
                  ? hijo
                  : const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (_, _, _) => const SizedBox(
                width: 180,
                height: 180,
                child: Center(
                  child: Text(
                    'No se pudo cargar el QR',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCarta extends StatelessWidget {
  final PlatoModel plato;

  const _FilaCarta({required this.plato});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          plato.fotoUrl != null && plato.fotoUrl!.isNotEmpty
              ? MiniaturaDeFoto(fotoUrl: plato.fotoUrl, lado: 46)
              : Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(_emojiDeCategoria(plato.categoria), style: const TextStyle(fontSize: 24)),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plato.nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                if (plato.descripcion != null)
                  Text(
                    plato.descripcion!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'S/ ${plato.precio.toStringAsFixed(2)}',
            style: const TextStyle(fontFamily: AppTypography.mono, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

/// El backend no guarda un emoji por plato: se deriva de la categoria para
/// mantener la carta tan visual como el prototipo aprobado.
String _emojiDeCategoria(String? categoria) {
  final texto = (categoria ?? '').toLowerCase();
  if (texto.contains('bebida') || texto.contains('refresco')) return '🥤';
  if (texto.contains('postre')) return '🍰';
  if (texto.contains('entrada') || texto.contains('ensalada')) return '🥗';
  if (texto.contains('sopa') || texto.contains('caldo')) return '🍲';
  return '🍽️';
}

// ---------- COMUNES ----------

class _TituloSeccion extends StatelessWidget {
  final String texto;
  final Widget accion;

  const _TituloSeccion({required this.texto, required this.accion});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: AppColors.yellow),
        const SizedBox(width: 8),
        Text(texto, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const Spacer(),
        accion,
      ],
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;
  const _AvisoError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: const TextStyle(color: AppColors.red))),
        ],
      ),
    );
  }
}
