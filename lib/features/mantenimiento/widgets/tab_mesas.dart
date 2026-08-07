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
          textoBoton: '+ Mesa',
          alAgregar: () => mostrarFormularioDeMesa(context),
        ),
        if (mantenimiento.error != null)
          AvisoDeError(mensaje: mantenimiento.error!, alCerrar: mantenimiento.limpiarError),
        Expanded(
          child: mantenimiento.cargandoMesas && mesas.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
              : RefreshIndicator(
                  color: AppColors.yellow,
                  onRefresh: mantenimiento.cargarMesas,
                  child: mesas.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 50),
                            MensajeDeListaVacia(
                              icono: Icons.table_restaurant,
                              mensaje: 'Aun no hay mesas.\nRegistralas para que el mesero pueda abrir comandas.',
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 170,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.25,
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

/// Mismo lenguaje que el tablero del mozo: mesa libre en blanco, mesa
/// ocupada en amarillo, para que la sala se lea de un vistazo.
class _FichaDeMesa extends StatelessWidget {
  final MesaModel mesa;

  const _FichaDeMesa({required this.mesa});

  @override
  Widget build(BuildContext context) {
    final ocupada = mesa.estado == 'ocupada';

    return Material(
      color: ocupada ? AppColors.yellow : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: AppColors.black.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => mostrarFormularioDeMesa(context, mesa: mesa),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.table_restaurant,
                size: 22,
                color: ocupada ? AppColors.black : AppColors.textDim,
              ),
              Text(
                mesa.numeroONombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ocupada ? AppColors.black : AppColors.greenSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ocupada ? 'Ocupada' : 'Libre',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ocupada ? AppColors.yellow : AppColors.green,
                  ),
                ),
              ),
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
      textoGuardar: _esEdicion ? 'Guardar' : 'Crear mesa',
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
            if (_esEdicion) ...[
              const Text(
                'Estado',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDim),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _OpcionDeEstado(
                    texto: 'Libre',
                    elegido: _estado == 'libre',
                    alElegir: () => setState(() => _estado = 'libre'),
                  ),
                  const SizedBox(width: 8),
                  _OpcionDeEstado(
                    texto: 'Ocupada',
                    elegido: _estado == 'ocupada',
                    alElegir: () => setState(() => _estado = 'ocupada'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpcionDeEstado extends StatelessWidget {
  final String texto;
  final bool elegido;
  final VoidCallback alElegir;

  const _OpcionDeEstado({required this.texto, required this.elegido, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: alElegir,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: elegido ? AppColors.yellowSoft : AppColors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: elegido ? AppColors.yellow : AppColors.line,
              width: elegido ? 3 : 2,
            ),
          ),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.black),
          ),
        ),
      ),
    );
  }
}
