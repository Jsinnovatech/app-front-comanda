import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/plato_model.dart';
import '../../../providers/mantenimiento_provider.dart';
import 'piezas_mantenimiento.dart';
import 'selector_imagen.dart';

/// Catalogo de platos: existe una sola vez cada plato, con su foto y precio.
/// Lo que se ofrece hoy se arma en la pestaña Cartas eligiendo de aca.
class TabPlatos extends StatelessWidget {
  const TabPlatos({super.key});

  @override
  Widget build(BuildContext context) {
    final mantenimiento = context.watch<MantenimientoProvider>();
    final platos = mantenimiento.platos;

    return Column(
      children: [
        EncabezadoDeSeccion(
          titulo: 'Platos',
          detalle: '${platos.length} en el catalogo · ${platos.where((p) => p.disponible).length} disponibles',
          textoBoton: 'Nuevo plato',
          alAgregar: () => mostrarFormularioDePlato(context),
        ),
        if (mantenimiento.error != null)
          AvisoDeError(mensaje: mantenimiento.error!, alCerrar: mantenimiento.limpiarError),
        Expanded(
          child: mantenimiento.cargandoPlatos && platos.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: mantenimiento.cargarPlatos,
                  child: platos.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 60),
                            MensajeDeListaVacia(
                              icono: Icons.restaurant_menu,
                              mensaje: 'Todavia no hay platos.\nCrea el primero para poder armar cartas y tomar comandas.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: platos.length,
                          itemBuilder: (_, i) => _FichaDePlato(plato: platos[i]),
                        ),
                ),
        ),
      ],
    );
  }
}

class _FichaDePlato extends StatelessWidget {
  final PlatoModel plato;

  const _FichaDePlato({required this.plato});

  @override
  Widget build(BuildContext context) {
    return TarjetaDeFicha(
      alTocar: () => mostrarFormularioDePlato(context, plato: plato),
      hijo: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiniaturaDeFoto(fotoUrl: plato.fotoUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plato.nombre,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                if (plato.descripcion != null && plato.descripcion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    plato.descripcion!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'S/ ${plato.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Courier New',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pine,
                      ),
                    ),
                    if (plato.categoria != null && plato.categoria!.isNotEmpty) ...[
                      const Text(' · ', style: TextStyle(color: AppColors.textDim)),
                      Flexible(
                        child: Text(
                          plato.categoria!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              EtiquetaDeEstado(
                texto: plato.disponible ? 'Disponible' : 'Agotado',
                color: plato.disponible ? AppColors.sage : AppColors.ember,
              ),
              _MenuDePlato(plato: plato),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuDePlato extends StatelessWidget {
  final PlatoModel plato;

  const _MenuDePlato({required this.plato});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textDim),
      onSelected: (opcion) async {
        final mantenimiento = context.read<MantenimientoProvider>();
        final mensajero = ScaffoldMessenger.of(context);

        switch (opcion) {
          case 'editar':
            mostrarFormularioDePlato(context, plato: plato);
          case 'foto':
            final elegida = await elegirImagenDeGaleria();
            if (elegida == null) return;
            final subida = await mantenimiento.subirFotoPlato(plato.id, elegida.bytes, elegida.nombreArchivo);
            mensajero.showSnackBar(
              SnackBar(content: Text(subida ? 'Foto actualizada' : mantenimiento.error ?? 'No se pudo subir la foto')),
            );
          case 'disponibilidad':
            await mantenimiento.cambiarDisponibilidadPlato(plato);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'editar', child: Text('Editar')),
        const PopupMenuItem(value: 'foto', child: Text('Cambiar foto')),
        PopupMenuItem(
          value: 'disponibilidad',
          child: Text(plato.disponible ? 'Marcar agotado' : 'Marcar disponible'),
        ),
      ],
    );
  }
}

void mostrarFormularioDePlato(BuildContext context, {PlatoModel? plato}) {
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<MantenimientoProvider>(),
      child: _FormularioDePlato(plato: plato),
    ),
  );
}

class _FormularioDePlato extends StatefulWidget {
  final PlatoModel? plato;

