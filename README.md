# Farma-Check — Control de stock para farmacia

Sistema para el control de inventario de una farmacia: catálogo de medicamentos, lotes con
**semáforo de vencimiento**, movimientos de stock, proveedores y **órdenes de compra con recepción de
mercadería**.

El proyecto tiene dos partes, en dos repositorios:

| Parte | Repositorio | Tecnología | Para quién |
|---|---|---|---|
| **Back-end** (este repo) | [Kano55K/Farma-Check](https://github.com/Kano55K/Farma-Check) | Ruby on Rails 8.1 + SQLite | API REST `api/v1` + **back-office** de administración (vistas ERB) |
| **Front-end** | [Kano55K/farma-check-front](https://github.com/Kano55K/farma-check-front) (carpeta hermana `farma-check-front/`) | React 19 + Vite + TypeScript | **Usuario final**: empleado de mostrador / farmacéutico |

Administración (back-office Rails) y uso diario (front-end) son contextos distintos: el back-office sigue
funcionando igual que en el TP 1 y el front-end consume solo la API.

## Datos del trabajo

| | |
|---|---|
| Materia | Programación IV — Trabajo Práctico N.º 2 (integración back-end + front-end) |
| Temática | Control de stock y vencimientos de una farmacia |
| Integrantes | {{INTEGRANTES}} |
| Modalidad de trabajo | {{MODALIDAD}} |
| Back-end original (TP 1) | Kano55K |
| Framework del front-end | React + Vite + TypeScript ([farma-check-front](https://github.com/Kano55K/farma-check-front)) |

## Documentación

- **Contrato de la API**: [`docs/api/`](docs/api/README.md) (Markdown con ejemplos reales, [`openapi.yaml`](docs/api/openapi.yaml) y [colección de Postman](docs/api/farma-check.postman_collection.json)).
- **Checkpoint del TP 2** (alcance, mapa de pantallas, endpoints, observaciones del TP 1): [`docs/checkpoint.md`](docs/checkpoint.md).

---

## Requisitos (versiones probadas)

| Herramienta | Versión |
|---|---|
| Ruby | **3.3.12** (ver `.ruby-version`) |
| Rails | 8.1.3.1 |
| Bundler | el que trae Ruby 3.3 |
| SQLite | incluido en la gema `sqlite3` |
| Node.js | 24.12.0 (solo para el front-end) |
| npm | 11.7.0 |

> En Windows, si tenés varias versiones de Ruby instaladas (por ejemplo `D:\Ruby40-x64`), asegurate de
> que `ruby -v` muestre 3.3.12 antes de correr los comandos (el `Gemfile.lock` se resolvió con 3.3).

## Instalación y ejecución

### 1. Back-end (este repo) — http://localhost:3000

```bash
git clone https://github.com/Kano55K/Farma-Check.git
cd Farma-Check
bundle install
bin/rails db:prepare        # crea la base, carga el esquema y los seeds de demo
bin/rails server            # http://localhost:3000
```

- Back-office: http://localhost:3000 (login con las credenciales de abajo).
- API: http://localhost:3000/api/v1.
- Para recompilar los estilos del back-office mientras se edita: `bin/dev` (servidor + `tailwindcss:watch`).
- Para volver los datos de demo a cero: detené el servidor, borrá `db/development.sqlite3` y corré `bin/rails db:prepare`
  (en Windows `bin/rails db:reset` puede fallar con "Permission denied" porque el archivo queda abierto).
- `bin/rails db:seed` es **idempotente**: se puede correr varias veces sin duplicar datos.

### 2. Front-end — http://localhost:5173

```bash
git clone https://github.com/Kano55K/farma-check-front.git   # o usá la carpeta hermana farma-check-front/
cd farma-check-front
cp .env.example .env        # VITE_API_URL=http://localhost:3000/api/v1
npm install
npm run dev                 # http://localhost:5173
```

### Variables de entorno

Back-end ([`.env.example`](.env.example), todas opcionales):

| Variable | Por defecto | Uso |
|---|---|---|
| `FRONTEND_ORIGIN` | `http://localhost:5173,http://127.0.0.1:5173` | Orígenes permitidos por CORS para `/api/*` |
| `API_TOKEN_TTL_HOURS` | `12` | Duración del token de la API |

Front-end (`.env.example`): `VITE_API_URL` (URL base de la API).

## Credenciales de demostración

Los crea `bin/rails db:seed`. Son **solo para la demo** (no hay contraseñas reales en el repositorio).

| Rol | Email | Contraseña |
|---|---|---|
| Administrador | `admin@farma-check.com` | `demo1234` |
| Empleado | `empleado@farma-check.com` | `demo1234` |
| Empleado | `farmaceutica@farma-check.com` | `demo1234` |

Crear otros usuarios:

- Desde el back-office, como admin: **Usuarios → /users/new** (envía un mail de bienvenida, visible en http://localhost:3000/letter_opener).
- Desde la consola: `bin/rails runner 'User.create!(email_address: "nuevo@farma-check.com", password: "otra-clave", role: :employee)'`

## Pruebas y calidad

| Comando | Qué verifica | Último resultado |
|---|---|---|
| `bin/rails test` | Modelos, controladores del back-office e **integración de la API** (`test/integration/api/v1`) | 149 tests, 0 fallas |
| `bin/rubocop` | Estilo (rubocop-rails-omakase) | 0 ofensas |
| `bin/brakeman --no-pager` | Análisis de seguridad estático | 0 advertencias |
| `script/e2e_api.sh` | Recorrido real de la API y el back-office con curl (requiere el servidor corriendo con seeds) | 64 chequeos OK |
| `npm run lint` / `npm run test` / `npm run build` (front) | oxlint, Vitest + Testing Library + MSW, build de producción | sin advertencias / 9 tests OK / build OK |
| `npm run e2e` (front) | Playwright contra la API real (requiere los dos servidores) | 4 escenarios OK |

Notas:

- En Windows los tests corren en serie: la paralelización con threads comparte la conexión SQLite y falla
  (`cannot start a transaction within a transaction`). En Linux/CI se paraleliza por procesos.
- Los warnings `VIPS-WARNING ... unable to load vips-*.dll` que aparecen al arrancar en Windows vienen de
  libvips (procesamiento de imágenes de Active Storage) y no afectan a la aplicación.
- `bin/brakeman` usa `--ensure-latest`: si sale una versión nueva de Brakeman, el comando falla hasta
  actualizarla con `bundle update brakeman`. No hay advertencias justificadas ni `config/brakeman.ignore`.
- El CI de GitHub (`.github/workflows/ci.yml`) corre Brakeman, bundler-audit, importmap audit, RuboCop y los tests en cada PR y en cada push a `main`.

---

## Guion de demo

Preparación: base con seeds recién cargados, `bin/rails server` en una terminal y `npm run dev` (front) en otra.

1. **Empleado: consulta y salida de stock**
   1. Abrir http://localhost:5173 → redirige al login. Ingresar como `empleado@farma-check.com` / `demo1234`.
   2. **Inicio**: KPIs (productos, sin stock, stock bajo, lotes vencidos/críticos) y alertas.
   3. **Productos** → buscar "ibuprofeno" (la búsqueda espera 300 ms y queda en la URL) → **Ver** "Ibuprofeno 400 mg".
   4. En el lote `IBU-2401` → **+ Movimiento** → tipo Salida, cantidad 2, motivo "Venta" → **Guardar** (el botón pasa a "Guardando…").
   5. Aparece el aviso "Movimiento registrado…" y el stock total y el del lote bajan 2 unidades.
2. **Escenario de error**: en el lote `IBU-2312` → **+ Movimiento** → Salida de 1000 unidades → la API responde 422 y se
   ve debajo del campo: "supera el stock disponible del lote (25)". No se registra nada.
3. **Admin: orden de compra completa**
   1. Cerrar sesión → ingresar como `admin@farma-check.com`.
   2. **Órdenes de compra → Nueva orden** → proveedor "Droguería del Sur S.A.", ítem "Paracetamol 500 mg", 10 u a $950,50 → el total se calcula en vivo → **Crear orden**.
   3. En el detalle: **Enviar al proveedor** (pasa a Enviada) → **Recibir mercadería** → lote `L-DEMO-1`, vencimiento dentro de un año, ubicación "Depósito" → **Confirmar recepción**.
   4. Ir al producto: aparece el lote `L-DEMO-1` y el stock subió 10 unidades. En **Movimientos** figura la entrada.
   5. (Opcional) Probar **Cancelar orden** en una orden pendiente: solo el admin ve el botón; con un empleado la API respondería 403.
4. **Sesión vencida o logout**: **Cerrar sesión** vuelve al login. Si el token vence (12 h) o es inválido, la próxima
   petición responde 401 y la app vuelve al login con el aviso "Tu sesión expiró".
5. **Back-office intacto**: http://localhost:3000 → login con `admin@farma-check.com` → `/dashboard`, `/products`,
   `/batches`, `/stock_movements`, `/suppliers`, `/purchase_orders` funcionan como en el TP 1.

Estos mismos flujos están automatizados en `script/e2e_api.sh` (API) y en `npm run e2e` del front (navegador).

---

## Modelo de datos

| Entidad | Descripción |
|---|---|
| User | Usuarios con rol `employee` o `admin`; `api_token` + `api_token_expires_at` para la API |
| Product | Medicamento: droga, laboratorio, presentación, código de barras, stock mínimo |
| Batch | Lote de un producto: número, vencimiento, cantidad, ubicación, estado |
| StockMovement | Movimiento sobre un lote: `entrada`, `salida`, `ajuste`, `devaluacion_vencimiento` |
| Supplier | Proveedor con CUIT validado (formato y dígito verificador) |
| PurchaseOrder | Orden a un proveedor: `pending` → `sent` → `received` / `cancelled` |
| PurchaseOrderItem | Línea de una orden (producto, cantidad, precio unitario) |
| Session | Sesión del back-office (cookie) |

Reglas principales: una salida no puede superar el stock del lote ni hacerse sobre un lote vencido o retirado;
el movimiento y el cambio de stock se guardan en una transacción; el total de una orden lo calcula el
servidor; la recepción crea los lotes y las entradas en una sola transacción.

## Matriz de permisos

| Acción | Empleado | Administrador |
|---|:---:|:---:|
| Ver stock, vencimientos, movimientos, proveedores y órdenes | ✔ | ✔ |
| Registrar movimientos de stock | ✔ | ✔ |
| Crear, enviar y recibir órdenes de compra | ✔ | ✔ |
| Crear y editar proveedores (API) | ✘ | ✔ |
| Cancelar órdenes de compra (API) | ✘ | ✔ |
| Eliminar productos o proveedores (back-office) | ✘ | ✔ |
| Gestión de usuarios (back-office) | ✘ | ✔ |

## Módulos del back-office

| Módulo | URL | Descripción |
|---|---|---|
| Dashboard | `/dashboard` | KPIs, alertas de vencimiento y movimientos recientes |
| Inventario | `/products` | ABM de medicamentos con filtros y semáforo de stock |
| Vencimientos | `/batches` | Lotes por fecha con semáforo de criticidad |
| Movimientos | `/stock_movements` | Historial de entradas y salidas |
| Proveedores | `/suppliers` | ABM de droguerías y laboratorios |
| Órdenes de compra | `/purchase_orders` | Gestión de pedidos |
| Usuarios | `/users/new` | Alta de usuarios (solo admin) |
| Emails (desarrollo) | `/letter_opener` | Mails enviados |
