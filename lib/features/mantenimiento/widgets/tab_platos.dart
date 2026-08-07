import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/plato_model.dart';
import '../../../providers/mantenimiento_provider.dart';
import 'piezas_mantenimiento.dart';
import 'selector_imagen.dart';

const _todos = 'Todos';
const _sinCategoria = 'Sin categoria';

String _categoriaDe(PlatoModel plato) {
  final categoria = (plato.categoria ?? '').trim();
  return categoria.isEmpty ? _sinCategoria : categoria;
}

/// Catalogo de platos: existe una sola vez cada plato, con su foto y precio.
/// Lo que se ofrece hoy se arma en la pestaña Cartas eligiendo de aca.
class TabPlatos extends StatefulWidget {
  const TabPlatos({super.key});

  @override
  State<TabPlatos> createState() => _TabPlatosState();
}

class _TabPlatosState extends State<TabPlatos> {
  String _categoriaElegida = _todos;

  @override
  Widget build(BuildContext context) {
    final mantenimiento = context.watch<MantenimientoProvider>();
    final platos = mantenimiento.platos;

    final categorias = _categoriasDisponibles(platos);
    // La categoria elegida puede desaparecer al borrar su ultimo plato.
    final categoria = categorias.contains(_categoriaElegida) ? _categoriaElegida : _todos;
    final lista = categoria == _todos ? platos : platos.where((p) => _categoriaDe(p) == categoria).toList();

    return Column(
      children: [
        if (categorias.length > 1)
          SizedBox(
            height: 54,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              itemCount: categorias.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, i) => ChipDeFiltro(
                texto: categorias[i],
                elegido: categorias[i] == categoria,
                alTocar: () => setState(() => _categoriaElegida = categorias[i]),
              ),
            ),
          ),
        EncabezadoDeSeccion(
          titulo: categoria == _todos ? 'Platos' : categoria,
          detalle: '${lista.length} en el catalogo · ${lista.where((p) => p.disponible).length} disponibles',
          textoBoton: '+ Plato',
          alAgregar: () => mostrarFormularioDePlato(context),
        ),
        if (mantenimiento.error != null)
          AvisoDeError(mensaje: mantenimiento.error!, alCerrar: mantenimiento.limpiarError),
        Expanded(
          child: mantenimiento.cargandoPlatos && platos.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
              : RefreshIndicator(
                  color: AppColors.yellow,
                  onRefresh: mantenimiento.cargarPlatos,
                  child: lista.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 50),
                            MensajeDeListaVacia(
                              icono: Icons.restaurant_menu,
                              mensaje: platos.isEmpty
                                  ? 'Todavia no hay platos.\nCrea el primero para poder armar cartas y tomar comandas.'
                                  : 'Aun no hay platos en $categoria.\nAgrega el primero.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                          itemCount: lista.length,
                          itemBuilder: (_, i) => _FichaDePlato(plato: lista[i]),
                        ),
                ),
        ),
      ],
    );
  }

  List<String> _categoriasDisponibles(List<PlatoModel> platos) {
    final conNombre = platos.map(_categoriaDe).where((c) => c != _sinCategoria).toSet().toList()..sort();
    final haySueltos = platos.any((p) => _categoriaDe(p) == _sinCategoria);
    return [_todos, ...conNombre, if (haySueltos) _sinCategoria];
  }
}

class _FichaDePlato extends StatelessWidget {
  final PlatoModel plato;

  const _FichaDePlato({required this.plato});

  @override
  Widget build(BuildContext context) {
    final descripcion = (plato.descripcion ?? '').trim();

    return TarjetaDeFicha(
      alTocar: () => mostrarFormularioDePlato(context, plato: plato),
      hijo: Row(
        children: [
          MiniaturaDeFoto(fotoUrl: plato.fotoUrl, lado: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plato.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.black),
                ),
                if (descripcion.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDim),
                  ),
                ],
                if (!plato.disponible) ...[
                  const SizedBox(height: 6),
                  const EtiquetaDeEstado(texto: 'Agotado', color: AppColors.red),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'S/ ${plato.precio.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppColors.black),
          ),
          _MenuDePlato(plato: plato),
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
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      textoGuardar: _esEdicion ? 'Guardar' : 'Crear plato',
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
            CampoDeTexto(controlador: _descripcion, etiqueta: 'Descripcion corta (opcional)', lineas: 2),
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
              title: const Text(
                'Disponible para pedir',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.black),
              ),
              activeThumbColor: AppColors.yellow,
              activeTrackColor: AppColors.yellowSoft,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
