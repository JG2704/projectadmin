from datetime import datetime
from pathlib import Path
import sqlite3
from typing import Any, Dict, List, Optional

import bcrypt
from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="API Hotel de Mascotas - SQLite")

# ── CORS ──────────────────────────────────────────────────────────────────────
# Allows the Flutter Android emulator (10.0.2.2) and any localhost dev client
# to reach this API without being blocked by same-origin policy.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

BASE_DIR = Path(__file__).resolve().parent
DB_DIR = BASE_DIR / "database"
DB_PATH = DB_DIR / "petlodge_backend.db"
SCHEMA_PATH = DB_DIR / "schema.sql"
SEED_PATH = DB_DIR / "seed.sql"
DEFAULT_USER_ID = 1


# ── Pydantic models ───────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email: str
    password: str


class UsuarioRegister(BaseModel):
    cedula: str
    nombre: str
    email: str
    telefono: str
    direccion: str
    password: str


class MascotaCreate(BaseModel):
    nombre: str
    especie: str
    raza: str
    edad: int
    sexo: Optional[int] = None
    peso: Optional[float] = None
    vacunas: Optional[str] = "No especificado"
    alergias: Optional[str] = "Ninguna"
    condicion: Optional[str] = "Desconocida"
    contrato: Optional[str] = "No definido"
    cuidados_especiales: Optional[str] = "Ninguno"
    notas: Optional[str] = ""
    id_veterinario: Optional[int] = None


class MascotaResponse(BaseModel):
    id: int
    nombre: str
    edad: int
    tipo: Optional[str] = "Desconocido"
    raza: Optional[str] = "Desconocida"
    sexo: Optional[str] = "No especificado"
    tamaño: Optional[str] = "No especificado"
    vacunacion: Optional[str] = "No especificado"
    condicion: Optional[str] = "Desconocida"
    contrato: Optional[str] = "No definido"
    cuidados_especiales: Optional[str] = "Ninguno"
    id_veterinario: Optional[int] = None



class ReservaCreateRequest(BaseModel):
    name: str        # pet name
    room: str        # e.g. "Habitación 101"
    type: str        # "Estándar" | "Especial"
    fecha_ingreso: str
    fecha_salida: str


class UsuarioUpdate(BaseModel):
    nombre: str
    email: str
    telefono: str


class TarjetaCreate(BaseModel):
    numero: str


# ── DB helpers ────────────────────────────────────────────────────────────────

def get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def resolve_current_user_id(
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")
) -> int:
    user_id = x_user_id if x_user_id is not None else DEFAULT_USER_ID
    with get_conn() as conn:
        exists = conn.execute(
            "SELECT 1 FROM usuario WHERE id=? AND activo=1", (user_id,)
        ).fetchone()
    if not exists:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user_id


def table_exists(conn: sqlite3.Connection, table_name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
    ).fetchone()
    return row is not None


def normalize_sex_to_db(sex: Optional[Any]) -> Optional[int]:
    if sex is None or sex == "":
        return None

    if isinstance(sex, int):
        return sex if sex in (0, 1) else None

    lowered = str(sex).strip().lower()
    if lowered in {"macho", "male", "m", "0"}:
        return 0
    if lowered in {"hembra", "female", "f", "1"}:
        return 1
    return None


def sex_to_label(value: Optional[int]) -> str:
    if value == 0:
        return "Macho"
    if value == 1:
        return "Hembra"
    return "No especificado"


def normalize_size_to_db(tamano: Optional[str]) -> Optional[float]:
    if not tamano:
        return None
    stripped = tamano.strip().lower().replace("cm", "").replace("m", "")
    try:
        return float(stripped)
    except ValueError:
        return None


def size_to_label(value: Optional[float]) -> str:
    if value is None:
        return "No especificado"
    return f"{value} cm"


def ensure_tipo_mascota(conn: sqlite3.Connection, especie: str, raza: str) -> int:
    especie_db = especie.strip().lower() or "desconocido"
    raza_db = raza.strip().lower() or "sin raza"
    row = conn.execute(
        "SELECT id FROM tipo_mascota WHERE especie=? AND raza=?",
        (especie_db, raza_db),
    ).fetchone()
    if row:
        return row["id"]
    cur = conn.execute(
        "INSERT INTO tipo_mascota (especie, raza) VALUES (?, ?)",
        (especie_db, raza_db),
    )
    return cur.lastrowid


