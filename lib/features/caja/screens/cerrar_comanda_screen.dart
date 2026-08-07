import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/comanda_model.dart';
import '../../../models/comprobante_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/caja_provider.dart';

const _etiquetasTipo = {
  'boleta': 'Boleta',
  'factura': 'Factura',
  'nota_venta': 'Nota de venta',
};

const _metodosDePago = {
  'efectivo': ('Efectivo', '💵'),
  'tarjeta': ('Tarjeta', '💳'),
  'yape_plin': ('Yape / Plin', '📱'),
  'otro': ('Otro', '🧾'),
};

String _etiquetaDe(String tipo) => _etiquetasTipo[tipo] ?? tipo;

String _nombreMetodo(String metodo) => _metodosDePago[metodo]?.$1 ?? metodo;

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
    final cobrado = caja.comprobanteEmitido != null;

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        title: const Text('Cobrar Mesa'),
        actions: [
          if (comanda != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.table_restaurant, size: 14, color: AppColors.black),
                      const SizedBox(width: 4),
                      Text(
                        _nombreMesa(comanda),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: comanda == null ? _cargandoOError(caja) : _cuerpo(caja, comanda, cobrado),
      bottomNavigationBar: (comanda == null || cobrado) ? null : _barraInferior(caja, comanda),
    );
  }

  Widget _cargandoOError(CajaProvider caja) {
    return Center(
      child: caja.error != null
          ? Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                caja.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
              ),
            )
          : const CircularProgressIndicator(color: AppColors.yellow),
    );
  }

  Widget _cuerpo(CajaProvider caja, ComandaModel comanda, bool cobrado) {
    if (cobrado) {
      return _CobroRealizado(
        comprobante: caja.comprobanteEmitido!,
        tipoSolicitado: _tipoSolicitado,
        mesa: _nombreMesa(comanda),
        metodoPago: _nombreMetodo(_metodoPago),
        total: comanda.total,
      );
    }

    // Decision de negocio pendiente de confirmar por el dueno: no se sabe aun
    // si el IGV va incluido en el precio del plato o se suma aparte. Mientras
    // tanto el desglose se calcula HACIA DENTRO del total que da el backend,
    // para no alterar ni un centavo de lo que realmente se cobra.
    final total = comanda.total;
    final subtotal = total / 1.18;
    final igv = total - subtotal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _TituloSeccion('Resumen del Pedido'),
        const SizedBox(height: 10),
        ...comanda.items.map((item) => _FilaItem(item: item)),
        const SizedBox(height: 12),
        _ResumenMontos(subtotal: subtotal, igv: igv, total: total),
        const SizedBox(height: 18),
        const _TituloSeccion('Método de Pago'),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final entrada in _metodosDePago.entries) ...[
              if (entrada.key != _metodosDePago.keys.first) const SizedBox(width: 8),
              Expanded(
                child: _BotonOpcion(
                  emoji: entrada.value.$2,
                  texto: entrada.value.$1,
                  activo: _metodoPago == entrada.key,
                  onTap: () => setState(() => _metodoPago = entrada.key),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        const _TituloSeccion('Comprobante'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BotonOpcion(
                emoji: '🧾',
                texto: 'Boleta',
                activo: _tipoSolicitado == 'boleta',
                onTap: () => setState(() => _tipoSolicitado = 'boleta'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BotonOpcion(
                emoji: '🏢',
                texto: 'Factura',
                activo: _tipoSolicitado == 'factura',
                onTap: () => setState(() => _tipoSolicitado = 'factura'),
              ),
            ),
          ],
        ),
        if (_tipoSolicitado == 'factura') ...[
          const SizedBox(height: 12),
          TextField(
            controller: _rucController,
            keyboardType: TextInputType.number,
            maxLength: 11,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontWeight: FontWeight.w800),
            decoration: const InputDecoration(
              labelText: 'RUC del cliente',
              counterText: '',
              helperText: 'Solo se exige si el restaurante puede emitir factura',
            ),
          ),
        ],
        const SizedBox(height: 14),
        _AvisoTipoPrevisto(
          tipoSolicitado: _tipoSolicitado,
          tipoPrevisto: caja.tipoPrevistoPara(_tipoSolicitado),
        ),
        const SizedBox(height: 14),
        _TarjetaRecibir(total: total),
        if (_avisoLocal != null) ...[
          const SizedBox(height: 12),
          _Alerta(texto: _avisoLocal!),
        ],
        if (caja.error != null) ...[
          const SizedBox(height: 12),
          _Alerta(texto: caja.error!),
        ],
      ],
    );
  }

  Widget _barraInferior(CajaProvider caja, ComandaModel comanda) {
    final puedeCobrar = !caja.cargando && comanda.items.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: caja.cargando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 14,
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: puedeCobrar ? _cobrar : null,
                  child: Text(caja.cargando ? 'Procesando...' : '✓ Cobrar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nombreMesa(ComandaModel comanda) {
    final mesas = comanda.mesas.map((m) => m.numeroONombre).join(', ');
    return mesas.isEmpty ? 'Sin mesa' : 'Mesa $mesas';
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

/// Linea del pedido. Solo lectura: el cierre de cuenta no edita cantidades ni
/// elimina platos - `CajaProvider` no expone esas operaciones y el prototipo
/// las ubica en la pantalla del mozo, antes de enviar a cocina.
class _FilaItem extends StatelessWidget {
  final ComandaItemModel item;
  const _FilaItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final precio = item.platoPrecio;
    final subtotal = precio != null ? precio * item.cantidad : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('🍽️', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.platoNombre ?? 'Plato ${item.platoId}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  subtotal != null ? 'S/ ${subtotal.toStringAsFixed(2)}' : 'S/ --',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '×${item.cantidad}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenMontos extends StatelessWidget {
  final double subtotal;
  final double igv;
  final double total;

  const _ResumenMontos({required this.subtotal, required this.igv, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _fila('Subtotal', subtotal, AppColors.black),
          const SizedBox(height: 4),
          _fila('IGV (18%)', igv, AppColors.textDim),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.black)),
                Text(
                  'S/ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String etiqueta, double monto, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiqueta, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text('S/ ${monto.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _TarjetaRecibir extends StatelessWidget {
  final double total;
  const _TarjetaRecibir({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'Recibir',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDim),
          ),
          const SizedBox(height: 4),
          Text(
            'S/ ${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.black),
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
        color: degrada ? AppColors.yellowSoft : AppColors.white,
        border: Border.all(color: degrada ? AppColors.yellow : AppColors.line, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(degrada ? Icons.info_outline : Icons.description_outlined,
              size: 20, color: degrada ? AppColors.black : AppColors.textDim),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.black)),
                if (degrada) ...[
                  const SizedBox(height: 4),
                  Text(
                    'El restaurante no tiene habilitada la emision de ${_etiquetaDe(tipoSolicitado).toLowerCase()} '
                    'ante SUNAT, asi que el documento sale como nota de venta.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim),
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

/// Pantalla de confirmacion: el cobro ya ocurrio y el comprobante existe. Se
/// muestra el tipo REAL que devolvio el backend; si no coincide con lo pedido
/// se explica, nunca se presenta como fallo.
class _CobroRealizado extends StatelessWidget {
  final ComprobanteModel comprobante;
  final String tipoSolicitado;
  final String mesa;
  final String metodoPago;
  final double total;

  const _CobroRealizado({
    required this.comprobante,
    required this.tipoSolicitado,
    required this.mesa,
    required this.metodoPago,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final numeracion = [comprobante.serie, comprobante.numero].whereType<String>().join('-');
    final degradado = comprobante.tipo != tipoSolicitado;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      children: [
        const _CheckExito(),
        const SizedBox(height: 18),
        const Text(
          '¡Cobro realizado!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        const SizedBox(height: 6),
        Text(
          '$mesa · $metodoPago',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDim),
        ),
        const SizedBox(height: 4),
        Text(
          'S/ ${total.toStringAsFixed(2)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _FilaDato(etiqueta: 'Documento', valor: _etiquetaDe(comprobante.tipo)),
              if (numeracion.isNotEmpty) _FilaDato(etiqueta: 'Numero', valor: numeracion),
              _FilaDato(etiqueta: 'Monto', valor: 'S/ ${comprobante.montoTotal.toStringAsFixed(2)}'),
              if (degradado) ...[
                const SizedBox(height: 10),
                Text(
                  'Se pidio ${_etiquetaDe(tipoSolicitado).toLowerCase()}, pero el restaurante no tiene ese '
                  'permiso SUNAT activo: el documento valido emitido es una ${_etiquetaDe(comprobante.tipo).toLowerCase()}.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDim),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ControlesImpresion(comprobante: comprobante),
        const SizedBox(height: 20),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Liberar mesa y volver'),
          ),
        ),
      ],
    );
  }
}

/// Check circular con halo verde suave, como el `box-shadow: 0 0 0 12px` del
/// prototipo. Entra con un pequeno rebote para que el cajero note el exito.
class _CheckExito extends StatelessWidget {
  const _CheckExito();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.elasticOut,
        builder: (_, escala, hijo) => Transform.scale(scale: escala, child: hijo),
        child: Container(
          width: 90,
          height: 90,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.green,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.greenSoft, spreadRadius: 12)],
          ),
          child: const Icon(Icons.check, size: 46, color: AppColors.white),
        ),
      ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.print, size: 18, color: AppColors.green),
          SizedBox(width: 8),
          Text('Comprobante impreso',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.green)),
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
            child: _Alerta(
              texto: 'La impresora reporto un fallo. La cuenta sigue cobrada; reintenta cuando la repongas.',
            ),
          ),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => caja.marcarImpreso(comprobante.id),
                  icon: const Icon(Icons.print, size: 18),
                  label: Text(fallo ? 'Reintentar' : 'Marcar impreso'),
                ),
              ),
            ),
            if (!fallo) ...[
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => caja.marcarErrorImpresora(comprobante.id),
                    icon: const Icon(Icons.print_disabled, size: 18),
                    label: const Text('Fallo'),
                  ),
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

  const _FilaDato({required this.etiqueta, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDim)),
          Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.black)),
        ],
      ),
    );
  }
}

class _Alerta extends StatelessWidget {
  final String texto;
  const _Alerta({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.red),
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
      texto,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.black),
    );
  }
}

class _BotonOpcion extends StatelessWidget {
  final String emoji;
  final String texto;
  final bool activo;
  final VoidCallback onTap;

  const _BotonOpcion({required this.emoji, required this.texto, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: activo ? AppColors.yellow : AppColors.white,
          border: Border.all(color: activo ? AppColors.yellow : AppColors.line, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              texto,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.black),
            ),
          ],
        ),
      ),
    );
  }
}
