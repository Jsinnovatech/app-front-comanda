import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/restaurante_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/plataforma_provider.dart';
import '../../mantenimiento/widgets/piezas_mantenimiento.dart';
import '../../mantenimiento/widgets/selector_imagen.dart';

/// Cartera de restaurantes del super_admin de plataforma: todos los locales
/// del sistema, con la puerta de entrada para operar cualquiera de ellos.
class ListaRestaurantes extends StatefulWidget {
  const ListaRestaurantes({super.key});

  @override
  State<ListaRestaurantes> createState() => _ListaRestaurantesState();
}

class _ListaRestaurantesState extends State<ListaRestaurantes> {
  /// Restaurante al que se esta entrando ahora mismo: entrar mintea un token
  /// nuevo contra el servidor, asi que solo esa tarjeta muestra el spinner.
  int? _entrandoA;

  Future<void> _entrarARestaurante(RestauranteModel restaurante) async {
    setState(() => _entrandoA = restaurante.id);
    try {
      await context.read<AuthProvider>().entrarARestaurante(restaurante.id);
      // El cambio de sesion hace que el portero de main.dart navegue solo:
      // este widget puede haber sido desmontado, por eso no se toca el estado.
    } catch (_) {
      if (!mounted) return;
      setState(() => _entrandoA = null);
      _avisar('No se pudo entrar a ${restaurante.nombre}', AppColors.red);
    }
  }

  Future<void> _eliminarRestaurante(RestauranteModel restaurante) async {
    final proveedor = context.read<PlataformaProvider>();
    final confirmado = await _confirmarEliminacion(restaurante);
    if (confirmado != true) return;

    final elimino = await proveedor.eliminarRestaurante(restaurante.id);
    if (!mounted) return;
    _avisar(
      elimino
          ? '${restaurante.nombre} fue desactivado'
          : proveedor.error ?? 'No se pudo eliminar el restaurante',
      elimino ? AppColors.green : AppColors.red,
    );
  }

  Future<bool?> _confirmarEliminacion(RestauranteModel restaurante) {
    return showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          '¿Eliminar ${restaurante.nombre}?',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        content: const Text(
          'Esta accion desactiva el restaurante, no se puede deshacer desde aqui.',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _avisar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(
          mensaje,
          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plataforma = context.watch<PlataformaProvider>();

    return Scaffold(
      backgroundColor: AppColors.gray,
      body: _cuerpo(plataforma),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.black,
        tooltip: 'Nuevo restaurante',
        onPressed: () => _avisar(
          'Por ahora, registra restaurantes nuevos con el endpoint publico de registro. Pantalla dedicada: pendiente.',
          AppColors.black,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _cuerpo(PlataformaProvider plataforma) {
    if (plataforma.cargando && plataforma.restaurantes.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
    }
    if (plataforma.error != null && plataforma.restaurantes.isEmpty) {
      return _errorSinLista(plataforma);
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: plataforma.cargarRestaurantes,
      child: plataforma.restaurantes.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 60),
                MensajeDeListaVacia(
                  icono: Icons.storefront,
                  mensaje: 'Todavia no hay restaurantes en la plataforma.\nCuando registres el primero, aparecera aca.',
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
              itemCount: plataforma.restaurantes.length,
              itemBuilder: (_, i) => _TarjetaDeRestaurante(
                restaurante: plataforma.restaurantes[i],
                entrando: _entrandoA == plataforma.restaurantes[i].id,
                bloqueado: _entrandoA != null,
                alEditar: () => _entrarARestaurante(plataforma.restaurantes[i]),
                alEliminar: () => _eliminarRestaurante(plataforma.restaurantes[i]),
              ),
            ),
    );
  }

  Widget _errorSinLista(PlataformaProvider plataforma) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppColors.textDim),
            const SizedBox(height: 12),
            Text(
              plataforma.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            BotonAmarillo(
              texto: 'Reintentar',
              alTocar: plataforma.cargarRestaurantes,
              compacto: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaDeRestaurante extends StatelessWidget {
  final RestauranteModel restaurante;
  final bool entrando;
  final bool bloqueado;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;

  const _TarjetaDeRestaurante({
    required this.restaurante,
    required this.entrando,
    required this.bloqueado,
    required this.alEditar,
    required this.alEliminar,
  });

  /// Que puede facturar el local: si no tiene RUC ni permisos, solo emite
  /// nota de venta (documento interno, sin valor tributario).
  String get _detalleTributario {
    final comprobantes = [
      if (restaurante.puedeEmitirBoleta) 'Boleta',
      if (restaurante.puedeEmitirFactura) 'Factura',
    ];
    if (comprobantes.isEmpty) return 'Nota de venta';
    final ruc = restaurante.ruc;
    final conRuc = (ruc != null && ruc.isNotEmpty) ? 'RUC $ruc · ' : '';
    return '$conRuc${comprobantes.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    return TarjetaDeFicha(
      hijo: Row(
        children: [
          MiniaturaDeFoto(fotoUrl: restaurante.fotoUrl, iconoVacio: Icons.storefront, lado: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurante.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.black),
                ),
                const SizedBox(height: 3),
                Text(
                  _detalleTributario,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (entrando)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow),
              ),
            )
          else ...[
            IconButton(
              onPressed: bloqueado ? null : alEditar,
              tooltip: 'Editar',
              icon: const Icon(Icons.settings, color: AppColors.black),
            ),
            IconButton(
              onPressed: bloqueado ? null : alEliminar,
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline, color: AppColors.red),
            ),
          ],
        ],
      ),
    );
  }
}
