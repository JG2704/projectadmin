import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Términos y Condiciones", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Usamos SingleChildScrollView para que el usuario pueda bajar a leer todo
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0), // Le damos un margen para que no pegue con los bordes
        child: const Text(
          '''1. Aceptación de los Términos
Al descargar, acceder o utilizar la aplicación PetLodge (en adelante, "la App"), usted acepta estar sujeto a estos Términos y Condiciones. Tenga en cuenta que esta aplicación es un proyecto académico y/o de demostración de software, por lo que los servicios ofrecidos no son reales.

2. Descripción del Servicio
PetLodge proporciona una plataforma simulada para la gestión de reservas de hospedaje para mascotas, registro de perfiles animales y seguimiento de estado. Ninguna reserva realizada en esta App se traducirá en un servicio físico real.

3. Registro de Cuentas
Para utilizar ciertas funciones, se requiere el registro de una cuenta. Usted es responsable de mantener la confidencialidad de sus credenciales (las cuales, al ser un entorno de prueba, no deben incluir contraseñas reales que utilice en otros servicios personales).

4. Limitación de Responsabilidad
Dado el carácter educativo de esta plataforma, los desarrolladores no asumen ninguna responsabilidad por la pérdida de datos, interrupciones del servicio (caídas del servidor local) o cualquier daño derivado del uso de esta aplicación de prueba.

5. Modificaciones
Nos reservamos el derecho de modificar estos términos en cualquier momento durante el ciclo de desarrollo del proyecto.''',
          style: TextStyle(fontSize: 16, height: 1.5), // height 1.5 hace que los renglones no se vean tan pegados
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}