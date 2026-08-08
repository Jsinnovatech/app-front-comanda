import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/boton_salir.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/plataforma_provider.dart';
import '../widgets/plataforma_dashboard.dart';
import '../widgets/lista_restaurantes.dart';

/// Home del super_admin de plataforma: dueño de Comanda, ve y gestiona
/// TODOS los restaurantes del sistema. No confundir con el _AdminShell
/// (restaurante-scoped) que ve un admin normal, o un super_admin cuando
/// "entra" a operar un restaurante especifico.
class PlataformaShellScreen extends StatelessWidget {
  const PlataformaShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlataformaProvider()..cargarRestaurantes(),
      child: const _PanelDePlataforma(),
    );
  }
}

class _PanelDePlataforma extends StatefulWidget {
  const _PanelDePlataforma();

  @override
  State<_PanelDePlataforma> createState() => _PanelDePlataformaState();
}

class _PanelDePlataformaState extends State<_PanelDePlataforma> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<AuthProvider>().sesion;
    final pantallas = const [PlataformaDashboard(), ListaRestaurantes()];

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.yellow,
        title: Text(sesion != null ? 'Comanda · ${sesion.nombre}' : 'Comanda'),
        actions: [BotonSalir(onPressed: () => context.read<AuthProvider>().cerrarSesion())],
      ),
      body: pantallas[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Restaurantes'),
        ],
      ),
    );
  }
}
