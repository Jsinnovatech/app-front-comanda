import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Boton amarillo de accion (agregar, guardar): el mismo peso y radio en
/// todo el modulo para que "lo que crea algo" siempre se vea igual.
class BotonAmarillo extends StatelessWidget {
  final String texto;
  final VoidCallback? alTocar;
  final bool compacto;

  const BotonAmarillo({
    super.key,
    required this.texto,
    required this.alTocar,
    this.compacto = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: alTocar,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.black,
        disabledBackgroundColor: AppColors.line,
        disabledForegroundColor: AppColors.textDim,
        elevation: 0,
        padding: compacto
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: compacto ? 12.5 : 14.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(texto),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          BotonAmarillo(texto: textoBoton, alTocar: alAgregar, compacto: true),
        ],
      ),
    );
  }
}

/// Titulo de un grupo dentro de una lista (una categoria, un rol).
class TituloDeGrupo extends StatelessWidget {
  final String texto;
  final IconData? icono;

  const TituloDeGrupo({super.key, required this.texto, this.icono});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 14, color: AppColors.textDim),
            const SizedBox(width: 6),
          ],
          Text(
            texto.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textDim,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastilla de filtro horizontal: la activa se pinta amarilla solida.
class ChipDeFiltro extends StatelessWidget {
  final String texto;
  final bool elegido;
  final VoidCallback alTocar;

  const ChipDeFiltro({super.key, required this.texto, required this.elegido, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: elegido ? AppColors.yellow : AppColors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: elegido ? 0 : 1,
      shadowColor: AppColors.black.withValues(alpha: 0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: alTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.black),
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
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
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
              child: Icon(icono, size: 30, color: AppColors.black),
            ),
            const SizedBox(height: 14),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta blanca: la unidad visual de todas las listas del modulo (un
/// plato, una mesa, un colaborador, una carta).
class TarjetaDeFicha extends StatelessWidget {
  final Widget hijo;
  final VoidCallback? alTocar;

  const TarjetaDeFicha({super.key, required this.hijo, this.alTocar});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: AppColors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 1)),
        ],
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
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: const TextStyle(color: AppColors.red, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(onTap: alCerrar, child: const Icon(Icons.close, color: AppColors.red, size: 18)),
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
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        titulo,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.black),
      ),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: contenido)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        TextButton(
          onPressed: guardando ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w800),
          ),
        ),
        BotonAmarillo(
          alTocar: guardando ? null : alGuardar,
          texto: textoGuardar,
          compacto: true,
        ),
        if (guardando)
          const Padding(
            padding: EdgeInsets.only(left: 10),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow),
            ),
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
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.black),
        decoration: InputDecoration(
          labelText: etiqueta,
          helperText: ayuda,
          isDense: true,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDim),
          helperStyle: const TextStyle(fontSize: 11, color: AppColors.textDim),
        ),
        validator: validar,
      ),
    );
  }
}
