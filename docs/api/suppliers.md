# Proveedores

[← Volver al índice](README.md)

## Campos de un proveedor

| Campo | Tipo | Significado |
|---|---|---|
| `id` | entero | Id |
| `company_name` | string | Razón social |
| `cuit` | string | CUIT con formato `XX-XXXXXXXX-X` (único, con dígito verificador válido) |
| `email` | string o `null` | Email de contacto |
| `phone` | string o `null` | Teléfono |
| `contact_name` | string o `null` | Persona de contacto |
| `created_at`, `updated_at` | timestamp | Alta y última modificación |

## GET /suppliers

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |

Parámetros opcionales: `search` (razón social o CUIT, parcial), `page`, `per_page`. Orden alfabético.

```bash
curl -s "http://localhost:3000/api/v1/suppliers?per_page=2" -H "Authorization: Bearer $TOKEN"
```

`200 OK`:

```json
{
  "data": [
    {
      "id": 2,
      "company_name": "Distribuidora Pampa S.R.L.",
      "cuit": "30-70987654-2",
      "email": "pedidos@pampa.com.ar",
      "phone": "0221 422-9876",
      "contact_name": "Jorge Ruiz",
      "created_at": "2026-10-28T14:29:10Z",
      "updated_at": "2026-10-28T14:29:10Z"
    },
    "…"
  ],
  "meta": { "page": 1, "per_page": 2, "total_count": 5, "total_pages": 3 }
}
```

Errores: `401`.

---

## GET /suppliers/:id

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Parámetros de ruta | `id` (entero) |

Incluye `recent_purchase_orders`: las últimas 10 órdenes del proveedor (forma resumida de
[purchase_orders.md](purchase_orders.md#campos-de-una-orden), sin `items`).

```bash
curl -s http://localhost:3000/api/v1/suppliers/2 -H "Authorization: Bearer $TOKEN"
```

`200 OK`:

```json
{
  "data": {
    "id": 2,
    "company_name": "Distribuidora Pampa S.R.L.",
    "cuit": "30-70987654-2",
    "email": "pedidos@pampa.com.ar",
    "phone": "0221 422-9876",
    "contact_name": "Jorge Ruiz",
    "created_at": "2026-10-28T14:29:10Z",
    "updated_at": "2026-10-28T14:29:10Z",
    "recent_purchase_orders": [
      {
        "id": 2,
        "status": "sent",
        "notes": "[seed-oc-2] Antibióticos y antihipertensivos",
        "total_amount": 302000.0,
        "items_count": 2,
        "supplier": { "id": 2, "company_name": "Distribuidora Pampa S.R.L." },
        "created_at": "2026-10-28T14:29:11Z",
        "updated_at": "2026-10-28T14:29:11Z"
      }
    ]
  }
}
```

Errores: `401`, `404` (`"Proveedor no encontrado"`).

---

## POST /suppliers

| | |
|---|---|
| Acceso | Protegida |
| Rol | **admin** |
| Encabezados | `Authorization: Bearer <token>`, `Content-Type: application/json` |

### Cuerpo

| Campo | Tipo | Obligatorio | Validaciones |
|---|---|---|---|
| `supplier.company_name` | string | sí | No vacío |
| `supplier.cuit` | string | sí | Formato `XX-XXXXXXXX-X`, dígito verificador válido, único |
| `supplier.email` | string | no | Formato de email |
| `supplier.phone` | string | no | — |
| `supplier.contact_name` | string | no | — |

```bash
curl -s -X POST http://localhost:3000/api/v1/suppliers \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"supplier":{"company_name":"Droguería Demo S.A.","cuit":"30-64619026-2","email":"ventas@demo.com.ar","phone":"011 4000-1234","contact_name":"Ana Pérez"}}'
```

`201 Created`:

```json
{
  "message": "Proveedor creado",
  "data": {
    "id": 6,
    "company_name": "Droguería Demo S.A.",
    "cuit": "30-64619026-2",
    "email": "ventas@demo.com.ar",
    "phone": "011 4000-1234",
    "contact_name": "Ana Pérez",
    "created_at": "2026-10-28T14:33:26Z",
    "updated_at": "2026-10-28T14:33:26Z"
  }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 400 | `bad_request` | Falta el objeto `supplier` |
| 401 | `unauthorized` / `token_expired` | Sesión inválida o vencida |
| 403 | `forbidden` | El usuario es `employee` |
| 422 | `validation_failed` | Razón social vacía, CUIT con formato o dígito inválido, CUIT repetido, email inválido |

```json
// 403 — empleado
{ "error": { "code": "forbidden", "message": "No tenés permisos para realizar esta acción", "details": null } }

// 422 — CUIT 30-12345678-9
{
  "error": {
    "code": "validation_failed",
    "message": "Los datos enviados no son válidos: CUIT tiene un dígito verificador inválido",
    "details": { "cuit": ["tiene un dígito verificador inválido"] }
  }
}
```

---

## PATCH /suppliers/:id

| | |
|---|---|
| Acceso | Protegida |
| Rol | **admin** |

Mismo cuerpo que el alta; se envían solo los campos a modificar. Mismas validaciones y errores
(más `404` si no existe).

```bash
curl -s -X PATCH http://localhost:3000/api/v1/suppliers/6 \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"supplier":{"phone":"011 4999-0000"}}'
```

`200 OK`:

```json
{
  "message": "Proveedor actualizado",
  "data": {
    "id": 6,
    "company_name": "Droguería Demo S.A.",
    "cuit": "30-64619026-2",
    "email": "ventas@demo.com.ar",
    "phone": "011 4999-0000",
    "contact_name": "Ana Pérez",
    "created_at": "2026-10-28T14:33:26Z",
    "updated_at": "2026-10-28T14:33:28Z"
  }
}
```
