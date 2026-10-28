# Lotes

[← Volver al índice](README.md)

## Campos de un lote

| Campo | Tipo | Significado |
|---|---|---|
| `id` | entero | Id del lote |
| `product_id` | entero | Producto al que pertenece |
| `lot_number` | string | Número de lote |
| `expiration_date` | fecha | Vencimiento (`AAAA-MM-DD`) |
| `quantity` | entero | Unidades disponibles en el lote (≥ 0) |
| `location` | string o `null` | Ubicación física |
| `status` | string | `active`, `expired` (dado de baja) o `recalled` (retirado) |
| `expiration_status` | string | Semáforo: `vencido`, `critico` (≤ 30 días), `alerta` (31 a 90 días), `ok` (> 90 días) |
| `days_to_expiration` | entero | Días hasta el vencimiento (negativo si ya venció) |
| `product` | objeto | Solo en `/batches`: `id`, `name`, `active_ingredient`, `laboratory`, `presentation` |

## GET /batches

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Encabezados | `Authorization: Bearer <token>` |

### Parámetros de consulta (todos opcionales)

| Parámetro | Tipo | Valores / validación | Descripción |
|---|---|---|---|
| `expiration_status` | string | `vencido`, `critico`, `alerta`, `ok` | Filtra por semáforo de vencimiento. Otro valor → 422 |
| `product_id` | entero | — | Lotes de un producto |
| `with_stock` | string | `true` | Solo lotes con `quantity > 0` |
| `sort` | string | `expiration_date` (por defecto), `-expiration_date` | Orden por vencimiento ascendente o descendente |
| `page`, `per_page` | entero | ver [paginación](README.md#paginación) | |

```bash
curl -s "http://localhost:3000/api/v1/batches?expiration_status=critico&per_page=2" -H "Authorization: Bearer $TOKEN"
```

### Respuesta exitosa — `200 OK`

```json
{
  "data": [
    {
      "id": 19,
      "product_id": 17,
      "lot_number": "IBP-2405",
      "expiration_date": "2026-11-02",
      "quantity": 9,
      "location": "Góndola 3 - A",
      "status": "active",
      "expiration_status": "critico",
      "days_to_expiration": 5,
      "product": {
        "id": 17,
        "name": "Ibuprofeno pediátrico 2% jarabe",
        "active_ingredient": "Ibuprofeno",
        "laboratory": "Bagó",
        "presentation": "Suspensión x 90 ml"
      }
    },
    "…"
  ],
  "meta": { "page": 1, "per_page": 2, "total_count": 5, "total_pages": 3 }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `unauthorized` / `token_expired` | Sesión inválida o vencida |
| 422 | `invalid_params` | `expiration_status` o `sort` con un valor no admitido |

```json
{
  "error": {
    "code": "invalid_params",
    "message": "Hay parámetros con valores no válidos",
    "details": { "expiration_status": ["debe ser uno de: vencido, critico, alerta, ok"] }
  }
}
```

---

## GET /batches/:id

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Parámetros de ruta | `id` (entero) — id del lote |

```bash
curl -s http://localhost:3000/api/v1/batches/1 -H "Authorization: Bearer $TOKEN"
```

### Respuesta exitosa — `200 OK`

```json
{
  "data": {
    "id": 1,
    "product_id": 1,
    "lot_number": "IBU-2401",
    "expiration_date": "2027-12-22",
    "quantity": 116,
    "location": "Góndola 1 - A",
    "status": "active",
    "expiration_status": "ok",
    "days_to_expiration": 420,
    "product": {
      "id": 1,
      "name": "Ibuprofeno 400 mg",
      "active_ingredient": "Ibuprofeno",
      "laboratory": "Bagó",
      "presentation": "Comprimidos x 20"
    }
  }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `unauthorized` / `token_expired` | Sesión inválida o vencida |
| 404 | `not_found` | `"Lote no encontrado"` |
