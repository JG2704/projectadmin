from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

app = FastAPI(title="API Hotel de Mascotas - Full Schema")

# ==========================================
# 1. BASES DE DATOS ALAMBRADAS (MOCKS)
# ==========================================

USUARIO_MOCK = {
    "id": 1,
    "cedula": "3-0000-0000",
    "nombre": "Sebastian Guillen",
    "email": "cliente@hotel.com",
    "telefono": "8888-8888",
    "direccion": "Cartago, Costa Rica",
    "id_tipo_pago": 1,
    "id_tipo_usuario": 1
}

# Base de datos de mascotas con esquema completo
MASCOTAS_MOCK = [
    {
        "id": 101,
        "nombre": "Max",
        "especie": "Perro",
        "raza": "Golden Retriever",
        "edad": 3,
        "sexo": "Macho",
        "peso": "32kg",
        "fecha_nacimiento": "2021-05-10",
        "vacunas": "Todas al día",
        "alergias": "Ninguna",
        "dieta": "Alimento seco premium",
        "notas": "Le gusta jugar con pelotas de tenis."
    },
    {
        "id": 102,
        "nombre": "Luna",
        "especie": "Gato",
        "raza": "Persa",
        "edad": 2,
        "sexo": "Hembra",
        "peso": "4.5kg",
        "fecha_nacimiento": "2022-08-15",
        "vacunas": "Triple felina completa",
        "alergias": "Polen",
        "dieta": "Dieta blanda",
        "notas": "Es un poco tímida con desconocidos."
    }
]

RESERVAS_MOCK = []
NOTIFICACIONES_MOCK = [
    {"id": 1, "type": "reserva", "title": "Bienvenido", "message": "Gracias por usar Pet Hotel.", "time": "Ahora"}
]

# ==========================================
# 2. MODELOS DE DATOS 
# ==========================================

class LoginRequest(BaseModel):
    email: str
    password: str

# Modelo para los datos de registro
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

# Modelo para la edición del perfil
class UsuarioUpdate(BaseModel):
    nombre: str
    email: str
    telefono: str

# ==========================================
# 3. ENDPOINTS
# ==========================================

@app.post("/auth/login")
def login(datos: LoginRequest):
    if datos.email in "cliente@hotel.com" and datos.password == "123456":
        return {"success": True, "token": "token_pro_123", "id_tipo_usuario": 1}
    raise HTTPException(status_code=401, detail="Credenciales incorrectas")



@app.post("/auth/register")
def register(datos: UsuarioRegister):
    # Aqui aplicamos el hash: hash_pw = bcrypt.hash(datos.password)
    # Y hacemos el INSERT en la tabla Usuarios.
    
    print(f"Nuevo usuario registrado en el sistema: {datos.nombre} | Email: {datos.email}")
    
    # Devolvemos un éxito para que Flutter sepa que puede ir al Login
    return {"success": True, "message": "Usuario creado exitosamente"}

@app.get("/users/me")
def get_perfil():
    # 1. Calculamos las estadísticas "en vivo" recorriendo los MOCKS
    num_mascotas = len(MASCOTAS_MOCK)
    num_reservas = len(RESERVAS_MOCK)
    
    # Calculamos "Días de Estancia" sumando los días de todas las reservas activas basado en fechas reales
    total_dias = 0
    for r in RESERVAS_MOCK:
        if r["status"] == "Activa":
            try:
                ingreso = datetime.fromisoformat(r["fecha_ingreso"].replace('Z', '+00:00'))
                salida = datetime.fromisoformat(r["fecha_salida"].replace('Z', '+00:00'))
                dias = max((salida - ingreso).days, 1)
                total_dias += dias
            except (KeyError, ValueError):
                pass
    
    # 2. Creamos un objeto de estadísticas
    stats = {
        "reservas": num_reservas,
        "mascotas": num_mascotas,
        "dias": total_dias
    }
    
    # 3. Devolvemos el perfil original pero inyectándole las stats calculadas
    perfil_con_stats = USUARIO_MOCK.copy()
    perfil_con_stats["stats"] = stats
    
    return perfil_con_stats