def upsert_need(
    conn: sqlite3.Connection, mascota_id: int, need_type: str, description: str
) -> None:
    description = (description or "").strip()
    if not description:
        return
    need_row = conn.execute(
        "SELECT id FROM necesidad WHERE tipo=?", (need_type,)
    ).fetchone()
    if not need_row:
        return
    conn.execute(
        "INSERT INTO mascota_x_necesidad (descripcion, id_mascota, id_necesidad) VALUES (?, ?, ?)",
        (description, mascota_id, need_row["id"]),
    )


def serialize_pet_row(conn: sqlite3.Connection, row: sqlite3.Row) -> Dict[str, Any]:
    needs_rows = conn.execute(
        """
        SELECT n.tipo, mxn.descripcion
        FROM mascota_x_necesidad mxn
        INNER JOIN necesidad n ON n.id = mxn.id_necesidad
        WHERE mxn.id_mascota = ?
        """,
        (row["id"],),
    ).fetchall()

    vacunas = row["vacunacion"] if "vacunacion" in row.keys() else "No especificado"
    if not vacunas:
        vacunas = "No especificado"

    for item in needs_rows:
        if item["tipo"] == "vacuna":
            vacunas = item["descripcion"]

    return {
        "id": row["id"],
        "nombre": row["nombre"],
        "edad": row["edad"] if row["edad"] is not None else 0,
        "sexo": sex_to_label(row["sexo"]),
        "tamaño": size_to_label(row["tamaño"]),
        "vacunacion": vacunas,
        "condicion": row["condicion"] if "condicion" in row.keys() and row["condicion"] else "Desconocida",
        "contrato": row["contrato"] if "contrato" in row.keys() and row["contrato"] else "No definido",
        "cuidados_especiales": row["cuidados_especiales"] if "cuidados_especiales" in row.keys() and row["cuidados_especiales"] else "Ninguno",
        "id_tipo_mascota": row["id_tipo_mascota"] if "id_tipo_mascota" in row.keys() else None,
        "id_veterinario": row["id_veterinario"] if "id_veterinario" in row.keys() else None,
    }


def map_reservation_row(row: sqlite3.Row) -> Dict[str, Any]:
    estado_db = (row["estado_reserva"] or "pendiente").lower()
    status = {
        "activa": "Activa",
        "completada": "Completada",
        "cancelada": "Cancelada",
        "pendiente": "Activa",
    }.get(estado_db, "Activa")

    check_in = row["fecha_ingreso"]
    check_out = row["fecha_salida"]
    in_dt = datetime.fromisoformat(check_in)
    out_dt = datetime.fromisoformat(check_out)

    room = f"Habitación {row['numero']}"
    tipo_raw = (row["tipo_hospedaje"] or "estandar").lower()
    hospedaje = "Estándar" if tipo_raw.startswith("est") else "especial"

    return {
        "id": row["id"],
        "name": row["mascota_nombre"],
        "room": room,
        "type": hospedaje,
        "date": f"{in_dt.strftime('%d %b')} - {out_dt.strftime('%d %b %Y')}",
        "fecha_ingreso": check_in,
        "fecha_salida": check_out,
        "status": status,
        "total": f"${row['precio']:.2f}",
    }


# ── Password helpers ──────────────────────────────────────────────────────────

def hash_password(password: str) -> str:
    """Return a bcrypt hash of the given plaintext password."""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    """Return True if plain matches the stored bcrypt hash."""
    try:
        return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
    except Exception:
        return False


# ── DB initialisation ─────────────────────────────────────────────────────────

def initialize_database() -> None:
    DB_DIR.mkdir(parents=True, exist_ok=True)
    with get_conn() as conn:
        has_usuario = table_exists(conn, "usuario")
        if not has_usuario:
            conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
            conn.executescript(SEED_PATH.read_text(encoding="utf-8"))
            return

        users_count = conn.execute(
            "SELECT COUNT(*) AS total FROM usuario"
        ).fetchone()["total"]
        if users_count == 0:
            conn.executescript(SEED_PATH.read_text(encoding="utf-8"))


@app.on_event("startup")
def on_startup() -> None:
    initialize_database()


# ── Auth endpoints ────────────────────────────────────────────────────────────

