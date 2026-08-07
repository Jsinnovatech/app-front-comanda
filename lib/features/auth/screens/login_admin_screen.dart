import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/aviso_de_error.dart';
import '../widgets/marca_comanda.dart';
import 'solicitar_reset_screen.dart';

/// Entrada de super_admin/admin con su propia cuenta: sirve tanto dentro del
/// local como fuera, por eso es correo y contrasena y no PIN de dispositivo.
class LoginAdminScreen extends StatefulWidget {
  const LoginAdminScreen({super.key});

  @override
  State<LoginAdminScreen> createState() => _LoginAdminScreenState();
}

class _LoginAdminScreenState extends State<LoginAdminScreen> {
  final _emailControlador = TextEditingController();
  final _passwordControlador = TextEditingController();
  bool _passwordOculta = true;
  bool _ingresando = false;
  String? _error;

  @override
  void dispose() {
    _emailControlador.dispose();
    _passwordControlador.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    final email = _emailControlador.text.trim();
    final password = _passwordControlador.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Ingresa tu correo y tu contraseña');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _ingresando = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().loginAdmin(email: email, password: password);
      if (!mounted) return;
      // El portero de main.dart ya cambio la pantalla de fondo al notificar
      // AuthProvider; aqui solo se sueltan las rutas de login apiladas encima.
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _ingresando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor';
        _ingresando = false;
      });
    }
  }

  void _irARecuperarPassword() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SolicitarResetScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _ingresando ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.white),
              ),
            ),
            const MarcaComanda(tagline: 'Ventas · Platos · Personal · Carta'),
            Expanded(
              child: PanelClaro(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Ingresa a tu cuenta',
                        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.black),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Para revisar reportes y configurar el restaurante',
                        style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _emailControlador,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enabled: !_ingresando,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.mail_outline, color: AppColors.textDim),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordControlador,
                        obscureText: _passwordOculta,
                        enabled: !_ingresando,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textDim),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordOculta ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textDim,
                            ),
                            onPressed: () => setState(() => _passwordOculta = !_passwordOculta),
                          ),
                        ),
                        onSubmitted: (_) => _ingresar(),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        AvisoDeError(mensaje: _error!),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _ingresando ? null : _ingresar,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                        child: _ingresando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation(AppColors.black),
                                ),
                              )
                            : const Text('Ingresar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _ingresando ? null : _irARecuperarPassword,
                        style: TextButton.styleFrom(foregroundColor: AppColors.black),
                        child: const Text(
                          'Olvidé mi contraseña',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
