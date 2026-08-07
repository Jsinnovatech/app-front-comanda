import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/personal_model.dart';
import '../../../providers/mantenimiento_provider.dart';
import 'piezas_mantenimiento.dart';

/// Tipos que el admin puede dar de alta. `super_admin` no aparece: nace con
/// el restaurante y no se crea desde aca.
const _tiposDeColaborador = <String, String>{
  'mesero': 'Mesero',
  'cocinero': 'Cocinero',
  'cajero': 'Cajero',
  'admin': 'Administrador',
};

const _iconosPorTipo = <String, IconData>{
  'mesero': Icons.room_service,
  'cocinero': Icons.soup_kitchen,
  'cajero': Icons.point_of_sale,
  'admin': Icons.admin_panel_settings,
  'super_admin': Icons.workspace_premium,
};

const _gruposPorTipo = <String, String>{
  'cocinero': 'Cocineros',
  'mesero': 'Meseros',
  'cajero': 'Cajeros',
  'admin': 'Administradores',
  'super_admin': 'Dueño',
};

const _ordenDeGrupos = ['cocinero', 'mesero', 'cajero', 'admin', 'super_admin'];

/// Quien entra con PIN y quien entra con email+password: los roles de piso
/// comparten tablet y se identifican con un codigo corto; el administrador
/// entra desde su propio equipo con credenciales completas.
bool entraConPin(String tipoColaboradorCodigo) =>
    tipoColaboradorCodigo == 'mesero' || tipoColaboradorCodigo == 'cocinero' || tipoColaboradorCodigo == 'cajero';

class TabPersonal extends StatelessWidget {
  const TabPersonal({super.key});

  @override
  Widget build(BuildContext context) {
    final mantenimiento = context.watch<MantenimientoProvider>();
    final personal = mantenimiento.personal;
    final activos = personal.where((p) => p.activo).length;

    return Column(
      children: [
        EncabezadoDeSeccion(
          titulo: 'Personal',
          detalle: '${personal.length} colaboradores · $activos activos',
          textoBoton: '+ Persona',
          alAgregar: () => mostrarFormularioDePersonal(context),
        ),
        if (mantenimiento.error != null)
          AvisoDeError(mensaje: mantenimiento.error!, alCerrar: mantenimiento.limpiarError),
        Expanded(
          child: mantenimiento.cargandoPersonal && personal.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
              : RefreshIndicator(
                  color: AppColors.yellow,
                  onRefresh: mantenimiento.cargarPersonal,
                  child: personal.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 50),
                            MensajeDeListaVacia(
                              icono: Icons.badge_outlined,
                              mensaje: 'Aun no registras colaboradores.\nCrea meseros, cocineros y cajeros con su PIN.',
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                          children: _porRol(personal),
                        ),
                ),
        ),
      ],
    );
  }

  /// Se listan por rol (como los ve el dueño al armar turnos), no en el orden
  /// en que se crearon.
  List<Widget> _porRol(List<PersonalModel> personal) {
    final tiposPresentes = personal.map((p) => p.tipoColaboradorCodigo).toSet();
    final tipos = [
      ..._ordenDeGrupos.where(tiposPresentes.contains),
      ...tiposPresentes.where((t) => !_ordenDeGrupos.contains(t)),
    ];

    final bloques = <Widget>[];
    for (final tipo in tipos) {
      final grupo = personal.where((p) => p.tipoColaboradorCodigo == tipo).toList();
      bloques.add(Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TituloDeGrupo(
          texto: '${_gruposPorTipo[tipo] ?? tipo} (${grupo.length})',
          icono: _iconosPorTipo[tipo] ?? Icons.person,
        ),
      ));
      bloques.addAll(grupo.map((persona) => _FichaDePersonal(persona: persona)));
    }
    return bloques;
  }
}

class _FichaDePersonal extends StatelessWidget {
  final PersonalModel persona;

  const _FichaDePersonal({required this.persona});

  @override
  Widget build(BuildContext context) {
    final mantenimiento = context.read<MantenimientoProvider>();
    final esSuperAdmin = persona.tipoColaboradorCodigo == 'super_admin';

    return TarjetaDeFicha(
      alTocar: esSuperAdmin ? null : () => mostrarFormularioDePersonal(context, persona: persona),
      hijo: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  persona.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  entraConPin(persona.tipoColaboradorCodigo) ? 'Entra con PIN' : 'Entra con correo',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (esSuperAdmin)
            const EtiquetaDeEstado(texto: 'Dueño', color: AppColors.yellow)
          else
            _InterruptorDeEstado(persona: persona, alAlternar: () => mantenimiento.cambiarActivoPersonal(persona)),
        ],
      ),
    );
  }
}

/// El estado se ve como texto (asi lo lee el dueño de un vistazo) y ese mismo
/// texto es el boton que lo da de baja: no hace falta abrir el formulario.
class _InterruptorDeEstado extends StatelessWidget {
  final PersonalModel persona;
  final VoidCallback alAlternar;

  const _InterruptorDeEstado({required this.persona, required this.alAlternar});

  @override
  Widget build(BuildContext context) {
    final activo = persona.activo;

    return Tooltip(
      message: activo ? 'Tocar para dar de baja' : 'Tocar para reactivar',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: alAlternar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            activo ? '● Activo' : '○ Inactivo',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: activo ? AppColors.green : AppColors.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

void mostrarFormularioDePersonal(BuildContext context, {PersonalModel? persona}) {
  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<MantenimientoProvider>(),
      child: _FormularioDePersonal(persona: persona),
    ),
  );
}

/// El formulario cambia de forma segun el tipo elegido: los roles de piso
/// piden PIN y el administrador pide correo + contraseña. Es la misma regla
/// que valida el backend, asi que el campo que no aplica ni se muestra ni
/// se envia.
class _FormularioDePersonal extends StatefulWidget {
  final PersonalModel? persona;

