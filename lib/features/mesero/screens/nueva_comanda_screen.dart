import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/mesa_model.dart';
import '../../../models/plato_model.dart';
import '../../../providers/comanda_provider.dart';
import '../../mantenimiento/widgets/selector_imagen.dart';
import 'detalle_comanda_screen.dart';

/// Selector de platos con steppers. Sirve para los dos caminos: abrir una
/// comanda nueva sobre la(s) mesa(s) elegida(s), o sumar platos a una comanda
/// que ya existe (cuando llega [comandaId] desde el detalle).
class NuevaComandaScreen extends StatefulWidget {
  final List<MesaModel> mesas;
  final int? comandaId;

  const NuevaComandaScreen({super.key, required this.mesas, this.comandaId});

  bool get esAgregado => comandaId != null;

  @override
  State<NuevaComandaScreen> createState() => _NuevaComandaScreenState();
}

class _NuevaComandaScreenState extends State<NuevaComandaScreen> {
  final Map<int, int> _cantidadPorPlato = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ComandaProvider>().cargarCartaDisponible();
    });
  }

  void _cambiarCantidad(PlatoModel plato, int delta) {
    setState(() {
      final nueva = (_cantidadPorPlato[plato.id] ?? 0) + delta;
      if (nueva <= 0) {
        _cantidadPorPlato.remove(plato.id);
      } else {
        _cantidadPorPlato[plato.id] = nueva;
      }
    });
  }

  double _calcularSubtotal(List<PlatoModel> carta) {
    return carta.fold<double>(
      0,
      (suma, plato) => suma + plato.precio * (_cantidadPorPlato[plato.id] ?? 0),
    );
  }

  /// Nada sale a cocina sin que el mesero vea antes lo que va a enviar:
  /// la previsualizacion es el ultimo punto donde puede corregir.
  Future<void> _previsualizarPedido(List<PlatoModel> carta) async {
    final elegidos = carta.where((p) => _cantidadPorPlato.containsKey(p.id)).toList();
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PrevisualizacionPedido(
        platos: elegidos,
        cantidades: Map.of(_cantidadPorPlato),
        total: _calcularSubtotal(carta),
        etiquetaMesas: widget.esAgregado
            ? 'Comanda #${widget.comandaId}'
            : 'Mesa ${widget.mesas.map((m) => m.numeroONombre).join(' + ')}',
        etiquetaConfirmar: widget.esAgregado ? 'Confirmar y agregar' : 'Confirmar y enviar',
      ),
    );
    if (confirmado == true && mounted) await _confirmarPedido();
  }

  Future<void> _confirmarPedido() async {
    final provider = context.read<ComandaProvider>();
    final items = _cantidadPorPlato.entries
        .map((e) => {'plato_id': e.key, 'cantidad': e.value})
        .toList();

    if (widget.esAgregado) {
      for (final item in items) {
        final agregado = await provider.agregarItem(
          widget.comandaId!,
          item['plato_id'] as int,
          item['cantidad'] as int,
        );
        if (!agregado) break;
      }
      if (!mounted) return;
      if (provider.error != null) {
        _mostrarError(provider.error!);
      } else {
        Navigator.pop(context);
      }
      return;
    }

    final comanda = await provider.abrirComanda(
      widget.mesas.map((m) => m.id).toList(),
      items,
    );
    if (!mounted) return;
    if (comanda == null) {
      _mostrarError(provider.error ?? 'No se pudo abrir la comanda');
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: DetalleComandaScreen(comandaId: comanda.id),
        ),
      ),
    );
  }

  /// El backend es quien decide si la mesa admite otra comanda (modo estricto
  /// vs comodin): su mensaje se muestra tal cual, sin traducirlo ni ocultarlo.
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.red),
    );
    context.read<ComandaProvider>().limpiarError();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComandaProvider>();
    final carta = provider.carta;
    final subtotal = _calcularSubtotal(carta);
    final platosElegidos = _cantidadPorPlato.values.fold<int>(0, (suma, c) => suma + c);
    final nombresMesas = widget.mesas.map((m) => m.numeroONombre).join(' + ');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esAgregado ? 'Agregar platos' : 'Nuevo pedido'),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.esAgregado ? 'Comanda #${widget.comandaId}' : '🪑 Mesa $nombresMesas',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
      body: carta.isEmpty && provider.error != null
          ? _AvisoErrorCarta(
              mensaje: provider.error!,
              onReintentar: () {
                provider.limpiarError();
                provider.cargarCartaDisponible();
              },
            )
          : carta.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: carta.length,
                  itemBuilder: (_, i) {
                    final plato = carta[i];
                    return _TarjetaPlato(
                      plato: plato,
                      cantidad: _cantidadPorPlato[plato.id] ?? 0,
                      onSumar: () => _cambiarCantidad(plato, 1),
                      onRestar: () => _cambiarCantidad(plato, -1),
                    );
                  },
                ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      platosElegidos > 0 ? 'Total · $platosElegidos platos' : 'Total',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const Spacer(),
                    Text(
                      'S/ ${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: AppTypography.mono,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.yellow,
                  ),
                  onPressed: platosElegidos > 0 && !provider.cargando
                      ? () => _previsualizarPedido(carta)
                      : null,
                  child: Text(widget.esAgregado ? 'Agregar a la comanda' : 'Confirmar pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resumen final antes de mandar el pedido a cocina: solo lectura, con salida
/// para volver a corregir cantidades.
class _PrevisualizacionPedido extends StatelessWidget {
  final List<PlatoModel> platos;
  final Map<int, int> cantidades;
  final double total;
  final String etiquetaMesas;
  final String etiquetaConfirmar;

  const _PrevisualizacionPedido({
    required this.platos,
    required this.cantidades,
    required this.total,
    required this.etiquetaMesas,
    required this.etiquetaConfirmar,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Revisa el pedido', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              etiquetaMesas,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: ListView(
                shrinkWrap: true,
                children: platos.map((plato) {
                  final cantidad = cantidades[plato.id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.yellowSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '${cantidad}x',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            plato.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                        ),
                        Text(
                          'S/ ${(plato.precio * cantidad).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: AppTypography.mono,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  const Spacer(),
                  Text(
                    'S/ ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: AppTypography.mono,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Volver'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.yellow,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(etiquetaConfirmar),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisoErrorCarta extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const _AvisoErrorCarta({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPlato extends StatelessWidget {
  final PlatoModel plato;
  final int cantidad;
  final VoidCallback onSumar;
  final VoidCallback onRestar;

  const _TarjetaPlato({
    required this.plato,
    required this.cantidad,
    required this.onSumar,
    required this.onRestar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cantidad > 0 ? AppColors.yellow : Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          plato.fotoUrl != null && plato.fotoUrl!.isNotEmpty
              ? MiniaturaDeFoto(fotoUrl: plato.fotoUrl, lado: 44)
              : Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_emojiDeCategoria(plato.categoria), style: const TextStyle(fontSize: 22)),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plato.nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(
                  'S/ ${plato.precio.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontFamily: AppTypography.mono,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (cantidad > 0) ...[
            _BotonCantidad(icono: Icons.remove, resaltado: false, onTap: onRestar),
            SizedBox(
              width: 30,
              child: Text(
                '$cantidad',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ),
          ],
          _BotonCantidad(icono: Icons.add, resaltado: true, onTap: onSumar),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final bool resaltado;
  final VoidCallback onTap;

  const _BotonCantidad({required this.icono, required this.resaltado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: resaltado ? AppColors.yellow : AppColors.white,
          shape: BoxShape.circle,
          border: resaltado ? null : Border.all(color: AppColors.line, width: 2),
        ),
        child: Icon(icono, size: 18, color: AppColors.black),
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
