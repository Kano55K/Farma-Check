# Autenticación

[← Volver al índice](README.md)

## POST /login

| | |
|---|---|
| Acceso | **Pública** |
| Rol | — |
| Encabezados | `Content-Type: application/json` |

### Cuerpo

Acepta los campos en la raíz o anidados en `session` (`{ "session": { ... } }`).

| Campo | Tipo | Obligatorio | Validaciones |
|---|---|---|---|
| `email_address` | string | sí | Email del usuario (no distingue mayúsculas ni espacios al inicio/fin) |
| `password` | string | sí | Contraseña |

### Respuesta exitosa — `200 OK`

| Campo | Tipo | Significado |
|---|---|---|
| `token` | string | Token para el encabezado `Authorization: Bearer <token>` |
| `token_type` | string | Siempre `"Bearer"` |
| `expires_at` | timestamp | Vencimiento del token (UTC). Por defecto, 12 h después del login |
| `user.id` | entero | Id del usuario |
| `user.email` | string | Email |
| `user.role` | string | `employee` o `admin` |

```bash
curl -s -X POST http://localhost:3000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email_address":"empleado@farma-check.com","password":"demo1234"}'
```

```json
{
  "token": "DsTz52XnBCBp3Y82PpfeHWhf",
  "token_type": "Bearer",
  "expires_at": "2026-10-29T02:32:53Z",
  "user": { "id": 2, "email": "empleado@farma-check.com", "role": "employee" }
}
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `invalid_credentials` | Email o contraseña incorrectos |
| 422 | `validation_failed` | Falta el email o la contraseña |
| 400 | `bad_request` | JSON mal formado |

```json
// 401 — contraseña incorrecta
{ "error": { "code": "invalid_credentials", "message": "Email o contraseña incorrectos", "details": null } }

// 422 — cuerpo vacío: {}
{
  "error": {
    "code": "validation_failed",
    "message": "Ingresá email y contraseña",
    "details": { "email_address": ["es obligatorio"], "password": ["es obligatoria"] }
  }
}
```

---

## DELETE /logout

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Encabezados | `Authorization: Bearer <token>` |

Sin cuerpo. Invalida el token: a partir de ese momento las peticiones con él responden `401 unauthorized`.

### Respuesta exitosa — `200 OK`

```bash
curl -s -X DELETE http://localhost:3000/api/v1/logout -H "Authorization: Bearer $TOKEN"
```

```json
{ "message": "Sesión cerrada" }
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `unauthorized` | Sin token o token ya inválido |
| 401 | `token_expired` | El token venció (la sesión ya terminó) |

```json
// 401 — logout sin token, o cualquier petición con el token después del logout
{ "error": { "code": "unauthorized", "message": "Falta el token o no es válido. Iniciá sesión.", "details": null } }
```

---

## GET /profile

| | |
|---|---|
| Acceso | Protegida |
| Rol | cualquiera |
| Encabezados | `Authorization: Bearer <token>` |

### Respuesta exitosa — `200 OK`

| Campo | Tipo | Significado |
|---|---|---|
| `id` | entero | Id del usuario |
| `email` | string | Email |
| `role` | string | `employee` o `admin` |
| `token_expires_at` | timestamp | Vencimiento del token actual |

```bash
curl -s http://localhost:3000/api/v1/profile -H "Authorization: Bearer $TOKEN"
```

```json
{ "id": 2, "email": "empleado@farma-check.com", "role": "employee", "token_expires_at": "2026-10-29T02:32:53Z" }
```

### Errores

| HTTP | `code` | Causa |
|---|---|---|
| 401 | `unauthorized` | Sin token, token inexistente o revocado |
| 401 | `token_expired` | Token vencido |

```json
{ "error": { "code": "token_expired", "message": "La sesión expiró. Iniciá sesión nuevamente.", "details": null } }
```
