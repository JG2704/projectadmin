import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'petlodge.db');

    print('📁 Ruta de la base de datos: $path');

    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        print('✅ Foreign keys activadas');
      },
      onCreate: (db, version) async {
        print('🛠️ Creando base de datos por primera vez...');
        await _onCreate(db, version);
        print('✅ Base de datos y tablas creadas correctamente');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // =========================
    // CATÁLOGOS DE USUARIO
    // =========================
    await db.execute('''
      CREATE TABLE tipo_pago (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE tipo_usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE usuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cedula TEXT NOT NULL,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        telefono TEXT,
        direccion TEXT,
        clave_hash TEXT NOT NULL,
        fecha_registro TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        activo INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0,1)),
        id_tipo_pago INTEGER,
        id_tipo_usuario INTEGER NOT NULL,
        FOREIGN KEY (id_tipo_pago) REFERENCES tipo_pago(id),
        FOREIGN KEY (id_tipo_usuario) REFERENCES tipo_usuario(id)
      )
    ''');

    // =========================
    // CATÁLOGOS DE MASCOTA
    // =========================
    await db.execute('''
      CREATE TABLE tipo_mascota (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        especie TEXT NOT NULL,
        raza TEXT NOT NULL,
        UNIQUE(especie, raza)
      )
    ''');

    await db.execute('''
      CREATE TABLE veterinario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        correo TEXT,
        direccion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE mascota (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        foto TEXT,
        edad INTEGER,
        sexo INTEGER CHECK (sexo IN (0,1) OR sexo IS NULL),
        peso REAL,
        altura REAL,
        microchip TEXT,
        fecha_nacimiento TEXT,
        notas TEXT,
        id_usuario INTEGER NOT NULL,
        id_tipo_mascota INTEGER NOT NULL,
        id_veterinario INTEGER,
        FOREIGN KEY (id_usuario) REFERENCES usuario(id) ON DELETE CASCADE,
        FOREIGN KEY (id_tipo_mascota) REFERENCES tipo_mascota(id),
        FOREIGN KEY (id_veterinario) REFERENCES veterinario(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE necesidad (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE mascota_x_necesidad (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT NOT NULL,
        id_mascota INTEGER NOT NULL,
        id_necesidad INTEGER NOT NULL,
        FOREIGN KEY (id_mascota) REFERENCES mascota(id) ON DELETE CASCADE,
        FOREIGN KEY (id_necesidad) REFERENCES necesidad(id)
      )
    ''');

    // =========================
    // HOTEL Y HABITACIONES
    // =========================
    await db.execute('''
      CREATE TABLE hotel (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        correo TEXT,
        direccion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habitacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT NOT NULL UNIQUE,
        estado TEXT NOT NULL CHECK (estado IN ('ocupado', 'disponible', 'en_limpieza'))
      )
    ''');

    // =========================
    // RESERVAS
    // =========================
    await db.execute('''
      CREATE TABLE estado_reserva (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        estado TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE tipo_hospedaje (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE reserva (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_ingreso TEXT NOT NULL,
        fecha_salida TEXT NOT NULL,
        estancia INTEGER NOT NULL,
        precio REAL NOT NULL,
        id_mascota INTEGER NOT NULL,
        id_habitacion INTEGER NOT NULL,
        id_estado INTEGER NOT NULL,
        id_tipo_hospedaje INTEGER NOT NULL,
        FOREIGN KEY (id_mascota) REFERENCES mascota(id),
        FOREIGN KEY (id_habitacion) REFERENCES habitacion(id),
        FOREIGN KEY (id_estado) REFERENCES estado_reserva(id),
        FOREIGN KEY (id_tipo_hospedaje) REFERENCES tipo_hospedaje(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE actualizaciones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT NOT NULL,
        fecha_hora TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        visible_para_cliente INTEGER NOT NULL DEFAULT 1 CHECK (visible_para_cliente IN (0,1)),
        id_reserva INTEGER NOT NULL,
        FOREIGN KEY (id_reserva) REFERENCES reserva(id) ON DELETE CASCADE
      )
    ''');

    // =========================
    // SERVICIOS
    // =========================
    await db.execute('''
      CREATE TABLE servicio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        tipo_hospedaje INTEGER NOT NULL,
        precio REAL NOT NULL,
        FOREIGN KEY (tipo_hospedaje) REFERENCES tipo_hospedaje(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE detalle_reserva (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT,
        precio REAL NOT NULL,
        id_reserva INTEGER NOT NULL,
        id_servicio INTEGER NOT NULL,
        FOREIGN KEY (id_reserva) REFERENCES reserva(id) ON DELETE CASCADE,
        FOREIGN KEY (id_servicio) REFERENCES servicio(id)
      )
    ''');

    // =========================
    // NOTIFICACIONES
    // =========================
    await db.execute('''
      CREATE TABLE tipo_notificacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE notificacion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        descripcion TEXT NOT NULL,
        fecha TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        leida INTEGER NOT NULL DEFAULT 0 CHECK (leida IN (0,1)),
        id_usuario INTEGER NOT NULL,
        id_reserva INTEGER,
        id_tipo_notificacion INTEGER NOT NULL,
        FOREIGN KEY (id_usuario) REFERENCES usuario(id) ON DELETE CASCADE,
        FOREIGN KEY (id_reserva) REFERENCES reserva(id) ON DELETE SET NULL,
        FOREIGN KEY (id_tipo_notificacion) REFERENCES tipo_notificacion(id)
      )
    ''');

    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Tipo pago
    await db.insert('tipo_pago', {'tipo': 'efectivo'});
    await db.insert('tipo_pago', {'tipo': 'tarjeta'});

    // Tipo usuario
    await db.insert('tipo_usuario', {'tipo': 'cliente'});
    await db.insert('tipo_usuario', {'tipo': 'admin'});

    // Usuario Prueba
    await db.insert('hotel', {
      'nombre': 'PetLodge',
      'telefono': '8888-8888',
      'correo': 'info@petlodge.com',
      'direccion': 'Cartago, Costa Rica',
    });

    // Necesidades
    await db.insert('necesidad', {'tipo': 'vacuna'});
    await db.insert('necesidad', {'tipo': 'alergia'});
    await db.insert('necesidad', {'tipo': 'dieta'});

    // Estados de reserva
    await db.insert('estado_reserva', {'estado': 'pendiente'});
    await db.insert('estado_reserva', {'estado': 'activa'});
    await db.insert('estado_reserva', {'estado': 'completada'});
    await db.insert('estado_reserva', {'estado': 'cancelada'});

    // Tipo hospedaje
    await db.insert('tipo_hospedaje', {'tipo': 'estandar'});
    await db.insert('tipo_hospedaje', {'tipo': 'especial'});

    // Tipo notificación
    await db.insert('tipo_notificacion', {'tipo': 'reserva_confirmada'});
    await db.insert('tipo_notificacion', {'tipo': 'reserva_modificada'});
    await db.insert('tipo_notificacion', {'tipo': 'reserva_finalizada'});
    await db.insert('tipo_notificacion', {'tipo': 'actualizacion'});
    await db.insert('tipo_notificacion', {'tipo': 'recordatorio'});
    await db.insert('tipo_notificacion', {'tipo': 'novedad_app'});

    // Insertar usuario de prueba
    await db.insert('usuario', {
      'cedula': '301110222',
      'nombre': 'Cliente Prueba',
      'email': 'cliente@hotel.com',
      'telefono': '7777-7777',
      'direccion': '300 mts Norte de Lumaca',
      'clave_hash': '123456',
      'fecha_registro': '2026-04-05',
      'id_tipo_pago': 1,
      'id_tipo_usuario': 1
    });

    // Habitaciones
    await db.insert('habitacion', {'numero': '101', 'estado': 'ocupado'});
    await db.insert('habitacion', {'numero': '102', 'estado': 'disponible'});
    await db.insert('habitacion', {'numero': '103', 'estado': 'disponible'});

    // Tipos de mascota de ejemplo
    await db.insert('tipo_mascota', {
      'especie': 'perro',
      'raza': 'golden retriever',
    });

    await db.insert('tipo_mascota', {
      'especie': 'gato',
      'raza': 'persa',
    });

    await db.insert('tipo_mascota', {
      'especie': 'conejo',
      'raza': 'mini lop',
    });

    // Servicios de ejemplo
    await db.insert('servicio', {
      'nombre': 'bano',
      'tipo_hospedaje': 2,
      'precio': 15.0,
    });

    await db.insert('servicio', {
      'nombre': 'grooming',
      'tipo_hospedaje': 2,
      'precio': 25.0,
    });

    await db.insert('servicio', {
      'nombre': 'paseo',
      'tipo_hospedaje': 1,
      'precio': 10.0,
    });
    // =========================
// USUARIOS EXTRA
// =========================

    await db.insert('usuario', {
      'cedula': '1-1111-1111',
      'nombre': 'Valeria Solano',
      'email': 'valeria@petlodge.com',
      'telefono': '7000-1111',
      'direccion': 'San Jose, Costa Rica',
      'clave_hash': 'admin123',
      'fecha_registro': '2026-04-06',
      'activo': 1,
      'id_tipo_pago': 2,
      'id_tipo_usuario': 2,
    });

    await db.insert('usuario', {
      'cedula': '2-2222-2222',
      'nombre': 'Carlos Mendez',
      'email': 'carlos@gmail.com',
      'telefono': '7111-2222',
      'direccion': 'Cartago, Costa Rica',
      'clave_hash': '123456',
      'fecha_registro': '2026-04-07',
      'activo': 1,
      'id_tipo_pago': 2,
      'id_tipo_usuario': 1,
    });

// =========================
// VETERINARIOS
// =========================

    await db.insert('veterinario', {
      'nombre': 'Dra. Laura Ramirez',
      'telefono': '6000-1111',
      'correo': 'laura.ramirez@vet.com',
      'direccion': 'Cartago, Costa Rica',
    });

    await db.insert('veterinario', {
      'nombre': 'Dr. Andres Vargas',
      'telefono': '6000-2222',
      'correo': 'andres.vargas@vet.com',
      'direccion': 'San Jose, Costa Rica',
    });

// =========================
// MASCOTAS
// id_usuario:
// 1 = cliente demo ya existente
// 3 = Carlos Mendez
// id_tipo_mascota:
// 1 = perro/golden retriever
// 2 = gato/persa
// 3 = conejo/mini lop
// =========================

    await db.insert('mascota', {
      'nombre': 'Max',
      'foto': '',
      'edad': 3,
      'sexo': 0,
      'peso': 32.5,
      'altura': 55.0,
      'microchip': 'MC-0001',
      'fecha_nacimiento': '2023-05-10',
      'notas': 'Le gusta jugar con pelotas.',
      'id_usuario': 1,
      'id_tipo_mascota': 1,
      'id_veterinario': 1,
    });

    await db.insert('mascota', {
      'nombre': 'Mia',
      'foto': '',
      'edad': 2,
      'sexo': 1,
      'peso': 4.8,
      'altura': 28.0,
      'microchip': 'MC-0002',
      'fecha_nacimiento': '2024-01-20',
      'notas': 'Muy tranquila y sociable.',
      'id_usuario': 3,
      'id_tipo_mascota': 2,
      'id_veterinario': 2,
    });

    await db.insert('mascota', {
      'nombre': 'Copito',
      'foto': '',
      'edad': 1,
      'sexo': 0,
      'peso': 1.4,
      'altura': 18.0,
      'microchip': '',
      'fecha_nacimiento': '2025-02-11',
      'notas': 'Necesita espacio tranquilo.',
      'id_usuario': 3,
      'id_tipo_mascota': 3,
      'id_veterinario': 2,
    });

// =========================
// NECESIDADES DE MASCOTAS
// id_necesidad:
// 1 = vacuna
// 2 = alergia
// 3 = dieta
// =========================

    await db.insert('mascota_x_necesidad', {
      'descripcion': 'Vacunas al dia',
      'id_mascota': 1,
      'id_necesidad': 1,
    });

    await db.insert('mascota_x_necesidad', {
      'descripcion': 'Dieta de alimento seco premium',
      'id_mascota': 1,
      'id_necesidad': 3,
    });

    await db.insert('mascota_x_necesidad', {
      'descripcion': 'Alergia al pollo',
      'id_mascota': 2,
      'id_necesidad': 2,
    });

    await db.insert('mascota_x_necesidad', {
      'descripcion': 'Verduras y pellets diariamente',
      'id_mascota': 3,
      'id_necesidad': 3,
    });

// =========================
// RESERVAS
// id_habitacion:
// 1 = 101
// 2 = 102
// 3 = 103
// id_estado:
// 1 = pendiente
// 2 = activa
// 3 = completada
// 4 = cancelada
// id_tipo_hospedaje:
// 1 = estandar
// 2 = especial
// =========================

    await db.insert('reserva', {
      'fecha_ingreso': '2026-04-10',
      'fecha_salida': '2026-04-15',
      'estancia': 5,
      'precio': 250.0,
      'id_mascota': 1,
      'id_habitacion': 1,
      'id_estado': 2,
      'id_tipo_hospedaje': 1,
    });

    await db.insert('reserva', {
      'fecha_ingreso': '2026-04-18',
      'fecha_salida': '2026-04-20',
      'estancia': 2,
      'precio': 180.0,
      'id_mascota': 2,
      'id_habitacion': 2,
      'id_estado': 1,
      'id_tipo_hospedaje': 2,
    });

    await db.insert('reserva', {
      'fecha_ingreso': '2026-03-28',
      'fecha_salida': '2026-03-30',
      'estancia': 2,
      'precio': 90.0,
      'id_mascota': 3,
      'id_habitacion': 3,
      'id_estado': 3,
      'id_tipo_hospedaje': 1,
    });

// =========================
// ACTUALIZACIONES DE RESERVA
// =========================

    await db.insert('actualizaciones', {
      'descripcion': 'Max comio normalmente y salio a paseo.',
      'fecha_hora': '2026-04-11 09:30:00',
      'visible_para_cliente': 1,
      'id_reserva': 1,
    });

    await db.insert('actualizaciones', {
      'descripcion': 'Se realizo limpieza de la habitacion.',
      'fecha_hora': '2026-04-11 14:15:00',
      'visible_para_cliente': 0,
      'id_reserva': 1,
    });

    await db.insert('actualizaciones', {
      'descripcion': 'Reserva pendiente de confirmacion por parte del hotel.',
      'fecha_hora': '2026-04-08 10:00:00',
      'visible_para_cliente': 1,
      'id_reserva': 2,
    });

// =========================
// DETALLE DE RESERVA
// id_servicio:
// 1 = bano
// 2 = grooming
// 3 = paseo
// =========================

    await db.insert('detalle_reserva', {
      'descripcion': 'Paseo matutino',
      'precio': 10.0,
      'id_reserva': 1,
      'id_servicio': 3,
    });

    await db.insert('detalle_reserva', {
      'descripcion': 'Bano completo',
      'precio': 15.0,
      'id_reserva': 2,
      'id_servicio': 1,
    });

    await db.insert('detalle_reserva', {
      'descripcion': 'Sesion de grooming',
      'precio': 25.0,
      'id_reserva': 2,
      'id_servicio': 2,
    });

// =========================
// NOTIFICACIONES
// id_tipo_notificacion:
// 1 = reserva_confirmada
// 2 = reserva_modificada
// 3 = reserva_finalizada
// 4 = actualizacion
// 5 = recordatorio
// 6 = novedad_app
// =========================

    await db.insert('notificacion', {
      'descripcion': 'Tu reserva para Max fue confirmada correctamente.',
      'fecha': '2026-04-10',
      'leida': 0,
      'id_usuario': 1,
      'id_reserva': 1,
      'id_tipo_notificacion': 1,
    });

    await db.insert('notificacion', {
      'descripcion': 'Hay una nueva actualizacion disponible de tu mascota hospedada.',
      'fecha': '2026-04-11',
      'leida': 0,
      'id_usuario': 1,
      'id_reserva': 1,
      'id_tipo_notificacion': 4,
    });

    await db.insert('notificacion', {
      'descripcion': 'Tu reserva para Mia esta pendiente de aprobacion.',
      'fecha': '2026-04-08',
      'leida': 1,
      'id_usuario': 3,
      'id_reserva': 2,
      'id_tipo_notificacion': 5,
    });

    await db.insert('notificacion', {
      'descripcion': 'Gracias por usar PetLodge App.',
      'fecha': '2026-04-09',
      'leida': 0,
      'id_usuario': 3,
      'id_reserva': null,
      'id_tipo_notificacion': 6,
    });
    print('✅ Datos semilla insertados correctamente');
  }

  // =========================
  // USUARIO
  // =========================

  Future<int> insertUsuario(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('usuario', data);
  }

  Future<Map<String, dynamic>?> getUsuarioByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      'usuario',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<int> updateUsuario(int usuarioId, Map<String, dynamic> data) async {
    final db = await database;
    return db.update(
      'usuario',
      data,
      where: 'id = ?',
      whereArgs: [usuarioId],
    );
  }

  // =========================
  // MASCOTA
  // =========================

  Future<int> insertMascota(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('mascota', data);
  }

  Future<List<Map<String, dynamic>>> getMascotasByUsuario(int usuarioId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        m.*,
        tm.especie,
        tm.raza,
        v.nombre AS veterinario_nombre
      FROM mascota m
      INNER JOIN tipo_mascota tm ON tm.id = m.id_tipo_mascota
      LEFT JOIN veterinario v ON v.id = m.id_veterinario
      WHERE m.id_usuario = ?
      ORDER BY m.id DESC
    ''', [usuarioId]);
  }

  Future<int> updateMascota(int mascotaId, Map<String, dynamic> data) async {
    final db = await database;
    return db.update(
      'mascota',
      data,
      where: 'id = ?',
      whereArgs: [mascotaId],
    );
  }

  Future<int> deleteMascota(int mascotaId) async {
    final db = await database;
    return db.delete(
      'mascota',
      where: 'id = ?',
      whereArgs: [mascotaId],
    );
  }

  // =========================
  // MASCOTA X NECESIDAD
  // =========================

  Future<int> insertMascotaNecesidad(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('mascota_x_necesidad', data);
  }

  Future<List<Map<String, dynamic>>> getNecesidadesByMascota(int mascotaId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        mxn.*,
        n.tipo
      FROM mascota_x_necesidad mxn
      INNER JOIN necesidad n ON n.id = mxn.id_necesidad
      WHERE mxn.id_mascota = ?
      ORDER BY mxn.id DESC
    ''', [mascotaId]);
  }

  // =========================
  // RESERVA
  // =========================

  Future<int> insertReserva(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('reserva', data);
  }

  Future<List<Map<String, dynamic>>> getReservasByUsuario(int usuarioId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        r.*,
        m.nombre AS mascota_nombre,
        h.numero AS habitacion_numero,
        er.estado,
        th.tipo AS tipo_hospedaje_nombre
      FROM reserva r
      INNER JOIN mascota m ON m.id = r.id_mascota
      INNER JOIN habitacion h ON h.id = r.id_habitacion
      INNER JOIN estado_reserva er ON er.id = r.id_estado
      INNER JOIN tipo_hospedaje th ON th.id = r.id_tipo_hospedaje
      WHERE m.id_usuario = ?
      ORDER BY r.id DESC
    ''', [usuarioId]);
  }

  Future<int> updateReserva(int reservaId, Map<String, dynamic> data) async {
    final db = await database;
    return db.update(
      'reserva',
      data,
      where: 'id = ?',
      whereArgs: [reservaId],
    );
  }

  // =========================
  // ACTUALIZACIONES
  // =========================

  Future<int> insertActualizacion(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('actualizaciones', data);
  }

  Future<List<Map<String, dynamic>>> getActualizacionesByReserva(int reservaId) async {
    final db = await database;
    return db.query(
      'actualizaciones',
      where: 'id_reserva = ?',
      whereArgs: [reservaId],
      orderBy: 'fecha_hora DESC',
    );
  }

  // =========================
  // SERVICIOS / DETALLE RESERVA
  // =========================

  Future<int> insertServicio(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('servicio', data);
  }

  Future<List<Map<String, dynamic>>> getServiciosByTipoHospedaje(int tipoHospedajeId) async {
    final db = await database;
    return db.query(
      'servicio',
      where: 'tipo_hospedaje = ?',
      whereArgs: [tipoHospedajeId],
      orderBy: 'nombre ASC',
    );
  }

  Future<int> insertDetalleReserva(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('detalle_reserva', data);
  }

  Future<List<Map<String, dynamic>>> getDetalleReserva(int reservaId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        dr.*,
        s.nombre AS servicio_nombre
      FROM detalle_reserva dr
      INNER JOIN servicio s ON s.id = dr.id_servicio
      WHERE dr.id_reserva = ?
      ORDER BY dr.id DESC
    ''', [reservaId]);
  }

  // =========================
  // NOTIFICACIONES
  // =========================

  Future<int> insertNotificacion(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('notificacion', data);
  }

  Future<List<Map<String, dynamic>>> getNotificacionesByUsuario(int usuarioId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        n.*,
        tn.tipo
      FROM notificacion n
      INNER JOIN tipo_notificacion tn ON tn.id = n.id_tipo_notificacion
      WHERE n.id_usuario = ?
      ORDER BY n.id DESC
    ''', [usuarioId]);
  }

  Future<int> marcarNotificacionLeida(int notificacionId) async {
    final db = await database;
    return db.update(
      'notificacion',
      {'leida': 1},
      where: 'id = ?',
      whereArgs: [notificacionId],
    );
  }

  // =========================
  // AUXILIARES
  // =========================

  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'petlodge.db');
    await deleteDatabase(path);
    _database = null;
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}