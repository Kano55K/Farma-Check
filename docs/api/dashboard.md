# Dashboard

[← Volver al índice](README.md)

## GET /dashboard

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Encabezados | `Authorization: Bearer <token>` |
| Parámetros | ninguno |

Indicadores para la pantalla de inicio y hasta 10 alertas de lotes (vencidos o críticos con stock) más
hasta 10 de stock (primero sin stock, después stock bajo).

### Respuesta exitosa — `200 OK`

| Campo | Tipo | Significado |
|---|---|---|
| `data.kpis.total_products` | entero | Productos del catálogo |
| `data.kpis.low_stock_products` | entero | Productos con `stock_status = stock_bajo` |
| `data.kpis.out_of_stock_products` | entero | Productos con `stock_status = sin_stock` |
| `data.kpis.expired_batches` | entero | Lotes vencidos que todavía tienen unidades |
| `data.kpis.critical_batches` | entero | Lotes con stock que vencen en 30 días o menos |
| `data.kpis.warning_batches` | entero | Lotes con stock que vencen en 31 a 90 días |
| `data.kpis.pending_purchase_orders` | entero | Órdenes en estado `pending` o `sent` |
| `data.alerts[]` | arreglo | Alertas ordenadas por urgencia |
| `alerts[].type` | string | `batch_expired`, `batch_critical`, `out_of_stock`, `low_stock` |
| `alerts[].severity` | string | `danger` o `warning` (para el color en la interfaz) |
| `alerts[].message` | string | Texto listo para mostrar |
| `alerts[].product_id` | entero | Producto relacionado |
| `alerts[].batch_id` | entero o `null` | Lote relacionado (`null` en alertas de stock) |
| `alerts[].date` | fecha o `null` | Vencimiento del lote (`null` en alertas de stock) |

```bash
curl -s http://localhost:3000/api/v1/dashboard -H "Authorization: Bearer $TOKEN"
```

```json
{
  "data": {
    "kpis": {
      "total_products": 25,
      "low_stock_products": 4,
      "out_of_stock_products": 2,
      "expired_batches": 3,
      "critical_batches": 5,
      "warning_batches": 5,
      "pending_purchase_orders": 3
    },
    "alerts": [
      {
        "type": "batch_expired",
        "severity": "danger",
        "message": "Amoxicilina + ácido clavulánico 875/125 mg: lote AMC-2402 vencido el 18/09/2026",
        "product_id": 14,
        "batch_id": 17,
        "date": "2026-09-18"
      },
      {
        "type": "batch_expired",
        "severity": "danger",
        "message": "Amoxicilina 500 mg: lote AMX-2311 vencido el 13/10/2026",
        "product_id": 3,
        "batch_id": 5,
        "date": "2026-10-13"
      },
      "…"
    ]
  }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `unauthorized` / `token_expired` | Sesión inválida o vencida |
