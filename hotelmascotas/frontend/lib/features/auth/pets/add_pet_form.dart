import 'package:flutter/material.dart';
import '../../../models/pet_model.dart';
import '../../../services/auth_service.dart';

class AddPetForm extends StatefulWidget {
  const AddPetForm({super.key});

  @override
  State<AddPetForm> createState() => _AddPetFormState();
}

class _AddPetFormState extends State<AddPetForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController speciesController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController vacunacionController = TextEditingController();
  final TextEditingController condicionController = TextEditingController();
  final TextEditingController contratoController = TextEditingController();
  final TextEditingController cuidadosController = TextEditingController();

  int? sexo;
  bool _isLoading = false;

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

  Future<void> _savePetToBackend() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El nombre es obligatorio")),
      );
      return;
    }

    if (speciesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La especie es obligatoria")),
      );
      return;
    }

    if (breedController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La raza es obligatoria")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = await AuthService.getDioWithAuth();

      final response = await dio.post(
        '/pets',
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final savedPet =
            Pet.fromBackend(Map<String, dynamic>.from(response.data));

        if (!mounted) return;
        Navigator.pop(context, savedPet);
      }
    } catch (e) {
      debugPrint("Error al guardar mascota: $e");
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al conectar con el servidor"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Agregar Mascota",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 15),
            _input("Nombre", "Nombre de la mascota", nameController,
                TextInputType.text),
            _input("Especie", "Ej: perro, gato, conejo", speciesController,
                TextInputType.text),
            _input("Raza", "Ej: golden retriever, persa", breedController,
                TextInputType.text),
            _input("Edad", "Años", ageController, TextInputType.number),
            _input("Tamaño", "Ej: 45 (cm)", sizeController,
                TextInputType.number),
            _input("Vacunación", "Estado de vacunas", vacunacionController,
                TextInputType.text),
            _input("Condición", "Estado de salud", condicionController,
                TextInputType.text),
            _input("Contrato", "Tipo de contrato", contratoController,
                TextInputType.text),
            _input("Cuidados especiales", "Opcional", cuidadosController,
                TextInputType.text),
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    onPressed: _isLoading ? null : _savePetToBackend,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text("Agregar"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _input(String label, String hint, TextEditingController controller,
      TextInputType keyboardType) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}