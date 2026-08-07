import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/mesa_model.dart';
import '../models/personal_model.dart';
import '../models/plato_model.dart';
import '../models/restaurante_model.dart';
import '../services/mantenimiento_service.dart';

/// Estado del modulo Mantenimiento: platos, mesas y personal viven juntos
/// porque son las tres tablas maestras que el dueño configura en la misma
/// pantalla y casi siempre se cargan de una sola vez al entrar. Las cartas
/// tienen su propio provider (`CartaProvider`) porque son un dominio distinto:
/// componen platos ya existentes y tienen vigencia en el tiempo.
class MantenimientoProvider extends ChangeNotifier {
  List<PlatoModel> _platos = [];
  List<MesaModel> _mesas = [];
  List<PersonalModel> _personal = [];
  RestauranteModel? _restaurante;

  bool _cargandoPlatos = false;
  bool _cargandoMesas = false;
  bool _cargandoPersonal = false;
  bool _cargandoRestaurante = false;
  String? _error;

  List<PlatoModel> get platos => _platos;
  List<MesaModel> get mesas => _mesas;
  List<PersonalModel> get personal => _personal;
  RestauranteModel? get restaurante => _restaurante;

  bool get cargandoPlatos => _cargandoPlatos;
  bool get cargandoMesas => _cargandoMesas;
  bool get cargandoPersonal => _cargandoPersonal;
  bool get cargandoRestaurante => _cargandoRestaurante;
  String? get error => _error;

  void limpiarError() {
    _error = null;
    notifyListeners();
  }

  Future<void> cargarTodo({required int restauranteId}) async {
    await Future.wait([cargarPlatos(), cargarMesas(), cargarPersonal(), cargarRestaurante(restauranteId)]);
  }

  // ---------------- Restaurante ----------------

  Future<void> cargarRestaurante(int restauranteId) async {
    _cargandoRestaurante = true;
    _error = null;
    notifyListeners();
    try {
      _restaurante = await MantenimientoService.obtenerRestaurante(restauranteId);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargandoRestaurante = false;
      notifyListeners();
    }
  }

  Future<bool> actualizarNombreRestaurante(int restauranteId, String nombre) async {
    final actualizado = await _ejecutar(
      () => MantenimientoService.actualizarRestaurante(restauranteId, {'nombre': nombre}),
    );
    if (actualizado == null) return false;
    _restaurante = actualizado;
    notifyListeners();
    return true;
  }

  Future<bool> subirFotoRestaurante(int restauranteId, Uint8List bytes, String nombreArchivo) async {
    final actualizado = await _ejecutar(
      () => MantenimientoService.subirFotoRestaurante(restauranteId, bytes, nombreArchivo),
    );
    if (actualizado == null) return false;
    _restaurante = actualizado;
    notifyListeners();
    return true;
  }

  // ---------------- Platos ----------------

  Future<void> cargarPlatos() async {
    _cargandoPlatos = true;
    _error = null;
    notifyListeners();
    try {
      _platos = await MantenimientoService.listarPlatos();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargandoPlatos = false;
      notifyListeners();
    }
  }

  /// Devuelve el plato creado (no un bool) porque el formulario necesita su
  /// `id` para subir la foto elegida antes de que el plato existiera.
  Future<PlatoModel?> crearPlato({
    required String nombre,
    String? descripcion,
    required double precio,
    String? categoria,
    bool disponible = true,
  }) async {
    return _ejecutar(() async {
      final creado = await MantenimientoService.crearPlato(
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        categoria: categoria,
        disponible: disponible,
      );
      _platos = [..._platos, creado];
      return creado;
    });
  }

  Future<PlatoModel?> actualizarPlato(int id, Map<String, dynamic> cambios) async {
    return _ejecutar(() async {
      final actualizado = await MantenimientoService.actualizarPlato(id, cambios);
      _reemplazarPlato(actualizado);
      return actualizado;
    });
  }

