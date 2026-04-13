import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Política de Privacidad", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white, // Asegura que el texto e íconos sean blancos
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Usamos SingleChildScrollView para que el usuario pueda bajar a leer todo
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Le damos un margen para que no pegue con los bordes
        child: const Text(
          '''En PetLodge valoramos la privacidad de nuestros usuarios (incluso en entornos de prueba). Esta política explica cómo manejamos la información dentro de nuestro ecosistema simulado.

1. Información que Recopilamos
Recopilamos información proporcionada directamente por usted al crear una cuenta o registrar una mascota, la cual puede incluir:

Nombre completo y correo electrónico (ficticios o reales, bajo su propio riesgo).

Datos de sus mascotas (nombre, raza, edad, historial médico simulado).

Datos técnicos de las reservas (fechas de ingreso y salida).

2. Uso de la Información
Toda la información recopilada se utiliza de forma exclusiva para:

Demostrar la funcionalidad de conexión entre nuestro Frontend (Flutter) y Backend (FastAPI).

Procesar lógicas matemáticas de tarifas de hospedaje.

Cumplir con los requisitos de evaluación académica o de portafolio del proyecto.

3. Compartir Información con Terceros
Al ser un proyecto cerrado de desarrollo, sus datos residen únicamente en nuestras bases de datos locales o servidores de prueba. No vendemos, alquilamos ni compartimos su información con empresas de terceros, agencias de marketing ni entidades externas.

4. Seguridad de los Datos
Aunque aplicamos medidas de seguridad básicas (como el hashing de contraseñas para fines demostrativos), le recordamos encarecidamente que NO debe ingresar información personal sensible ni datos bancarios reales en los formularios de esta aplicación.''',
          style: TextStyle(fontSize: 16, height: 1.5), // height 1.5 hace que los renglones no se vean tan pegados
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}