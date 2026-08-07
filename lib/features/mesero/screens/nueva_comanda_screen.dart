import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/mesa_model.dart';
import '../../../models/plato_model.dart';
import '../../../providers/comanda_provider.dart';
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
      context.read<ComandaProvider>().cargarCartaDisponible();
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
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.ember),
    );
    context.read<ComandaProvider>().limpiarError();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComandaProvider>();
    final carta = provider.carta;
    final subtotal = _calcularSubtotal(carta);
    final hayPlatos = _cantidadPorPlato.isNotEmpty;
    final nombresMesas = widget.mesas.map((m) => m.numeroONombre).join(' + ');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esAgregado ? 'Agregar platos' : 'Nuevo pedido'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.esAgregado ? 'Comanda #${widget.comandaId}' : 'Mesa $nombresMesas',
                style: const TextStyle(color: AppColors.brassSoft, fontFamily: AppTypography.mono),
              ),
            ),
          ),
        ),
      ),
      body: carta.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: carta.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line),
              itemBuilder: (_, i) {
                final plato = carta[i];
                return _FilaPlato(
                  plato: plato,
                  cantidad: _cantidadPorPlato[plato.id] ?? 0,
                  onSumar: () => _cambiarCantidad(plato, 1),
                  onRestar: () => _cambiarCantidad(plato, -1),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                    Text(
                      'S/ ${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: AppTypography.mono,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: hayPlatos && !provider.cargando ? _confirmarPedido : null,
                child: Text(widget.esAgregado ? 'Agregar a la comanda' : 'Confirmar pedido'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaPlato extends StatelessWidget {
  final PlatoModel plato;
  final int cantidad;
  final VoidCallback onSumar;
  final VoidCallback onRestar;

  const _FilaPlato({
    required this.plato,
    required this.cantidad,
    required this.onSumar,
    required this.onRestar,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(plato.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        plato.categoria ?? plato.descripcion ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textDim),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'S/ ${plato.precio.toStringAsFixed(2)}',
            style: const TextStyle(fontFamily: AppTypography.mono),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: cantidad > 0 ? onRestar : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: AppColors.pine,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.mono,
                fontWeight: FontWeight.bold,
                color: cantidad > 0 ? AppColors.ink : AppColors.textDim,
              ),
            ),
          ),
          IconButton(
            onPressed: onSumar,
            icon: const Icon(Icons.add_circle),
            color: AppColors.pine,
          ),
        ],
      ),
    );
  }
}
