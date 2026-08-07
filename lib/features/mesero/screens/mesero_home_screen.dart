import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/comanda_model.dart';
import '../../../models/mesa_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/comanda_provider.dart';
import 'detalle_comanda_screen.dart';
import 'nueva_comanda_screen.dart';

/// Tablero de mesas del mesero. Monta el ComandaProvider para todo el modulo:
/// las pantallas hijas lo reciben con .value al navegar, para que mesas y
/// comandas sean el mismo estado en todo el flujo.
class MeseroHomeScreen extends StatelessWidget {
  const MeseroHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ComandaProvider()..cargarMesas(),
      child: const _TableroMesas(),
    );
  }
}

class _TableroMesas extends StatefulWidget {
  const _TableroMesas();

  @override
  State<_TableroMesas> createState() => _TableroMesasState();
}

class _TableroMesasState extends State<_TableroMesas> {
  final Set<int> _mesasAgrupadas = {};

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
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: AppColors.brass),
                  const SizedBox(width: 10),
                  Text(
                    'Mesa ${mesa.numeroONombre} · ${comandas.length} cuentas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ...comandas.map(
              (comanda) => ListTile(
                leading: const Icon(Icons.receipt_long, color: AppColors.pine),
                title: Text('Comanda #${comanda.id}'),
                subtitle: Text('${comanda.items.length} platos'),
                trailing: Text(
                  'S/ ${comanda.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: AppTypography.mono, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _irADetalle(comanda.id);
                },
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppColors.brass),
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
    final provider = context.watch<ComandaProvider>();
    final sesion = context.read<AuthProvider>().sesion;
    final agrupadas = provider.mesas.where((m) => _mesasAgrupadas.contains(m.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(sesion?.nombre ?? 'Mesero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
          ),
        ],
      ),
      floatingActionButton: agrupadas.length > 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.brass,
              foregroundColor: AppColors.ink,
              icon: const Icon(Icons.link),
              label: Text('Comanda para ${agrupadas.length} mesas'),
              onPressed: () => _irANuevaComanda(agrupadas),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: provider.cargarMesas,
        child: provider.cargando && provider.mesas.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (provider.error != null) _AvisoError(mensaje: provider.error!),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        childAspectRatio: 1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: provider.mesas.length,
                      itemBuilder: (_, i) {
                        final mesa = provider.mesas[i];
                        return _TarjetaMesa(
                          mesa: mesa,
                          comandas: provider.comandasDeMesa(mesa.id),
                          agrupada: _mesasAgrupadas.contains(mesa.id),
                          onTap: () => _tocarMesa(mesa),
                          onLongPress: () => _alternarAgrupada(mesa),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Verde punteado = libre, verde solido = ocupada con una cuenta,
/// dorado = comodin (varias cuentas en la misma mesa).
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
    final libre = comandas.isEmpty;
    final comodin = comandas.length > 1;
    final acento = comodin ? AppColors.brass : AppColors.pine;
    final total = comandas.fold<double>(0, (suma, c) => suma + c.total);

    return InkWell(
      onTap: onTap,
      onLongPress: libre ? onLongPress : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: libre ? Colors.white : acento,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: agrupada ? AppColors.brass : acento,
            width: agrupada ? 3 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              comodin ? Icons.groups : Icons.table_restaurant,
              size: 32,
              color: libre ? AppColors.pine : Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              mesa.numeroONombre,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: libre ? AppColors.ink : Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              libre
                  ? (agrupada ? 'Seleccionada' : 'Libre')
                  : comodin
                      ? '${comandas.length} cuentas · S/ ${total.toStringAsFixed(2)}'
                      : 'S/ ${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: AppTypography.mono,
                fontSize: 12,
                color: libre ? AppColors.textDim : Colors.white70,
              ),
            ),
          ],
        ),
      ),
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
      color: AppColors.ember.withValues(alpha: 0.12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.ember, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: const TextStyle(color: AppColors.ember))),
        ],
      ),
    );
  }
}
