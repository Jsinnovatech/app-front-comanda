import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/restaurante_model.dart';
import '../../../providers/plataforma_provider.dart';

/// Resumen de plataforma del super_admin. El backend todavia no expone
/// metricas agregadas cross-restaurante (ventas, comandas del sistema), asi
/// que todo lo que se ve aca sale de la lista de restaurantes que ya carga
/// PlataformaProvider - no se inventan cifras.
class PlataformaDashboard extends StatelessWidget {
  const PlataformaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final plataforma = context.watch<PlataformaProvider>();
    final restaurantes = plataforma.restaurantes;

    if (plataforma.cargando && restaurantes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => context.read<PlataformaProvider>().cargarRestaurantes(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (plataforma.error != null)
            _AvisoError(
              mensaje: plataforma.error!,
              alReintentar: () => context.read<PlataformaProvider>().cargarRestaurantes(),
            )
          else if (restaurantes.isEmpty)
            const _SinRestaurantes()
          else ...[
            _TarjetaRestaurantesActivos(restaurantes: restaurantes),
            const SizedBox(height: 20),
            const Text(
              'Restaurantes del sistema',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black),
            ),
            const SizedBox(height: 10),
            for (final restaurante in restaurantes) ...[
              _AcordeonRestaurante(restaurante: restaurante),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _TarjetaRestaurantesActivos extends StatelessWidget {
  final List<RestauranteModel> restaurantes;

  const _TarjetaRestaurantesActivos({required this.restaurantes});

  @override
  Widget build(BuildContext context) {
    final activos = restaurantes.where((r) => r.activo).length;
    final facturadores = restaurantes.where((r) => r.puedeEmitirFactura).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.storefront, size: 18, color: AppColors.yellow),
              SizedBox(width: 8),
              Text(
                'Restaurantes activos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.yellow),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$activos',
            style: const TextStyle(
              fontSize: 46,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'de ${restaurantes.length} registrados · $facturadores puede${facturadores == 1 ? '' : 'n'} emitir factura',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta-acordeon: cerrada muestra lo mismo que antes (logo, nombre,
/// etiquetas de comprobante). Al expandir, pide el resumen (admins + conteo
/// de mesas/mesero/cocinero/cajero) solo para ESE restaurante - no se carga
/// nada de mas hasta que el usuario abre la tarjeta.
class _AcordeonRestaurante extends StatelessWidget {
  final RestauranteModel restaurante;

  const _AcordeonRestaurante({required this.restaurante});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          iconColor: AppColors.yellow,
          collapsedIconColor: AppColors.textDim,
          onExpansionChanged: (abierto) {
            if (abierto) context.read<PlataformaProvider>().cargarResumen(restaurante.id);
          },
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: restaurante.activo ? AppColors.yellowSoft : AppColors.gray,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.storefront,
              size: 20,
              color: restaurante.activo ? AppColors.black : AppColors.textDim,
            ),
          ),
          title: Text(
            restaurante.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.black),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (!restaurante.activo)
                  const _Etiqueta(texto: 'Inactivo', fondo: AppColors.redSoft, tinta: AppColors.red),
                if (restaurante.puedeEmitirBoleta)
                  const _Etiqueta(texto: 'Boleta', fondo: AppColors.greenSoft, tinta: AppColors.green),
                if (restaurante.puedeEmitirFactura)
                  const _Etiqueta(texto: 'Factura', fondo: AppColors.greenSoft, tinta: AppColors.green),
                if (!restaurante.puedeEmitirBoleta && !restaurante.puedeEmitirFactura)
                  const _Etiqueta(texto: 'Solo nota de venta', fondo: AppColors.gray, tinta: AppColors.textDim),
              ],
            ),
          ),
          children: [_ContenidoResumen(restauranteId: restaurante.id)],
        ),
      ),
    );
  }
}

class _ContenidoResumen extends StatelessWidget {
  final int restauranteId;

  const _ContenidoResumen({required this.restauranteId});

  @override
  Widget build(BuildContext context) {
    final plataforma = context.watch<PlataformaProvider>();
    final resumen = plataforma.resumenDe(restauranteId);
    final cargando = plataforma.cargandoResumenDe(restauranteId);

    if (cargando && resumen == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.yellow)),
      );
    }
    if (resumen == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No se pudo cargar el detalle.',
          style: TextStyle(color: AppColors.textDim, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.gray, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ADMINISTRA',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textDim, letterSpacing: 0.6),
          ),
          const SizedBox(height: 6),
          if (resumen.admins.isEmpty)
            const Text(
              'Sin administrador asignado',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.red),
            )
          else
            for (final admin in resumen.admins)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  admin.email != null ? '${admin.nombre} · ${admin.email}' : admin.nombre,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
              ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Metrica(icono: Icons.table_restaurant, valor: resumen.mesas, etiqueta: 'Mesas'),
              _Metrica(icono: Icons.room_service, valor: resumen.meseros, etiqueta: 'Meseros'),
              _Metrica(icono: Icons.soup_kitchen, valor: resumen.cocineros, etiqueta: 'Cocina'),
              _Metrica(icono: Icons.point_of_sale, valor: resumen.cajeros, etiqueta: 'Caja'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final IconData icono;
  final int valor;
  final String etiqueta;

  const _Metrica({required this.icono, required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, size: 18, color: AppColors.black),
          const SizedBox(height: 4),
          Text('$valor', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black)),
          Text(
            etiqueta,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color fondo;
  final Color tinta;

  const _Etiqueta({required this.texto, required this.fondo, required this.tinta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(8)),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: tinta),
      ),
    );
  }
}

class _SinRestaurantes extends StatelessWidget {
  const _SinRestaurantes();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.storefront_outlined, size: 34, color: AppColors.black),
          SizedBox(height: 10),
          Text(
            'Todavia no hay restaurantes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.black),
          ),
          SizedBox(height: 6),
          Text(
            'Crea el primer restaurante desde la pestaña "Restaurantes" para empezar a operar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback alReintentar;

  const _AvisoError({required this.mensaje, required this.alReintentar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red),
          const SizedBox(height: 8),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: alReintentar, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
