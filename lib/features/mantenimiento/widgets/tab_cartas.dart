import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/carta_model.dart';
import '../../../models/plato_model.dart';
import '../../../providers/carta_provider.dart';
import '../../../providers/mantenimiento_provider.dart';
import 'piezas_mantenimiento.dart';
import 'selector_imagen.dart';

const _mesesCortos = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'set', 'oct', 'nov', 'dic'];

String _comoDiaYMes(DateTime fecha) => '${fecha.day} ${_mesesCortos[fecha.month - 1]}';

String _comoFechaDeApi(DateTime fecha) =>
    '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

/// Una carta es lo que se ofrece en un periodo: agrupa platos que ya existen
/// en el catalogo, con su portada y sus fechas de vigencia.
class TabCartas extends StatelessWidget {
  const TabCartas({super.key});

  @override
  Widget build(BuildContext context) {
    final cartas = context.watch<CartaProvider>();
    final lista = cartas.cartas;

    return Column(
      children: [
        EncabezadoDeSeccion(
          titulo: 'Cartas',
          detalle: '${lista.length} cartas · ${lista.where((c) => c.activa).length} vigentes',
          textoBoton: 'Nueva carta',
          alAgregar: () => mostrarFormularioDeCarta(context),
        ),
        if (cartas.error != null) AvisoDeError(mensaje: cartas.error!, alCerrar: cartas.limpiarError),
        Expanded(
          child: cartas.cargando && lista.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: cartas.cargarCartas,
                  child: lista.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 60),
                            MensajeDeListaVacia(
                              icono: Icons.menu_book,
                              mensaje: 'Aun no armas ninguna carta.\nElige platos del catalogo y define desde cuando rigen.',
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          itemCount: lista.length,
                          itemBuilder: (_, i) => _FichaDeCarta(carta: lista[i]),
                        ),
                ),
        ),
      ],
    );
  }
}

class _FichaDeCarta extends StatelessWidget {
  final CartaModel carta;

  const _FichaDeCarta({required this.carta});

  @override
  Widget build(BuildContext context) {
    return TarjetaDeFicha(
      alTocar: () => mostrarFormularioDeCarta(context, carta: carta),
      hijo: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MiniaturaDeFoto(fotoUrl: carta.fotoUrl, iconoVacio: Icons.menu_book, lado: 64),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        carta.nombre,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                      ),
                    ),
                    EtiquetaDeEstado(
                      texto: carta.activa ? 'Vigente' : 'Inactiva',
                      color: carta.activa ? AppColors.sage : AppColors.textDim,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${carta.tipo == 'semanal' ? 'Semanal' : 'Diaria'} · ${_comoDiaYMes(carta.fechaInicio)} al ${_comoDiaYMes(carta.fechaFin)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
                const SizedBox(height: 6),
                Text(
                  '${carta.platos.length} platos incluidos',
                  style: const TextStyle(fontSize: 12, color: AppColors.pine, fontWeight: FontWeight.w600),
                ),
                if (carta.platos.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    carta.platos.map((p) => p.nombre).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void mostrarFormularioDeCarta(BuildContext context, {CartaModel? carta}) {
  final mantenimiento = context.read<MantenimientoProvider>();
  final cartas = context.read<CartaProvider>();
  showDialog(
    context: context,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: mantenimiento),
        ChangeNotifierProvider.value(value: cartas),
      ],
      child: _FormularioDeCarta(carta: carta),
    ),
  );
}

class _FormularioDeCarta extends StatefulWidget {
  final CartaModel? carta;

  const _FormularioDeCarta({this.carta});

  @override
  State<_FormularioDeCarta> createState() => _FormularioDeCartaState();
}

class _FormularioDeCartaState extends State<_FormularioDeCarta> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late String _tipo;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  late Set<int> _platosElegidos;
  ImagenElegida? _imagen;
  bool _guardando = false;
  bool _faltanPlatos = false;

  bool get _esEdicion => widget.carta != null;

  @override
  void initState() {
    super.initState();
    final carta = widget.carta;
    final hoy = DateTime.now();
    _nombre = TextEditingController(text: carta?.nombre ?? '');
    _tipo = carta?.tipo ?? 'diaria';
    _fechaInicio = carta?.fechaInicio ?? DateTime(hoy.year, hoy.month, hoy.day);
    _fechaFin = carta?.fechaFin ?? DateTime(hoy.year, hoy.month, hoy.day);
    _platosElegidos = carta?.platos.map((p) => p.id).toSet() ?? <int>{};
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  /// Cambiar a semanal estira la vigencia a 7 dias: es lo que el dueño espera
  /// al elegir esa opcion, y igual puede corregir las fechas a mano.
  void _cambiarTipo(String tipo) {
    setState(() {
      _tipo = tipo;
      _fechaFin = tipo == 'semanal' ? _fechaInicio.add(const Duration(days: 6)) : _fechaInicio;
    });
  }

  Future<void> _elegirFecha({required bool esInicio}) async {
    final inicial = esInicio ? _fechaInicio : _fechaFin;
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(inicial.year - 1),
      lastDate: DateTime(inicial.year + 2),
    );
    if (elegida == null) return;
    setState(() {
      if (esInicio) {
        _fechaInicio = elegida;
        if (_fechaFin.isBefore(elegida)) _fechaFin = elegida;
      } else {
        _fechaFin = elegida.isBefore(_fechaInicio) ? _fechaInicio : elegida;
      }
    });
  }

