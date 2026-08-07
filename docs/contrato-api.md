# Contrato de API — Backend Comanda Restaurantes

Base URL: `ApiConfig.baseUrl` (ya definido en `lib/core/config/api_config.dart`, junto con
la constante de cada endpoint — usar SIEMPRE esas constantes, nunca escribir la URL a mano).

Todas las llamadas HTTP pasan por `lib/core/network/api_client.dart` (`ApiClient.get/post/put`),
que ya maneja headers, token Bearer, y lanza `ApiException(statusCode, message, errorCode)` en
cualquier respuesta de error — nunca parsear errores a mano en un service de feature.

La sesión activa vive en `AuthProvider` (`context.read<AuthProvider>().sesion`), con
`sesion.restauranteId`, `sesion.personalId`, `sesion.tipoColaborador`, `sesion.nombre`.
Ningún service debe volver a pedir `restaurante_id` al usuario — ya está en la sesión.

## Auth (ya implementado en `services/auth_service.dart` y `providers/auth_provider.dart` — NO tocar)

- `POST /auth/login` — PIN (mesero/cocinero/cajero). Body: `{restaurante_id, codigo_acceso}`.
- `POST /auth/login-admin` — email+password (super_admin/admin). Body: `{email, password}`.
- `POST /auth/solicitar-reset` — Body: `{email}`. Envía código por correo.
- `POST /auth/resetear-password` — Body: `{email, codigo, nueva_password}`.

Todas devuelven `{access_token, token_type, personal_id, restaurante_id, nombre, tipo_colaborador}`
(las 2 primeras) o `{message}` (las 2 de reset).

## Mantenimiento — requiere login, super_admin/admin salvo que se indique

- `POST /api/v1/restaurantes` — SIN auth. Registro inicial. Body: `{nombre, foto_url?, nombre_super_admin, email_super_admin, password_super_admin}`. Devuelve sesión completa ya logueada + `restaurante`.
- `GET /api/v1/restaurantes/{id}` — cualquier rol autenticado, solo si es su propio restaurante.
- `PUT /api/v1/restaurantes/{id}` — super_admin. Body parcial: `{nombre?, foto_url?, modo_asignacion_mesas?, ruc?, puede_emitir_boleta?, puede_emitir_factura?}`.

- `POST /api/v1/personal` — super_admin/admin. Body: `{nombre, tipo_colaborador_codigo, codigo_acceso?, email?, password?}` — `codigo_acceso` para mesero/cocinero/cajero, `email`+`password` para admin (min 8 caracteres).
- `GET /api/v1/personal` — super_admin/admin. Lista del restaurante.
- `PUT /api/v1/personal/{id}` — super_admin/admin. Body parcial (mismos campos que crear + `activo?`).

- `POST /api/v1/mesas` — super_admin/admin. Body: `{numero_o_nombre}`.
- `GET /api/v1/mesas` — cualquier rol autenticado (el mesero necesita verlas).
- `PUT /api/v1/mesas/{id}` — super_admin/admin. Body: `{numero_o_nombre?, estado?}` (`estado`: `'libre'|'ocupada'`).

- `POST /api/v1/platos` — super_admin/admin. Body: `{nombre, descripcion?, precio, categoria?, disponible?}`.
- `GET /api/v1/platos?disponible=true` — cualquier rol autenticado (el mesero necesita la carta).
- `PUT /api/v1/platos/{id}` — super_admin/admin. Body parcial.
- `POST /api/v1/platos/{id}/foto` — super_admin/admin. **Multipart**, campo `foto` (archivo). Devuelve `{plato_id, foto_url}`.

`PlatoResponse` incluye `foto_url` (recién agregado, ver `models/plato_model.dart`).

## Cartas — requiere login

