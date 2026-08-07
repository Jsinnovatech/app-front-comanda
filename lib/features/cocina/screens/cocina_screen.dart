import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/comanda_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cocina_provider.dart';

/// Pantalla tactil de cocina: la cola de platos por preparar como tickets.
/// El refresco es manual (boton en el AppBar o desliz hacia abajo); no hay
/// polling con Timer para el MVP, se decidio no gastar bateria/red del tablet
/// mientras no haya una necesidad medida de tiempo real.
class CocinaScreen extends StatelessWidget {
  const CocinaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CocinaProvider()..cargarItemsPendientes(),
      child: const _VistaCocina(),
    );
  }
}

enum _FiltroEstado { todos, pendientes, enPreparacion }

class _VistaCocina extends StatefulWidget {
  const _VistaCocina();

  @override
  State<_VistaCocina> createState() => _VistaCocinaState();
}

class _VistaCocinaState extends State<_VistaCocina> {
  _FiltroEstado _filtro = _FiltroEstado.todos;

  List<ItemCocinaModel> _aplicarFiltro(List<ItemCocinaModel> items) {
    switch (_filtro) {
      case _FiltroEstado.todos:
        return items;
      case _FiltroEstado.pendientes:
        return items.where((i) => i.estado == 'pendiente').toList();
      case _FiltroEstado.enPreparacion:
        return items.where((i) => i.estado == 'en_preparacion').toList();
    }
  }

  Future<void> _tomarItem(ItemCocinaModel item) async {
    final codigoAcceso = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoPinCocinero(platoNombre: item.platoNombre),
    );
    if (codigoAcceso == null || !mounted) return;

    final cocina = context.read<CocinaProvider>();
    final exito = await cocina.tomarItem(item.id, codigoAcceso);
    if (!mounted) return;
    if (!exito) _avisar(cocina.error ?? 'No se pudo tomar el plato');
  }

  Future<void> _marcarListo(ItemCocinaModel item) async {
    final cocina = context.read<CocinaProvider>();
    final exito = await cocina.marcarListo(item.id);
    if (!mounted) return;
    if (!exito) _avisar(cocina.error ?? 'No se pudo marcar como listo');
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.ember),
    );
  }

  Future<void> _cerrarSesion() async {
    await context.read<AuthProvider>().cerrarSesion();
  }

  @override
  Widget build(BuildContext context) {
    final cocina = context.watch<CocinaProvider>();
    final sesion = context.read<AuthProvider>().sesion;
    final visibles = _aplicarFiltro(cocina.items);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cocina'),
            if (sesion != null)
              Text(
                sesion.nombre,
                style: const TextStyle(fontSize: 12, color: AppColors.brassSoft),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar cola',
            onPressed: cocina.cargando ? null : cocina.cargarItemsPendientes,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesion',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          _BarraFiltros(
            filtro: _filtro,
            conteos: cocina.items,
            alCambiar: (nuevo) => setState(() => _filtro = nuevo),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: cocina.cargarItemsPendientes,
              child: _contenido(cocina, visibles),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenido(CocinaProvider cocina, List<ItemCocinaModel> visibles) {
    if (cocina.cargando && cocina.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cocina.error != null && cocina.items.isEmpty) {
      return _MensajeCentrado(
        icono: Icons.wifi_off,
        titulo: 'No se pudo cargar la cola',
        detalle: cocina.error!,
        accion: FilledButton(onPressed: cocina.cargarItemsPendientes, child: const Text('Reintentar')),
      );
    }
    if (visibles.isEmpty) {
      return const _MensajeCentrado(
        icono: Icons.done_all,
        titulo: 'Sin platos en cola',
        detalle: 'Cuando un mesero envie una comanda aparecera aca.',
      );
    }

    return LayoutBuilder(
      builder: (context, restricciones) {
        final columnas = restricciones.maxWidth >= 1100
            ? 3
            : restricciones.maxWidth >= 720
                ? 2
                : 1;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 208,
          ),
          itemCount: visibles.length,
          itemBuilder: (_, indice) {
            final item = visibles[indice];
            return _TicketCocina(
              item: item,
              alTomar: () => _tomarItem(item),
              alMarcarListo: () => _marcarListo(item),
            );
          },
        );
      },
    );
  }
}

class _BarraFiltros extends StatelessWidget {
  final _FiltroEstado filtro;
  final List<ItemCocinaModel> conteos;
  final ValueChanged<_FiltroEstado> alCambiar;

  const _BarraFiltros({required this.filtro, required this.conteos, required this.alCambiar});

