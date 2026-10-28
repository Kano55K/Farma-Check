# Productos

[← Volver al índice](README.md)

## GET /products

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Encabezados | `Authorization: Bearer <token>` |

Listado paginado, ordenado por nombre. El stock se calcula en la misma consulta (sin N+1).

### Parámetros de consulta (todos opcionales)

| Parámetro | Tipo | Valores / validación | Descripción |
|---|---|---|---|
| `search` | string | texto libre | Busca en nombre, droga (`active_ingredient`) y código de barras. No distingue mayúsculas |
| `laboratory` | string | coincidencia exacta | Filtra por laboratorio (los valores posibles vienen en `meta.laboratories`) |
| `stock_status` | string | `sin_stock`, `stock_bajo`, `ok` | Filtra por semáforo de stock. Otro valor → 422 |
| `prescription_required` | string | `true`, `false` | Venta bajo receta. Otro valor → 422 |
| `page` | entero | ≥ 1 | Página (por defecto 1) |
| `per_page` | entero | 1 a 100 | Tamaño de página (por defecto 20) |

### Respuesta exitosa — `200 OK`

Cada elemento de `data`:

| Campo | Tipo | Significado |
|---|---|---|
| `id` | entero | Id del producto |
| `name` | string | Nombre comercial con concentración |
| `active_ingredient` | string o `null` | Droga |
| `laboratory` | string o `null` | Laboratorio |
| `presentation` | string o `null` | Presentación |
| `barcode` | string o `null` | Código de barras (único) |
| `code` | string o `null` | Código interno |
| `therapeutic_action` | string o `null` | Acción terapéutica |
| `gondola_location` | string o `null` | Ubicación en góndola |
| `min_stock` | entero o `null` | Stock mínimo (umbral de `stock_bajo`) |
| `safety_stock` | entero o `null` | Stock de seguridad |
| `prescription_required` | booleano | Requiere receta |
| `total_stock` | entero | Unidades en lotes con `status = active` (incluye lotes activos vencidos por fecha) |
| `stock_status` | string | `sin_stock` si `total_stock = 0`; `stock_bajo` si `total_stock ≤ min_stock`; si no, `ok` |

`meta` agrega `laboratories`: lista ordenada de laboratorios existentes (para armar el filtro).

```bash
curl -s "http://localhost:3000/api/v1/products?search=ibuprofeno&per_page=2" -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": [
    {
      "id": 1,
      "name": "Ibuprofeno 400 mg",
      "active_ingredient": "Ibuprofeno",
      "laboratory": "Bagó",
      "presentation": "Comprimidos x 20",
      "barcode": "7790000100000",
      "code": "IBU001",
      "therapeutic_action": "Analgésico / antiinflamatorio",
      "gondola_location": "Góndola 1 - A",
      "min_stock": 30,
      "safety_stock": 15,
      "prescription_required": false,
      "total_stock": 141,
      "stock_status": "ok"
    },
    "…"
  ],
  "meta": {
    "page": 1,
    "per_page": 2,
    "total_count": 2,
    "total_pages": 1,
    "laboratories": ["Bagó", "Baliarda", "Bayer", "Casasco", "Elea", "Gador", "Laboratorios Beta", "Montpellier", "Raffo", "Roemmers", "Sidus"]
  }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `unauthorized` / `token_expired` | Sesión inválida o vencida |
| 422 | `invalid_params` | `stock_status` o `prescription_required` con un valor no admitido |

```bash
curl -s "http://localhost:3000/api/v1/products?stock_status=mucho" -H "Authorization: Bearer $TOKEN"
```

```json
{
  "error": {
    "code": "invalid_params",
    "message": "Hay parámetros con valores no válidos",
    "details": { "stock_status": ["debe ser uno de: sin_stock, stock_bajo, ok"] }
  }
}
```

---

## GET /products/:id

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Parámetros de ruta | `id` (entero) — id del producto |

### Respuesta exitosa — `200 OK`

`data` tiene todos los campos del listado y además `batches`: los lotes del producto (de todos los
estados), ordenados por vencimiento. Cada lote tiene la forma descrita en [batches.md](batches.md#campos-de-un-lote)
(sin el objeto `product`).

```bash
curl -s http://localhost:3000/api/v1/products/1 -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": {
    "id": 1,
    "name": "Ibuprofeno 400 mg",
    "active_ingredient": "Ibuprofeno",
    "laboratory": "Bagó",
    "presentation": "Comprimidos x 20",
    "barcode": "7790000100000",
    "code": "IBU001",
    "therapeutic_action": "Analgésico / antiinflamatorio",
    "gondola_location": "Góndola 1 - A",
    "min_stock": 30,
    "safety_stock": 15,
    "prescription_required": false,
    "total_stock": 141,
    "stock_status": "ok",
    "batches": [
      {
        "id": 2,
        "product_id": 1,
        "lot_number": "IBU-2312",
        "expiration_date": "2026-11-17",
        "quantity": 25,
        "location": "Góndola 1 - A",
        "status": "active",
        "expiration_status": "critico",
        "days_to_expiration": 20
      },
      {
        "id": 1,
        "product_id": 1,
        "lot_number": "IBU-2401",
        "expiration_date": "2027-12-22",
        "quantity": 116,
        "location": "Góndola 1 - A",
        "status": "active",
        "expiration_status": "ok",
        "days_to_expiration": 420
      }
    ]
  }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `unauthorized` / `token_expired` | Sesión inválida o vencida |
| 404 | `not_found` | No existe un producto con ese id |

```json
{ "error": { "code": "not_found", "message": "Producto no encontrado", "details": null } }
```
