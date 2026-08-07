import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';
import '../widgets/aviso_de_error.dart';

const _largoDelCodigo = 6;
const _largoMinimoDePassword = 8;

/// Segundo paso de recuperar contrasena: el codigo que llego al correo mas la
/// contrasena nueva. Termina devolviendo al usuario al selector de login.
class ResetearPasswordScreen extends StatefulWidget {
  final String email;

  const ResetearPasswordScreen({super.key, required this.email});

  @override
  State<ResetearPasswordScreen> createState() => _ResetearPasswordScreenState();
}

class _ResetearPasswordScreenState extends State<ResetearPasswordScreen> {
  final _codigoControlador = TextEditingController();
  final _passwordControlador = TextEditingController();
  final _confirmacionControlador = TextEditingController();
  bool _passwordOculta = true;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _codigoControlador.dispose();
    _passwordControlador.dispose();
    _confirmacionControlador.dispose();
    super.dispose();
  }

  String? _validacionLocal() {
    if (_codigoControlador.text.trim().length != _largoDelCodigo) {
      return 'El codigo tiene $_largoDelCodigo digitos';
    }
    if (_passwordControlador.text.length < _largoMinimoDePassword) {
      return 'La contrasena necesita al menos $_largoMinimoDePassword caracteres';
    }
    if (_passwordControlador.text != _confirmacionControlador.text) {
      return 'Las contrasenas no coinciden';
    }
    return null;
  }

  Future<void> _guardarNuevaPassword() async {
    final problema = _validacionLocal();
    if (problema != null) {
      setState(() => _error = problema);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final mensaje = await AuthService.resetearPassword(
        email: widget.email,
        codigo: _codigoControlador.text.trim(),
        nuevaPassword: _passwordControlador.text,
      );
      if (!mounted) return;
      final mensajero = ScaffoldMessenger.of(context);
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
      mensajero.showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppColors.sage),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _guardando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor';
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contrasena')),
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
                    'Revisa tu correo',
                    style: TextStyle(
                      fontFamily: AppTypography.display,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enviamos el codigo a ${widget.email}',
                    style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textDim),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _codigoControlador,
                    keyboardType: TextInputType.number,
                    enabled: !_guardando,
                    maxLength: _largoDelCodigo,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontFamily: AppTypography.mono,
                      fontSize: 22,
                      letterSpacing: 8,
                      color: AppColors.ink,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Codigo de 6 digitos',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordControlador,
                    obscureText: _passwordOculta,
                    enabled: !_guardando,
                    decoration: InputDecoration(
                      labelText: 'Contrasena nueva',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textDim),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordOculta ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.textDim,
                        ),
                        onPressed: () => setState(() => _passwordOculta = !_passwordOculta),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmacionControlador,
                    obscureText: _passwordOculta,
                    enabled: !_guardando,
                    decoration: const InputDecoration(
                      labelText: 'Repite la contrasena',
                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.textDim),
                    ),
                    onSubmitted: (_) => _guardarNuevaPassword(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    AvisoDeError(mensaje: _error!),
                  ],
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardarNuevaPassword,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                    child: _guardando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Guardar contrasena',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
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