- `POST /api/v1/cartas` — super_admin/admin. Body: `{nombre, tipo: 'diaria'|'semanal', fecha_inicio, fecha_fin, plato_ids: [int]}` (fechas en formato `YYYY-MM-DD`).
- `GET /api/v1/cartas` — cualquier rol autenticado. Lista todas las cartas del restaurante.
- `GET /api/v1/cartas/{id}` — detalle con sus platos.
- `PUT /api/v1/cartas/{id}` — super_admin/admin. Body parcial, incluye `plato_ids?` (reemplaza el set completo si se manda).
- `POST /api/v1/cartas/{id}/foto` — super_admin/admin. Multipart, campo `foto`.

## Comandas — requiere login

- `POST /api/v1/comandas` — mesero (en la práctica cualquier autenticado). Body: `{mesa_ids: [int], items: [{plato_id, cantidad}]}` — `items` puede ir vacío, se agregan después.
- `GET /api/v1/comandas?estado=abierta` — lista comandas del restaurante, `estado` opcional.
- `GET /api/v1/comandas/{id}` — detalle con items y mesas.
- `POST /api/v1/comandas/{id}/items` — Body: `{plato_id, cantidad}`. Agrega un plato a una comanda ya abierta.
- `POST /api/v1/comandas/{id}/cerrar` — Body: `{metodo_pago: 'efectivo'|'tarjeta'}`.

- `GET /api/v1/cocina/items-pendientes` — cocinero/admin/super_admin. Cola de items `pendiente`+`en_preparacion` (shape `ItemCocinaModel`, con `mesas: [String]`, distinto del item dentro de una comanda).
- `POST /api/v1/comanda-items/{id}/tomar` — cocinero. Body: `{codigo_acceso}` (el PIN de ESE cocinero especifico, aunque el dispositivo ya este logueado como cocinero — asi queda registrado "tomado por Fulano").
- `POST /api/v1/comanda-items/{id}/marcar-listo` — cocinero. Sin body.
- `POST /api/v1/comanda-items/{id}/marcar-servido` — mesero. Sin body (usa el `personal_id` del token para `mesero_id_entrega`).

Todas las respuestas de item usan `ComandaItemModel` salvo la cola de cocina que usa `ItemCocinaModel`.

## Comprobantes — requiere login

- `POST /api/v1/comandas/{comanda_id}/comprobante` — Body: `{tipo_solicitado: 'boleta'|'factura', ruc_cliente?}`. El `tipo` REAL devuelto puede no coincidir con lo pedido (degrada a `nota_venta` si el restaurante no tiene permisos SUNAT — comportamiento esperado, no es error, mostrarlo tal cual).
- `GET /api/v1/comandas/{comanda_id}/comprobante` — 404 si aún no se emitió.
- `GET /api/v1/comprobantes/{id}` — detalle.
- `PUT /api/v1/comprobantes/{id}/estado-impresion` — Body: `{estado_impresion: 'impreso'|'error_impresora'}`.

## Público — SIN login, para el flujo de QR del cliente

- `GET /api/v1/public/restaurantes/{id}/carta` — JSON de la carta activa.
- `GET /api/v1/public/restaurantes/{id}/carta.pdf` — el PDF (para abrir en navegador/webview).
- `GET /api/v1/public/restaurantes/{id}/qr-carta.png` — imagen del QR.

## Estados — nombres exactos, no traducir en el codigo (solo en la UI)

- Comanda: `abierta` → `pagada` (opcional, solo tarjeta) → `cerrada`.
- ComandaItem: `pendiente` → `en_preparacion` → `listo` → `servido`.
- Mesa: `libre` | `ocupada`.
- Comprobante: `tipo` = `boleta`|`factura`|`nota_venta`; `estado_impresion` = `pendiente`|`impreso`|`error_impresora`.

Colores por estado ya definidos en `core/theme/app_colors.dart` (`AppColors.pendiente`, `.enPreparacion`, `.listo`, `.servido`, `.abierta`, `.cerrada`) — usar esos, no inventar otros.