  int _cantidad(_FiltroEstado opcion) {
    switch (opcion) {
      case _FiltroEstado.todos:
        return conteos.length;
      case _FiltroEstado.pendientes:
        return conteos.where((i) => i.estado == 'pendiente').length;
      case _FiltroEstado.enPreparacion:
        return conteos.where((i) => i.estado == 'en_preparacion').length;
    }
  }

  String _etiqueta(_FiltroEstado opcion) {
    switch (opcion) {
      case _FiltroEstado.todos:
        return 'Todos';
      case _FiltroEstado.pendientes:
        return 'Pendientes';
      case _FiltroEstado.enPreparacion:
        return 'En preparacion';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: _FiltroEstado.values.map((opcion) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${_etiqueta(opcion)} (${_cantidad(opcion)})'),
              selected: filtro == opcion,
              onSelected: (_) => alCambiar(opcion),
              selectedColor: AppColors.pine,
              labelStyle: TextStyle(
                color: filtro == opcion ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.line),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TicketCocina extends StatelessWidget {
  final ItemCocinaModel item;
  final VoidCallback alTomar;
  final VoidCallback alMarcarListo;

  const _TicketCocina({required this.item, required this.alTomar, required this.alMarcarListo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
        boxShadow: const [BoxShadow(color: Color(0x0F1C1917), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.mesas.isEmpty ? 'Sin mesa' : item.mesas.join(' + '),
                  style: const TextStyle(
                    fontFamily: AppTypography.mono,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDim,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _PillEstado(estado: item.estado),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brassSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x${item.cantidad}',
                    style: const TextStyle(
                      fontFamily: AppTypography.mono,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.platoNombre,
                        style: const TextStyle(
                          fontFamily: AppTypography.display,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _detalleSecundario(),
                        style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: _accion()),
        ],
      ),
    );
  }

  String _detalleSecundario() {
    if (item.horaTomado == null) return 'Comanda #${item.comandaId}';
    final hora = DateFormat('HH:mm').format(item.horaTomado!.toLocal());
    final quien = item.cocineroNombre ?? 'cocina';
    return 'Tomado $hora por $quien';
  }

  Widget _accion() {
    switch (item.estado) {
      case 'pendiente':
        return ElevatedButton.icon(
          onPressed: alTomar,
          icon: const Icon(Icons.pan_tool_alt, size: 18),
          label: const Text('Tomar'),
        );
      case 'en_preparacion':
        return ElevatedButton.icon(
          onPressed: alMarcarListo,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.sage),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Marcar listo'),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          child: const Text(
            'Avisar al mesero',
            style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
          ),
        );
    }
  }
}

class _PillEstado extends StatelessWidget {
  final String estado;
  const _PillEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = switch (estado) {
      'pendiente' => AppColors.pendiente,
      'en_preparacion' => AppColors.enPreparacion,
      'listo' => AppColors.listo,
      _ => AppColors.servido,
    };
    final texto = switch (estado) {
      'pendiente' => 'Pendiente',
      'en_preparacion' => 'En preparacion',
      'listo' => 'Listo',
      _ => estado,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// El tablet esta logueado como "cocinero" generico, asi que cada cocinero
/// escribe su propio PIN al tomar un plato: es lo unico que permite registrar
/// quien se hizo cargo.
class _DialogoPinCocinero extends StatefulWidget {
  final String platoNombre;
  const _DialogoPinCocinero({required this.platoNombre});

  @override
  State<_DialogoPinCocinero> createState() => _DialogoPinCocineroState();
}

class _DialogoPinCocineroState extends State<_DialogoPinCocinero> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _confirmar() {
    final codigo = _controlador.text.trim();
    if (codigo.isEmpty) return;
    Navigator.of(context).pop(codigo);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tu codigo de acceso'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vas a tomar "${widget.platoNombre}". Ingresa tu PIN para que quede registrado a tu nombre.',
            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controlador,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: AppTypography.mono, fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(hintText: '····'),
            onSubmitted: (_) => _confirmar(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _confirmar, child: const Text('Tomar plato')),
      ],
    );
  }
}

class _MensajeCentrado extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final Widget? accion;

  const _MensajeCentrado({required this.icono, required this.titulo, required this.detalle, this.accion});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
          child: Column(
            children: [
              Icon(icono, size: 44, color: AppColors.textDim),
              const SizedBox(height: 12),
              Text(titulo, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textDim),
              ),
              if (accion != null) ...[const SizedBox(height: 20), accion!],
            ],
          ),
        ),
      ],
    );
  }
}
