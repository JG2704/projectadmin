import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../models/pet_model.dart';

class AddPetForm extends StatefulWidget {
  const AddPetForm({super.key});

  @override
  State<AddPetForm> createState() => _AddPetFormState();
}

class _AddPetFormState extends State<AddPetForm> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController tipoController = TextEditingController();
  final TextEditingController razaController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController vacunacionController = TextEditingController();
  final TextEditingController condicionController = TextEditingController();
  final TextEditingController contratoController = TextEditingController();
  final TextEditingController cuidadosController = TextEditingController();

  int? sexo; // 0 = macho, 1 = hembra

  bool _isLoading = false;

Future<void> _savePetToBackend() async {
    // 1. Validamos que no envíes cosas vacías por accidente
    if (nameController.text.isEmpty || tipoController.text.isEmpty || razaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre, Especie y Raza son obligatorios")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      final response = await dio.post(
        'http://10.0.2.2:8000/pets',
        data: {
          "nombre": nameController.text.trim(),
          "especie": tipoController.text.trim(),
          "raza": razaController.text.trim(),
          "edad": int.tryParse(ageController.text) ?? 0,
          "sexo": sexo ?? 0, // Aseguramos enviar 0 si es null
          "peso": double.tryParse(sizeController.text) ?? 0.0,
          "vacunas": vacunacionController.text.isEmpty ? "No especificado" : vacunacionController.text,
          "alergias": condicionController.text.isEmpty ? "Ninguna" : condicionController.text,
          "notas": cuidadosController.text.trim(),
        },
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("¡Mascota registrada con éxito!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Cerramos el formulario
      
    } on DioException catch (e) {
      // 🔥 ESTO OBLIGA A MOSTRAR EL ERROR EN PANTALLA EN VEZ DE QUEDARSE PEGADO
      if (!mounted) return;
      String errorMsg = e.response?.data?.toString() ?? e.message ?? "Error desconocido";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error del servidor: $errorMsg"), 
          backgroundColor: Colors.red, 
          duration: const Duration(seconds: 6)
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error en la app: $e"), backgroundColor: Colors.red),
      );
    } finally {
      // 🔥 ESTO APAGA LA BOLITA PASE LO QUE PASE
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
            // HEADER
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

            // INPUTS
            _input("Nombre", "Nombre de la mascota", nameController, TextInputType.text),
            _input("Tipo", "Ej: Perro, Gato", tipoController, TextInputType.text),
            _input("Raza", "Ej: Labrador, Siamés", razaController, TextInputType.text),
            _input("Edad", "Años", ageController, TextInputType.number),
            _input("Tamaño", "Ej: 45 (cm)", sizeController, TextInputType.number),
            _input("Vacunación", "Estado de vacunas", vacunacionController, TextInputType.text),
            _input("Condición", "Estado de salud", condicionController, TextInputType.text),
            _input("Contrato", "Tipo de contrato", contratoController, TextInputType.text),
            _input("Cuidados especiales", "Opcional", cuidadosController, TextInputType.text),

            const SizedBox(height: 10),

            // SEXO
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

            // BOTONES
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
                                color: Colors.white, strokeWidth: 2),
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

  Widget _input(String label, String hint, TextEditingController controller, TextInputType keyboardType) {
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