@app.post("/auth/login")
def login(datos: LoginRequest):
    with get_conn() as conn:
        user = conn.execute(
            "SELECT id, clave_hash, id_tipo_usuario FROM usuario WHERE email=? AND activo=1",
            (datos.email,),
        ).fetchone()

    if not user or not verify_password(datos.password, user["clave_hash"]):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")

    return {
        "success": True,
        "token": f"token_user_{user['id']}",
        "id_tipo_usuario": user["id_tipo_usuario"],
    }


@app.post("/auth/register")
def register(datos: UsuarioRegister):
    with get_conn() as conn:
        try:
            fecha_actual = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            # Hasheo simulado (o real si están usando bcrypt)
            hash_pw = hash_password(datos.password) 
            
            # Asignamos ID de tipo pago (1 = Efectivo) y tipo usuario (1 = Cliente) por defecto
            conn.execute(
                """
                INSERT INTO usuario (cedula, nombre, email, telefono, direccion, clave_hash, fecha_registro, id_tipo_pago, id_tipo_usuario)
                VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1)
                """,
                (datos.cedula, datos.nombre, datos.email, datos.telefono, datos.direccion, hash_pw, fecha_actual)
            )
            conn.commit()
            return {"success": True, "message": "Usuario creado"}
        except sqlite3.IntegrityError:
            # Esto atrapa si alguien intenta registrar una cédula o correo que ya existe
            raise HTTPException(status_code=400, detail="La cédula o el correo ya están registrados en el sistema.")


# ── User endpoints ────────────────────────────────────────────────────────────

@app.get("/users/me")
def get_perfil(
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")
):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        user = conn.execute(
            """
            SELECT u.id, u.cedula, u.nombre, u.email, u.telefono,
                   u.direccion, u.id_tipo_pago, u.id_tipo_usuario
            FROM usuario u
            WHERE u.id=?
            """,
            (user_id,),
        ).fetchone()
        if not user:
            raise HTTPException(status_code=404, detail="Usuario no encontrado")

        mascotas = conn.execute(
            "SELECT COUNT(*) AS total FROM mascota WHERE id_usuario=?", (user_id,)
        ).fetchone()["total"]

        reservas = conn.execute(
            """
            SELECT COUNT(*) AS total
            FROM reserva r
            JOIN mascota m ON m.id = r.id_mascota
            WHERE m.id_usuario=?
            """,
            (user_id,),
        ).fetchone()["total"]

        dias_row = conn.execute(
            """
            SELECT COALESCE(SUM(r.estancia), 0) AS total
            FROM reserva r
            JOIN mascota m ON m.id = r.id_mascota
            JOIN estado_reserva er ON er.id = r.id_estado
            WHERE m.id_usuario=? AND er.estado='activa'
            """,
            (user_id,),
        ).fetchone()

    perfil = dict(user)
    perfil["stats"] = {
        "reservas": reservas,
        "mascotas": mascotas,
        "dias": dias_row["total"],
    }
    return perfil


class ProfileUpdate(BaseModel):
    nombre: str
    cedula: str
    email: str
    telefono: str
    direccion: str

@app.put("/users/me")
def update_profile(datos: ProfileUpdate, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        conn.execute(
            """
            UPDATE usuario 
            SET nombre=?, cedula=?, email=?, telefono=?, direccion=? 
            WHERE id=?
            """,
            (datos.nombre, datos.cedula, datos.email, datos.telefono, datos.direccion, user_id)
        )
        conn.commit()
    return {"success": True, "message": "Perfil actualizado"}


# ── Pet endpoints ─────────────────────────────────────────────────────────────

@app.get("/pets", response_model=List[MascotaResponse])
def get_mascotas(
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")
):
    user_id = resolve_current_user_id(x_user_id)

    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT 
                id,
                nombre,
                edad,
                sexo,
                tamaño,
                vacunacion,
                condicion,
                contrato,
                cuidados_especiales,
                id_tipo_mascota,
                id_veterinario
            FROM mascota
            WHERE id_usuario=?
            ORDER BY id DESC
            """,
            (user_id,),
        ).fetchall()

        return [serialize_pet_row(conn, row) for row in rows]

# 2. El endpoint que procesa todo
@app.post("/pets")
def create_mascota(m: MascotaCreate, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        # Buscamos o creamos el tipo de mascota (especie/raza)
        tipo_row = conn.execute(
            "SELECT id FROM tipo_mascota WHERE especie=? AND raza=?", 
            (m.especie.lower(), m.raza.lower())
        ).fetchone()

        if not tipo_row:
            cur = conn.execute(
                "INSERT INTO tipo_mascota (especie, raza) VALUES (?, ?)",
                (m.especie.lower(), m.raza.lower())
            )
            tipo_id = cur.lastrowid
        else:
            tipo_id = tipo_row["id"]

        # Insertamos en la tabla 'mascota' con los nombres de columna reales del schema.sql
        # Combinamos vacunas y alergias en la columna 'notas' ya que tu tabla no tiene esas columnas
        notas_completas = f"Vacunas: {m.vacunas} | Alergias: {m.alergias} | Notas: {m.notas}"
        
        conn.execute(
            """
            INSERT INTO mascota (nombre, edad, sexo, tamaño, vacunacion, condicion, contrato, cuidados_especiales, id_usuario, id_tipo_mascota, id_veterinario, foto)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                m.nombre,
                m.edad,
                m.sexo,
                m.peso,
                m.vacunas,
                m.condicion,
                m.contrato,
                m.cuidados_especiales,
                user_id,
                tipo_id,
                "1",
                ""
            )
        )
        conn.commit()
    return {"success": True}


