# Farma-Check — Sistema de Control de Stock para Farmacia

Aplicación web desarrollada con Ruby on Rails 8.1 para la gestión interna de inventario, control de vencimientos, proveedores y órdenes de compra de una farmacia.

## Tecnologías

- Ruby 3.3.12
- Rails 8.1.3.1
- SQLite3
- Tailwind CSS (CDN)
- Active Storage
- Action Mailer + Letter Opener Web

---

## Instalación y ejecución

### 1. Clonar el repositorio

    git clone <URL_DEL_REPO>
    cd farma-stock

### 2. Instalar dependencias

    bundle install

### 3. Preparar la base de datos

    rails db:migrate
    rails db:seed

### 4. Ejecutar el servidor

    rails server

Accedé en: http://localhost:3000

---

## Credenciales de acceso al back-office

| Email | Contraseña | Rol |
|-------|-----------|-----|
| admin@farma-stock.com | (la que configuraste) | Administrador |

Para crear el usuario admin inicial desde la consola:

    rails runner "User.create!(email_address: 'admin@farma-stock.com', password: 'password123', role: :admin)"

---

## Modelo de datos

| Entidad | Descripción |
|---------|-------------|
| User | Usuarios del sistema con roles (admin/employee) |
| Product | Catálogo de medicamentos con droga activa, laboratorio, presentación, código de barras |
| Batch | Lotes de cada producto con cantidad, vencimiento y ubicación |
| StockMovement | Registro de entradas y salidas de stock por lote |
| Supplier | Proveedores (droguerías y laboratorios) con CUIT y datos de contacto |
| PurchaseOrder | Órdenes de compra asociadas a proveedores |
| PurchaseOrderItem | Líneas de cada orden de compra |

### Relaciones principales

- Product tiene muchos Batch y muchos PurchaseOrderItem
- Batch pertenece a Product y tiene muchos StockMovement
- Supplier tiene muchas PurchaseOrder
- PurchaseOrder tiene muchos PurchaseOrderItem
- User tiene muchas Session

---

## API REST — Endpoints principales

Base URL: http://localhost:3000/api/v1

### Autenticación

    POST /api/v1/login
    Body: { "email_address": "admin@farma-stock.com", "password": "password123" }
    Respuesta: { "token": "...", "user": { ... } }

    DELETE /api/v1/logout
    Header: Authorization: Bearer <token>

### Perfil

    GET /api/v1/profile
    Header: Authorization: Bearer <token>

### Productos

    GET /api/v1/products
    GET /api/v1/products/:id
    Header: Authorization: Bearer <token>

    Parametros opcionales:
      ?search=ibuprofeno
      ?laboratory=Bago

### Lotes

    GET /api/v1/batches
    GET /api/v1/batches/:id
    Header: Authorization: Bearer <token>

### Movimientos de stock

    GET  /api/v1/stock_movements
    POST /api/v1/stock_movements
    Header: Authorization: Bearer <token>
    Body: { "batch_id": 1, "movement_type": "entry", "quantity": 10, "reason": "Compra" }

### Proveedores

    GET /api/v1/suppliers
    GET /api/v1/suppliers/:id
    Header: Authorization: Bearer <token>

---

## Modulos del back-office

| Modulo | URL | Descripción |
|--------|-----|-------------|
| Dashboard | /dashboard | KPIs, alertas de vencimiento y movimientos recientes |
| Inventario | /products | CRUD de medicamentos con filtros y semaforo de stock |
| Vencimientos | /batches | Control de lotes por fecha con semaforo de criticidad |
| Movimientos | /stock_movements | Historial de entradas y salidas |
| Proveedores | /suppliers | CRUD de droguerias y laboratorios |
| Ordenes de Compra | /purchase_orders | Gestion de pedidos a proveedores |
| Usuarios | /users/new | Alta de usuarios (solo admin) |

---

## Matriz de permisos

| Accion | Empleado | Administrador |
|--------|----------|---------------|
| Ver stock y alertas | SI | SI |
| Cargar lotes | SI | SI |
| Eliminar productos | NO | SI |
| Gestion de usuarios | NO | SI |
| Ordenes de compra | SI | SI |

---

## Testing

    rails test test/models/

28 tests, 51 assertions, 0 failures.

Cobertura: modelos Product, Batch, User, Supplier — validaciones, scopes y logica de negocio.

---

## Emails

En desarrollo los emails se visualizan en: http://localhost:3000/letter_opener

Emails implementados:
- Bienvenida: se envia al crear un nuevo usuario desde el back-office.

---

## Seguridad y calidad

    bundle exec brakeman
    bundle exec rubocop