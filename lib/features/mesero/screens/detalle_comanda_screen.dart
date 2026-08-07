import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
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
      context.read<ComandaProvider>().cargarComanda(widget.comandaId);
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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Cobrar S/ ${comanda.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.payments, color: AppColors.pine),
              title: const Text('Efectivo'),
              onTap: () => Navigator.pop(context, 'efectivo'),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card, color: AppColors.pine),
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
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.ember),
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Comanda #${comanda.id}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mesa ${comanda.mesas.map((m) => m.numeroONombre).join(' + ')}',
                style: const TextStyle(color: AppColors.brassSoft, fontFamily: AppTypography.mono),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.cargarComanda(widget.comandaId),
        child: comanda.items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Sin platos todavia', style: TextStyle(color: AppColors.textDim))),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: comanda.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line),
                itemBuilder: (_, i) {
                  final item = comanda.items[i];
                  return _FilaItem(
                    item: item,
                    onMarcarServido: item.estado == 'listo' ? () => _marcarServido(item.id) : null,
                  );
                },
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Total', style: TextStyle(color: AppColors.textDim)),
                  const Spacer(),
                  Text(
                    'S/ ${comanda.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: AppTypography.mono,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (abierta)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _agregarPlatos(comanda),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar plato'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _cerrarCuenta(comanda),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Cerrar cuenta'),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'Cuenta ${comanda.estado}',
                  style: const TextStyle(color: AppColors.cerrada, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilaItem extends StatelessWidget {
  final ComandaItemModel item;
  final VoidCallback? onMarcarServido;

  const _FilaItem({required this.item, this.onMarcarServido});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.paper,
        child: Text(
          'x${item.cantidad}',
          style: const TextStyle(fontFamily: AppTypography.mono, fontSize: 12, color: AppColors.ink),
        ),
      ),
      title: Text(item.platoNombre ?? 'Plato #${item.platoId}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            _PastillaEstado(estado: item.estado),
            if (item.cocineroNombre != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.cocineroNombre!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      trailing: onMarcarServido != null
          ? FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.listo),
              onPressed: onMarcarServido,
              child: const Text('Servido'),
            )
          : Text(
              'S/ ${((item.platoPrecio ?? 0) * item.cantidad).toStringAsFixed(2)}',
              style: const TextStyle(fontFamily: AppTypography.mono),
            ),
    );
  }
}

class _PastillaEstado extends StatelessWidget {
  final String estado;

  const _PastillaEstado({required this.estado});

  static const Map<String, Color> _colorPorEstado = {
    'pendiente': AppColors.pendiente,
    'en_preparacion': AppColors.enPreparacion,
    'listo': AppColors.listo,
    'servido': AppColors.servido,
  };

  static const Map<String, String> _etiquetaPorEstado = {
    'pendiente': 'Pendiente',
    'en_preparacion': 'En preparacion',
    'listo': 'Listo',
    'servido': 'Servido',
  };

  @override
  Widget build(BuildContext context) {
    final color = _colorPorEstado[estado] ?? AppColors.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        _etiquetaPorEstado[estado] ?? estado,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
