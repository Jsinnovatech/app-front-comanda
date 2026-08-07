import 'package:intl/intl.dart';

/// Formatos de ticket: montos y conteos siempre con la misma cara, para que
/// la columna de numeros del dashboard se lea como una cuenta impresa.
class FormatoDashboard {
  static final NumberFormat _conDecimales = NumberFormat('#,##0.00');
  static final NumberFormat _sinDecimales = NumberFormat('#,##0');

  static String soles(double monto) => 'S/ ${_conDecimales.format(monto)}';

  static String entero(int valor) => _sinDecimales.format(valor);

  static String diaDeSemana(DateTime dia) {
    const nombres = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return nombres[dia.weekday - 1];
  }

  static String diaYMes(DateTime dia) =>
      '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}';

  static String horaMinuto(DateTime momento) =>
      '${momento.hour.toString().padLeft(2, '0')}:${momento.minute.toString().padLeft(2, '0')}';
}
