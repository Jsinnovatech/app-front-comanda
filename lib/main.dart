import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/inactivity_wrapper.dart';
import 'providers/auth_provider.dart';
import 'models/personal_model.dart';

import 'features/auth/screens/login_selector_screen.dart';
import 'features/mesero/screens/mesero_home_screen.dart';
import 'features/cocina/screens/cocina_screen.dart';
import 'features/caja/screens/caja_screen.dart';
import 'features/mantenimiento/screens/mantenimiento_home_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/plataforma/screens/plataforma_shell_screen.dart';

void main() {
  runApp(const ComandaApp());
}

class ComandaApp extends StatelessWidget {
  const ComandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Comanda',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const _Portero(),
        builder: (context, child) => InactivityWrapper(child: child!),
      ),
    );
  }
}

/// Decide que pantalla mostrar segun el estado de sesion. Unico lugar de la
/// app que sabe "que rol ve que home" - las pantallas de cada feature no
/// se preguntan entre si, ni redirigen por su cuenta.
class _Portero extends StatelessWidget {
  const _Portero();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.autenticado) {
      return const LoginSelectorScreen();
    }

    return _HomePorRol(sesion: auth.sesion!);
  }
}

class _HomePorRol extends StatelessWidget {
  final SesionActual sesion;
  const _HomePorRol({required this.sesion});

  @override
  Widget build(BuildContext context) {
    switch (sesion.tipoColaborador) {
      case 'mesero':
        return const MeseroHomeScreen();
      case 'cocinero':
        return const CocinaScreen();
      case 'cajero':
        return const CajaScreen();
      case 'admin':
        return const _AdminShell();
      case 'super_admin':
        // Si entro a operar un restaurante especifico (via PlataformaShellScreen),
        // ve el mismo shell restaurante-scoped que admin. Si no, ve la plataforma.
        final enModoPlataforma = context.watch<AuthProvider>().enModoPlataforma;
        return enModoPlataforma ? const _AdminShell() : const PlataformaShellScreen();
      default:
        return Scaffold(body: Center(child: Text('Rol desconocido: ${sesion.tipoColaborador}')));
    }
  }
}

/// super_admin (operando un restaurante especifico)/admin ven 2 pestañas:
/// Dashboard (analitica) y Mantenimiento (platos/mesas/personal/cartas).
/// Un solo shell para ambos roles.
class _AdminShell extends StatefulWidget {
  const _AdminShell();

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pantallas = [const DashboardScreen(), const MantenimientoHomeScreen()];
    return Scaffold(
      appBar: auth.enModoPlataforma
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Volver a plataforma',
                onPressed: () => context.read<AuthProvider>().volverAPlataforma(),
              ),
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/icons/logicono.webp', width: 30, height: 30, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Comanda',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3),
                        ),
                        Text(
                          'Operando: ${auth.sesion?.nombre ?? ""}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: pantallas[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Mantenimiento'),
        ],
      ),
    );
  }
}
