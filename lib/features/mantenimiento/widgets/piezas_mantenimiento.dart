import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Barra superior de cada seccion: que se esta viendo, cuantos hay y el
/// boton para agregar uno nuevo. Se repite en las 4 pestañas para que el
/// panel se sienta uno solo y no cuatro pantallas distintas.
class EncabezadoDeSeccion extends StatelessWidget {
  final String titulo;
  final String detalle;
  final String textoBoton;
  final VoidCallback alAgregar;

  const EncabezadoDeSeccion({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.textoBoton,
    required this.alAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: AppTypography.display,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detalle, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: alAgregar,
            icon: const Icon(Icons.add, size: 18),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
            label: Text(textoBoton),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de estado (disponible/agotado, libre/ocupada, activa/vencida).
class EtiquetaDeEstado extends StatelessWidget {
  final String texto;
  final Color color;

  const EtiquetaDeEstado({super.key, required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class MensajeDeListaVacia extends StatelessWidget {
  final IconData icono;
  final String mensaje;

  const MensajeDeListaVacia({super.key, required this.icono, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 44, color: AppColors.textDim.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta blanca con borde fino: la unidad visual de todas las listas del
/// modulo (un plato, una mesa, un colaborador, una carta).
class TarjetaDeFicha extends StatelessWidget {
  final Widget hijo;
  final VoidCallback? alTocar;

  const TarjetaDeFicha({super.key, required this.hijo, this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: alTocar,
          child: Padding(padding: const EdgeInsets.all(12), child: hijo),
        ),
      ),
    );
  }
}

/// Aviso de error de la API arriba de la lista, sin tapar el contenido.
class AvisoDeError extends StatelessWidget {
  final String mensaje;
  final VoidCallback alCerrar;

  const AvisoDeError({super.key, required this.mensaje, required this.alCerrar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ember.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ember.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.ember, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: const TextStyle(color: AppColors.ember, fontSize: 13))),
          InkWell(onTap: alCerrar, child: const Icon(Icons.close, color: AppColors.ember, size: 18)),
        ],
      ),
    );
  }
}

/// Envoltorio comun de los formularios: titulo, contenido desplazable y
/// botones Cancelar/Guardar con indicador mientras se envia.
class DialogoDeFormulario extends StatelessWidget {
  final String titulo;
  final Widget contenido;
  final bool guardando;
  final VoidCallback alGuardar;
  final String textoGuardar;

  const DialogoDeFormulario({
    super.key,
    required this.titulo,
    required this.contenido,
    required this.guardando,
    required this.alGuardar,
    this.textoGuardar = 'Guardar',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(titulo, style: const TextStyle(fontFamily: AppTypography.display, fontSize: 20)),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: contenido)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: AppColors.textDim)),
        ),
        ElevatedButton(
          onPressed: guardando ? null : alGuardar,
          child: guardando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(textoGuardar),
        ),
      ],
    );
  }
}

/// Campo de texto con el mismo espaciado en todos los formularios.
class CampoDeTexto extends StatelessWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final String? ayuda;
  final bool obscuro;
  final TextInputType? tipoTeclado;
  final int lineas;
  final String? Function(String?)? validar;

  const CampoDeTexto({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.ayuda,
    this.obscuro = false,
    this.tipoTeclado,
    this.lineas = 1,
    this.validar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controlador,
        obscureText: obscuro,
        keyboardType: tipoTeclado,
        maxLines: lineas,
        decoration: InputDecoration(labelText: etiqueta, helperText: ayuda, isDense: true),
        validator: validar,
      ),
    );
  }
}
