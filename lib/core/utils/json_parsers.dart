/// FastAPI serializa los campos Numeric/Decimal del backend (precio, total,
/// monto_total, etc.) como String en el JSON (ej. "35.00"), no como numero.
/// Los fromJson de los modelos deben pasar por aca, nunca castear directo
/// con `as num` o `as double`.
double aDouble(dynamic valor) {
  if (valor is String) return double.parse(valor);
  return (valor as num).toDouble();
}
