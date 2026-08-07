import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Bloque con titulo serif y cuerpo sobre papel: todas las secciones del
/// dashboard usan este marco para que la pagina se lea como un solo documento.
class SeccionDashboard extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? accion;
  final Widget child;

  const SeccionDashboard({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.accion,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontFamily: AppTypography.display,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (subtitulo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitulo!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textDim),
                        ),
                      ),
                  ],
                ),
              ),
              ?accion,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Mensaje neutro para cuando una seccion no tiene nada que mostrar todavia.
class SeccionVacia extends StatelessWidget {
  final String mensaje;

  const SeccionVacia(this.mensaje, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textDim),
        ),
      ),
    );
  }
}
