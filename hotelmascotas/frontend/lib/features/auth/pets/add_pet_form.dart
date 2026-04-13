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
  final TextEditingController typeController = TextEditingController();
  final TextEditingController breedController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  // Controla el estado de carga al enviar los datos
  bool _isLoading = false;

  // Función asíncrona para enviar datos al servidor
  Future<void> _savePetToBackend() async {
    // 1. Validación básica
    if (nameController.text.isEmpty || typeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa al menos Nombre y Tipo")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();
      
      // 2. Hacemos el POST a Python
      final response = await dio.post(
        'http://10.0.2.2:8000/pets',
        data: {
          "nombre": nameController.text.trim(),
          "especie": typeController.text.trim(),
          "raza": breedController.text.trim(),
          "edad": int.tryParse(ageController.text.trim()) ?? 0,
          "sexo": "No especificado", 
          "peso": "No especificado",
          "vacunas": "No especificado",
          "notas": ""
        },
      );

      // 3. Si el servidor lo guardó correctamente
      if (response.statusCode == 200) {
        // Python nos devuelve la mascota recién creada con su ID real.
        // Lo usamos para crear el objeto local que pets_page.dart espera
        final savedPet = Pet(
          name: response.data['nombre'],
          type: response.data['especie'],
          breed: response.data['raza'],
          age: response.data['edad'].toString(),
        );

        if (!mounted) return;
        // Cerramos el modal y regresamos el objeto a la página principal
        Navigator.pop(context, savedPet);
      }
    } on DioException catch (e) {
      debugPrint("Error al crear mascota: ${e.message}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión con el servidor", style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
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
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            _input("Tipo", "Perro, Gato, Conejo...", typeController, TextInputType.text),
            _input("Raza", "Opcional", breedController, TextInputType.text),
            // Le forzamos el teclado numérico a la edad
            _input("Edad", "Años", ageController, TextInputType.number), 

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
                    // Si está cargando anulamos el botón para evitar doble envío
                    onPressed: _isLoading ? null : _savePetToBackend,
                    child: _isLoading 
                        ? const SizedBox(
                            width: 20, height: 20, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
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