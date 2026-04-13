import 'package:flutter/material.dart';
import '../../../models/pet_model.dart';
import 'edit_pet_page.dart';

class PetDetailPage extends StatefulWidget {
  final Pet pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Column(
        children: [
          // HEADER MORADO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.deepPurple],
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.pets, color: Colors.purple),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pet.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${widget.pet.breed} • ${widget.pet.age} años",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              ],
            ),
          ),

          // CONTENIDO
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(15),
              children: [

                _sectionCard(
                  "Información General",
                  [
                    _row("Tipo", widget.pet.type),
                    _row("Raza", widget.pet.breed),
                    _row("Género", widget.pet.gender),
                    _row("Edad", "${widget.pet.age} años"),
                    _row("Peso", widget.pet.weight),
                  ],
                  icon: Icons.favorite_border,
                  iconColor: Colors.purple,
                ),

                _sectionCard(
                  "Fecha de Nacimiento",
                  [
                    Text(widget.pet.birthDate),
                  ],
                  icon: Icons.calendar_today,
                  iconColor: Colors.purple,
                ),

                _sectionCard(
                  "Información de Salud",
                  [
                    _row("Vacunas", widget.pet.vaccines),
                    _row("Alergias", widget.pet.allergies),
                  ],
                  icon: Icons.info_outline,
                  iconColor: Colors.purple,
                ),

                _sectionCard(
                  "Dieta",
                  [
                    Text(widget.pet.diet),
                  ],
                  icon: Icons.restaurant_menu,
                  iconColor: Colors.purple,
                ),

                _sectionCard(
                  "Notas Adicionales",
                  [
                    Text(
                      widget.pet.notes.isEmpty
                          ? "Sin notas"
                          : widget.pet.notes,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // BOTONES
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Volver"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPetPage(pet: widget.pet),
                            ),
                          );
                          // ACTUALIZA LA UI AL VOLVER
                          setState(() {});
                        },
                        child: const Text("Editar"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // TARJETA DE SECCIÓN
  Widget _sectionCard(
    String title,
    List<Widget> children, {
    IconData? icon,
    Color iconColor = Colors.pink,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            )
          else
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          const SizedBox(height: 10),
          ...children
        ],
      ),
    );
  }

  // FILA DE INFORMACIÓN
  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}