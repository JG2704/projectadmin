import 'package:flutter/material.dart';
import '../../../models/pet_model.dart';
import '../../../services/auth_service.dart';

class EditPetPage extends StatefulWidget {
  final Pet pet;

  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  late TextEditingController nameController;
  late TextEditingController speciesController;
  late TextEditingController breedController;
  late TextEditingController ageController;
  late TextEditingController sizeController;
  late TextEditingController vacunacionController;
  late TextEditingController condicionController;
  late TextEditingController contratoController;
  late TextEditingController cuidadosController;

  int? sexo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.pet.name);
    speciesController = TextEditingController(text: widget.pet.type);
    breedController = TextEditingController(text: widget.pet.breed);
    ageController = TextEditingController(text: widget.pet.age);
    sizeController = TextEditingController(text: widget.pet.size);
    vacunacionController = TextEditingController(text: widget.pet.vaccines);
    condicionController = TextEditingController(text: widget.pet.condition);
    contratoController = TextEditingController(text: widget.pet.contract);
    cuidadosController = TextEditingController(text: widget.pet.specialCare);

    sexo = widget.pet.genderInt;
  }

  @override
  void dispose() {
    nameController.dispose();
    speciesController.dispose();
    breedController.dispose();
    ageController.dispose();
    sizeController.dispose();
    vacunacionController.dispose();
    condicionController.dispose();
    contratoController.dispose();
    cuidadosController.dispose();
    super.dispose();
  }

  Future<void> _updatePetInBackend() async {
    if (nameController.text.trim().isEmpty ||
        speciesController.text.trim().isEmpty ||
        breedController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nombre, especie y raza son obligatorios"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = await AuthService.getDioWithAuth();
      final petId = widget.pet.id;

      if (petId == null) throw Exception("ID inválido");

      final response = await dio.put(
        '/pets/$petId',
        data: {
          "nombre": nameController.text.trim(),
          "especie": speciesController.text.trim(),
          "raza": breedController.text.trim(),
          "edad": int.tryParse(ageController.text.trim()) ?? 0,
          "sexo": sexo,
          "tamaño": double.tryParse(sizeController.text.trim()),
          "vacunacion": vacunacionController.text.trim().isEmpty
              ? "No especificado"
              : vacunacionController.text.trim(),
          "condicion": condicionController.text.trim().isEmpty
              ? "Desconocida"
              : condicionController.text.trim(),
          "contrato": contratoController.text.trim().isEmpty
              ? "No definido"
              : contratoController.text.trim(),
          "cuidados_especiales": cuidadosController.text.trim().isEmpty
              ? "Ninguno"
              : cuidadosController.text.trim(),
          "id_veterinario": null
        },
      );

      if (response.statusCode == 200) {
        final updated =
            Pet.fromBackend(Map<String, dynamic>.from(response.data));

        widget.pet.name = updated.name;
        widget.pet.type = updated.type;
        widget.pet.breed = updated.breed;
        widget.pet.age = updated.age;
        widget.pet.gender = updated.gender;
        widget.pet.genderInt = updated.genderInt;
        widget.pet.size = updated.size;
        widget.pet.vaccines = updated.vaccines;
        widget.pet.condition = updated.condition;
        widget.pet.contract = updated.contract;
        widget.pet.specialCare = updated.specialCare;

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Cambios guardados!")),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Error al actualizar mascota: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Editar Mascota"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            _sectionCard("Información General", [
              _input("Nombre", nameController),
              _input("Especie *", speciesController),
              _input("Raza *", breedController),
              _input("Edad", ageController, keyboardType: TextInputType.number),
              _input("Tamaño (cm)", sizeController,
                  keyboardType: TextInputType.number),
              Row(
                children: [
                  const Text("Sexo: "),
                  const SizedBox(width: 10),
                  DropdownButton<int>(
                    value: sexo,
                    hint: const Text("Seleccionar"),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text("Macho")),
                      DropdownMenuItem(value: 1, child: Text("Hembra")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        sexo = value;
                      });
                    },
                  )
                ],
              ),
            ]),
            _sectionCard("Información Médica", [
              _input("Vacunación", vacunacionController, maxLines: 2),
              _input("Condición", condicionController, maxLines: 2),
            ]),
            _sectionCard("Otros", [
              _input("Contrato", contratoController),
              _input("Cuidados especiales", cuidadosController, maxLines: 2),
            ]),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isLoading ? null : _updatePetInBackend,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Guardar Cambios"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
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
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...children
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
