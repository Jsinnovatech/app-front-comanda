import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../formato_dashboard.dart';
import '../widgets/grafico_ventas_por_dia.dart';
import '../widgets/panel_mesas.dart';
import '../widgets/seccion_dashboard.dart';
import '../widgets/tabla_ranking.dart';
import '../widgets/tarjeta_metrica.dart';

/// Analitica del restaurante para super_admin/admin. Todo lo que se ve aca
/// sale de comandas, personal y mesas reales; lo que el backend todavia no
/// guarda (metodo de pago, costos) se declara como pendiente, no se inventa.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider()..cargar(),
      child: const _VistaDashboard(),
    );
  }
}

class _VistaDashboard extends StatelessWidget {
  const _VistaDashboard();

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final nombre = context.select<AuthProvider, String>((auth) => auth.sesion?.nombre ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del restaurante'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: dashboard.cargando ? null : () => dashboard.cargar(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => dashboard.cargar(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _Encabezado(nombre: nombre, ultimaActualizacion: dashboard.ultimaActualizacion),
            const SizedBox(height: 14),
            _SelectorDeRango(dashboard: dashboard),
            const SizedBox(height: 16),
            if (dashboard.cargando && !dashboard.hayDatos)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (dashboard.error != null)
              _AvisoError(mensaje: dashboard.error!, alReintentar: dashboard.cargar)
            else ...[
              _TarjetasDeMetricas(dashboard: dashboard),
              const SizedBox(height: 16),
              SeccionDashboard(
                titulo: 'Ventas por dia',
                subtitulo: 'Ultimos 7 dias · barra = ingresos, numero arriba = pedidos',
                child: GraficoVentasPorDia(ventas: dashboard.ventasPorDia),
              ),
              SeccionDashboard(
                titulo: 'Top 5 platos',
                subtitulo: 'Por unidades vendidas en el periodo',
                child: dashboard.topPlatos.isEmpty
                    ? const SeccionVacia('Sin platos vendidos en este periodo.')
                    : TablaRanking(
                        filas: dashboard.topPlatos.map((plato) {
                          final lider = dashboard.topPlatos.first.unidades;
                          return FilaRanking(
                            etiqueta: plato.nombre,
                            valor: FormatoDashboard.entero(plato.unidades),
                            detalle: FormatoDashboard.soles(plato.ingresos),
                            proporcion: lider == 0 ? 0 : plato.unidades / lider,
                          );
                        }).toList(),
                      ),
              ),
              SeccionDashboard(
                titulo: 'Meseros',
                subtitulo: 'Comandas cobradas que atendio cada uno',
                child: dashboard.rankingMeseros.isEmpty
                    ? const SeccionVacia('Sin comandas cobradas en este periodo.')
                    : TablaRanking(
                        filas: dashboard.rankingMeseros.map((mesero) {
                          final lider = dashboard.rankingMeseros.first.comandasAtendidas;
                          return FilaRanking(
                            etiqueta: mesero.nombre,
                            valor: FormatoDashboard.entero(mesero.comandasAtendidas),
                            detalle: FormatoDashboard.soles(mesero.ingresos),
                            proporcion: lider == 0 ? 0 : mesero.comandasAtendidas / lider,
                          );
                        }).toList(),
                      ),
              ),
              SeccionDashboard(
                titulo: 'Salon ahora',
                subtitulo: '${dashboard.mesasOcupadas} ocupadas · ${dashboard.mesasLibres} libres',
                child: dashboard.mesas.isEmpty
                    ? const SeccionVacia('Todavia no hay mesas registradas.')
                    : PanelMesas(mesas: dashboard.mesas),
              ),
              _SeccionComprobantes(dashboard: dashboard),
              const _NotaDeLimitaciones(),
            ],
          ],
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final String nombre;
  final DateTime? ultimaActualizacion;

  const _Encabezado({required this.nombre, required this.ultimaActualizacion});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombre.isEmpty ? 'Resumen del negocio' : 'Hola, $nombre',
          style: const TextStyle(
            fontFamily: AppTypography.display,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          ultimaActualizacion == null
              ? 'Cargando datos del restaurante...'
              : 'Actualizado ${FormatoDashboard.horaMinuto(ultimaActualizacion!)}',
          style: const TextStyle(fontSize: 12, color: AppColors.textDim),
        ),
      ],
    );
  }
}

