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
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/icons/logicono.webp',
                width: 88,
                height: 78,
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

/// Wordmark "Comanda / RESTAURANTE" sobre fondo claro, con la tagline
/// debajo. Va inmediatamente bajo [EncabezadoLogin] en las 3 pantallas
/// de login.
class MarcaTexto extends StatelessWidget {
  final String tagline;

  const MarcaTexto({super.key, this.tagline = 'Control · Pedidos · Ventas · Todo en un solo lugar'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 6),
      child: Column(
        children: [
          const Text(
            'Comanda',
            style: TextStyle(color: AppColors.black, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(20)),
            child: const Text(
              'RESTAURANTE',
              style: TextStyle(color: AppColors.black, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 3),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
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