@app.put("/pets/{pet_id}", response_model=MascotaResponse)
def update_mascota(
    pet_id: int,
    m: MascotaBase,
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")
):
    user_id = resolve_current_user_id(x_user_id)

    with get_conn() as conn:
        existing = conn.execute(
            "SELECT id FROM mascota WHERE id=? AND id_usuario=?",
            (pet_id, user_id),
        ).fetchone()

        if not existing:
            raise HTTPException(status_code=404, detail="Mascota no encontrada")

        conn.execute(
            """
            UPDATE mascota
            SET nombre=?, edad=?, sexo=?, tamaño=?, vacunacion=?, condicion=?, contrato=?, cuidados_especiales=?,
                id_tipo_mascota=?, id_veterinario=?
            WHERE id=?
            """,
            (
                m.nombre,
                m.edad,
                normalize_sex_to_db(m.sexo),
                m.tamaño,
                m.vacunacion,
                m.condicion,
                m.contrato,
                m.cuidados_especiales,
                m.id_tipo_mascota,
                m.id_veterinario,
                pet_id,
            ),
        )

        conn.commit()

        row = conn.execute(
            """
            SELECT 
                id, nombre, edad, sexo, tamaño, vacunacion, condicion, contrato,
                cuidados_especiales, id_tipo_mascota, id_veterinario
            FROM mascota
            WHERE id=?
            """,
            (pet_id,),
        ).fetchone()

        return serialize_pet_row(conn, row)


@app.delete("/pets/{pet_id}")
def delete_mascota(
    pet_id: int,
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")
):
    user_id = resolve_current_user_id(x_user_id)

    with get_conn() as conn:
        # 1. Verificar que la mascota exista y pertenezca al usuario
        mascota = conn.execute(
            "SELECT id FROM mascota WHERE id=? AND id_usuario=?",
            (pet_id, user_id),
        ).fetchone()

        if not mascota:
            raise HTTPException(status_code=404, detail="Mascota no encontrada")

        # 2. Validar que NO tenga reservas activas (por fecha actual)
        reserva_activa = conn.execute(
            """
            SELECT id FROM reserva
            WHERE id_mascota = ?
            AND DATE(fecha_ingreso) <= DATE('now')
            AND DATE(fecha_salida) >= DATE('now')
            LIMIT 1
            """,
            (pet_id,),
        ).fetchone()

        if reserva_activa:
            raise HTTPException(
                status_code=400,
                detail="No se puede eliminar la mascota porque tiene una reserva activa"
            )

        # 3. Eliminar mascota
        conn.execute(
            "DELETE FROM mascota WHERE id=?",
            (pet_id,),
        )

        conn.commit()

        return {"message": "Mascota eliminada correctamente"}


# ── Rooms endpoint (so Flutter shows real available rooms) ────────────────────

@app.get("/rooms")
def get_rooms():
    """Return all rooms with their current status."""
    with get_conn() as conn:
        rows = conn.execute(
            "SELECT id, numero, estado FROM habitacion ORDER BY numero"
        ).fetchall()
    return [dict(row) for row in rows]


# ── Reservation endpoints ─────────────────────────────────────────────────────

