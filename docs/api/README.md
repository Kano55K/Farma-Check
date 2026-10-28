# Contrato de la API de Farma-Check (v1)

API REST en JSON que consume el front-end del usuario final ([farma-check-front](../../README.md#front-end)).
El back-office de Rails (vistas ERB) es un contexto aparte y **no** usa esta API.

Todos los ejemplos de este contrato son **respuestas reales**: se obtuvieron con el servidor en
desarrollo y los seeds cargados, ejecutando [`script/e2e_api.sh`](../../script/e2e_api.sh), que guarda
cada respuesta en `tmp/api_examples/`. Los ids, tokens y fechas cambian en cada base. En los listados se
recortó el arreglo `data` (lo indica `…`).

| Documento | Contenido |
|---|---|
| [auth.md](auth.md) | `POST /login`, `DELETE /logout`, `GET /profile` |
| [dashboard.md](dashboard.md) | `GET /dashboard` |
| [products.md](products.md) | `GET /products`, `GET /products/:id` |
| [batches.md](batches.md) | `GET /batches`, `GET /batches/:id` |
| [stock_movements.md](stock_movements.md) | `GET /stock_movements`, `POST /stock_movements` |
| [suppliers.md](suppliers.md) | `GET /suppliers`, `GET /suppliers/:id`, `POST /suppliers`, `PATCH /suppliers/:id` |
| [purchase_orders.md](purchase_orders.md) | `GET`/`POST /purchase_orders`, `GET /purchase_orders/:id`, `PATCH …/send`, `PATCH …/cancel`, `POST …/receive` |
| [openapi.yaml](openapi.yaml) | Especificación OpenAPI 3.0 resumida (para importar en Postman/Swagger) |
| [farma-check.postman_collection.json](farma-check.postman_collection.json) | Colección de Postman con todos los endpoints |

---

## 1. Configuración general

### URL base

| Entorno | URL |
|---|---|
| Desarrollo | `http://localhost:3000/api/v1` |

### Formato

- Peticiones y respuestas en JSON (`Content-Type: application/json`), codificado en UTF-8.
- Fechas sin hora en **ISO 8601 `AAAA-MM-DD`** (ej.: `"2027-03-31"`).
- Instantes (timestamps) en **ISO 8601 UTC `AAAA-MM-DDTHH:MM:SSZ`** (ej.: `"2026-10-28T14:33:16Z"`).
- Importes como número decimal con hasta 2 decimales (ej.: `34812.0`), en pesos argentinos.
- Los campos opcionales sin valor se envían como `null` (nunca se omiten).
- Los recursos individuales se devuelven dentro de `data`; los listados, como `{ "data": [...], "meta": {...} }`.
- Las operaciones que crean o modifican algo agregan un `message` legible para mostrar al usuario.

### CORS

La API acepta peticiones de los orígenes de la variable de entorno `FRONTEND_ORIGIN` (lista separada por
comas). Por defecto, `http://localhost:5173` y `http://127.0.0.1:5173` (servidor de Vite).

### Autenticación

1. **Iniciar sesión**: `POST /login` con `email_address` y `password`. Devuelve un `token` y su vencimiento `expires_at`.
2. **Enviar el token** en todas las demás peticiones:

   ```
   Authorization: Bearer <token>
   ```

3. **Vencimiento**: el token dura **12 horas** (configurable con `API_TOKEN_TTL_HOURS`). Un token vencido
   responde `401` con `code: "token_expired"`; uno inexistente o revocado, `401` con `code: "unauthorized"`.
   En ambos casos el cliente debe volver a iniciar sesión.
4. **Cerrar sesión**: `DELETE /logout` (con el token). Invalida el token en el servidor.
5. Cada login emite un token nuevo e invalida el anterior del mismo usuario (una sesión de API activa por usuario).

### Roles y permisos

| Acción | `employee` | `admin` |
|---|:---:|:---:|
| Consultar dashboard, productos, lotes, movimientos, proveedores y órdenes | ✔ | ✔ |
| Registrar movimientos de stock | ✔ | ✔ |
| Crear, enviar y recibir órdenes de compra | ✔ | ✔ |
| Crear y editar proveedores | ✘ (403) | ✔ |
| Cancelar órdenes de compra | ✘ (403) | ✔ |

### Paginación

Los listados aceptan `page` (desde 1, por defecto 1) y `per_page` (por defecto 20, máximo 100; valores
mayores se limitan a 100). La respuesta incluye:

```json
"meta": { "page": 1, "per_page": 2, "total_count": 5, "total_pages": 3 }
```

| Campo | Tipo | Significado |
|---|---|---|
| `page` | entero | Página devuelta |
| `per_page` | entero | Tamaño de página aplicado |
| `total_count` | entero | Total de registros que cumplen los filtros |
| `total_pages` | entero | Total de páginas (`0` si no hay resultados) |

Una página fuera de rango devuelve `data: []` con los metadatos correctos (no es un error).

---

## 2. Formato único de error

Todas las respuestas de error de la API tienen esta forma:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Los datos enviados no son válidos: Cantidad supera el stock disponible del lote (114)",
    "details": { "quantity": ["supera el stock disponible del lote (114)"] }
  }
}
```

| Campo | Tipo | Significado |
|---|---|---|
| `error.code` | string | Código estable para el programa (ver tabla) |
| `error.message` | string | Mensaje en español para mostrar al usuario |
| `error.details` | objeto o `null` | Errores por campo: `{ "campo": ["mensaje", ...] }`. `null` si no aplica |

| HTTP | `code` | Cuándo |
|---|---|---|
| 400 | `bad_request` | Falta un parámetro obligatorio (ej. `stock_movement.batch_id`) o el JSON está mal formado |
| 401 | `unauthorized` | No se envió token, o no existe / fue revocado por logout |
| 401 | `token_expired` | El token venció |
| 401 | `invalid_credentials` | Login con email o contraseña incorrectos |
| 403 | `forbidden` | El usuario no tiene el rol necesario |
| 404 | `not_found` | El recurso no existe (`"Producto no encontrado"`, `"Lote no encontrado"`, …) |
| 422 | `validation_failed` | El recurso no pasó las validaciones (detalle por campo en `details`) |
| 422 | `invalid_params` | Un filtro de consulta tiene un valor no admitido o una fecha con formato incorrecto |
| 422 | `invalid_value` | Un valor de enumeración no admitido en un campo |
| 422 | `invalid_transition` | Cambio de estado no permitido en una orden de compra |

Ejemplos reales:

```json
// 401 — sin token
{ "error": { "code": "unauthorized", "message": "Falta el token o no es válido. Iniciá sesión.", "details": null } }

