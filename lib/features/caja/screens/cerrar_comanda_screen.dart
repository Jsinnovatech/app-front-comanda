import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/comanda_model.dart';
import '../../../models/comprobante_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/caja_provider.dart';

const _etiquetasTipo = {
  'boleta': 'Boleta',
  'factura': 'Factura',
  'nota_venta': 'Nota de venta',
};

String _etiquetaDe(String tipo) => _etiquetasTipo[tipo] ?? tipo;

/// Cierre de cuenta: el ticket de la comanda, el metodo de pago y la emision
/// del comprobante. El tipo que finalmente se emite lo decide el backend
/// segun los permisos SUNAT del restaurante, no esta pantalla.
class CerrarComandaScreen extends StatefulWidget {
  final int comandaId;
  const CerrarComandaScreen({super.key, required this.comandaId});

  @override
  State<CerrarComandaScreen> createState() => _CerrarComandaScreenState();
}

class _CerrarComandaScreenState extends State<CerrarComandaScreen> {
  String _metodoPago = 'efectivo';
  String _tipoSolicitado = 'boleta';
  final _rucController = TextEditingController();
  String? _avisoLocal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final caja = context.read<CajaProvider>();
      final sesion = context.read<AuthProvider>().sesion;
      caja.seleccionarComanda(widget.comandaId);
      if (sesion != null) caja.cargarPermisosSunat(sesion.restauranteId);
    });
  }

  @override
  void dispose() {
    _rucController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caja = context.watch<CajaProvider>();
    final comanda = caja.comandaSeleccionada;

    return Scaffold(
      appBar: AppBar(title: Text('Cuenta #${widget.comandaId}')),
      body: comanda == null
          ? Center(
              child: caja.error != null
                  ? Text(caja.error!, style: const TextStyle(color: AppColors.ember))
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Ticket(comanda: comanda),
                const SizedBox(height: 24),
                if (caja.comprobanteEmitido != null)
                  _ResultadoEmision(
                    comprobante: caja.comprobanteEmitido!,
                    tipoSolicitado: _tipoSolicitado,
                    estadoComanda: comanda.estado,
                  )
                else
                  ..._formularioDeCobro(caja),
                if (caja.error != null) ...[
                  const SizedBox(height: 16),
                  Text(caja.error!, style: const TextStyle(color: AppColors.ember)),
                ],
              ],
            ),
    );
  }

  List<Widget> _formularioDeCobro(CajaProvider caja) {
    final tipoPrevisto = caja.tipoPrevistoPara(_tipoSolicitado);

    return [
      const _TituloSeccion('Metodo de pago'),
      const SizedBox(height: 10),
      Row(
        children: [
          _BotonAlterno(
            icono: Icons.payments_outlined,
            texto: 'Efectivo',
            activo: _metodoPago == 'efectivo',
            onTap: () => setState(() => _metodoPago = 'efectivo'),
          ),
          const SizedBox(width: 12),
          _BotonAlterno(
            icono: Icons.credit_card,
            texto: 'Tarjeta',
            activo: _metodoPago == 'tarjeta',
            onTap: () => setState(() => _metodoPago = 'tarjeta'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const _TituloSeccion('Comprobante'),
      const SizedBox(height: 10),
      Row(
        children: [
          _BotonAlterno(
            icono: Icons.receipt_long,
            texto: 'Boleta',
            activo: _tipoSolicitado == 'boleta',
            onTap: () => setState(() => _tipoSolicitado = 'boleta'),
          ),
          const SizedBox(width: 12),
          _BotonAlterno(
            icono: Icons.business_center_outlined,
            texto: 'Factura',
            activo: _tipoSolicitado == 'factura',
            onTap: () => setState(() => _tipoSolicitado = 'factura'),
          ),
        ],
      ),
      if (_tipoSolicitado == 'factura') ...[
        const SizedBox(height: 14),
        TextField(
          controller: _rucController,
          keyboardType: TextInputType.number,
          maxLength: 11,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'RUC del cliente',
            counterText: '',
            helperText: 'Solo se exige si el restaurante puede emitir factura',
          ),
        ),
      ],
      const SizedBox(height: 16),
      _AvisoTipoPrevisto(tipoSolicitado: _tipoSolicitado, tipoPrevisto: tipoPrevisto),
      if (_avisoLocal != null) ...[
        const SizedBox(height: 12),
        Text(_avisoLocal!, style: const TextStyle(color: AppColors.ember)),
      ],
      const SizedBox(height: 24),
      SizedBox(
        height: 54,
        child: ElevatedButton.icon(
          onPressed: caja.cargando ? null : _cobrar,
          icon: const Icon(Icons.point_of_sale),
          label: Text(caja.cargando ? 'Procesando...' : 'Cerrar cuenta y emitir'),
        ),
      ),
    ];
  }

  Future<void> _cobrar() async {
    final caja = context.read<CajaProvider>();
    final ruc = _rucController.text.trim();

    // El RUC solo bloquea cuando la factura se va a emitir de verdad: si los
    // permisos SUNAT la degradan a nota de venta, no hace falta.
    final exigeRuc = _tipoSolicitado == 'factura' && caja.tipoPrevistoPara('factura') == 'factura';
    if (exigeRuc && ruc.length != 11) {
      setState(() => _avisoLocal = 'La factura necesita un RUC de 11 digitos');
      return;
    }

    setState(() => _avisoLocal = null);
    await caja.cerrarYEmitir(
      metodoPago: _metodoPago,
      tipoSolicitado: _tipoSolicitado,
      rucCliente: ruc,
    );
  }
}

class _Ticket extends StatelessWidget {
  final ComandaModel comanda;
  const _Ticket({required this.comanda});

  @override
  Widget build(BuildContext context) {
    final mesas = comanda.mesas.map((m) => m.numeroONombre).join(', ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mesas.isEmpty ? 'Sin mesa' : 'Mesa $mesas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 14),
          ...comanda.items.map((item) => _FilaItem(item: item)),
          const Divider(height: 28, color: AppColors.line),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text(
                'S/ ${comanda.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: AppTypography.mono,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pine,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilaItem extends StatelessWidget {
  final ComandaItemModel item;
  const _FilaItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final precio = item.platoPrecio;
    final subtotal = precio != null ? precio * item.cantidad : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${item.cantidad}x',
              style: const TextStyle(fontFamily: AppTypography.mono, color: AppColors.textDim),
            ),
          ),
          Expanded(child: Text(item.platoNombre ?? 'Plato ${item.platoId}')),
          Text(
            subtotal != null ? subtotal.toStringAsFixed(2) : '--',
            style: const TextStyle(fontFamily: AppTypography.mono),
          ),
        ],
      ),
    );
  }
}

