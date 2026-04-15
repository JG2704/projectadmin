import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../models/pet_model.dart';

class EditPetPage extends StatefulWidget {
  final Pet pet;

  const EditPetPage({super.key, required this.pet});

  @override
  State<EditPetPage> createState() => _EditPetPageState();
}

class _EditPetPageState extends State<EditPetPage> {
  late TextEditingController nameController;
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
    ageController = TextEditingController(text: widget.pet.age);

    sizeController = TextEditingController(text: widget.pet.size ?? '');
    vacunacionController = TextEditingController(text: widget.pet.vaccines ?? '');
    condicionController = TextEditingController(text: widget.pet.condition ?? '');
    contratoController = TextEditingController(text: widget.pet.contract ?? '');
    cuidadosController = TextEditingController(text: widget.pet.specialCare ?? '');

    sexo = widget.pet.genderInt; // 0 o 1
  }

  Future<void> _updatePetInBackend() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre es obligatorio")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();
      final petId = widget.pet.id;

      if (petId == null) throw Exception("ID inválido");

      final response = await dio.put(
        'http://10.0.2.2:8000/pets/$petId',
        data: {
          "nombre": nameController.text.trim(),
          "edad": int.tryParse(ageController.text.trim()) ?? 0,
          "sexo": sexo,
          "tamaño": double.tryParse(sizeController.text.trim()),
          "vacunacion": vacunacionController.text.trim(),
          "condicion": condicionController.text.trim(),
          "contrato": contratoController.text.trim(),
          "cuidados_especiales": cuidadosController.text.trim(),
          "id_tipo_mascota": 1,
          "id_veterinario": null
        },
      );

      if (response.statusCode == 200) {
        // Actualizar objeto local
        widget.pet.name = nameController.text.trim();
        widget.pet.age = ageController.text.trim();
        widget.pet.size = sizeController.text.trim();
        widget.pet.vaccines = vacunacionController.text.trim();
        widget.pet.condition = condicionController.text.trim();
        widget.pet.contract = contratoController.text.trim();
        widget.pet.specialCare = cuidadosController.text.trim();
        widget.pet.genderInt = sexo;

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Cambios guardados!")),
        );

        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      debugPrint("Error: ${e.message}");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al actualizar")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
              _input("Edad", ageController, keyboardType: TextInputType.number),
              _input("Tamaño (cm)", sizeController, keyboardType: TextInputType.number),

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
                      borderRadius: BorderRadius.circular(10)),
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