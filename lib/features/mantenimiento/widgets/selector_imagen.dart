import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/api_config.dart';
import '../../../core/theme/app_colors.dart';

/// Foto elegida en el dispositivo pero todavia no subida: los endpoints de
/// foto necesitan que el plato/carta ya exista, asi que los formularios
/// guardan los bytes aca y los suben recien despues de crear el registro.
class ImagenElegida {
  final Uint8List bytes;
  final String nombreArchivo;

  ImagenElegida({required this.bytes, required this.nombreArchivo});
}

Future<ImagenElegida?> elegirImagenDeGaleria() async {
  final archivo = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 85,
  );
  if (archivo == null) return null;
  return ImagenElegida(bytes: await archivo.readAsBytes(), nombreArchivo: archivo.name);
}

/// El backend puede devolver la ruta relativa (`/static/...`); la app la
/// completa con el host de la API en vez de asumir que ya viene absoluta.
String urlAbsolutaDeFoto(String fotoUrl) {
  if (fotoUrl.startsWith('http')) return fotoUrl;
  return '${ApiConfig.baseUrl}$fotoUrl';
}

/// Cuadro tocable que muestra la foto actual (ya subida o recien elegida) y
/// permite reemplazarla. Se usa igual en el formulario de plato y de carta.
class SelectorDeFoto extends StatelessWidget {
  final ImagenElegida? imagenElegida;
  final String? fotoUrlActual;
  final ValueChanged<ImagenElegida> alElegir;
  final double alto;

  const SelectorDeFoto({
    super.key,
    required this.alElegir,
    this.imagenElegida,
    this.fotoUrlActual,
    this.alto = 120,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final elegida = await elegirImagenDeGaleria();
        if (elegida != null) alElegir(elegida);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: alto,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: _contenido(),
      ),
    );
  }

  Widget _contenido() {
    if (imagenElegida != null) {
      return Image.memory(imagenElegida!.bytes, fit: BoxFit.cover, width: double.infinity);
    }
    if (fotoUrlActual != null && fotoUrlActual!.isNotEmpty) {
      return Image.network(
        urlAbsolutaDeFoto(fotoUrlActual!),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, _, _) => _invitacion('No se pudo cargar la foto, toca para reemplazarla'),
      );
    }
    return _invitacion('Toca para elegir una foto');
  }

  Widget _invitacion(String texto) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo_outlined, color: AppColors.textDim),
        const SizedBox(height: 6),
        Text(texto, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
      ],
    );
  }
}

/// Miniatura cuadrada para las listas: foto si existe, inicial si no.
class MiniaturaDeFoto extends StatelessWidget {
  final String? fotoUrl;
  final IconData iconoVacio;
  final double lado;

  const MiniaturaDeFoto({
    super.key,
    this.fotoUrl,
    this.iconoVacio = Icons.restaurant_menu,
    this.lado = 52,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: AppColors.pine.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: (fotoUrl != null && fotoUrl!.isNotEmpty)
          ? Image.network(
              urlAbsolutaDeFoto(fotoUrl!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(iconoVacio, color: AppColors.pine, size: lado * 0.45),
            )
          : Icon(iconoVacio, color: AppColors.pine, size: lado * 0.45),
    );
  }
}