@app.post("/reservations")
def create_reserva(
    r: ReservaCreateRequest,
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id"),
):
    user_id = resolve_current_user_id(x_user_id)
    ingreso = datetime.fromisoformat(r.fecha_ingreso.replace("Z", "+00:00")).date()
    salida = datetime.fromisoformat(r.fecha_salida.replace("Z", "+00:00")).date()
    dias = max((salida - ingreso).days, 1)

    room_number = r.room.replace("Habitación", "").strip()

    tipo_hospedaje_db = "estandar" if r.type.lower().startswith("est") else "especial"
    precio_base = 50.0 if tipo_hospedaje_db == "estandar" else 85.0
    total = float(dias * precio_base)

    with get_conn() as conn:
        mascota = conn.execute(
            "SELECT id FROM mascota WHERE nombre=? AND id_usuario=? ORDER BY id DESC LIMIT 1",
            (r.name, user_id),
        ).fetchone()
        if not mascota:
            raise HTTPException(status_code=404, detail="Mascota no encontrada")

        habitacion = conn.execute(
            "SELECT id, estado FROM habitacion WHERE numero=?",
            (room_number,),
        ).fetchone()
        if not habitacion:
            raise HTTPException(status_code=404, detail="Habitación no encontrada")
        if (habitacion["estado"] or "").lower() != "disponible":
            raise HTTPException(status_code=409, detail="Habitación no disponible")

        estado = conn.execute(
            "SELECT id FROM estado_reserva WHERE estado='activa'"
        ).fetchone()
        tipo_hosp = conn.execute(
            "SELECT id FROM tipo_hospedaje WHERE tipo=?",
            (tipo_hospedaje_db,),
        ).fetchone()
        if not tipo_hosp:
            raise HTTPException(status_code=500, detail=f"tipo_hospedaje '{tipo_hospedaje_db}' no encontrado en BD")
        
        conflict = conn.execute(
            """
            SELECT 1
            FROM reserva r
            JOIN estado_reserva er ON er.id = r.id_estado
            WHERE r.id_habitacion = ?
            AND er.estado = 'activa'
            AND NOT (
                r.fecha_salida <= ? OR
                r.fecha_ingreso >= ?
            )
            LIMIT 1
            """,
            (habitacion["id"], ingreso.isoformat(), salida.isoformat())
        ).fetchone()

        if conflict:
            raise HTTPException(
                status_code=409,
                detail="La habitación ya está reservada en esas fechas"
            )

        cur = conn.execute(
            """
            INSERT INTO reserva
                (fecha_ingreso, fecha_salida, estancia, precio,
                 id_mascota, id_habitacion, id_estado, id_tipo_hospedaje)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                ingreso.isoformat(),
                salida.isoformat(),
                dias,
                total,
                mascota["id"],
                habitacion["id"],
                estado["id"],
                tipo_hosp["id"],
            ),
        )
        # conn.execute(
        #     "UPDATE habitacion SET estado='ocupado' WHERE id=?",
        #     (habitacion["id"],),
        # )
        reserva_id = cur.lastrowid
        conn.commit()

        row = conn.execute(
            """
            SELECT r.id, r.fecha_ingreso, r.fecha_salida, r.precio,
                   er.estado AS estado_reserva,
                   h.numero,
                   th.tipo AS tipo_hospedaje,
                   m.nombre AS mascota_nombre
            FROM reserva r
            JOIN estado_reserva er ON er.id = r.id_estado
            JOIN habitacion h ON h.id = r.id_habitacion
            JOIN tipo_hospedaje th ON th.id = r.id_tipo_hospedaje
            JOIN mascota m ON m.id = r.id_mascota
            WHERE r.id=?
            """,
            (reserva_id,),
        ).fetchone()
        return map_reservation_row(row)


@app.get("/reservations/history")
def get_history(
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")
):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT r.id, r.fecha_ingreso, r.fecha_salida, r.precio,
                   er.estado AS estado_reserva,
                   h.numero,
                   th.tipo AS tipo_hospedaje,
                   m.nombre AS mascota_nombre
            FROM reserva r
            JOIN mascota m ON m.id = r.id_mascota
            JOIN estado_reserva er ON er.id = r.id_estado
            JOIN habitacion h ON h.id = r.id_habitacion
            JOIN tipo_hospedaje th ON th.id = r.id_tipo_hospedaje
            WHERE m.id_usuario=?
            ORDER BY r.id DESC
            """,
            (user_id,),
        ).fetchall()
        return [map_reservation_row(row) for row in rows]