  Future<bool> cambiarDisponibilidadPlato(PlatoModel plato) async {
    final actualizado = await actualizarPlato(plato.id, {'disponible': !plato.disponible});
    return actualizado != null;
  }

  Future<bool> subirFotoPlato(int platoId, Uint8List bytes, String nombreArchivo) async {
    final url = await _ejecutar(() => MantenimientoService.subirFotoPlato(platoId, bytes, nombreArchivo));
    if (url == null) return false;
    _reemplazarPlato(_conFoto(_platos.firstWhere((p) => p.id == platoId), url));
    notifyListeners();
    return true;
  }

  PlatoModel _conFoto(PlatoModel plato, String fotoUrl) => PlatoModel(
        id: plato.id,
        restauranteId: plato.restauranteId,
        nombre: plato.nombre,
        descripcion: plato.descripcion,
        precio: plato.precio,
        categoria: plato.categoria,
        disponible: plato.disponible,
        fotoUrl: fotoUrl,
      );

  void _reemplazarPlato(PlatoModel plato) {
    final indice = _platos.indexWhere((p) => p.id == plato.id);
    if (indice == -1) return;
    _platos[indice] = plato;
  }

  // ---------------- Mesas ----------------

  Future<void> cargarMesas() async {
    _cargandoMesas = true;
    _error = null;
    notifyListeners();
    try {
      _mesas = await MantenimientoService.listarMesas();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargandoMesas = false;
      notifyListeners();
    }
  }

  Future<bool> crearMesa(String numeroONombre) async {
    final creada = await _ejecutar(() async {
      final mesa = await MantenimientoService.crearMesa(numeroONombre);
      _mesas = [..._mesas, mesa];
      return mesa;
    });
    return creada != null;
  }

  Future<bool> actualizarMesa(int id, Map<String, dynamic> cambios) async {
    final actualizada = await _ejecutar(() async {
      final mesa = await MantenimientoService.actualizarMesa(id, cambios);
      final indice = _mesas.indexWhere((m) => m.id == id);
      if (indice != -1) _mesas[indice] = mesa;
      return mesa;
    });
    return actualizada != null;
  }

  // ---------------- Personal ----------------

  Future<void> cargarPersonal() async {
    _cargandoPersonal = true;
    _error = null;
    notifyListeners();
    try {
      _personal = await MantenimientoService.listarPersonal();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _cargandoPersonal = false;
      notifyListeners();
    }
  }

  /// El backend exige credenciales distintas segun el tipo: PIN para quien
  /// trabaja en piso (mesero/cocinero/cajero) y email+password para admin.
  /// El formulario decide cuales manda; aca solo se reenvian los que llegaron.
  Future<bool> crearPersonal({
    required String nombre,
    required String tipoColaboradorCodigo,
    String? codigoAcceso,
    String? email,
    String? password,
  }) async {
    final creado = await _ejecutar(() async {
      final persona = await MantenimientoService.crearPersonal(
        nombre: nombre,
        tipoColaboradorCodigo: tipoColaboradorCodigo,
        codigoAcceso: codigoAcceso,
        email: email,
        password: password,
      );
      _personal = [..._personal, persona];
      return persona;
    });
    return creado != null;
  }

  Future<bool> actualizarPersonal(int id, Map<String, dynamic> cambios) async {
    final actualizado = await _ejecutar(() async {
      final persona = await MantenimientoService.actualizarPersonal(id, cambios);
      final indice = _personal.indexWhere((p) => p.id == id);
      if (indice != -1) _personal[indice] = persona;
      return persona;
    });
    return actualizado != null;
  }

  Future<bool> cambiarActivoPersonal(PersonalModel persona) async {
    return actualizarPersonal(persona.id, {'activo': !persona.activo});
  }

  /// Envoltorio comun de las mutaciones: deja el error listo para que la UI
  /// lo muestre y devuelve `null` cuando la llamada fallo.
  Future<T?> _ejecutar<T>(Future<T> Function() accion) async {
    _error = null;
    try {
      final resultado = await accion();
      notifyListeners();
      return resultado;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
}
