import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/mesa_model.dart';
import '../../../providers/mantenimiento_provider.dart';
import 'piezas_mantenimiento.dart';

/// Mesas del local. El estado (libre/ocupada) lo mueve la operacion diaria,
/// pero el admin puede corregirlo aca cuando una mesa quedo trabada.
class TabMesas extends StatelessWidget {
  const TabMesas({super.key});

  @override
  Widget build(BuildContext context) {
    final mantenimiento = context.watch<MantenimientoProvider>();
    final mesas = mantenimiento.mesas;
    final ocupadas = mesas.where((m) => m.estado == 'ocupada').length;

    return Column(
      children: [
        EncabezadoDeSeccion(
          titulo: 'Mesas',
          detalle: '${mesas.length} registradas · $ocupadas ocupadas ahora',
          textoBoton: 'Nueva mesa',
          alAgregar: () => mostrarFormularioDeMesa(context),
        ),
        if (mantenimiento.error != null)
          AvisoDeError(mensaje: mantenimiento.error!, alCerrar: mantenimiento.limpiarError),
        Expanded(
          child: mantenimiento.cargandoMesas && mesas.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: mantenimiento.cargarMesas,
                  child: mesas.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 60),
                            MensajeDeListaVacia(
                              icono: Icons.table_restaurant,
                              mensaje: 'Aun no hay mesas.\nRegistralas para que el mesero pueda abrir comandas.',
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.35,
                          ),
                          itemCount: mesas.length,
                          itemBuilder: (_, i) => _FichaDeMesa(mesa: mesas[i]),
                        ),
                ),
        ),
      ],
    );
  }
}

class _FichaDeMesa extends StatelessWidget {
  final MesaModel mesa;

  const _FichaDeMesa({required this.mesa});

  @override
  Widget build(BuildContext context) {
    final ocupada = mesa.estado == 'ocupada';
    final color = ocupada ? AppColors.ember : AppColors.sage;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => mostrarFormularioDeMesa(context, mesa: mesa),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.table_restaurant, color: color, size: 22),
              Text(
                mesa.numeroONombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              EtiquetaDeEstado(texto: ocupada ? 'Ocupada' : 'Libre', color: color),
            ],
          ),
        ),
      ),
    );
  }
}

void mostrarFormularioDeMesa(BuildContext context, {MesaModel? mesa}) {
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<MantenimientoProvider>(),
      child: _FormularioDeMesa(mesa: mesa),
    ),
  );
}

class _FormularioDeMesa extends StatefulWidget {
  final MesaModel? mesa;

  const _FormularioDeMesa({this.mesa});

  @override
  State<_FormularioDeMesa> createState() => _FormularioDeMesaState();
}

class _FormularioDeMesaState extends State<_FormularioDeMesa> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _numeroONombre;
  late String _estado;
  bool _guardando = false;

  bool get _esEdicion => widget.mesa != null;

  @override
  void initState() {
    super.initState();
    _numeroONombre = TextEditingController(text: widget.mesa?.numeroONombre ?? '');
    _estado = widget.mesa?.estado ?? 'libre';
  }

  @override
  void dispose() {
    _numeroONombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);

    final mantenimiento = context.read<MantenimientoProvider>();
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);
    final nombre = _numeroONombre.text.trim();

    final exito = _esEdicion
        ? await mantenimiento.actualizarMesa(widget.mesa!.id, {'numero_o_nombre': nombre, 'estado': _estado})
        : await mantenimiento.crearMesa(nombre);

    if (!mounted) return;
    if (!exito) {
      setState(() => _guardando = false);
      mensajero.showSnackBar(SnackBar(content: Text(mantenimiento.error ?? 'No se pudo guardar la mesa')));
      return;
    }
    navegador.pop();
    mensajero.showSnackBar(SnackBar(content: Text(_esEdicion ? 'Mesa actualizada' : 'Mesa creada')));
  }

  @override
  Widget build(BuildContext context) {
    return DialogoDeFormulario(
      titulo: _esEdicion ? 'Editar mesa' : 'Nueva mesa',
      guardando: _guardando,
      alGuardar: _guardar,
      contenido: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoDeTexto(
              controlador: _numeroONombre,
              etiqueta: 'Numero o nombre',
              ayuda: 'Mesa 1, Barra 2, Terraza...',
              validar: (v) => (v == null || v.trim().isEmpty) ? 'Indica como se llama la mesa' : null,
            ),
            if (_esEdicion)
              DropdownButtonFormField<String>(
                initialValue: _estado,
                decoration: const InputDecoration(labelText: 'Estado', isDense: true),
                items: const [
                  DropdownMenuItem(value: 'libre', child: Text('Libre')),
                  DropdownMenuItem(value: 'ocupada', child: Text('Ocupada')),
                ],
                onChanged: (v) => setState(() => _estado = v ?? 'libre'),
              ),
          ],
        ),
      ),
    );
  }
}
