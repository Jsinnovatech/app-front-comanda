import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'login_admin_screen.dart';
import 'login_pin_screen.dart';

/// Puerta de entrada: el usuario declara si es personal del local (entra con
/// PIN sobre el dispositivo compartido) o administrador (entra con su propia
/// cuenta de correo).
///
/// El `restaurante_id` se pide aqui y no en el pin pad: el dispositivo del
/// local pertenece a un solo restaurante, mientras que el PIN cambia con cada
/// persona del turno. Separarlos deja el pin pad limpio, sin teclado de texto
/// encima, y hace del codigo del local un dato que se escribe al montar el
/// dispositivo y no en cada turno.
class LoginSelectorScreen extends StatefulWidget {
  const LoginSelectorScreen({super.key});

  @override
  State<LoginSelectorScreen> createState() => _LoginSelectorScreenState();
}

class _LoginSelectorScreenState extends State<LoginSelectorScreen> {
  final _codigoLocalControlador = TextEditingController();
  String? _errorCodigoLocal;

  @override
  void dispose() {
    _codigoLocalControlador.dispose();
    super.dispose();
  }

  void _irAPinDelPersonal() {
    final restauranteId = int.tryParse(_codigoLocalControlador.text.trim());
    if (restauranteId == null || restauranteId <= 0) {
      setState(() => _errorCodigoLocal = 'Ingresa el codigo del local');
      return;
    }
    setState(() => _errorCodigoLocal = null);
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginPinScreen(restauranteId: restauranteId)),
    );
  }

  void _irALoginAdministrador() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginAdminScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _MarcaDelSistema(),
                  const SizedBox(height: 48),
                  Text(
                    'CODIGO DEL LOCAL',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codigoLocalControlador,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      fontFamily: AppTypography.mono,
                      fontSize: 20,
                      letterSpacing: 2,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: '000',
                      errorText: _errorCodigoLocal,
                      prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.textDim),
                    ),
                    onSubmitted: (_) => _irAPinDelPersonal(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _irAPinDelPersonal,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: const Text(
                      'Soy personal del local',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: _irALoginAdministrador,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.pine,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: const BorderSide(color: AppColors.pine, width: 1.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Soy administrador',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'El personal del local entra con su PIN. El administrador entra con su correo y contrasena.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textDim),
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

class _MarcaDelSistema extends StatelessWidget {
  const _MarcaDelSistema();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.pine,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.receipt_long, color: AppColors.brassSoft, size: 36),
        ),
        const SizedBox(height: 20),
        const Text(
          'Comanda',
          style: TextStyle(
            fontFamily: AppTypography.display,
            fontSize: 38,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 44, height: 2, color: AppColors.brass),
        const SizedBox(height: 12),
        const Text(
          'SALON  ·  COCINA  ·  CAJA',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
            color: AppColors.textDim,
          ),
        ),
      ],
    );
  }
}