  const _FormularioDePersonal({this.persona});

  @override
  State<_FormularioDePersonal> createState() => _FormularioDePersonalState();
}

class _FormularioDePersonalState extends State<_FormularioDePersonal> {
  final _formulario = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  final _codigoAcceso = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late String _tipo;
  late bool _activo;
  bool _guardando = false;

  bool get _esEdicion => widget.persona != null;
  bool get _pideCodigo => entraConPin(_tipo);

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.persona?.nombre ?? '');
    _tipo = widget.persona?.tipoColaboradorCodigo ?? 'mesero';
    _activo = widget.persona?.activo ?? true;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _codigoAcceso.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);

    final mantenimiento = context.read<MantenimientoProvider>();
    final navegador = Navigator.of(context);
    final mensajero = ScaffoldMessenger.of(context);

    final nombre = _nombre.text.trim();
    final codigo = _codigoAcceso.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    final bool exito;
    if (_esEdicion) {
      // En edicion las credenciales son opcionales: campo vacio = no se toca.
      exito = await mantenimiento.actualizarPersonal(widget.persona!.id, {
        'nombre': nombre,
        'activo': _activo,
        if (_pideCodigo && codigo.isNotEmpty) 'codigo_acceso': codigo,
        if (!_pideCodigo && email.isNotEmpty) 'email': email,
        if (!_pideCodigo && password.isNotEmpty) 'password': password,
      });
    } else {
      exito = await mantenimiento.crearPersonal(
        nombre: nombre,
        tipoColaboradorCodigo: _tipo,
        codigoAcceso: _pideCodigo ? codigo : null,
        email: _pideCodigo ? null : email,
        password: _pideCodigo ? null : password,
      );
    }

    if (!mounted) return;
    if (!exito) {
      setState(() => _guardando = false);
      mensajero.showSnackBar(SnackBar(content: Text(mantenimiento.error ?? 'No se pudo guardar el colaborador')));
      return;
    }
    navegador.pop();
    mensajero.showSnackBar(SnackBar(content: Text(_esEdicion ? 'Colaborador actualizado' : 'Colaborador creado')));
  }

  String? _validarCodigo(String? valor) {
    final codigo = (valor ?? '').trim();
    if (codigo.isEmpty) return _esEdicion ? null : 'El PIN es obligatorio para este rol';
    if (codigo.length < 4) return 'Usa al menos 4 digitos';
    if (int.tryParse(codigo) == null) return 'Solo numeros';
    return null;
  }

  String? _validarEmail(String? valor) {
    final email = (valor ?? '').trim();
    if (email.isEmpty) return _esEdicion ? null : 'El correo es obligatorio para un administrador';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Correo invalido';
    return null;
  }

  String? _validarPassword(String? valor) {
    final password = valor ?? '';
    if (password.isEmpty) return _esEdicion ? null : 'Define una contraseña';
    if (password.length < 8) return 'Minimo 8 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DialogoDeFormulario(
      titulo: _esEdicion ? 'Editar colaborador' : 'Nuevo colaborador',
      guardando: _guardando,
      alGuardar: _guardar,
      textoGuardar: _esEdicion ? 'Guardar' : 'Registrar',
      contenido: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CampoDeTexto(
              controlador: _nombre,
              etiqueta: 'Nombre completo',
              validar: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
            ),
            if (_esEdicion)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Rol: ${_tiposDeColaborador[_tipo] ?? _tipo}',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDim),
                ),
              )
            else
              _SelectorDeTipo(
                tipoElegido: _tipo,
                alElegir: (tipo) => setState(() => _tipo = tipo),
              ),
            const SizedBox(height: 4),
            if (_pideCodigo)
              CampoDeTexto(
                controlador: _codigoAcceso,
                etiqueta: _esEdicion ? 'Nuevo PIN (opcional)' : 'PIN de acceso',
                ayuda: _esEdicion
                    ? 'Dejalo vacio para conservar el PIN actual'
                    : 'Con este codigo entra al tablet del local',
                obscuro: true,
                tipoTeclado: TextInputType.number,
                validar: _validarCodigo,
              )
            else ...[
              CampoDeTexto(
                controlador: _email,
                etiqueta: _esEdicion ? 'Nuevo correo (opcional)' : 'Correo',
                tipoTeclado: TextInputType.emailAddress,
                validar: _validarEmail,
              ),
              CampoDeTexto(
                controlador: _password,
                etiqueta: _esEdicion ? 'Nueva contraseña (opcional)' : 'Contraseña',
                ayuda: 'Minimo 8 caracteres',
                obscuro: true,
                validar: _validarPassword,
              ),
            ],
            if (_esEdicion)
              SwitchListTile(
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
                title: const Text(
                  'Puede iniciar sesion',
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

/// Los roles se eligen como botones grandes y no como lista desplegable:
/// es la decision que mas cambia el formulario, conviene verla entera.
class _SelectorDeTipo extends StatelessWidget {
  final String tipoElegido;
  final ValueChanged<String> alElegir;

  const _SelectorDeTipo({required this.tipoElegido, required this.alElegir});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rol',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDim),
          ),
          const SizedBox(height: 8),
          Row(
            children: _tiposDeColaborador.entries.map((tipo) {
              final elegido = tipo.key == tipoElegido;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => alElegir(tipo.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: elegido ? AppColors.yellowSoft : AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: elegido ? AppColors.yellow : AppColors.line,
                          width: elegido ? 3 : 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(_iconosPorTipo[tipo.key], size: 18, color: AppColors.black),
                          const SizedBox(height: 4),
                          Text(
                            tipo.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
