import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/estado_chip.dart';
import '../../../models/comanda_model.dart';
import '../../../providers/comanda_provider.dart';
import 'nueva_comanda_screen.dart';

/// Detalle de una cuenta: sus platos con el estado en que va cada uno.
/// El mesero no mueve los estados intermedios (eso es de cocina): solo ve
/// avanzar los items y cierra el ciclo marcando 'servido' los que estan listos.
class DetalleComandaScreen extends StatefulWidget {
  final int comandaId;

  const DetalleComandaScreen({super.key, required this.comandaId});

  @override
  State<DetalleComandaScreen> createState() => _DetalleComandaScreenState();
}

class _DetalleComandaScreenState extends State<DetalleComandaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ComandaProvider>().cargarComanda(widget.comandaId);
    });
  }

  Future<void> _agregarPlatos(ComandaModel comanda) async {
    final provider = context.read<ComandaProvider>();
    final mesasDeLaComanda = provider.mesas
        .where((m) => comanda.mesas.any((resumen) => resumen.id == m.id))
        .toList();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: NuevaComandaScreen(mesas: mesasDeLaComanda, comandaId: comanda.id),
        ),
      ),
    );
    if (mounted) provider.cargarComanda(widget.comandaId);
  }

  Future<void> _marcarServido(int itemId) async {
    final provider = context.read<ComandaProvider>();
    final servido = await provider.marcarServido(itemId);
    if (!mounted || servido) return;
    _mostrarError(provider.error ?? 'No se pudo marcar como servido');
  }

  Future<void> _cerrarCuenta(ComandaModel comanda) async {
    final metodoPago = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Cobrar mesa', style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Recibir',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.textDim),
                    ),
                    Text(
                      'S/ ${comanda.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: AppTypography.mono,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'METODO DE PAGO',
                style: TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Text('💵', style: TextStyle(fontSize: 20)),
              title: const Text('Efectivo'),
              onTap: () => Navigator.pop(context, 'efectivo'),
            ),
            ListTile(
              leading: const Text('💳', style: TextStyle(fontSize: 20)),
              title: const Text('Tarjeta'),
              onTap: () => Navigator.pop(context, 'tarjeta'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (metodoPago == null || !mounted) return;

    final provider = context.read<ComandaProvider>();
    final cerrada = await provider.cerrarComanda(comanda.id, metodoPago);
    if (!mounted) return;
    if (cerrada) {
      Navigator.pop(context);
    } else {
      _mostrarError(provider.error ?? 'No se pudo cerrar la cuenta');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.red),
    );
    context.read<ComandaProvider>().limpiarError();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComandaProvider>();
    final comanda = provider.comandaActiva;

    if (comanda == null || comanda.id != widget.comandaId) {
      return Scaffold(
        appBar: AppBar(title: Text('Comanda #${widget.comandaId}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final abierta = comanda.estado == 'abierta';
    final mesas = comanda.mesas.map((m) => m.numeroONombre).join(' + ');

    return Scaffold(
      appBar: AppBar(
        title: Text('Comanda #${comanda.id}'),
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
              '🪑 Mesa $mesas',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.cargarComanda(widget.comandaId),
        child: comanda.items.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('🧾', style: TextStyle(fontSize: 40))),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Sin platos todavia',
                      style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: comanda.items.length,
                itemBuilder: (_, i) {
                  final item = comanda.items[i];
                  return _TarjetaItem(
                    item: item,
                    onMarcarServido: item.estado == 'listo' ? () => _marcarServido(item.id) : null,
                  );
                },
              ),
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
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const Spacer(),
                    Text(
                      'S/ ${comanda.total.toStringAsFixed(2)}',
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
              if (abierta)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _agregarPlatos(comanda),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar plato'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.yellow,
                        ),
                        onPressed: () => _cerrarCuenta(comanda),
                        icon: const Icon(Icons.point_of_sale, size: 18),
                        label: const Text('Cobrar'),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [EstadoChip(estado: comanda.estado)],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaItem extends StatelessWidget {
  final ComandaItemModel item;
  final VoidCallback? onMarcarServido;

  const _TarjetaItem({required this.item, this.onMarcarServido});

  @override
  Widget build(BuildContext context) {
    final listo = item.estado == 'listo';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: listo ? AppColors.green : Colors.transparent, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${item.cantidad}x',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.platoNombre ?? 'Plato #${item.platoId}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    EstadoChip(estado: item.estado),
                    if (item.cocineroNombre != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.cocineroNombre!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textDim, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onMarcarServido != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
              onPressed: onMarcarServido,
              child: const Text('Servido'),
            )
          else
            Text(
              'S/ ${((item.platoPrecio ?? 0) * item.cantidad).toStringAsFixed(2)}',
              style: const TextStyle(fontFamily: AppTypography.mono, fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}
