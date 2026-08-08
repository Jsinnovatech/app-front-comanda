import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/plataforma_provider.dart';

/// Alta de un restaurante nuevo con su super_admin, desde el panel de
/// plataforma. Usa el mismo endpoint publico de registro; quien crea esto
/// ya esta logueado como super_admin de plataforma y se queda como tal -
/// no pasa a ser sesion del restaurante nuevo (ver PlataformaProvider).
class CrearRestauranteScreen extends StatefulWidget {
  const CrearRestauranteScreen({super.key});

  @override
  State<CrearRestauranteScreen> createState() => _CrearRestauranteScreenState();
}

class _CrearRestauranteScreenState extends State<CrearRestauranteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _nombreAdminController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  bool _passwordOculta = true;
  bool _guardando = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreAdminController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final exito = await context.read<PlataformaProvider>().crearRestaurante(
          nombre: _nombreController.text.trim(),
          nombreSuperAdmin: _nombreAdminController.text.trim(),
          emailSuperAdmin: _emailController.text.trim(),
          passwordSuperAdmin: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (exito) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            '${_nombreController.text.trim()} creado. El logo se puede agregar entrando a su Mantenimiento.',
            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
          ),
        ),
      );
    } else {
      final error = context.read<PlataformaProvider>().error ?? 'No se pudo crear el restaurante';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.red, content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(title: const Text('Nuevo restaurante')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Datos del restaurante',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreController,
                enabled: !_guardando,
                decoration: const InputDecoration(hintText: 'Nombre del restaurante'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Ingresa un nombre valido' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Cuenta del dueño (super_admin)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black),
              ),
              const SizedBox(height: 4),
              const Text(
                'Esta persona entra con correo y clave a gestionar su propio restaurante.',
                style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nombreAdminController,
                enabled: !_guardando,
                decoration: const InputDecoration(hintText: 'Nombre del dueño'),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Ingresa un nombre valido' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                enabled: !_guardando,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.mail_outline, color: AppColors.yellow),
                ),
                validator: (v) =>
                    (v == null || !v.contains('@') || v.trim().length < 5) ? 'Ingresa un correo valido' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                enabled: !_guardando,
                obscureText: _passwordOculta,
                decoration: InputDecoration(
                  hintText: 'Clave (minimo 8 caracteres)',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.yellow),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordOculta ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textDim,
                    ),
                    onPressed: () => setState(() => _passwordOculta = !_passwordOculta),
                  ),
                ),
                validator: (v) => (v == null || v.length < 8) ? 'Minimo 8 caracteres' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmarPasswordController,
                enabled: !_guardando,
                obscureText: _passwordOculta,
                decoration: const InputDecoration(hintText: 'Repetir clave'),
                validator: (v) => v != _passwordController.text ? 'Las claves no coinciden' : null,
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(AppColors.black),
                        ),
                      )
                    : const Text('Crear restaurante'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