/// Adelanta al cajero que su boleta/factura saldra como nota de venta. Es
/// informativo, no una advertencia de error: el restaurante simplemente no
/// tiene ese permiso SUNAT activo.
class _AvisoTipoPrevisto extends StatelessWidget {
  final String tipoSolicitado;
  final String? tipoPrevisto;

  const _AvisoTipoPrevisto({required this.tipoSolicitado, required this.tipoPrevisto});

  @override
  Widget build(BuildContext context) {
    final degrada = tipoPrevisto == 'nota_venta' && tipoSolicitado != 'nota_venta';
    final titulo = tipoPrevisto == null
        ? 'Se emitira ${_etiquetaDe(tipoSolicitado)}'
        : 'Se emitira ${_etiquetaDe(tipoPrevisto!)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: degrada ? AppColors.brassSoft.withValues(alpha: 0.35) : AppColors.paper,
        border: Border.all(color: degrada ? AppColors.brass : AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(degrada ? Icons.info_outline : Icons.description_outlined,
              size: 20, color: degrada ? AppColors.brass : AppColors.textDim),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (degrada) ...[
                  const SizedBox(height: 4),
                  Text(
                    'El restaurante no tiene habilitada la emision de ${_etiquetaDe(tipoSolicitado).toLowerCase()} '
                    'ante SUNAT, asi que el documento sale como nota de venta.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Comprobante ya emitido: se muestra el tipo REAL que devolvio el backend.
/// Si no coincide con lo pedido se explica, nunca se presenta como fallo.
class _ResultadoEmision extends StatelessWidget {
  final ComprobanteModel comprobante;
  final String tipoSolicitado;
  final String estadoComanda;

  const _ResultadoEmision({
    required this.comprobante,
    required this.tipoSolicitado,
    required this.estadoComanda,
  });

  @override
  Widget build(BuildContext context) {
    final numeracion = [comprobante.serie, comprobante.numero].whereType<String>().join('-');
    final degradado = comprobante.tipo != tipoSolicitado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.sage, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.sage),
                  const SizedBox(width: 8),
                  Text(
                    'Cuenta ${estadoComanda == 'pagada' ? 'pagada' : 'cerrada'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FilaDato(etiqueta: 'Documento', valor: _etiquetaDe(comprobante.tipo)),
              if (numeracion.isNotEmpty) _FilaDato(etiqueta: 'Numero', valor: numeracion, mono: true),
              _FilaDato(etiqueta: 'Monto', valor: 'S/ ${comprobante.montoTotal.toStringAsFixed(2)}', mono: true),
              if (degradado) ...[
                const SizedBox(height: 12),
                Text(
                  'Se pidio ${_etiquetaDe(tipoSolicitado).toLowerCase()}, pero el restaurante no tiene ese '
                  'permiso SUNAT activo: el documento valido emitido es una ${_etiquetaDe(comprobante.tipo).toLowerCase()}.',
                  style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ControlesImpresion(comprobante: comprobante),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Volver a caja'),
        ),
      ],
    );
  }
}

/// La impresora termica puede estar sin papel o desconectada. El cobro ya
/// esta hecho, por eso el estado de impresion se corrige aparte y nunca
/// invalida el comprobante.
class _ControlesImpresion extends StatelessWidget {
  final ComprobanteModel comprobante;
  const _ControlesImpresion({required this.comprobante});

  @override
  Widget build(BuildContext context) {
    final caja = context.read<CajaProvider>();

    if (comprobante.estadoImpresion == 'impreso') {
      return const Row(
        children: [
          Icon(Icons.print, size: 18, color: AppColors.sage),
          SizedBox(width: 8),
          Text('Comprobante impreso', style: TextStyle(color: AppColors.sage)),
        ],
      );
    }

    final fallo = comprobante.estadoImpresion == 'error_impresora';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (fallo)
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'La impresora reporto un fallo. La cuenta sigue cobrada; reintenta cuando la repongas.',
              style: TextStyle(fontSize: 12, color: AppColors.ember),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => caja.marcarImpreso(comprobante.id),
                icon: const Icon(Icons.print, size: 18),
                label: Text(fallo ? 'Reintentar impresion' : 'Marcar como impreso'),
              ),
            ),
            if (!fallo) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => caja.marcarErrorImpresora(comprobante.id),
                  icon: const Icon(Icons.print_disabled, size: 18),
                  label: const Text('Fallo impresora'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _FilaDato extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool mono;

  const _FilaDato({required this.etiqueta, required this.valor, this.mono = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(color: AppColors.textDim)),
          Text(
            valor,
            style: TextStyle(
              fontFamily: mono ? AppTypography.mono : null,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String texto;
  const _TituloSeccion(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: const TextStyle(fontSize: 12, letterSpacing: 1.2, color: AppColors.textDim, fontWeight: FontWeight.w600),
    );
  }
}

class _BotonAlterno extends StatelessWidget {
  final IconData icono;
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _BotonAlterno({required this.icono, required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: activo ? AppColors.pine : Colors.white,
            border: Border.all(color: activo ? AppColors.pine : AppColors.line, width: activo ? 1.5 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icono, color: activo ? Colors.white : AppColors.textDim),
              const SizedBox(height: 6),
              Text(
                texto,
                style: TextStyle(
                  color: activo ? Colors.white : AppColors.ink,
                  fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
