import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/marca_comanda.dart';
import 'login_admin_screen.dart';
import 'login_pin_screen.dart';

/// Puerta de entrada: el usuario declara si es personal del local (entra con
/// su PIN en el dispositivo compartido) o administrador (entra con su propia
/// cuenta de correo). No se pide ningun codigo de local: tanto el PIN como el
/// correo identifican por si solos a la persona y a su restaurante.
class LoginSelectorScreen extends StatelessWidget {
  const LoginSelectorScreen({super.key});

  void _abrir(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const EncabezadoLogin(),
              const MarcaTexto(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ingresa con tu perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.black),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Elige como vas a entrar al sistema',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),
                    _OpcionDeEntrada(
                      icono: '🧾',
                      titulo: 'Personal del local',
                      descripcion: 'Mesero, cocina y caja — entra con tu PIN',
                      alTocar: () => _abrir(context, const LoginPinScreen()),
                    ),
                    const SizedBox(height: 10),
                    _OpcionDeEntrada(
                      icono: '📊',
                      titulo: 'Admin / Dueño',
                      descripcion: 'Ventas, platos, personal y carta',
                      alTocar: () => _abrir(context, const LoginAdminScreen()),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'El personal del local entra con su PIN. El administrador entra con su correo y contraseña.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textDim, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const PieDeLogin(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpcionDeEntrada extends StatelessWidget {
  final String icono;
  final String titulo;
  final String descripcion;
  final VoidCallback alTocar;

  const _OpcionDeEntrada({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(icono, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textDim, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.yellow, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}
