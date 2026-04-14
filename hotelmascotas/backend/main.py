from datetime import datetime
from pathlib import Path
import sqlite3
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel

app = FastAPI(title="API Hotel de Mascotas - SQLite")

BASE_DIR = Path(__file__).resolve().parent
DB_DIR = BASE_DIR / "database"
DB_PATH = DB_DIR / "petlodge_backend.db"
SCHEMA_PATH = DB_DIR / "schema.sql"
SEED_PATH = DB_DIR / "seed.sql"
DEFAULT_USER_ID = 1


class LoginRequest(BaseModel):
    email: str
    password: str


class UsuarioRegister(BaseModel):
    nombre: str
    email: str
    telefono: str
    password: str


class MascotaBase(BaseModel):
    nombre: str
    especie: str
    raza: str
    edad: int
    sexo: Optional[str] = "No especificado"
    peso: Optional[str] = "No especificado"
    fecha_nacimiento: Optional[str] = "No especificado"
    vacunas: Optional[str] = "No especificado"
    alergias: Optional[str] = "Ninguna"
    dieta: Optional[str] = "Normal"
    notas: Optional[str] = ""


class MascotaResponse(MascotaBase):
    id: int


class ReservaCreateRequest(BaseModel):
    name: str
    room: str
    type: str
    fecha_ingreso: str
    fecha_salida: str


class UsuarioUpdate(BaseModel):
    nombre: str
    email: str
    telefono: str


class TarjetaCreate(BaseModel):
    numero: str


def get_conn() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def resolve_current_user_id(x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")) -> int:
    user_id = x_user_id if x_user_id is not None else DEFAULT_USER_ID
    with get_conn() as conn:
        exists = conn.execute("SELECT 1 FROM usuario WHERE id=? AND activo=1", (user_id,)).fetchone()
    if not exists:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    return user_id


def table_exists(conn: sqlite3.Connection, table_name: str) -> bool:
    row = conn.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?",
        (table_name,),
    ).fetchone()
    return row is not None


def normalize_sex_to_db(sex: Optional[str]) -> Optional[int]:
    if not sex:
        return None
    lowered = sex.strip().lower()
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


def normalize_weight_to_db(peso: Optional[str]) -> Optional[float]:
    if not peso:
        return None
    stripped = peso.strip().lower().replace("kg", "")
    try:
        return float(stripped)
    except ValueError:
        return None


def weight_to_label(value: Optional[float]) -> str:
    if value is None:
        return "No especificado"
    return f"{value}kg"


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


def upsert_need(conn: sqlite3.Connection, mascota_id: int, need_type: str, description: str) -> None:
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

    needs = {"vacunas": "No especificado", "alergias": "Ninguna", "dieta": "Normal"}
    for item in needs_rows:
        if item["tipo"] == "vacuna":
            needs["vacunas"] = item["descripcion"]
        elif item["tipo"] == "alergia":
            needs["alergias"] = item["descripcion"]
        elif item["tipo"] == "dieta":
            needs["dieta"] = item["descripcion"]

    return {
        "id": row["id"],
        "nombre": row["nombre"],
        "especie": (row["especie"] or "Desconocido").title(),
        "raza": (row["raza"] or "Desconocida").title(),
        "edad": row["edad"] if row["edad"] is not None else 0,
        "sexo": sex_to_label(row["sexo"]),
        "peso": weight_to_label(row["peso"]),
        "fecha_nacimiento": row["fecha_nacimiento"] or "No especificado",
        "vacunas": needs["vacunas"],
        "alergias": needs["alergias"],
        "dieta": needs["dieta"],
        "notas": row["notas"] or "",
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
    hospedaje = "Estándar" if (row["tipo_hospedaje"] or "estandar") == "estandar" else "Premium"
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


def initialize_database() -> None:
    DB_DIR.mkdir(parents=True, exist_ok=True)
    with get_conn() as conn:
        has_usuario = table_exists(conn, "usuario")
        if not has_usuario:
            conn.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))
            conn.executescript(SEED_PATH.read_text(encoding="utf-8"))
            return

        users_count = conn.execute("SELECT COUNT(*) AS total FROM usuario").fetchone()["total"]
        if users_count == 0:
            conn.executescript(SEED_PATH.read_text(encoding="utf-8"))


@app.on_event("startup")
def on_startup() -> None:
    initialize_database()


