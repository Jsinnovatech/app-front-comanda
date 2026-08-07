import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/comanda_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/caja_provider.dart';
import 'cerrar_comanda_screen.dart';

/// Home del cajero: todas las cuentas abiertas del restaurante, sin filtrar
/// por mesero, porque en caja se cobra lo que llegue al mostrador.
class CajaScreen extends StatelessWidget {
  const CajaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CajaProvider()..cargarComandasAbiertas(),
      child: const _CuentasAbiertas(),
    );
  }
}

class _CuentasAbiertas extends StatelessWidget {
  const _CuentasAbiertas();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final caja = context.watch<CajaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caja'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(auth.sesion?.nombre ?? '', style: const TextStyle(fontSize: 13)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesion',
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<CajaProvider>().cargarComandasAbiertas(),
        child: _contenido(context, caja),
      ),
    );
  }

  Widget _contenido(BuildContext context, CajaProvider caja) {
    if (caja.cargando && caja.comandasAbiertas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (caja.error != null && caja.comandasAbiertas.isEmpty) {
      return _mensajeCentrado(caja.error!, AppColors.ember);
    }

    if (caja.comandasAbiertas.isEmpty) {
      return _mensajeCentrado('No hay cuentas abiertas', AppColors.textDim);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: caja.comandasAbiertas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, indice) => _TarjetaCuenta(comanda: caja.comandasAbiertas[indice]),
    );
  }

  /// El mensaje va dentro de un scroll siempre desplazable para que el gesto
  /// de "deslizar para refrescar" siga funcionando con la lista vacia.
  Widget _mensajeCentrado(String texto, Color color) {
    return LayoutBuilder(
      builder: (_, restricciones) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: restricciones.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(texto, textAlign: TextAlign.center, style: TextStyle(color: color)),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaCuenta extends StatelessWidget {
  final ComandaModel comanda;
  const _TarjetaCuenta({required this.comanda});

  @override
  Widget build(BuildContext context) {
    final mesas = comanda.mesas.map((m) => m.numeroONombre).join(', ');
    final apertura = TimeOfDay.fromDateTime(comanda.fechaApertura).format(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirCierre(context),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mesas.isEmpty ? 'Sin mesa' : 'Mesa $mesas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Comanda #${comanda.id}  ·  ${comanda.items.length} items  ·  $apertura',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              Text(
                'S/ ${comanda.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: AppTypography.mono,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pine,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textDim),
            ],
          ),
        ),
      ),
    );
  }

  /// El provider viaja a la pantalla de cierre con `.value` para que ambas
  /// compartan el mismo estado: al volver, la lista ya no trae la cuenta cobrada.
  Future<void> _abrirCierre(BuildContext context) async {
    final caja = context.read<CajaProvider>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: caja,
          child: CerrarComandaScreen(comandaId: comanda.id),
        ),
      ),
    );
    caja.limpiarSeleccion();
  }
}