// 401 — token vencido
{ "error": { "code": "token_expired", "message": "La sesión expiró. Iniciá sesión nuevamente.", "details": null } }

// 403 — sin permisos
{ "error": { "code": "forbidden", "message": "No tenés permisos para realizar esta acción", "details": null } }

// 404 — inexistente
{ "error": { "code": "not_found", "message": "Producto no encontrado", "details": null } }

// 422 — filtro inválido
{ "error": { "code": "invalid_params", "message": "Hay parámetros con valores no válidos",
             "details": { "stock_status": ["debe ser uno de: sin_stock, stock_bajo, ok"] } } }

// 422 — transición inválida
{ "error": { "code": "invalid_transition", "message": "No se puede enviar una orden enviada", "details": null } }
```

> Nota: si el cuerpo trae bytes que no son UTF-8 válido, Rails lo rechaza antes de llegar a la API con
> `400 {"status":400,"error":"Bad Request"}` (fuera del formato único). Los navegadores y Postman siempre
> envían UTF-8; con `curl` en Windows conviene mandar el cuerpo desde un archivo (`--data-binary @body.json`).

---

## 3. Resumen de endpoints

| Método | Ruta | Acceso | Rol | Descripción |
|---|---|---|---|---|
| POST | `/login` | Pública | — | Inicia sesión y devuelve el token |
| DELETE | `/logout` | Protegida | cualquiera | Invalida el token |
| GET | `/profile` | Protegida | cualquiera | Usuario autenticado |
| GET | `/dashboard` | Protegida | cualquiera | KPIs y alertas |
| GET | `/products` | Protegida | cualquiera | Búsqueda, filtros y paginación de productos |
| GET | `/products/:id` | Protegida | cualquiera | Detalle con lotes |
| GET | `/batches` | Protegida | cualquiera | Lotes por semáforo de vencimiento |
| GET | `/batches/:id` | Protegida | cualquiera | Detalle de un lote |
| GET | `/stock_movements` | Protegida | cualquiera | Historial con filtros |
| POST | `/stock_movements` | Protegida | cualquiera | Registra un movimiento y actualiza el lote |
| GET | `/suppliers` | Protegida | cualquiera | Listado de proveedores |
| GET | `/suppliers/:id` | Protegida | cualquiera | Detalle con órdenes recientes |
| POST | `/suppliers` | Protegida | admin | Alta de proveedor |
| PATCH | `/suppliers/:id` | Protegida | admin | Edición de proveedor |
| GET | `/purchase_orders` | Protegida | cualquiera | Listado por estado y proveedor |
| POST | `/purchase_orders` | Protegida | cualquiera | Alta con ítems (total calculado en el servidor) |
| GET | `/purchase_orders/:id` | Protegida | cualquiera | Detalle con ítems |
| PATCH | `/purchase_orders/:id/send` | Protegida | cualquiera | `pending` → `sent` |
| PATCH | `/purchase_orders/:id/cancel` | Protegida | admin | `pending`/`sent` → `cancelled` |
| POST | `/purchase_orders/:id/receive` | Protegida | cualquiera | `sent` → `received`; crea lotes y entradas de stock |

### Valores de enumeración

| Campo | Valores |
|---|---|
| `user.role` | `employee`, `admin` |
| `product.stock_status` | `sin_stock` (stock 0), `stock_bajo` (stock ≤ `min_stock`), `ok` |
| `batch.status` | `active`, `expired` (dado de baja), `recalled` (retirado) |
| `batch.expiration_status` | `vencido` (ya venció o dado de baja), `critico` (≤ 30 días), `alerta` (31 a 90 días), `ok` (> 90 días) |
| `stock_movement.movement_type` | `entrada`, `salida`, `ajuste`, `devaluacion_vencimiento` |
| `purchase_order.status` | `pending`, `sent`, `received`, `cancelled` |

---

## 4. Probar la API

```bash
# Con el servidor corriendo y los seeds cargados:
curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email_address":"empleado@farma-check.com","password":"demo1234"}'

TOKEN=<el token de la respuesta>
curl -s http://localhost:3000/api/v1/products?search=ibu -H "Authorization: Bearer $TOKEN"

# Recorrido completo automático (64 chequeos):
script/e2e_api.sh
```
