import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/boton_salir.dart';
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
    final abiertas = caja.comandasAbiertas.length;

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Caja'),
            Text(
              '$abiertas cuenta${abiertas == 1 ? '' : 's'} por cobrar',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.black),
            ),
          ],
        ),
        actions: [
          if ((auth.sesion?.nombre ?? '').isNotEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  auth.sesion!.nombre,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.black),
                ),
              ),
            ),
          BotonSalir(onPressed: () => context.read<AuthProvider>().cerrarSesion()),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.yellow,
        onRefresh: () => context.read<CajaProvider>().cargarComandasAbiertas(),
        child: _contenido(context, caja),
      ),
    );
  }

  Widget _contenido(BuildContext context, CajaProvider caja) {
    if (caja.cargando && caja.comandasAbiertas.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
    }

    if (caja.error != null && caja.comandasAbiertas.isEmpty) {
      return _mensajeCentrado('!', caja.error!, AppColors.red);
    }

    if (caja.comandasAbiertas.isEmpty) {
      return _mensajeCentrado('SIN CUENTAS', 'No hay cuentas abiertas por cobrar', AppColors.textDim);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: caja.comandasAbiertas.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, indice) => _TarjetaCuenta(comanda: caja.comandasAbiertas[indice]),
    );
  }

  /// El mensaje va dentro de un scroll siempre desplazable para que el gesto
  /// de "deslizar para refrescar" siga funcionando con la lista vacia.
  Widget _mensajeCentrado(String rotulo, String texto, Color color) {
    return LayoutBuilder(
      builder: (_, restricciones) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: restricciones.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.yellowSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rotulo,
                      style: const TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w900,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
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
    final items = comanda.items.length;

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _abrirCierre(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🪑', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mesas.isEmpty ? 'Sin mesa' : 'Mesa $mesas',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.black),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#${comanda.id}  ·  $items item${items == 1 ? '' : 's'}  ·  $apertura',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'S/ ${comanda.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.black),
                ),
              ),
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