class _SelectorDeRango extends StatelessWidget {
  final DashboardProvider dashboard;

  const _SelectorDeRango({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: RangoDashboard.values.map((rango) {
        final activo = rango == dashboard.rango;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => dashboard.cambiarRango(rango),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: activo ? AppColors.pine : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: activo ? AppColors.pine : AppColors.line),
                ),
                child: Text(
                  rango.etiqueta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: activo ? Colors.white : AppColors.textDim,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TarjetasDeMetricas extends StatelessWidget {
  final DashboardProvider dashboard;

  const _TarjetasDeMetricas({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TarjetaMetrica(
                  titulo: 'Ingresos',
                  valor: FormatoDashboard.soles(dashboard.ingresosTotales),
                  detalle: '${FormatoDashboard.entero(dashboard.unidadesVendidas)} platos vendidos',
                  icono: Icons.payments_outlined,
                  destacada: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TarjetaMetrica(
                  titulo: 'Pedidos cobrados',
                  valor: FormatoDashboard.entero(dashboard.pedidosFinalizados),
                  detalle: 'comandas pagadas o cerradas',
                  icono: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TarjetaMetrica(
                  titulo: 'Ticket promedio',
                  valor: FormatoDashboard.soles(dashboard.ticketPromedio),
                  detalle: 'por comanda cobrada',
                  icono: Icons.trending_up,
                  acento: AppColors.sage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TarjetaMetrica(
                  titulo: 'Comandas abiertas',
                  valor: FormatoDashboard.entero(dashboard.comandasAbiertas),
                  detalle: 'en curso ahora mismo',
                  icono: Icons.local_fire_department_outlined,
                  acento: AppColors.ember,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// El backend no tiene "listar comprobantes": hay que preguntarle uno por
/// comanda. Por eso este conteo no se carga solo, lo pide el admin.
class _SeccionComprobantes extends StatelessWidget {
  final DashboardProvider dashboard;

  const _SeccionComprobantes({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final conteo = dashboard.conteoComprobantes;

    return SeccionDashboard(
      titulo: 'Comprobantes emitidos',
      subtitulo: 'Se consulta comanda por comanda, puede demorar',
      accion: dashboard.cargandoComprobantes
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : TextButton(
              onPressed: dashboard.cargarConteoComprobantes,
              child: Text(conteo == null ? 'Calcular' : 'Recalcular'),
            ),
      child: dashboard.errorComprobantes != null
          ? SeccionVacia('No se pudo contar: ${dashboard.errorComprobantes}')
          : conteo == null
              ? const SeccionVacia('Toca "Calcular" para contar boletas, facturas y notas de venta del periodo.')
              : conteo.isEmpty
                  ? const SeccionVacia('Ninguna comanda del periodo tiene comprobante emitido.')
                  : Row(
                      children: ['boleta', 'factura', 'nota_venta'].map((tipo) {
                        return Expanded(
                          child: Column(
                            children: [
                              Text(
                                FormatoDashboard.entero(conteo[tipo] ?? 0),
                                style: const TextStyle(
                                  fontFamily: AppTypography.mono,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tipo.replaceAll('_', ' '),
                                style: const TextStyle(fontSize: 11, color: AppColors.textDim),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
    );
  }
}

/// Se muestra en vez de graficar ceros: son datos que el backend hoy no guarda.
class _NotaDeLimitaciones extends StatelessWidget {
  const _NotaDeLimitaciones();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.construction_outlined, size: 16, color: AppColors.textDim),
              const SizedBox(width: 6),
              Text(
                'Proximamente',
                style: TextStyle(
                  fontFamily: AppTypography.display,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Distribucion por metodo de pago: el backend recibe el metodo al cerrar la comanda pero no lo guarda, '
            'asi que no hay dato real que mostrar.\n\n'
            'Costos y rentabilidad: el modelo de datos aun no registra costo de insumos por plato.',
            style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;
  final Future<void> Function() alReintentar;

  const _AvisoError({required this.mensaje, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ember),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.ember),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
