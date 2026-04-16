PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS notificacion;
DROP TABLE IF EXISTS tipo_notificacion;
DROP TABLE IF EXISTS detalle_reserva;
DROP TABLE IF EXISTS servicio;
DROP TABLE IF EXISTS actualizaciones;
DROP TABLE IF EXISTS reserva;
DROP TABLE IF EXISTS estado_reserva;
DROP TABLE IF EXISTS habitacion;
DROP TABLE IF EXISTS hotel;
DROP TABLE IF EXISTS mascota_x_necesidad;
DROP TABLE IF EXISTS necesidad;
DROP TABLE IF EXISTS mascota;
DROP TABLE IF EXISTS veterinario;
DROP TABLE IF EXISTS tipo_mascota;
DROP TABLE IF EXISTS usuario;
DROP TABLE IF EXISTS tipo_usuario;
DROP TABLE IF EXISTS tipo_pago;
DROP TABLE IF EXISTS tipo_hospedaje;

CREATE TABLE tipo_pago (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo TEXT NOT NULL UNIQUE
);

CREATE TABLE tipo_usuario (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo TEXT NOT NULL UNIQUE
);

CREATE TABLE usuario (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cedula TEXT NOT NULL UNIQUE,
    nombre TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    telefono TEXT,
    direccion TEXT,
    clave_hash TEXT NOT NULL,
    fecha_registro TEXT NOT NULL,
    activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    id_tipo_pago INTEGER NOT NULL,
    id_tipo_usuario INTEGER NOT NULL,
    FOREIGN KEY (id_tipo_pago) REFERENCES tipo_pago(id),
    FOREIGN KEY (id_tipo_usuario) REFERENCES tipo_usuario(id)
);

CREATE TABLE tipo_mascota (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    especie TEXT NOT NULL,
    raza TEXT NOT NULL,
    UNIQUE (especie, raza)
);

CREATE TABLE veterinario (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    telefono TEXT,
    correo TEXT,
    direccion TEXT
);

CREATE TABLE mascota (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    foto TEXT,
    edad INTEGER,
    sexo INTEGER CHECK (sexo IN (0, 1) OR sexo IS NULL),
    tamaño REAL,
    vacunacion TEXT,
    condicion TEXT,
    contrato TEXT,
    cuidados_especiales TEXT,
    id_usuario INTEGER NOT NULL,
    id_tipo_mascota INTEGER NOT NULL,
    id_veterinario INTEGER,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id) ON DELETE CASCADE,
    FOREIGN KEY (id_tipo_mascota) REFERENCES tipo_mascota(id),
    FOREIGN KEY (id_veterinario) REFERENCES veterinario(id)
);

CREATE TABLE necesidad (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo TEXT NOT NULL UNIQUE
);

CREATE TABLE mascota_x_necesidad (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descripcion TEXT NOT NULL,
    id_mascota INTEGER NOT NULL,
    id_necesidad INTEGER NOT NULL,
    FOREIGN KEY (id_mascota) REFERENCES mascota(id) ON DELETE CASCADE,
    FOREIGN KEY (id_necesidad) REFERENCES necesidad(id)
);

CREATE TABLE hotel (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    telefono TEXT,
    correo TEXT,
    direccion TEXT
);

CREATE TABLE habitacion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numero TEXT NOT NULL UNIQUE,
    estado TEXT NOT NULL CHECK (estado IN ('ocupado', 'disponible', 'en limpieza'))
);

CREATE TABLE estado_reserva (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    estado TEXT NOT NULL UNIQUE
);

CREATE TABLE tipo_hospedaje (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo TEXT NOT NULL UNIQUE
);

CREATE TABLE reserva (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fecha_ingreso TEXT NOT NULL,
    fecha_salida TEXT NOT NULL,
    estancia INTEGER NOT NULL CHECK (estancia >= 1),
    precio REAL NOT NULL CHECK (precio >= 0),
    id_mascota INTEGER NOT NULL,
    id_habitacion INTEGER NOT NULL,
    id_estado INTEGER NOT NULL,
    id_tipo_hospedaje INTEGER NOT NULL,
    FOREIGN KEY (id_mascota) REFERENCES mascota(id),
    FOREIGN KEY (id_habitacion) REFERENCES habitacion(id),
    FOREIGN KEY (id_estado) REFERENCES estado_reserva(id),
    FOREIGN KEY (id_tipo_hospedaje) REFERENCES tipo_hospedaje(id)
);

CREATE TABLE actualizaciones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descripcion TEXT NOT NULL,
    fecha_hora TEXT NOT NULL,
    visible_para_cliente INTEGER NOT NULL DEFAULT 1 CHECK (visible_para_cliente IN (0, 1)),
    id_reserva INTEGER NOT NULL,
    FOREIGN KEY (id_reserva) REFERENCES reserva(id) ON DELETE CASCADE
);

CREATE TABLE servicio (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL UNIQUE,
    tipo_hospedaje INTEGER NOT NULL,
    precio REAL NOT NULL CHECK (precio >= 0),
    FOREIGN KEY (tipo_hospedaje) REFERENCES tipo_hospedaje(id)
);

CREATE TABLE detalle_reserva (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descripcion TEXT NOT NULL,
    precio REAL NOT NULL CHECK (precio >= 0),
    id_reserva INTEGER NOT NULL,
    id_servicio INTEGER NOT NULL,
    FOREIGN KEY (id_reserva) REFERENCES reserva(id) ON DELETE CASCADE,
    FOREIGN KEY (id_servicio) REFERENCES servicio(id)
);

CREATE TABLE tipo_notificacion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo TEXT NOT NULL UNIQUE
);

CREATE TABLE notificacion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descripcion TEXT NOT NULL,
    fecha TEXT NOT NULL,
    leida INTEGER NOT NULL DEFAULT 0 CHECK (leida IN (0, 1)),
    id_usuario INTEGER NOT NULL,
    id_reserva INTEGER,
    id_tipo_notificacion INTEGER NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuario(id) ON DELETE CASCADE,
    FOREIGN KEY (id_reserva) REFERENCES reserva(id) ON DELETE SET NULL,
    FOREIGN KEY (id_tipo_notificacion) REFERENCES tipo_notificacion(id)
);

CREATE INDEX idx_mascota_usuario ON mascota(id_usuario);
CREATE INDEX idx_reserva_mascota ON reserva(id_mascota);
CREATE INDEX idx_reserva_habitacion ON reserva(id_habitacion);
CREATE INDEX idx_notificacion_usuario ON notificacion(id_usuario);
CREATE INDEX idx_actualizaciones_reserva ON actualizaciones(id_reserva);
