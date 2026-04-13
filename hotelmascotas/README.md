# PetLodge App - Hotel de Mascotas
## Miembros
- Sebastián Guillen Guzmán 
- Brandon Ramírez Campos
- Kevin Espinoza Barrantes
- José Gabriel Marín Aguilar
---
## Profesor
- Jaime Solano Soto

---
# Frontend

# Backend

## Bases de datos

### Descripción
Se implementó una base de datos local en SQLite para la aplicación móvil **PetLodge App** usando Flutter.  
El objetivo de esta base es almacenar de forma local la información principal del sistema mientras se integra posteriormente con el backend.

### Tecnologías utilizadas
- **Flutter**
- **SQLite**^2.4.2
- Paquete **sqflite**
- Paquete **path**

### Archivo principal
La lógica de la base de datos se encuentra en:

```text
lib/services/database_helper.dart
```
La inicialización de la base se realiza en:
```text
lib/main.dart
```

Al ejecutar la llamada
`await DatabaseHelper.instance.database;`

### Nombre de la base de datos
- petlodge.db

### Config importante
- Se habilitaron las foreign keys con `PRAGMA foreign_keys = ON;`

### Tablas Implementadas
Usuarios
- tipo_pago
- tipo_usuario
- usuario

Mascotas
- tipo_mascota
- veterinario
- mascota
- necesidad
- mascota_x_necesidad

Hotel y habitaciones
- hotel
- habitacion

Reservas
- estado_reserva
- tipo_hospedaje
- reserva
- actualizaciones

Servicios
- servicio
- detalle_reserva

Notificaciones
- tipo_notificacion
- notificacion

### Relaciones principales
- Una **mascota** pertenece a un **usuario**
- Una **mascota** pertenece a un **tipo_mascota**
- Una **mascota** puede tener un **veterinario**
- **mascota_x_necesidad** relaciona una mascota con sus necesidades
- Una **reserva** pertenece a una **mascota**
- Una **reserva** pertenece a una **habitacion**
- Una **reserva** pertenece a un **tipo_hospedaje**
- **detalle_reserva** relaciona una reserva con los servicios contratados
- Una **notificacion** pertenece a un **usuario**
- Una **notificacion** puede pertenecer a una **reserva**

### Datos de las tablas catálogo
Se dejaron datos iniciales para facilitar pruebas:

Tipo de pago
- efectivo
- tarjeta

Tipo de usuario
- cliente
- admin

Necesidad
- vacuna
- alergia
- dieta

Estado de reserva
- pendiente
- activa
- completada
- cancelada

Tipo de hospedaje
- estandar
- especial

Tipo de notificación
- reserva_confirmada
- reserva_modificada
- reserva_finalizada
- actualizacion
- recordatorio
- novedad_app

Hotel
- PetLodge

Habitaciones
- 101
- 102
- 103

Tipos de mascota de prueba
- perro / golden retriever
- gato / persa
- conejo / mini lop

Servicios de prueba
- bano
- grooming
- paseo

Usuario de prueba
- Email: cliente@hotel.com
- Clave: 123456

### Verificaciones de funcionamiento
Se comprobó en ejecución real sobre dispositivo Android que:

- la base se crea correctamente
- las foreign keys se activan
- los datos semilla se insertan
- las tablas quedan registradas en SQLite

### Consideraciones
- Los nombres de tablas y columnas se dejaron sin tildes ni caracteres especiales para evitar problemas de compatibilidad en SQLite.
- Las fechas se almacenan como texto en formato ISO (`YYYY-MM-DD` o `YYYY-MM-DD HH:MM:SS`).
- Los valores booleanos se almacenan como `0` y `1`.

### ¿Cómo reiniciar la base?
Si en el futuro se cambian tablas o columnas, la base puede reiniciarse con el siguiente código. Debe reemplazarse por el de inicialización en el archivo `main.dart` (y, al correrse una vez, debe volver a cambiarse al de antes):

```dart
await DatabaseHelper.instance.resetDatabase();
await DatabaseHelper.instance.database;
```