  Future<void> _guardar() async {
    final formularioValido = _formulario.currentState!.validate();
    setState(() => _faltanPlatos = _platosElegidos.isEmpty);
    if (!formularioValido || _platosElegidos.isEmpty) return;

    setState(() => _guardando = true);

    final cartas = context.read<CartaProvider>();
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);
    final nombre = _nombre.text.trim();

    int? cartaId;
    if (_esEdicion) {
      final actualizada = await cartas.actualizarCarta(widget.carta!.id, {
        'nombre': nombre,
        'tipo': _tipo,
        'fecha_inicio': _comoFechaDeApi(_fechaInicio),
        'fecha_fin': _comoFechaDeApi(_fechaFin),
        'plato_ids': _platosElegidos.toList(),
      });
      if (actualizada) cartaId = widget.carta!.id;
    } else {
      final creada = await cartas.crearCarta(
        nombre: nombre,
        tipo: _tipo,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        platoIds: _platosElegidos.toList(),
      );
      cartaId = creada?.id;
    }

    if (cartaId != null && _imagen != null) {
      await cartas.subirFotoCarta(cartaId, _imagen!.bytes, _imagen!.nombreArchivo);
    }

    if (!mounted) return;
    if (cartaId == null) {
      setState(() => _guardando = false);
      mensajero.showSnackBar(SnackBar(content: Text(cartas.error ?? 'No se pudo guardar la carta')));
      return;
    }
    navegador.pop();
    mensajero.showSnackBar(SnackBar(content: Text(_esEdicion ? 'Carta actualizada' : 'Carta creada')));
  }

  @override
  Widget build(BuildContext context) {
    final platosDelCatalogo = context.watch<MantenimientoProvider>().platos;

    return DialogoDeFormulario(
      titulo: _esEdicion ? 'Editar carta' : 'Nueva carta',
      guardando: _guardando,
      alGuardar: _guardar,
      contenido: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectorDeFoto(
              imagenElegida: _imagen,
              fotoUrlActual: widget.carta?.fotoUrl,
              alto: 110,
              alElegir: (imagen) => setState(() => _imagen = imagen),
            ),
            const SizedBox(height: 14),
            CampoDeTexto(
              controlador: _nombre,
              etiqueta: 'Nombre de la carta',
              ayuda: 'Menu del dia, Carta de temporada...',
              validar: (v) => (v == null || v.trim().isEmpty) ? 'Ponle un nombre' : null,
            ),
            Row(
              children: [
                _ChipDeTipo(texto: 'Diaria', elegido: _tipo == 'diaria', alElegir: () => _cambiarTipo('diaria')),
                const SizedBox(width: 8),
                _ChipDeTipo(texto: 'Semanal', elegido: _tipo == 'semanal', alElegir: () => _cambiarTipo('semanal')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BotonDeFecha(
                    etiqueta: 'Desde',
                    fecha: _fechaInicio,
                    alTocar: () => _elegirFecha(esInicio: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BotonDeFecha(
                    etiqueta: 'Hasta',
                    fecha: _fechaFin,
                    alTocar: () => _elegirFecha(esInicio: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Platos de esta carta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('${_platosElegidos.length} elegidos',
                    style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
              ],
            ),
            const SizedBox(height: 6),
            _ListaDePlatosSeleccionables(
              platos: platosDelCatalogo,
              elegidos: _platosElegidos,
              alAlternar: (id) => setState(() {
                if (_platosElegidos.contains(id)) {
                  _platosElegidos.remove(id);
                } else {
                  _platosElegidos.add(id);
                }
                _faltanPlatos = false;
              }),
            ),
            if (_faltanPlatos)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Elige al menos un plato', style: TextStyle(color: AppColors.ember, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListaDePlatosSeleccionables extends StatelessWidget {
  final List<PlatoModel> platos;
  final Set<int> elegidos;
  final ValueChanged<int> alAlternar;

  const _ListaDePlatosSeleccionables({
    required this.platos,
    required this.elegidos,
    required this.alAlternar,
  });

  @override
  Widget build(BuildContext context) {
    if (platos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: const Text(
          'No hay platos en el catalogo todavia. Crea platos en la pestaña Platos para poder armar una carta.',
          style: TextStyle(fontSize: 12, color: AppColors.textDim),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        itemCount: platos.length,
        itemBuilder: (_, i) {
          final plato = platos[i];
          return CheckboxListTile(
            dense: true,
            value: elegidos.contains(plato.id),
            onChanged: (_) => alAlternar(plato.id),
            activeColor: AppColors.pine,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(plato.nombre, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              'S/ ${plato.precio.toStringAsFixed(2)}${plato.disponible ? '' : ' · agotado'}',
              style: const TextStyle(fontSize: 11, color: AppColors.textDim),
            ),
          );
        },
      ),
    );
  }
}

class _ChipDeTipo extends StatelessWidget {
  final String texto;
  final bool elegido;
  final VoidCallback alElegir;

  const _ChipDeTipo({required this.texto, required this.elegido, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: elegido,
      onSelected: (_) => alElegir(),
      label: Text(texto),
      labelStyle: TextStyle(color: elegido ? Colors.white : AppColors.ink, fontSize: 13),
      selectedColor: AppColors.pine,
      backgroundColor: AppColors.paper,
      side: const BorderSide(color: AppColors.line),
      showCheckmark: false,
    );
  }
}

class _BotonDeFecha extends StatelessWidget {
  final String etiqueta;
  final DateTime fecha;
  final VoidCallback alTocar;

  const _BotonDeFecha({required this.etiqueta, required this.fecha, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(etiqueta, style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppColors.pine),
                const SizedBox(width: 6),
                Text(
                  '${_comoDiaYMes(fecha)} ${fecha.year}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
