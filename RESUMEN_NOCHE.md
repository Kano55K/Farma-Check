# Resumen del trabajo — TP 2 Farma-Check

Estado: **la integración está completa, probada y documentada en local**. No se pusheó nada (decisión
acordada); los pasos para publicar están en [BLOQUEOS.md](BLOQUEOS.md).

## Qué se hizo

### Back-end (`Farma-Check`, rama `tp2-integracion`)

**Correcciones de la sección 2 (las 13 se verificaron y quedaron resueltas)**

- La API ahora hereda de `ActionController::API`: [`app/controllers/api/v1/base_controller.rb`](app/controllers/api/v1/base_controller.rb).
  Desde ahí se centralizan el token Bearer con vencimiento, el **formato único de error**
  `{ error: { code, message, details } }` (con `rescue_from` para 400/401/403/404/422), la autorización por rol (`require_admin!` → 403) y la paginación.
- CORS con `rack-cors` y la variable `FRONTEND_ORIGIN`: [`config/initializers/cors.rb`](config/initializers/cors.rb).
- `StockMovement` valida tipo, cantidad (> 0, o ≥ 0 en ajuste), stock suficiente y lote vencido o retirado.
  El enum inexistente ahora da 422 en lugar de 500, y el movimiento y el cambio de stock se guardan en la misma transacción: [`app/models/stock_movement.rb`](app/models/stock_movement.rb).
- Token con vencimiento (migración reversible `api_token_expires_at`, 12 h, configurable con `API_TOKEN_TTL_HOURS`). Además, `logout` ahora exige un token válido.
- Strong params en movimientos (acepta el objeto anidado y el cuerpo plano).
- `products#index` sin N+1 (`Product.with_active_stock`, una sola consulta) y con paginación.
- `.ruby-version` pasó a 3.3.12. Las bases SQLite salieron del repo. Los seeds son completos e idempotentes, con contraseña de demo: [`db/seeds.rb`](db/seeds.rb).

**Hallazgos extra corregidos**

- El back-office buscaba con `ILIKE`, que no existe en SQLite, y toda búsqueda de productos daba 500.
- `CheckExpiredBatchesJob` usaba un estado inexistente (`:vencido`).
- Los movimientos del back-office quedaban a nombre de `User.first` y el código creaba un usuario con contraseña fija. Ahora se usa el usuario de la sesión y la vista muestra los errores.
- Borrar un proveedor eliminaba en cascada sus órdenes. Ahora se impide y se muestra un aviso.
- Faltaba validar el CUIT. Ahora se controlan el formato y el dígito verificador.
- La suite heredada estaba rota (29 de 60 tests fallaban). Las causas eran tres: tests sin sesión, helpers de rutas inexistentes y la paralelización con threads, que en Windows rompe SQLite.
- `tailwindcss-rails` solo estaba en el grupo `:test` del Gemfile.
- El método `User#admin?` duplicaba lo que ya provee el enum y se quitó.
- Los mensajes de validación pasaron a español y la zona horaria a Buenos Aires: [`config/locales/es.yml`](config/locales/es.yml).
- El CI escuchaba `master`, una rama que no existe. Ahora escucha `main`.

**Endpoints nuevos (sección 3)**: dashboard, lotes, proveedores (alta y edición solo admin) y órdenes de
compra (alta con ítems, total calculado en el servidor, `send`, `cancel` solo admin y `receive`, que crea los lotes y las entradas en una transacción).
Están en [`app/controllers/api/v1/`](app/controllers/api/v1/), con un único serializador en [`app/serializers/`](app/serializers/) y fechas ISO 8601.

**Tests**

- Tests de integración por endpoint en [`test/integration/api/v1/`](test/integration/api/v1/): caso exitoso, 401, token vencido, 403, 404 y 422.
- Tests de modelo de `StockMovement` y `PurchaseOrder`, con fixtures nuevos.

### Front-end (`D:\Programacion\RUBY\farma-check-front`, repo propio)

- Stack: React 19, Vite 8, TypeScript, React Router 7, TanStack Query 5 y Tailwind 4, todo con componentes propios.
- Las 10 pantallas pedidas siguen los wireframes que estaban en `D:\Programacion\RUBY\*.png` (rutas, modal de movimiento y paleta verde).
- Capa de API central con 401 → login con aviso y 403 → toast. La sesión guarda la expiración del token y las acciones se muestran según el rol.
- UX: estados de carga, vacío y error con **Reintentar**; toasts con `aria-live`; botones "Guardando…"; diseño responsive (menú colapsable, tablas que pasan a tarjetas) y accesible (labels, foco visible, teclado, `<dialog>`).
- Tests con Vitest, Testing Library y MSW. E2E con Playwright contra la API real.
- Documentado en su [README](../../farma-check-front/README.md).

### Documentación

- Contrato de la API: [`docs/api/`](docs/api/README.md), un archivo por recurso con **respuestas reales**, más [`openapi.yaml`](docs/api/openapi.yaml) y la [colección de Postman](docs/api/farma-check.postman_collection.json).
- [`README.md`](README.md) reescrito: requisitos, instalación de los dos proyectos, credenciales, calidad y guion de demo.
- [`docs/checkpoint.md`](docs/checkpoint.md): alcance, mapa de pantallas (Mermaid), endpoints y estado de las observaciones del TP 1.
- [`.env.example`](.env.example) en los dos repos.
- [`script/e2e_api.sh`](script/e2e_api.sh): prueba de punta a punta con curl.

