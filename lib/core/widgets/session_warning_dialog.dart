import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Dialogo modal que avisa que la sesion esta por cerrarse por inactividad.
/// Devuelve `true` si el usuario toca "Seguir conectado" (cancela el cierre),
/// o `false` si la cuenta regresiva llega a 0 sin respuesta.
class SessionWarningDialog extends StatefulWidget {
  final int secondsToClose;

  const SessionWarningDialog({super.key, this.secondsToClose = 30});

  @override
  State<SessionWarningDialog> createState() => _SessionWarningDialogState();
}

class _SessionWarningDialogState extends State<SessionWarningDialog> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.secondsToClose;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        Navigator.of(context).pop(false);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('¿Sigues ahí?', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text('Tu sesión se cerrará en $_secondsLeft segundos por inactividad.'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.black,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Seguir conectado'),
          ),
        ],
      ),
    );
  }
}
