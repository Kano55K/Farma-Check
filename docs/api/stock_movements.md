# Movimientos de stock

[← Volver al índice](README.md)

## Campos de un movimiento

| Campo | Tipo | Significado |
|---|---|---|
| `id` | entero | Id del movimiento |
| `movement_type` | string | `entrada`, `salida`, `ajuste` o `devaluacion_vencimiento` |
| `quantity` | entero | Unidades del movimiento (en `ajuste`, el stock final del lote) |
| `reason` | string o `null` | Motivo |
| `created_at` | timestamp | Momento del registro (UTC) |
| `batch` | objeto | `id`, `lot_number`, `quantity` (stock actual del lote), `expiration_date` |
| `product` | objeto | `id`, `name` |
| `user` | objeto | `id`, `email` del usuario que lo registró |

## GET /stock_movements

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Encabezados | `Authorization: Bearer <token>` |

Ordenado del más reciente al más antiguo.

### Parámetros de consulta (todos opcionales)

| Parámetro | Tipo | Valores / validación | Descripción |
|---|---|---|---|
| `movement_type` | string | `entrada`, `salida`, `ajuste`, `devaluacion_vencimiento` | Filtra por tipo. Otro valor → 422 |
| `batch_id` | entero | — | Movimientos de un lote |
| `product_id` | entero | — | Movimientos de todos los lotes de un producto |
| `from` | fecha | `AAAA-MM-DD` | Desde ese día inclusive (hora argentina) |
| `to` | fecha | `AAAA-MM-DD` | Hasta ese día inclusive |
| `page`, `per_page` | entero | ver [paginación](README.md#paginación) | |

```bash
curl -s "http://localhost:3000/api/v1/stock_movements?movement_type=salida&per_page=2" -H "Authorization: Bearer $TOKEN"
```

### Respuesta exitosa — `200 OK`

```json
{
  "data": [
    {
      "id": 90,
      "movement_type": "salida",
      "quantity": 2,
      "reason": "Venta en mostrador",
      "created_at": "2026-10-28T14:33:16Z",
      "batch": { "id": 1, "lot_number": "IBU-2401", "quantity": 114, "expiration_date": "2027-12-22" },
      "product": { "id": 1, "name": "Ibuprofeno 400 mg" },
      "user": { "id": 2, "email": "empleado@farma-check.com" }
    },
    "…"
  ],
  "meta": { "page": 1, "per_page": 2, "total_count": 61, "total_pages": 31 }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `unauthorized` / `token_expired` | Sesión inválida o vencida |
| 422 | `invalid_params` | `movement_type` no admitido o fecha con formato incorrecto |

```json
// GET /stock_movements?from=28/10/2026
{
  "error": {
    "code": "invalid_params",
    "message": "Hay parámetros con valores no válidos",
    "details": { "from": ["debe tener formato AAAA-MM-DD"] }
  }
}
```

---

## POST /stock_movements

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera (`employee` o `admin`) |
| Encabezados | `Authorization: Bearer <token>`, `Content-Type: application/json` |

Registra el movimiento **y** actualiza el stock del lote en una sola transacción: si algo falla, no se
guarda nada. El usuario del movimiento es el dueño del token.

### Cuerpo

Los campos van dentro de `stock_movement`. Por compatibilidad también se aceptan en la raíz del JSON.

| Campo | Tipo | Obligatorio | Valores / validaciones |
|---|---|---|---|
| `stock_movement.batch_id` | entero | sí | Lote existente (si falta → 400; si no existe → 404) |
| `stock_movement.movement_type` | string | sí | `entrada`, `salida`, `ajuste`, `devaluacion_vencimiento` |
| `stock_movement.quantity` | entero | sí | `> 0`; en `ajuste`, `≥ 0` |
| `stock_movement.reason` | string | no | Motivo libre (ej. "Venta en mostrador") |

Efecto sobre el lote y reglas de negocio:

| Tipo | Efecto | Reglas |
|---|---|---|
| `entrada` | `quantity` del lote + cantidad | — |
| `salida` | `quantity` del lote − cantidad | No puede superar el stock del lote. No se permite si el lote está vencido (por fecha o dado de baja) o retirado |
| `devaluacion_vencimiento` | `quantity` del lote − cantidad | No puede superar el stock. Es la forma de dar de baja unidades de un lote vencido |
| `ajuste` | `quantity` del lote = cantidad | Fija el stock contado (puede ser 0) |

```bash
curl -s -X POST http://localhost:3000/api/v1/stock_movements \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"stock_movement":{"batch_id":1,"movement_type":"salida","quantity":2,"reason":"Venta en mostrador"}}'
```

### Respuesta exitosa — `201 Created`

`data` es el movimiento creado; `data.batch.quantity` ya refleja el stock actualizado del lote.

```json
{
  "message": "Movimiento registrado",
  "data": {
    "id": 90,
    "movement_type": "salida",
    "quantity": 2,
    "reason": "Venta en mostrador",
    "created_at": "2026-10-28T14:33:16Z",
    "batch": { "id": 1, "lot_number": "IBU-2401", "quantity": 114, "expiration_date": "2027-12-22" },
    "product": { "id": 1, "name": "Ibuprofeno 400 mg" },
    "user": { "id": 2, "email": "empleado@farma-check.com" }
  }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 400 | `bad_request` | Falta `batch_id` |
| 401 | `unauthorized` / `token_expired` | Sesión inválida o vencida |
| 404 | `not_found` | El lote no existe |
| 422 | `validation_failed` | Stock insuficiente, tipo inválido, cantidad inválida, lote vencido/retirado |

```json
// 422 — salida mayor al stock del lote (quantity: 100000)
{
  "error": {
    "code": "validation_failed",
    "message": "Los datos enviados no son válidos: Cantidad supera el stock disponible del lote (114)",
    "details": { "quantity": ["supera el stock disponible del lote (114)"] }
  }
}

// 422 — tipo inexistente (movement_type: "entry")
{
  "error": {
    "code": "validation_failed",
    "message": "Los datos enviados no son válidos: Tipo de movimiento no es válido (valores admitidos: entrada, salida, ajuste, devaluacion_vencimiento)",
    "details": { "movement_type": ["no es válido (valores admitidos: entrada, salida, ajuste, devaluacion_vencimiento)"] }
  }
}

// 422 — salida sobre un lote vencido
{
  "error": {
    "code": "validation_failed",
    "message": "Los datos enviados no son válidos: Lote está vencido o retirado: no admite salidas (usá devaluacion_vencimiento)",
    "details": { "batch": ["está vencido o retirado: no admite salidas (usá devaluacion_vencimiento)"] }
  }
}

// 400 — sin batch_id
{
  "error": {
    "code": "bad_request",
    "message": "Falta el parámetro obligatorio \"batch_id\"",
    "details": { "batch_id": ["es obligatorio"] }
  }
}
```