@app.post("/auth/login")
def login(datos: LoginRequest):
    with get_conn() as conn:
        user = conn.execute(
            "SELECT id, id_tipo_usuario FROM usuario WHERE email=? AND clave_hash=? AND activo=1",
            (datos.email, datos.password),
        ).fetchone()

    if not user:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas")

    return {
        "success": True,
        "token": f"token_user_{user['id']}",
        "id_tipo_usuario": user["id_tipo_usuario"],
    }


@app.post("/auth/register")
def register(datos: UsuarioRegister):
    with get_conn() as conn:
        exists = conn.execute("SELECT 1 FROM usuario WHERE email=?", (datos.email,)).fetchone()
        if exists:
            raise HTTPException(status_code=400, detail="El correo ya está registrado")

        cedula = f"TMP-{int(datetime.utcnow().timestamp())}"
        fecha = datetime.utcnow().strftime("%Y-%m-%d")
        conn.execute(
            """
            INSERT INTO usuario (cedula, nombre, email, telefono, direccion, clave_hash, fecha_registro, activo, id_tipo_pago, id_tipo_usuario)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1, 1)
            """,
            (cedula, datos.nombre, datos.email, datos.telefono, "No especificada", datos.password, fecha),
        )
        conn.commit()

    return {"success": True, "message": "Usuario creado exitosamente"}


