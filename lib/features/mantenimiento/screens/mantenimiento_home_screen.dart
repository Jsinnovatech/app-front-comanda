import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
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
        backgroundColor: AppColors.gray,
        appBar: AppBar(
          backgroundColor: AppColors.yellow,
          elevation: 0,
          titleSpacing: 16,
          toolbarHeight: 62,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Mantenimiento',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              Text(
                sesion != null ? 'Configuracion del local · ${sesion.nombre}' : 'Configuracion del local',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Material(
                color: AppColors.white.withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    context.read<MantenimientoProvider>().cargarTodo();
                    context.read<CartaProvider>().cargarCartas();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(9),
                    child: Icon(Icons.refresh, size: 20, color: AppColors.black),
                  ),
                ),
              ),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(46),
            child: ColoredBox(
              color: AppColors.white,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.yellow,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: AppColors.white,
                labelColor: AppColors.black,
                unselectedLabelColor: AppColors.textDim,
                labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(height: 46, text: 'Platos'),
                  Tab(height: 46, text: 'Mesas'),
                  Tab(height: 46, text: 'Personal'),
                  Tab(height: 46, text: 'Cartas'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [TabPlatos(), TabMesas(), TabPersonal(), TabCartas()],
        ),
      ),
    );
  }
}
