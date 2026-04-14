import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
  late TextEditingController typeController;
  late TextEditingController breedController;
  late TextEditingController ageController;

  late TextEditingController genderController;
  late TextEditingController weightController;
  late TextEditingController birthDateController;
  late TextEditingController vaccinesController;
  late TextEditingController allergiesController;
  late TextEditingController dietController;
  late TextEditingController notesController;

  // Estado para la bolita de carga
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // INICIALIZAR CON DATOS ACTUALES
    nameController = TextEditingController(text: widget.pet.name);
    typeController = TextEditingController(text: widget.pet.type);
    breedController = TextEditingController(text: widget.pet.breed);
    ageController = TextEditingController(text: widget.pet.age);

    // Estos campos podrían venir vacíos
    genderController = TextEditingController(text: widget.pet.gender ?? '');
    weightController = TextEditingController(text: widget.pet.weight ?? '');
    birthDateController = TextEditingController(text: widget.pet.birthDate ?? '');
    vaccinesController = TextEditingController(text: widget.pet.vaccines ?? '');
    allergiesController = TextEditingController(text: widget.pet.allergies ?? '');
    dietController = TextEditingController(text: widget.pet.diet ?? '');
    notesController = TextEditingController(text: widget.pet.notes ?? '');
  }

// MÉTODO PARA ENVIAR CAMBIOS AL BACKEND
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
      final dio = await AuthService.getDioWithAuth();
      final petId = widget.pet.id; 
      
      if (petId == null) throw Exception("ID de mascota no válido");

      // Agregamos todos los campos al JSON que viaja a Python
      final response = await dio.put(
        '/pets/$petId',
        data: {
          "nombre": nameController.text.trim(),
          "especie": typeController.text.trim(),
          "raza": breedController.text.trim(),
          "edad": int.tryParse(ageController.text.trim()) ?? 0,
          "sexo": genderController.text.trim(),
          "peso": weightController.text.trim(),
          "fecha_nacimiento": birthDateController.text.trim(), 
          "vacunas": vaccinesController.text.trim(),           
          "alergias": allergiesController.text.trim(),         
          "dieta": dietController.text.trim(),                 
          "notas": notesController.text.trim()
        },
      );

      if (response.statusCode == 200) {
        // Actualizamos los campos en la memoria de la pantalla
        widget.pet.name = nameController.text.trim();
        widget.pet.type = typeController.text.trim();
        widget.pet.breed = breedController.text.trim();
        widget.pet.age = ageController.text.trim();
        
        widget.pet.gender = genderController.text.trim();
        widget.pet.weight = weightController.text.trim();
        widget.pet.birthDate = birthDateController.text.trim(); 
        widget.pet.vaccines = vaccinesController.text.trim();   
        widget.pet.allergies = allergiesController.text.trim(); 
        widget.pet.diet = dietController.text.trim();           
        widget.pet.notes = notesController.text.trim();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Cambios guardados exitosamente!")),
        );
        Navigator.pop(context, true); 
      }
    } on DioException catch (e) {
      debugPrint("Error al actualizar: ${e.message}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con el servidor")),
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
            _sectionCard("Información Principal", [
              _input("Nombre", nameController),
              _input("Especie", typeController),
              _input("Raza", breedController),
              _input("Edad (Años)", ageController, keyboardType: TextInputType.number),
              Row(
                children: [
                  Expanded(child: _input("Sexo", genderController)),
                  const SizedBox(width: 10),
                  Expanded(child: _input("Peso", weightController)),
                ],
              )
            ]),
            _sectionCard("Historial Médico", [
              _input("Fecha de Nacimiento", birthDateController),
              _input("Vacunas al día", vaccinesController, maxLines: 2),
              _input("Alergias o condiciones", allergiesController, maxLines: 2),
            ]),
            _sectionCard("Preferencias", [
              _input("Dieta / Alimentación", dietController, maxLines: 2),
              _input("Notas de comportamiento", notesController, maxLines: 3),
            ]),
            const SizedBox(height: 20),
            
            // BOTÓN CON ESTADO DE CARGA
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...children
        ],
      ),
    );
  }

  // Modificado para aceptar el tipo de teclado 
  Widget _input(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType}) {
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