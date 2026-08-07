import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

const _largoMinimoDelCodigo = 4;
const _largoMaximoDelCodigo = 20;

/// Pin pad del dispositivo compartido del local: mesero, cocinero y cajero
/// entran aqui con su codigo personal. El `restaurante_id` ya viene resuelto
/// desde el selector, asi esta pantalla solo pide digitos.
class LoginPinScreen extends StatefulWidget {
  final int restauranteId;

  const LoginPinScreen({super.key, required this.restauranteId});

  @override
  State<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends State<LoginPinScreen> {
  String _codigoIngresado = '';
  bool _verificando = false;
  String? _error;

  bool get _codigoCompletable => _codigoIngresado.length >= _largoMinimoDelCodigo;

  void _agregarDigito(String digito) {
    if (_verificando || _codigoIngresado.length >= _largoMaximoDelCodigo) return;
    setState(() {
      _codigoIngresado += digito;
      _error = null;
    });
  }

  void _borrarUltimoDigito() {
    if (_verificando || _codigoIngresado.isEmpty) return;
    setState(() {
      _codigoIngresado = _codigoIngresado.substring(0, _codigoIngresado.length - 1);
      _error = null;
    });
  }

  Future<void> _entrar() async {
    if (_verificando || !_codigoCompletable) return;
    setState(() {
      _verificando = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().loginPin(
            restauranteId: widget.restauranteId,
            codigoAcceso: _codigoIngresado,
          );
      if (!mounted) return;
      // AuthProvider ya notifico y el portero de main.dart cambio la pantalla
      // de fondo; solo hay que soltar las rutas de login apiladas encima.
      Navigator.of(context).popUntil((ruta) => ruta.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _codigoIngresado = '';
        _verificando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el servidor';
        _verificando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pine,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: _verificando ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white70),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Tu codigo de acceso',
                          style: TextStyle(
                            fontFamily: AppTypography.display,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'LOCAL ${widget.restauranteId}',
                          style: const TextStyle(
                            fontFamily: AppTypography.mono,
                            fontSize: 12,
                            letterSpacing: 2,
                            color: AppColors.brassSoft,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _CirculosDeProgreso(digitosIngresados: _codigoIngresado.length),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 34,
                          child: _verificando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation(AppColors.brassSoft),
                                  ),
                                )
                              : Text(
                                  _error ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brassSoft,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        _TecladoNumerico(
                          habilitado: !_verificando,
                          puedeEntrar: _codigoCompletable,
                          alPresionarDigito: _agregarDigito,
                          alBorrar: _borrarUltimoDigito,
                          alEntrar: _entrar,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un circulo por digito ingresado, con un minimo de cuatro huecos visibles
/// para que se lea desde el principio cuanto falta como minimo.
class _CirculosDeProgreso extends StatelessWidget {
  final int digitosIngresados;

  const _CirculosDeProgreso({required this.digitosIngresados});

  @override
  Widget build(BuildContext context) {
    final total = digitosIngresados > _largoMinimoDelCodigo ? digitosIngresados : _largoMinimoDelCodigo;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: List.generate(total, (indice) {
        final relleno = indice < digitosIngresados;
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: relleno ? AppColors.brass : Colors.transparent,
            border: Border.all(color: relleno ? AppColors.brass : Colors.white38, width: 1.6),
          ),
        );
      }),
    );
  }
}

class _TecladoNumerico extends StatelessWidget {
  final bool habilitado;
  final bool puedeEntrar;
  final void Function(String digito) alPresionarDigito;
  final VoidCallback alBorrar;
  final VoidCallback alEntrar;

  const _TecladoNumerico({
    required this.habilitado,
    required this.puedeEntrar,
    required this.alPresionarDigito,
    required this.alBorrar,
    required this.alEntrar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final fila in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                for (final digito in fila)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _TeclaDelPad(
                        etiqueta: digito,
                        alPresionar: habilitado ? () => alPresionarDigito(digito) : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _TeclaDelPad(
                  icono: Icons.backspace_outlined,
                  alPresionar: habilitado ? alBorrar : null,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _TeclaDelPad(
                  etiqueta: '0',
                  alPresionar: habilitado ? () => alPresionarDigito('0') : null,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _TeclaDelPad(
                  icono: Icons.arrow_forward,
                  destacada: true,
                  alPresionar: habilitado && puedeEntrar ? alEntrar : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TeclaDelPad extends StatelessWidget {
  final String? etiqueta;
  final IconData? icono;
  final bool destacada;
  final VoidCallback? alPresionar;

  const _TeclaDelPad({
    this.etiqueta,
    this.icono,
    this.destacada = false,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    final inactiva = alPresionar == null;
    final fondo = destacada
        ? (inactiva ? Colors.white10 : AppColors.brass)
        : Colors.white.withValues(alpha: 0.08);
    final contenido = destacada
        ? (inactiva ? Colors.white30 : AppColors.pineDark)
        : (inactiva ? Colors.white30 : Colors.white);

    return Material(
      color: fondo,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 64,
          child: Center(
            child: icono != null
                ? Icon(icono, color: contenido, size: 24)
                : Text(
                    etiqueta!,
                    style: TextStyle(
                      fontFamily: AppTypography.mono,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: contenido,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