@app.put("/users/me")
def update_perfil(datos: UsuarioUpdate):
    # Aqui hacemos: UPDATE Usuario SET nombre=... WHERE id=...
    USUARIO_MOCK["nombre"] = datos.nombre
    USUARIO_MOCK["email"] = datos.email
    USUARIO_MOCK["telefono"] = datos.telefono
    
    print(f"👤 Perfil actualizado: {USUARIO_MOCK['nombre']}")
    return {"success": True, "data": USUARIO_MOCK}

# --- CRUD MASCOTAS ---

@app.get("/pets", response_model=List[MascotaResponse])
def get_mascotas():
    return MASCOTAS_MOCK

@app.post("/pets", response_model=MascotaResponse)
def create_mascota(m: MascotaBase):
    nuevo_id = max([pet["id"] for pet in MASCOTAS_MOCK]) + 1 if MASCOTAS_MOCK else 1
    nueva_pet = m.dict()
    nueva_pet["id"] = nuevo_id
    MASCOTAS_MOCK.append(nueva_pet)
    return nueva_pet

@app.put("/pets/{pet_id}", response_model=MascotaResponse)
def update_mascota(pet_id: int, m: MascotaBase):
    for pet in MASCOTAS_MOCK:
        if pet["id"] == pet_id:
            pet.update(m.dict())
            return pet
    raise HTTPException(status_code=404, detail="Mascota no encontrada")

# --- RESERVAS Y NOTIFICACIONES ---

@app.post("/reservations")
def create_reserva(r: ReservaCreateRequest):
    ingreso = datetime.fromisoformat(r.fecha_ingreso.replace('Z', '+00:00'))
    salida = datetime.fromisoformat(r.fecha_salida.replace('Z', '+00:00'))
    dias = max((salida - ingreso).days, 1)
    total = dias * (50 if r.type == "Estándar" else 85)
    
    reserva = {
        "id": len(RESERVAS_MOCK) + 1,
        "name": r.name,
        "room": r.room,
        "type": r.type,
        "date": f"{ingreso.strftime('%d %b')} - {salida.strftime('%d %b %Y')}",
        "fecha_ingreso": r.fecha_ingreso,
        "fecha_salida": r.fecha_salida,
        "status": "Activa",
        "total": f"${total}.00"
    }
    RESERVAS_MOCK.insert(0, reserva)
    return reserva

@app.get("/reservations/history")
def get_history():
    return RESERVAS_MOCK

@app.patch("/reservations/{res_id}/cancel")
def cancel_res(res_id: int):
    for r in RESERVAS_MOCK:
        if r["id"] == res_id:
            r["status"] = "Cancelada"
            return {"success": True}
    raise HTTPException(status_code=404)

@app.get("/notifications")
def get_notif():
    return NOTIFICACIONES_MOCK

# --- MÓDULO DE PAGOS ---

# Simulamos las tarjetas asociadas al usuario
TARJETAS_MOCK = [
    {"id": 1, "numero": "**** 1234", "marca": "Visa"},
    {"id": 2, "numero": "**** 5678", "marca": "MasterCard"}
]

class TarjetaCreate(BaseModel):
    numero: str

@app.get("/payments/methods")
def get_tarjetas():
    return TARJETAS_MOCK

@app.post("/payments/methods")
def add_tarjeta(t: TarjetaCreate):
    nueva = {
        "id": len(TARJETAS_MOCK) + 1,
        "numero": t.numero,
        "marca": "Visa" # Solo agregamos una tarjeta con un numero mas para el mock
    }
    print(nueva)
    TARJETAS_MOCK.append(nueva)
    return nueva

@app.delete("/payments/methods/{tarjeta_id}")
def delete_tarjeta(tarjeta_id: int):
    global TARJETAS_MOCK
    TARJETAS_MOCK = [t for t in TARJETAS_MOCK if t["id"] != tarjeta_id]
    return {"success": True}