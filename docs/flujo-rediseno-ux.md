# Rediseño de flujo y UX — Comanda Restaurantes

## Diagnóstico actual

El front funcional (MVP construido con 6 agentes en paralelo) cumple el contrato de API y no tiene bugs de arquitectura, pero el diseño visual y la experiencia de usuario están en nivel muy básico — "de junior", sin dirección de diseño real. Se necesita un rediseño completo, no ajustes puntuales. Este documento narra el flujo objetivo ANTES de tocar código, para no repetir el error de construir sin dirección clara.

## Flujo objetivo

### 1. Login simplificado
Hoy el mesero necesita saber y escribir el `restaurante_id` para entrar. Eso está mal — un mesero no debería tener que conocer un ID interno.

**Objetivo**: el usuario entra con **correo/usuario + PIN**, y el sistema resuelve solo a qué restaurante pertenece esa persona (el `codigo_acceso`/PIN ya es único por restaurante en el modelo actual — falta que el login lo resuelva sin pedir el ID a mano).

Icono de login: debe reemplazarse por uno "épico", acorde a la identidad visual del proyecto (pendiente de que el usuario suba la imagen a `assets/icons/`).

### 2. Pantalla principal con 2 pestañas
Después del login, la pantalla principal tiene **dos tabs**:

- **Carta**: muestra el menú del restaurante, con un **QR** visible (el mismo QR público que ya genera el backend para que el cliente lo escanee desde su mesa y vea el PDF de la carta).
- **Mesas**: el tablero de mesas (lo que hoy es `MeseroHomeScreen`).

### 3. Mesero arma el pedido
Selecciona platos → **previsualiza el pedido antes de confirmar** → recién ahí lo solicita/envía a cocina. Hoy el flujo confirma directo sin paso de previsualización.

### 4. Cocina ve todos los pedidos por mesa
Un usuario distinto (cocinero) entra con su propio PIN y ve **una pantalla con todos los pedidos agrupados por mesa** (no solo una cola plana de items). Marca cada pedido/item como **"en curso"** cuando empieza a prepararlo.

### 5. Sincronización cocina → mesero
Cuando cocina marca un item como "listo", la pantalla del mesero debe enterarse **sin que el mesero tenga que refrescar manualmente**.

**Pendiente de decidir** (afecta arquitectura del backend):
- Opción A — **Polling**: el front del mesero pregunta al backend cada pocos segundos si hay items listos. Simple, rápido de construir, ya funciona con la arquitectura REST actual.
- Opción B — **Push/WebSockets**: notificación instantánea. Más "épico" pero requiere agregar un canal de tiempo real al backend (no existe hoy).

### 6. Entrega
El mesero ve "pedido listo", va a la mesa, entrega, y marca el item como **servido**.

### 7. Cierre de cuenta
La mesa "cancela" (paga) — el mesero atiende ese cierre desde su pantalla y libera la mesa.

**Pendiente de aclarar**: ¿quién inicia esta acción — el mesero decide cerrar la cuenta desde su pantalla cuando el cliente pide la cuenta, o hay alguna señal del lado del cliente (ej. botón "llamar al mesero" en la vista pública de la carta)? Definir esto antes de diseñar la pantalla de cierre.

### 8. Vista de Admin — pendientes de pago
El admin necesita una vista que muestre **qué mesas/pedidos están pendientes de pago**, no solo el dashboard genérico actual.

## Estado de las preguntas abiertas
1. Mecanismo de sincronización cocina→mesero: **polling vs WebSockets** (pendiente).
2. Quién dispara el cierre/cobro de una mesa: **mesero vs señal del cliente** (pendiente).

## Dirección visual (referencia aprobada)

El usuario compartió mockups de referencia con la identidad objetivo del proyecto. Elementos confirmados a replicar:

- **Paleta**: fondo negro/carbón + acento dorado-ámbar (`#F5A623` aprox.), tarjetas blancas sobre fondo claro en las pantallas internas.
- **Logo**: campana/cloche humeante sobre una mano sirviendo, wordmark "Comanda Restaurante", tagline "Ordena · Cocina · Sirve".
- **Home (mesero/cliente)**: categorías en chips horizontales con ícono (Entradas/Platos de fondo/Bebidas/Postres), lista de "Platos destacados" con foto, nombre, descripción corta, precio y botón `+` circular dorado.
- **Detalle de mesa**: tabs "Pedido" / "Historial", lista de items con cantidad y precio, total destacado, botones "Agregar plato" (outline) y "Enviar a cocina" (relleno dorado).
- **Dashboard admin/mesero**: tabs superiores Mesas/Pedidos/Cocina/Ventas, grid de mesas con badge de cantidad de pedidos y estado (Ocupada en rojo / Disponible en verde), sección "Pedidos en Curso" con mesa + código de pedido + tiempo transcurrido + chip "En cocina".
- **Cobrar Mesa**: resumen de items con steppers +/- y borrar, **Subtotal / IGV (18%) / Total**, selector de método de pago (Efectivo/Tarjeta/Yape-Plin/Otro), monto a recibir destacado, botones "Cancelar" / "Cobrar".
- **Navegación inferior**: por rol — cliente/mesero ve Inicio/Pedidos/Mesas/Cuenta; admin/mesero con más permisos ve Inicio/Mesas/Pedidos/Cocina/Reportes.

### Gaps de backend que este diseño expone
1. **`metodo_pago` no existe en `Comanda`** — la pantalla de cobro lo necesita persistido, no solo capturado en el front.
2. **IGV no se calcula en ningún lado** — el mockup desglosa Subtotal/IGV(18%)/Total; hoy el backend no separa impuesto del precio. Definir si el IGV está incluido en el precio del plato (y se desglosa solo para mostrar) o se suma aparte.

## Siguiente paso
Con esto confirmado, se arma el rediseño real: paleta, tipografía, estructura de pantallas por rol (mesero/cocinero/cajero/admin), y recién ahí se reconstruye el front — no parche sobre parche.
