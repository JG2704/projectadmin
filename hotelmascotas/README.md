# PetLodge App - Hotel de Mascotas

## Miembros
- Sebastián Guillén Guzmán
- Brandon Ramírez Campos
- José Gabriel Marín Aguilar

## Profesor
- Jaime Solano Soto

---

# Instalación y ejecución paso a paso

## Requisitos previos
Antes de ejecutar el proyecto, tener instalado:

- **Python 3**
- **pip**
- **Flutter SDK**
- **Android SDK** o un dispositivo Android conectado
- **Git**
- Un editor como **VS Code** o **Android Studio**

## 1) Clonar o abrir el proyecto
Ubicarse en la carpeta principal del proyecto:

```bash
cd projectadmin/hotelmascotas
```

## 2) Backend (FastAPI + SQLite servidor)
Entrar a la carpeta del backend:

```bash
cd backend
```

Instalar dependencias del backend:

```bash
python -m pip install fastapi uvicorn bcrypt
```

### Inicialización de base de datos
La API valida en el arranque la base oficial compartida en:

```text
backend/database/petlodge_backend.db
```

Si la base no existe o todavía no tiene tablas, el backend la inicializa automáticamente usando:

```text
backend/database/schema.sql
backend/database/seed.sql
```

### Levantar API
Ejecutar:

```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

> Si `uvicorn` no es reconocido, usar siempre `python -m uvicorn ...`.

## 3) Frontend (Flutter)
Abrir otra terminal y entrar a la carpeta del frontend:

```bash
cd ../frontend
```

Instalar dependencias y limpiar compilación:

```bash
flutter clean
flutter pub get
```

Ejecutar la aplicación:

```bash
flutter run
```

## 4) Configuración de conexión según el dispositivo
- Si se usa **emulador Android**, normalmente el frontend puede apuntar a:

```text
http://10.0.2.2:8000
```

- Si se usa **celular físico**, el frontend debe apuntar a la **IP local de la computadora** donde corre el backend, por ejemplo:

```text
http://192.168.x.x:8000
```

*¿Cómo consigo esa IP?*
*Simplemente abrir la consola de comandos, y ejecutar:*
```text
ipconfig
```
*Y seleccionamos la mostrada en la línea de **DireccionIPv4***

La configuración de conexión se encuentra en:

```text
frontend/lib/services/auth_service.dart
```

---

# Descripción general del proyecto

**PetLodge App** es una aplicación para la gestión de un hotel de mascotas. Permite a los usuarios:

- Registrarse e iniciar sesión
- Gestionar su perfil
- Registrar, editar y eliminar mascotas
- Crear, consultar y cancelar reservas
- Consultar notificaciones del sistema
- Gestionar métodos de pago

La arquitectura actual trabaja con:

- **Frontend:** Flutter
- **Backend:** FastAPI
- **Base de datos oficial compartida:** SQLite en el backend

> La SQLite local del frontend se mantiene solo como referencia del modelo. La fuente oficial compartida de datos es la base del backend.

---

# Estructura actual del proyecto

```text
hotelmascotas/
├── backend/
│   ├── database/
│   │   ├── petlodge_backend.db
│   │   ├── schema.sql
│   │   └── seed.sql
│   └── main.py
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   ├── services/
    │   └── features/auth/
    │       ├── login/
    │       ├── home/
    │       ├── profile/
    │       ├── pets/
    │       ├── history/
    │       └── notifications/
    └── pubspec.yaml