## Resultado de cada verificación (última corrida, con la base recién creada desde los seeds)

| Comando | Resultado |
|---|---|
| `bin/rails db:seed` corrido dos veces | Mismos conteos las dos veces (3 usuarios, 5 proveedores, 25 productos, 29 lotes, 87 movimientos, 5 órdenes): **idempotente** |
| `bin/rails db:test:prepare test` | **149 runs, 442 assertions, 0 failures, 0 errors, 0 skips** |
| `bin/rubocop` | **117 files inspected, no offenses detected** |
| `bin/brakeman --no-pager` | **Brakeman 8.1.0 — 0 errores, 0 advertencias** (no hizo falta `brakeman.ignore`) |
| `script/e2e_api.sh` (servidor real) | **64 OK, 0 fallas**: auth, dashboard, productos, lotes, movimientos (incluye salida > stock → 422), proveedores (403/201/422), órdenes (crear → enviar → recibir crea el lote y suma 24 u; transiciones inválidas → 422), logout, CORS y 6 pantallas del back-office con login por cookie |
| Front `npm run lint` | oxlint **sin advertencias** |
| Front `npm run test` | **2 archivos, 9 tests OK** |
| Front `npm run build` | **OK** (`tsc -b` + Vite; JS 108 kB gzip) |
| Front `npm run e2e` (Playwright con Rails :3000 y Vite :5173 reales) | **5 OK**: flujo 1 (empleado registra una salida y el stock baja), flujo 2 (salida > stock muestra el 422 en el campo), flujo 3 (admin crea, envía y recibe una orden; el lote nuevo aparece y el stock sube), flujo 4 (logout y token inválido vuelven al login) y la vista en celular |

El flujo 5 de la demo (back-office intacto) lo cubren el script de curl (login y 6 pantallas → 200) y los tests de controladores del back-office.

## Cómo levantar todo mañana desde cero

En PowerShell o Git Bash, con Ruby 3.3.12 activo (`ruby -v`):

```bash
# 1) Back-end
cd D:\Programacion\RUBY\farma-check\Farma-Check
git checkout tp2-integracion
bundle install
# Para empezar con datos limpios: borrar la base (con el servidor apagado) y prepararla.
#   PowerShell: Remove-Item db\development.sqlite3* ;  Git Bash: rm -f db/development.sqlite3*
bin/rails db:prepare
bin/rails server                      # deja esta terminal abierta → http://localhost:3000

# 2) Front-end (otra terminal)
cd D:\Programacion\RUBY\farma-check-front
copy .env.example .env                # Git Bash: cp .env.example .env
npm install
npm run dev                           # → http://localhost:5173

# 3) (Opcional) verificaciones
cd D:\Programacion\RUBY\farma-check\Farma-Check
bin/rails test ; bin/rubocop ; bin/brakeman --no-pager
bash script/e2e_api.sh                # con el servidor corriendo
cd D:\Programacion\RUBY\farma-check-front
npm run lint ; npm run test ; npm run build
npx playwright install chromium       # solo la primera vez
npm run e2e                           # con Rails corriendo
```

Credenciales: `empleado@farma-check.com` / `demo1234` y `admin@farma-check.com` / `demo1234`.
El guion de demo paso a paso está en el [README](README.md#guion-de-demo).

> Importante para la demo: `script/e2e_api.sh` y `npm run e2e` **modifican los datos** (registran
> movimientos y crean órdenes). Antes de exponer, volvé a crear la base como en el paso 1.

## Pendientes y riesgos

- **Publicar**: push de `tp2-integracion`, PR contra `main` y creación del repo `farma-check-front` (ver [BLOQUEOS.md](BLOQUEOS.md)).
- **Completar** `{{INTEGRANTES}}` y `{{MODALIDAD}}` en `README.md` y `docs/checkpoint.md`.
- En Windows, `bin/rails db:reset` puede fallar con "Permission denied" si el servidor o algún visor tiene
  abierta la base. Hay que cerrar el servidor y borrar el archivo a mano (está explicado en el README).
- Los tests corren en serie en Windows (unos 25 s); en el CI (Linux) se paralelizan.
- Un cuerpo con bytes que no son UTF-8 válido lo rechaza Rails con un 400 genérico, fuera del formato
  único. No afecta a navegadores ni a Postman; está documentado en el contrato.
- Las carpetas viejas de Postman (`.postman/`, `postman/`) solo tenían la configuración del workspace,
  sin colección. La colección nueva está en `docs/api/` y no se tocaron esas carpetas.
- Los ejemplos del contrato son respuestas reales de una corrida; los ids, tokens y fechas cambian en cada base.

## Ramas y PRs

| Repo | Rama | Estado |
|---|---|---|
| Back-end `Farma-Check` | `tp2-integracion` (desde `main`) | Commits locales, **sin push**. `main` sin cambios. PR no creado (sin `gh` y sin push, como se acordó) |
| Front-end `farma-check-front` | `main` | Repo nuevo local, **sin remoto** todavía |