  const _FormularioDePlato({this.plato});

  @override
  State<_FormularioDePlato> createState() => _FormularioDePlatoState();
}

class _FormularioDePlatoState extends State<_FormularioDePlato> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _descripcion;
  late final TextEditingController _precio;
  late final TextEditingController _categoria;
  late bool _disponible;
  ImagenElegida? _imagen;
  bool _guardando = false;

  bool get _esEdicion => widget.plato != null;

  @override
  void initState() {
    super.initState();
    final plato = widget.plato;
    _nombre = TextEditingController(text: plato?.nombre ?? '');
    _descripcion = TextEditingController(text: plato?.descripcion ?? '');
    _precio = TextEditingController(text: plato != null ? plato.precio.toStringAsFixed(2) : '');
    _categoria = TextEditingController(text: plato?.categoria ?? '');
    _disponible = plato?.disponible ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _categoria.dispose();
    super.dispose();
  }

  double get _precioIngresado => double.parse(_precio.text.trim().replaceAll(',', '.'));

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);

    final mantenimiento = context.read<MantenimientoProvider>();
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);

    final descripcion = _descripcion.text.trim();
    final categoria = _categoria.text.trim();

    PlatoModel? guardado;
    if (_esEdicion) {
      guardado = await mantenimiento.actualizarPlato(widget.plato!.id, {
        'nombre': _nombre.text.trim(),
        'descripcion': descripcion.isEmpty ? null : descripcion,
        'precio': _precioIngresado,
        'categoria': categoria.isEmpty ? null : categoria,
        'disponible': _disponible,
      });
    } else {
      guardado = await mantenimiento.crearPlato(
        nombre: _nombre.text.trim(),
        descripcion: descripcion.isEmpty ? null : descripcion,
        precio: _precioIngresado,
        categoria: categoria.isEmpty ? null : categoria,
        disponible: _disponible,
      );
    }

    if (guardado != null && _imagen != null) {
      await mantenimiento.subirFotoPlato(guardado.id, _imagen!.bytes, _imagen!.nombreArchivo);
    }

    if (!mounted) return;
    if (guardado == null) {
      setState(() => _guardando = false);
      mensajero.showSnackBar(SnackBar(content: Text(mantenimiento.error ?? 'No se pudo guardar el plato')));
      return;
    }
    navegador.pop();
    mensajero.showSnackBar(SnackBar(content: Text(_esEdicion ? 'Plato actualizado' : 'Plato creado')));
  }

  @override
  Widget build(BuildContext context) {
    return DialogoDeFormulario(
      titulo: _esEdicion ? 'Editar plato' : 'Nuevo plato',
      guardando: _guardando,
      alGuardar: _guardar,
      contenido: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectorDeFoto(
              imagenElegida: _imagen,
              fotoUrlActual: widget.plato?.fotoUrl,
              alElegir: (imagen) => setState(() => _imagen = imagen),
            ),
            const SizedBox(height: 14),
            CampoDeTexto(
              controlador: _nombre,
              etiqueta: 'Nombre del plato',
              validar: (v) => (v == null || v.trim().isEmpty) ? 'Ponle un nombre' : null,
            ),
            CampoDeTexto(controlador: _descripcion, etiqueta: 'Descripcion (opcional)', lineas: 2),
            CampoDeTexto(
              controlador: _precio,
              etiqueta: 'Precio (S/)',
              tipoTeclado: const TextInputType.numberWithOptions(decimal: true),
              validar: (v) {
                final valor = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (valor == null) return 'Precio invalido';
                if (valor <= 0) return 'El precio debe ser mayor a 0';
                return null;
              },
            ),
            CampoDeTexto(
              controlador: _categoria,
              etiqueta: 'Categoria (opcional)',
              ayuda: 'Entradas, Segundos, Bebidas...',
            ),
            SwitchListTile(
              value: _disponible,
              onChanged: (v) => setState(() => _disponible = v),
              title: const Text('Disponible para pedir'),
              activeThumbColor: AppColors.pine,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
