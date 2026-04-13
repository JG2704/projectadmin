import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ayuda y Soporte"), backgroundColor: Colors.purple, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _HelpCard(
            question: "¿Cómo hacer una reserva?",
            answer: "Selecciona una mascota y elige fechas disponibles.",
          ),
          _HelpCard(
            question: "¿Cómo agregar una mascota?",
            answer: "Ve a la sección mascotas y presiona agregar.",
          ),
          _HelpCard(
            question: "¿Cómo pagar?",
            answer: "Agrega un método de pago en tu perfil.",
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final String question;
  final String answer;

  const _HelpCard({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: ExpansionTile(
        title: Text(question),
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(answer),
          )
        ],
      ),
    );
  }
}