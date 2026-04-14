PRAGMA foreign_keys = ON;
BEGIN TRANSACTION;

INSERT INTO tipo_pago (id, tipo) VALUES
(1, 'efectivo'),
(2, 'tarjeta');

INSERT INTO tipo_usuario (id, tipo) VALUES
(1, 'cliente'),
(2, 'admin');

INSERT INTO tipo_mascota (id, especie, raza) VALUES
(1, 'perro', 'golden retriever'),
(2, 'gato', 'persa'),
(3, 'conejo', 'mini lop');

INSERT INTO veterinario (id, nombre, telefono, correo, direccion) VALUES
(1, 'Dra. Laura Ramirez', '6000-1111', 'laura.ramirez@vet.com', 'Cartago, Costa Rica'),
(2, 'Dr. Andres Vargas', '6000-2222', 'andres.vargas@vet.com', 'San Jose, Costa Rica');

INSERT INTO necesidad (id, tipo) VALUES
(1, 'vacuna'),
(2, 'alergia'),
(3, 'dieta');

INSERT INTO hotel (id, nombre, telefono, correo, direccion) VALUES
(1, 'PetLodge', '8888-8888', 'info@petlodge.com', 'Cartago, Costa Rica');

INSERT INTO habitacion (id, numero, estado) VALUES
(1, '101', 'ocupado'),
(2, '102', 'disponible'),
(3, '103', 'disponible');

INSERT INTO estado_reserva (id, estado) VALUES
(1, 'pendiente'),
(2, 'activa'),
(3, 'completada'),
(4, 'cancelada');

INSERT INTO tipo_hospedaje (id, tipo) VALUES
(1, 'estandar'),
(2, 'especial');

INSERT INTO tipo_notificacion (id, tipo) VALUES
(1, 'reserva_confirmada'),
(2, 'reserva_modificada'),
(3, 'reserva_finalizada'),
(4, 'actualizacion'),
(5, 'recordatorio'),
(6, 'novedad_app');

INSERT INTO servicio (id, nombre, tipo_hospedaje, precio) VALUES
(1, 'bano', 2, 15.0),
(2, 'grooming', 2, 25.0),
(3, 'paseo', 1, 10.0);

INSERT INTO usuario (id, cedula, nombre, email, telefono, direccion, clave_hash, fecha_registro, activo, id_tipo_pago, id_tipo_usuario) VALUES
(1, '301110222', 'Cliente Prueba', 'cliente@hotel.com', '7777-7777', '300 mts Norte de Lumaca', '123456', '2026-04-05', 1, 1, 1),
(2, '1-1111-1111', 'Gabriel Marín', 'gabmar@hotel.com', '7000-1111', 'San Jose, Costa Rica', 'admin123', '2026-04-06', 1, 2, 2),
(3, '2-2222-2222', 'Carlos Mendez', 'carlos@gmail.com', '7111-2222', 'Cartago, Costa Rica', '123456', '2026-04-07', 1, 2, 1);

INSERT INTO mascota (id, nombre, foto, edad, sexo, peso, altura, microchip, fecha_nacimiento, notas, id_usuario, id_tipo_mascota, id_veterinario) VALUES
(1, 'Max', '', 3, 0, 32.5, 55.0, 'MC-0001', '2023-05-10', 'Le gusta jugar con pelotas.', 1, 1, 1),
(2, 'Mia', '', 2, 1, 4.8, 28.0, 'MC-0002', '2024-01-20', 'Muy tranquila y sociable.', 3, 2, 2),
(3, 'Copito', '', 1, 0, 1.4, 18.0, '', '2025-02-11', 'Necesita espacio tranquilo.', 3, 3, 2);

INSERT INTO mascota_x_necesidad (id, descripcion, id_mascota, id_necesidad) VALUES
(1, 'Vacunas al dia', 1, 1),
(2, 'Dieta de alimento seco premium', 1, 3),
(3, 'Alergia al pollo', 2, 2),
(4, 'Verduras y pellets diariamente', 3, 3);

INSERT INTO reserva (id, fecha_ingreso, fecha_salida, estancia, precio, id_mascota, id_habitacion, id_estado, id_tipo_hospedaje) VALUES
(1, '2026-04-10', '2026-04-15', 5, 250.0, 1, 1, 2, 1),
(2, '2026-04-18', '2026-04-20', 2, 180.0, 2, 2, 1, 2),
(3, '2026-03-28', '2026-03-30', 2, 90.0, 3, 3, 3, 1);

INSERT INTO actualizaciones (id, descripcion, fecha_hora, visible_para_cliente, id_reserva) VALUES
(1, 'Max comio normalmente y salio a paseo.', '2026-04-11 09:30:00', 1, 1),
(2, 'Se realizo limpieza de la habitacion.', '2026-04-11 14:15:00', 0, 1),
(3, 'Reserva pendiente de confirmacion por parte del hotel.', '2026-04-08 10:00:00', 1, 2);

INSERT INTO detalle_reserva (id, descripcion, precio, id_reserva, id_servicio) VALUES
(1, 'Paseo matutino', 10.0, 1, 3),
(2, 'Bano completo', 15.0, 2, 1),
(3, 'Sesion de grooming', 25.0, 2, 2);

INSERT INTO notificacion (id, descripcion, fecha, leida, id_usuario, id_reserva, id_tipo_notificacion) VALUES
(1, 'Tu reserva para Max fue confirmada correctamente.', '2026-04-10', 0, 1, 1, 1),
(2, 'Hay una nueva actualizacion disponible de tu mascota hospedada.', '2026-04-11', 0, 1, 1, 4),
(3, 'Tu reserva para Mia esta pendiente de aprobacion.', '2026-04-08', 1, 3, 2, 5),
(4, 'Gracias por usar PetLodge App.', '2026-04-09', 0, 3, NULL, 6);

COMMIT;
