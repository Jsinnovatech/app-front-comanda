import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/carta_provider.dart';
import '../../../providers/mantenimiento_provider.dart';
import '../widgets/tab_cartas.dart';
import '../widgets/tab_mesas.dart';
import '../widgets/tab_personal.dart';
import '../widgets/tab_platos.dart';

/// Panel de configuracion del restaurante: lo que el dueño arma una vez y
/// luego solo ajusta. Los providers se crean aca y no en `main.dart` porque
/// solo viven mientras la pestaña Mantenimiento esta en pantalla: el resto
/// de la app (mesero, cocina, caja) no necesita estas listas en memoria.
class MantenimientoHomeScreen extends StatelessWidget {
  const MantenimientoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MantenimientoProvider()..cargarTodo()),
        ChangeNotifierProvider(create: (_) => CartaProvider()..cargarCartas()),
      ],
      child: const _PanelDeMantenimiento(),
    );
  }
}

class _PanelDeMantenimiento extends StatelessWidget {
  const _PanelDeMantenimiento();

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<AuthProvider>().sesion;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Mantenimiento',
                style: TextStyle(fontFamily: AppTypography.display, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                sesion != null ? 'Configuracion del local · ${sesion.nombre}' : 'Configuracion del local',
                style: const TextStyle(fontSize: 12, color: AppColors.brassSoft),
              ),
            ],
          ),
          toolbarHeight: 64,
          actions: [
            IconButton(
              tooltip: 'Recargar',
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<MantenimientoProvider>().cargarTodo();
                context.read<CartaProvider>().cargarCartas();
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.brass,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(icon: Icon(Icons.restaurant_menu, size: 18), text: 'Platos', iconMargin: EdgeInsets.only(bottom: 2)),
              Tab(icon: Icon(Icons.table_restaurant, size: 18), text: 'Mesas', iconMargin: EdgeInsets.only(bottom: 2)),
              Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Personal', iconMargin: EdgeInsets.only(bottom: 2)),
              Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Cartas', iconMargin: EdgeInsets.only(bottom: 2)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [TabPlatos(), TabMesas(), TabPersonal(), TabCartas()],
        ),
      ),
    );
  }
}
