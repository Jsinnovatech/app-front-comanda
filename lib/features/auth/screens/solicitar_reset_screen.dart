import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../widgets/aviso_de_error.dart';
import 'resetear_password_screen.dart';

/// Primer paso de recuperar contrasena: pedir el codigo de 6 digitos al correo.
/// Llama a AuthService directo porque no cambia la sesion, no hay nada que
/// notificar al resto de la app.
class SolicitarResetScreen extends StatefulWidget {
  const SolicitarResetScreen({super.key});

  @override
  State<SolicitarResetScreen> createState() => _SolicitarResetScreenState();
}

class _SolicitarResetScreenState extends State<SolicitarResetScreen> {
  final _emailControlador = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _emailControlador.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    final email = _emailControlador.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Ingresa tu correo');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _enviando = true;
      _error = null;
    });

    try {
      final mensaje = await AuthService.solicitarReset(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ResetearPasswordScreen(email: email)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _enviando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor';
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contrasena')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Te enviamos un codigo',
                    style: TextStyle(
                      fontFamily: AppTypography.display,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escribe el correo de tu cuenta. Recibiras un codigo de 6 digitos para crear una contrasena nueva.',
                    style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textDim),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _emailControlador,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !_enviando,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline, color: AppColors.textDim),
                    ),
                    onSubmitted: (_) => _enviarCodigo(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    AvisoDeError(mensaje: _error!),
                  ],
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _enviando ? null : _enviarCodigo,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: _enviando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Enviar codigo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
