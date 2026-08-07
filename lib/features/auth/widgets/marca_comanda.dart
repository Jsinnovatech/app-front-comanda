import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Bloque de marca del login sobre fondo negro: cuadrado amarillo con el
/// icono, wordmark "Comanda / RESTAURANTE" y tagline, tal cual el prototipo
/// aprobado.
class MarcaComanda extends StatelessWidget {
  final String tagline;

  const MarcaComanda({
    super.key,
    this.tagline = 'Control · Pedidos · Ventas · Todo en un solo lugar',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // El logo trae su propio fondo negro, por eso va sin contenedor
              // amarillo detras: se funde con el header y solo se recorta el
              // aire sobrante de la imagen.
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/icons/logicono.webp',
                  width: 72,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comanda',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.15,
                    ),
                  ),
                  Text(
                    'RESTAURANTE',
                    style: TextStyle(
                      color: AppColors.yellow,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel claro que arranca debajo de la marca: fondo gris con las esquinas
/// superiores redondeadas, donde vive el formulario real de cada pantalla.
class PanelClaro extends StatelessWidget {
  final Widget child;

  const PanelClaro({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}
