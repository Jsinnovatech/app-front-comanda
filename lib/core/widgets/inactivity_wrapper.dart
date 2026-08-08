import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../navigation_service.dart';
import 'session_warning_dialog.dart';

/// Envuelve toda la app: detecta inactividad (sin toques ni clics) y, tras
/// [_idleTimeout], muestra un dialogo de aviso con cuenta regresiva antes
/// de cerrar sesion. Mismo patron que Casta de Gallos
/// (inactivity_wrapper.dart), adaptado: aca no hace falta navegar a mano -
/// `AuthProvider.cerrarSesion()` pone la sesion en null y `_Portero` en
/// main.dart reacciona solo, redirigiendo al login.
class InactivityWrapper extends StatefulWidget {
  final Widget child;

  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> with WidgetsBindingObserver {
  static const Duration _idleTimeout = Duration(minutes: 5);

  Timer? _idleTimer;
  bool _dialogShowing = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resetIdleTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  /// Solo imprime en debug: `assert` no se ejecuta en release, asi que estos
  /// rastros no llegan a produccion.
  void _rastro(String mensaje) {
    assert(() {
      debugPrint('⏱️ Inactividad: $mensaje');
      return true;
    }());
  }

  void _resetIdleTimer() {
    if (_dialogShowing) return;
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _mostrarAvisoDeCierre);
  }

  Future<void> _mostrarAvisoDeCierre() async {
    // El contexto propio de este widget vive POR ENCIMA del Navigator (esta
    // montado en `MaterialApp.builder`), asi que no sirve para `showDialog`.
    // El del navigatorKey si esta dentro del Navigator.
    final contextoDelNavigator = navigatorKey.currentContext;
    if (contextoDelNavigator == null) {
      _rastro('sin contexto de Navigator, no se muestra el aviso');
      return;
    }
    if (!contextoDelNavigator.read<AuthProvider>().autenticado) {
      _rastro('nadie con sesion abierta, no se muestra el aviso');
      return;
    }

    _rastro('inactividad alcanzada, mostrando aviso');
    _dialogShowing = true;
    try {
      final seguirConectado = await showDialog<bool>(
        context: contextoDelNavigator,
        barrierDismissible: false,
        builder: (_) => const SessionWarningDialog(),
      );
      if (seguirConectado == true) {
        _rastro('el usuario sigue conectado');
        _dialogShowing = false;
        _resetIdleTimer();
      } else {
        _rastro('cerrando sesion por inactividad');
        await _cerrarSesion();
      }
    } finally {
      _dialogShowing = false;
    }
  }

  Future<void> _cerrarSesion() async {
    final contextoDelNavigator = navigatorKey.currentContext;
    if (contextoDelNavigator == null) return;
    final auth = contextoDelNavigator.read<AuthProvider>();
    if (!auth.autenticado) return;
    await auth.cerrarSesion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Cancelar el timer: si sigue corriendo en segundo plano puede
      // disparar el dialogo sin pantalla visible.
      _idleTimer?.cancel();
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;

      // Solo en mobile el "background" es una senal confiable de que el
      // usuario se fue. En web, perder el foco solo significa que se
      // cambio de pestana - el timer de inactividad universal ya cubre
      // el abandono real en ambas plataformas.
      if (!kIsWeb &&
          backgroundedAt != null &&
          DateTime.now().difference(backgroundedAt) > _idleTimeout) {
        _rastro('volvio tras demasiado tiempo en segundo plano');
        _cerrarSesion();
      } else {
        _resetIdleTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetIdleTimer(),
      onPointerMove: (_) => _resetIdleTimer(),
      onPointerSignal: (_) => _resetIdleTimer(),
      child: widget.child,
    );
  }
}