@app.get("/users/me")
def get_perfil(x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        user = conn.execute(
            """
            SELECT u.id, u.cedula, u.nombre, u.email, u.telefono, u.direccion, u.id_tipo_pago, u.id_tipo_usuario
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
    perfil["stats"] = {"reservas": reservas, "mascotas": mascotas, "dias": dias_row["total"]}
    return perfil


@app.put("/users/me")
def update_perfil(datos: UsuarioUpdate, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        conn.execute(
            "UPDATE usuario SET nombre=?, email=?, telefono=? WHERE id=?",
            (datos.nombre, datos.email, datos.telefono, user_id),
        )
        conn.commit()
        user = conn.execute(
            "SELECT id, cedula, nombre, email, telefono, direccion, id_tipo_pago, id_tipo_usuario FROM usuario WHERE id=?",
            (user_id,),
        ).fetchone()

    return {"success": True, "data": dict(user)}


@app.get("/pets", response_model=List[MascotaResponse])
def get_mascotas(x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        rows = conn.execute(
            """
            SELECT m.id, m.nombre, m.edad, m.sexo, m.peso, m.fecha_nacimiento, m.notas, tm.especie, tm.raza
            FROM mascota m
            INNER JOIN tipo_mascota tm ON tm.id = m.id_tipo_mascota
            WHERE m.id_usuario=?
            ORDER BY m.id DESC
            """,
            (user_id,),
        ).fetchall()
        return [serialize_pet_row(conn, row) for row in rows]


@app.post("/pets", response_model=MascotaResponse)
def create_mascota(m: MascotaBase, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        tipo_id = ensure_tipo_mascota(conn, m.especie, m.raza)
        cur = conn.execute(
            """
            INSERT INTO mascota (nombre, foto, edad, sexo, peso, altura, microchip, fecha_nacimiento, notas, id_usuario, id_tipo_mascota, id_veterinario)
            VALUES (?, '', ?, ?, ?, NULL, NULL, ?, ?, ?, ?, NULL)
            """,
            (
                m.nombre,
                m.edad,
                normalize_sex_to_db(m.sexo),
                normalize_weight_to_db(m.peso),
                None if m.fecha_nacimiento == "No especificado" else m.fecha_nacimiento,
                m.notas,
                user_id,
                tipo_id,
            ),
        )
        mascota_id = cur.lastrowid
        upsert_need(conn, mascota_id, "vacuna", m.vacunas or "")
        upsert_need(conn, mascota_id, "alergia", m.alergias or "")
        upsert_need(conn, mascota_id, "dieta", m.dieta or "")
        conn.commit()

        row = conn.execute(
            """
            SELECT m.id, m.nombre, m.edad, m.sexo, m.peso, m.fecha_nacimiento, m.notas, tm.especie, tm.raza
            FROM mascota m
            INNER JOIN tipo_mascota tm ON tm.id = m.id_tipo_mascota
            WHERE m.id=?
            """,
            (mascota_id,),
        ).fetchone()

        return serialize_pet_row(conn, row)


@app.put("/pets/{pet_id}", response_model=MascotaResponse)
def update_mascota(
    pet_id: int, m: MascotaBase, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")
):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        existing = conn.execute(
            "SELECT id FROM mascota WHERE id=? AND id_usuario=?",
            (pet_id, user_id),
        ).fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="Mascota no encontrada")

        tipo_id = ensure_tipo_mascota(conn, m.especie, m.raza)
        conn.execute(
            """
            UPDATE mascota
            SET nombre=?, edad=?, sexo=?, peso=?, fecha_nacimiento=?, notas=?, id_tipo_mascota=?
            WHERE id=?
            """,
            (
                m.nombre,
                m.edad,
                normalize_sex_to_db(m.sexo),
                normalize_weight_to_db(m.peso),
                None if m.fecha_nacimiento == "No especificado" else m.fecha_nacimiento,
                m.notas,
                tipo_id,
                pet_id,
            ),
        )

        conn.execute("DELETE FROM mascota_x_necesidad WHERE id_mascota=?", (pet_id,))
        upsert_need(conn, pet_id, "vacuna", m.vacunas or "")
        upsert_need(conn, pet_id, "alergia", m.alergias or "")
        upsert_need(conn, pet_id, "dieta", m.dieta or "")
        conn.commit()

        row = conn.execute(
            """
            SELECT m.id, m.nombre, m.edad, m.sexo, m.peso, m.fecha_nacimiento, m.notas, tm.especie, tm.raza
            FROM mascota m
            INNER JOIN tipo_mascota tm ON tm.id = m.id_tipo_mascota
            WHERE m.id=?
            """,
            (pet_id,),
        ).fetchone()

        return serialize_pet_row(conn, row)


@app.post("/reservations")
def create_reserva(r: ReservaCreateRequest, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    ingreso = datetime.fromisoformat(r.fecha_ingreso.replace("Z", "+00:00")).date()
    salida = datetime.fromisoformat(r.fecha_salida.replace("Z", "+00:00")).date()
    dias = max((salida - ingreso).days, 1)

    room_number = r.room.replace("Habitación", "").strip()
    tipo_hospedaje_db = "estandar" if r.type.lower().startswith("est") else "especial"
    precio_base = 50 if tipo_hospedaje_db == "estandar" else 85
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

        estado = conn.execute("SELECT id FROM estado_reserva WHERE estado='activa'").fetchone()
        tipo_hosp = conn.execute(
            "SELECT id FROM tipo_hospedaje WHERE tipo=?",
            (tipo_hospedaje_db,),
        ).fetchone()

        cur = conn.execute(
            """
            INSERT INTO reserva (fecha_ingreso, fecha_salida, estancia, precio, id_mascota, id_habitacion, id_estado, id_tipo_hospedaje)
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
        conn.execute("UPDATE habitacion SET estado='ocupado' WHERE id=?", (habitacion["id"],))
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
def get_history(x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
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
def cancel_res(res_id: int, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
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


@app.get("/notifications")
def get_notif(x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
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


@app.get("/payments/methods")
def get_tarjetas(x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        row = conn.execute(
            """
            SELECT u.id_tipo_pago, tp.tipo
            FROM usuario u
            JOIN tipo_pago tp ON tp.id = u.id_tipo_pago
            WHERE u.id=?
            """,
            (user_id,),
        ).fetchone()

    if not row:
        return []

    numero = "**** 5678" if row["tipo"] == "tarjeta" else "Método en efectivo"
    marca = "Tarjeta" if row["tipo"] == "tarjeta" else "Efectivo"
    return [{"id": row["id_tipo_pago"], "numero": numero, "marca": marca}]


@app.post("/payments/methods")
def add_tarjeta(t: TarjetaCreate, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        tarjeta = conn.execute("SELECT id FROM tipo_pago WHERE tipo='tarjeta'").fetchone()
        conn.execute(
            "UPDATE usuario SET id_tipo_pago=? WHERE id=?",
            (tarjeta["id"], user_id),
        )
        conn.commit()

    return {"id": tarjeta["id"], "numero": t.numero, "marca": "Tarjeta"}


@app.delete("/payments/methods/{tarjeta_id}")
def delete_tarjeta(tarjeta_id: int, x_user_id: Optional[int] = Header(default=None, alias="X-User-Id")):
    user_id = resolve_current_user_id(x_user_id)
    with get_conn() as conn:
        efectivo = conn.execute("SELECT id FROM tipo_pago WHERE tipo='efectivo'").fetchone()
        conn.execute(
            "UPDATE usuario SET id_tipo_pago=? WHERE id=? AND id_tipo_pago=?",
            (efectivo["id"], user_id, tarjeta_id),
        )
        conn.commit()

    return {"success": True}
