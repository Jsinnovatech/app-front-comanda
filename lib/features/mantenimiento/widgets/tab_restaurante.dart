import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/mantenimiento_provider.dart';
import 'selector_imagen.dart';

/// Identidad del restaurante: nombre y logo, lo unico que el super_admin
/// puede configurar sobre el local en si (no sobre su catalogo/personal).
class TabRestaurante extends StatefulWidget {
  const TabRestaurante({super.key});

  @override
  State<TabRestaurante> createState() => _TabRestauranteState();
}

class _TabRestauranteState extends State<TabRestaurante> {
  final _nombreController = TextEditingController();
  ImagenElegida? _fotoElegida;
  bool _guardandoNombre = false;
  bool _subiendoFoto = false;
  String? _nombreCargadoPara;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardarNombre(int restauranteId) async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;
    setState(() => _guardandoNombre = true);
    final exito = await context.read<MantenimientoProvider>().actualizarNombreRestaurante(restauranteId, nombre);
    if (!mounted) return;
    setState(() => _guardandoNombre = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(exito ? 'Nombre actualizado' : 'No se pudo actualizar el nombre'),
        backgroundColor: exito ? AppColors.green : AppColors.red,
      ),
    );
  }

  Future<void> _subirFoto(int restauranteId, ImagenElegida elegida) async {
    setState(() {
      _fotoElegida = elegida;
      _subiendoFoto = true;
    });
    final exito = await context
        .read<MantenimientoProvider>()
        .subirFotoRestaurante(restauranteId, elegida.bytes, elegida.nombreArchivo);
    if (!mounted) return;
    setState(() => _subiendoFoto = false);
    if (!exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo subir el logo'), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restauranteId = context.read<AuthProvider>().sesion!.restauranteId;
    final mantenimiento = context.watch<MantenimientoProvider>();
    final restaurante = mantenimiento.restaurante;

    if (mantenimiento.cargandoRestaurante && restaurante == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (restaurante == null) {
      return Center(
        child: Text(mantenimiento.error ?? 'No se pudo cargar el restaurante', style: const TextStyle(color: AppColors.red)),
      );
    }

    // Sincroniza el controller una sola vez por restaurante cargado, para no
    // pisar lo que el usuario esta escribiendo en cada rebuild.
    if (_nombreCargadoPara != restaurante.nombre) {
      _nombreController.text = restaurante.nombre;
      _nombreCargadoPara = restaurante.nombre;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Logo del restaurante', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SelectorDeFoto(
              alto: 160,
              imagenElegida: _fotoElegida,
              fotoUrlActual: restaurante.fotoUrl,
              alElegir: (elegida) => _subirFoto(restauranteId, elegida),
            ),
            if (_subiendoFoto)
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Nombre del restaurante', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _nombreController,
          decoration: const InputDecoration(hintText: 'Ej. La Caleta de los Pulgas'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _guardandoNombre ? null : () => _guardarNombre(restauranteId),
          child: _guardandoNombre
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                )
              : const Text('Guardar nombre'),
        ),
      ],
    );
  }
}