```

---

# Frontend

## Tecnologías utilizadas
- **Flutter**
- **Dart**
- **Dio** para consumo de API
- **SharedPreferences** para persistencia de sesión local

## Archivo principal
```text
frontend/lib/main.dart
```

## Servicios importantes
```text
frontend/lib/services/auth_service.dart
```

Este archivo centraliza:
- URL base del backend
- envío del header `X-User-Id`
- guardado de `user_id` y token
- cierre de sesión

## Módulos principales del frontend

### Login y registro
```text
frontend/lib/features/auth/login/
```
Permite:
- iniciar sesión
- registrarse
- mantener sesión persistente

### Inicio / Dashboard
```text
frontend/lib/features/auth/home/
```
Muestra el resumen principal del usuario.

### Perfil
```text
frontend/lib/features/auth/profile/
```
Permite consultar y editar los datos del usuario.

### Mascotas
```text
frontend/lib/features/auth/pets/
```
Incluye:
- listado de mascotas
- detalle de mascota
- agregar mascota
- editar mascota
- eliminar mascota

### Reservas / Historial
```text
frontend/lib/features/auth/history/
```
Incluye:
- creación de reservas
- historial de reservas
- detalle de reserva
- cancelación de reservas

### Notificaciones
```text
frontend/lib/features/auth/notifications/
```
Permite:
- visualizar notificaciones
- marcar notificaciones como leídas

---

# Backend

## Tecnología utilizada
- **FastAPI**
- **SQLite**
- **bcrypt** para validación de contraseñas

## Archivo principal
```text
backend/main.py
```

## Responsabilidades del backend
El backend se encarga de:
- autenticación de usuarios
- registro de usuarios
- lectura y actualización de perfil
- CRUD de mascotas
- creación y consulta de reservas
- cancelación de reservas
- obtención de habitaciones
- consulta y actualización de notificaciones
- conexión oficial con la base de datos SQLite

## Base de datos oficial compartida
La base que usa el sistema en producción del proyecto está en:

```text
backend/database/petlodge_backend.db
```

Además, `main.py` usa estas rutas:

- `backend/database/petlodge_backend.db`
- `backend/database/schema.sql`
- `backend/database/seed.sql`

---

# Base de datos

## Motor
- **SQLite**

## Ubicación oficial
```text
backend/database/petlodge_backend.db
```

## Tablas principales

### Usuarios
- `tipo_pago`
- `tipo_usuario`
- `usuario`

### Mascotas
- `tipo_mascota`
- `veterinario`
- `mascota`
- `necesidad`
- `mascota_x_necesidad`

### Hotel y habitaciones
- `hotel`
- `habitacion`

### Reservas
- `estado_reserva`
- `tipo_hospedaje`
- `reserva`
- `actualizaciones`

### Servicios
- `servicio`
- `detalle_reserva`

### Notificaciones
- `tipo_notificacion`
- `notificacion`

## Relaciones principales
- Una **mascota** pertenece a un **usuario**
- Una **mascota** pertenece a un **tipo_mascota**
- Una **mascota** puede tener un **veterinario**
- `mascota_x_necesidad` relaciona una mascota con sus necesidades
- Una **reserva** pertenece a una **mascota**
- Una **reserva** pertenece a una **habitacion**
- Una **reserva** pertenece a un **tipo_hospedaje**
- `detalle_reserva` relaciona una reserva con servicios contratados
- Una **notificacion** pertenece a un **usuario**
- Una **notificacion** puede pertenecer a una **reserva**

---

# Datos iniciales y pruebas

## Usuario de prueba
- **Correo:** `cliente@hotel.com`
- **Clave:** `123456`

## Catálogos sembrados

### Tipo de pago
- efectivo
- tarjeta

### Tipo de usuario
- cliente
- admin

### Necesidad
- vacuna
- conditions
- dieta

### Estado de reserva
- pendiente
- activa
- completada
- cancelada

### Tipo de hospedaje
- estandar
- especial

### Tipo de notificación
- reserva_confirmada
- reserva_modificada
- reserva_cancelada
- reserva_finalizada
- actualizacion
- recordatorio
- novedad_app
- mascota_agregada
- mascota_eliminada

### Hotel
- PetLodge

### Habitaciones
- 101
- 102
- 103

### Tipos de mascota de prueba
- perro / golden retriever
- gato / persa
- conejo / mini lop

### Servicios de prueba
- bano
- grooming
- paseo

---

# Flujo básico de uso

## 1. Registro e inicio de sesión
El usuario puede:
- registrarse con sus datos personales
- iniciar sesión con correo y contraseña

## 2. Perfil
El usuario puede:
- ver sus datos
- editar nombre, cédula, correo, teléfono y dirección

## 3. Mascotas
El usuario puede:
- ver el listado de sus mascotas
- agregar una nueva mascota
- editar la información de una mascota
- eliminar una mascota si no tiene restricciones activas

## 4. Reservas
El usuario puede:
- crear una reserva
- consultar su historial
- ver el detalle de una reserva
- cancelar reservas

## 5. Notificaciones
El usuario puede:
- consultar notificaciones relacionadas con mascotas y reservas
- marcar notificaciones como leídas

---

# Archivos importantes

## Backend
```text
backend/main.py
backend/database/schema.sql
backend/database/seed.sql
backend/database/petlodge_backend.db
```

## Frontend
```text
frontend/lib/main.dart
frontend/lib/services/auth_service.dart
frontend/lib/features/auth/login/login_page.dart
frontend/lib/features/auth/home/home_page.dart
frontend/lib/features/auth/profile/profile_page.dart
frontend/lib/features/auth/pets/pets_page.dart
frontend/lib/features/auth/pets/add_pet_form.dart
frontend/lib/features/auth/pets/edit_pet_page.dart
frontend/lib/features/auth/pets/pet_detail_page.dart
frontend/lib/features/auth/history/history_page.dart
frontend/lib/features/auth/history/create_reservation_page.dart
frontend/lib/features/auth/history/reservation_detail_page.dart
frontend/lib/features/auth/notifications/notifications_page.dart
```

---

# Consideraciones técnicas

- La base oficial compartida es la del backend, no la SQLite local del frontend.
- Los nombres de tablas y columnas se dejaron sin tildes para evitar problemas de compatibilidad.
- Las fechas se almacenan como texto en formato ISO.
- Los valores booleanos se almacenan como `0` y `1`.
- El backend usa `X-User-Id` para resolver el usuario autenticado en la mayoría de endpoints.

---

# Solución de problemas comunes

## `uvicorn` no es reconocido
Usar:

```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## El celular no conecta al backend
- Verificar que backend esté corriendo con `--host 0.0.0.0`
- Verificar que celular y computadora estén en la misma red
- Cambiar la URL base del frontend a la IP local de la computadora

## Se cambiaron tablas o catálogos y no se reflejan
La base existente puede necesitar reinicialización. En ese caso:
- respaldar o borrar `backend/database/petlodge_backend.db`
- volver a levantar el backend para que cargue `schema.sql` y `seed.sql`

## Las notificaciones no aparecen correctamente
Verificar que los tipos existan en la tabla `tipo_notificacion`.

---

# Estado actual del proyecto

Actualmente el proyecto utiliza una arquitectura con:
- **Flutter** como interfaz móvil
- **FastAPI** como servidor
- **SQLite en backend** como fuente oficial de datos compartidos

Con esta estructura, el frontend y el backend trabajan contra una única base oficial, permitiendo que los datos creados o modificados se reflejen de forma consistente en todo el sistema.