@app.patch("/reservations/{res_id}/cancel")
def cancel_res(
    res_id: int,
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id"),
):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        active = conn.execute(
            """
            SELECT r.id, r.id_habitacion, er.estado AS estado_actual
            FROM reserva r
            JOIN mascota m ON m.id = r.id_mascota
            JOIN estado_reserva er ON er.id = r.id_estado
            WHERE r.id=? AND m.id_usuario=?
            """,
            (res_id, user_id),
        ).fetchone()
        if not active:
            raise HTTPException(status_code=404, detail="Reserva no encontrada")

        cancelled_state = conn.execute(
            "SELECT id FROM estado_reserva WHERE estado='cancelada'"
        ).fetchone()
        conn.execute(
            "UPDATE reserva SET id_estado=? WHERE id=?",
            (cancelled_state["id"], res_id),
        )
        if (active["estado_actual"] or "").lower() == "activa":
            other_active = conn.execute(
                """
                SELECT 1
                FROM reserva r
                JOIN estado_reserva er ON er.id = r.id_estado
                WHERE r.id_habitacion=? AND r.id<>? AND er.estado='activa'
                LIMIT 1
                """,
                (active["id_habitacion"], res_id),
            ).fetchone()
            if not other_active:
                conn.execute(
                    "UPDATE habitacion SET estado='disponible' WHERE id=?",
                    (active["id_habitacion"],),
                )
        conn.commit()

    return {"success": True}


# ── Notifications ─────────────────────────────────────────────────────────────

@app.get("/notifications")
def get_notif(
    x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")
):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT n.id, n.descripcion, n.fecha, tn.tipo
            FROM notificacion n
            JOIN tipo_notificacion tn ON tn.id = n.id_tipo_notificacion
            WHERE n.id_usuario=?
            ORDER BY n.id DESC
            """,
            (user_id,),
        ).fetchall()

    mapped = []
    for row in rows:
        tipo = row["tipo"]
        ui_type = "recordatorio"
        if "reserva" in tipo:
            ui_type = "reserva"
        elif tipo in {"actualizacion", "novedad_app"}:
            ui_type = "update"

        mapped.append(
            {
                "id": row["id"],
                "type": ui_type,
                "title": tipo.replace("_", " ").title(),
                "message": row["descripcion"],
                "time": row["fecha"],
            }
        )
    return mapped


# --- ENDPOINTS DE PAGOS ---

@app.get("/payments/methods")
def get_tarjetas(x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        # Buscamos el tipo de pago actual del usuario
        row = conn.execute(
            """
            SELECT u.id_tipo_pago, tp.tipo 
            FROM usuario u
            JOIN tipo_pago tp ON tp.id = u.id_tipo_pago
            WHERE u.id=?
            """,
            (user_id,),
        ).fetchone()

    if not row or row["id_tipo_pago"] is None:
        return []

    # Devolvemos un formato que Flutter entienda
    es_tarjeta = row["tipo"].lower() == "tarjeta"
    return [{
        "id": row["id_tipo_pago"], 
        "numero": "**** 8888" if es_tarjeta else "Efectivo", 
        "marca": "Visa" if es_tarjeta else "Cash"
    }]

@app.post("/payments/methods")
def add_tarjeta(t: TarjetaCreate, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        # 1. Buscamos el ID del tipo 'tarjeta'
        tarjeta_row = conn.execute("SELECT id FROM tipo_pago WHERE tipo='tarjeta'").fetchone()
        
        # 2. ACTUALIZAMOS (sobreescribimos) el método único del usuario
        conn.execute(
            "UPDATE usuario SET id_tipo_pago=? WHERE id=?",
            (tarjeta_row["id"], user_id),
        )
        conn.commit()
        return {"id": tarjeta_row["id"], "numero": t.numero, "marca": "Tarjeta"}

@app.delete("/payments/methods/{tarjeta_id}")
def delete_tarjeta(tarjeta_id: int, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        # 3. Al 'borrar', lo regresamos a Efectivo (ID 1) para no romper el NOT NULL
        conn.execute("UPDATE usuario SET id_tipo_pago=1 WHERE id=?", (user_id,))
        conn.commit()
    return {"success": True}