import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Header amarillo con curva hacia el cuerpo blanco: reemplaza el bloque
/// negro anterior por el patron que el usuario pidio explicitamente a
/// partir de una referencia visual (logo solo arriba, wordmark abajo en
/// el cuerpo claro). `onBack` es opcional: la pantalla selectora no
/// tiene a donde volver, las de PIN/admin si.
class EncabezadoLogin extends StatelessWidget {
  final VoidCallback? onBack;

  const EncabezadoLogin({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(48),
            bottomRight: Radius.circular(48),
          ),
          child: Container(
            width: double.infinity,
            height: 170,
            color: AppColors.yellow,
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset(
                'assets/icons/icono.webp',
                width: 118,
                height: 118,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        if (onBack != null)
          SafeArea(
            bottom: false,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.black),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tagline sobre fondo claro, bajo [EncabezadoLogin] en las 3 pantallas de
/// login. El wordmark "Comanda / RESTAURANTE" ya viene dentro del icono, asi
/// que aqui solo queda la linea que aporta informacion nueva.
class MarcaTexto extends StatelessWidget {
  final String tagline;

  const MarcaTexto({super.key, this.tagline = 'Control · Pedidos · Ventas · Todo en un solo lugar'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
      child: Text(
        tagline,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textDim, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Pie de pantalla con divisor + icono, replica el footer de la referencia
/// ("🍴🍽️ Sistema de Comanda / Control · Pedidos · Ventas").
class PieDeLogin extends StatelessWidget {
  const PieDeLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 44, height: 1, color: AppColors.line),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.restaurant, color: AppColors.yellow, size: 18),
              ),
              Container(width: 44, height: 1, color: AppColors.line),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sistema de Comanda',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.black),
          ),
          const Text(
            'Control · Pedidos · Ventas',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}
