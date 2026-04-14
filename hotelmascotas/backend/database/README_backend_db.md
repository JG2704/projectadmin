# Base de datos backend - PetLodge

## Archivos incluidos
- `schema.sql`: crea las tablas y llaves foráneas del backend.
- `seed.sql`: inserta datos semilla y datos de prueba.
- `petlodge_backend.db`: base SQLite compartida del backend.

## Uso desde la API
La API FastAPI (`backend/main.py`) usa esta base como fuente oficial de datos.

Comportamiento en startup:
1. Si la tabla `usuario` no existe, ejecuta `schema.sql` y luego `seed.sql`.
2. Si la tabla existe pero está vacía, ejecuta `seed.sql`.
3. Si ya hay datos, no los sobreescribe.

## Cómo abrirla en DB Browser for SQLite
1. Abrir **DB Browser for SQLite**.
2. Elegir **Open Database**.
3. Abrir `petlodge_backend.db`.

## Reinicialización manual
Si necesitas reconstruir la base desde cero:
1. Crear una base nueva.
2. Ejecutar `schema.sql`.
3. Ejecutar `seed.sql`.
4. Guardar como `petlodge_backend.db`.
