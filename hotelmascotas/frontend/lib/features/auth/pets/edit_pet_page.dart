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
  late TextEditingController tipoController;
  late TextEditingController razaController;
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
    // Inicializar con los datos actuales de la mascota
    nameController = TextEditingController(text: widget.pet.name);
    tipoController = TextEditingController(text: widget.pet.type ?? '');
    razaController = TextEditingController(text: widget.pet.breed ?? '');
    ageController = TextEditingController(text: widget.pet.age);
    sizeController = TextEditingController(text: widget.pet.size ?? '');
    vacunacionController = TextEditingController(
      text: widget.pet.vaccines ?? '',
    );
    condicionController = TextEditingController(
      text: widget.pet.condition ?? '',
    );
    contratoController = TextEditingController(text: widget.pet.contract ?? '');
    cuidadosController = TextEditingController(
      text: widget.pet.specialCare ?? '',
    );
    sexo = widget.pet.genderInt;
  }

  Future<void> _updatePetInBackend() async {
    if (nameController.text.trim().isEmpty ||
        tipoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nombre y Especie son obligatorios")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = await AuthService.getDioWithAuth();
      final petId = widget.pet.id;

      // PAYLOAD: Exactamente igual al que recibe tu Backend en MascotaCreate
      final response = await dio.put(
        '/pets/$petId',
        data: {
          "nombre": nameController.text.trim(),
          "especie": tipoController.text.trim(), // 🔥 mismo nombre que add
          "raza": razaController.text.trim(),
          "edad": int.tryParse(ageController.text.trim()) ?? 0,
          "sexo": sexo ?? 0,
          "peso": double.tryParse(sizeController.text.trim()) ?? 0.0,
          "vacunas": vacunacionController.text.isEmpty
              ? "No especificado"
              : vacunacionController.text,
          "condiciones": condicionController.text.isEmpty
              ? "Ninguna"
              : condicionController.text,
          "notas": cuidadosController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        // Actualizamos localmente para que la UI se refresque al volver
        _updateLocalPetObject();

        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Mascota actualizada!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on DioException catch (e) {
      String errorMsg = "Error al actualizar";

      // SOLUCIÓN AL ERROR DE List<dynamic>:
      // FastAPI devuelve una lista de errores en 'detail' cuando hay fallos de validación (422)
      if (e.response?.data != null && e.response?.data['detail'] != null) {
        var detail = e.response?.data['detail'];
        if (detail is List) {
          // Mapeamos la lista de errores a un solo string legible
          errorMsg = detail
              .map((err) => "${err['loc'].last}: ${err['msg']}")
              .join("\n");
        } else {
          errorMsg = detail.toString();
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePetFromBackend() async {
    final petId = widget.pet.id;
    if (petId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo eliminar la mascota porque no tiene ID"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar mascota"),
        content: const Text(
          "Esta acción no se puede deshacer. ¿Deseas eliminar esta mascota?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isLoading = true);

    try {
      final dio = await AuthService.getDioWithAuth();
      await dio.delete('/pets/$petId');

      try {
        await dio.post(
          '/notifications',
          data: {
            "tipo": "mascota_eliminada",
            "descripcion": "Eliminaste a ${widget.pet.name} de tus mascotas.",
          },
        );
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mascota eliminada correctamente"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final errorMsg = _extractApiErrorMessage(
        e.response?.data,
        fallback: "Error al eliminar",
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractApiErrorMessage(
    dynamic responseData, {
    required String fallback,
  }) {
    if (responseData == null) return fallback;

    if (responseData is String) {
      return responseData;
    }

    if (responseData is Map) {
      final detail = responseData['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        return detail
            .map((err) {
              if (err is Map && err['msg'] != null) {
                final location = err['loc'];
                final field = location is List && location.isNotEmpty
                    ? location.last.toString()
                    : 'campo';
                return '$field: ${err['msg']}';
              }
              return err.toString();
            })
            .join('\n');
      }
      if (detail != null) return detail.toString();

      return responseData.toString();
    }

    if (responseData is List) {
      return responseData.map((item) => item.toString()).join('\n');
    }

    return responseData.toString();
  }

  // Función auxiliar para mantener el objeto limpio
  void _updateLocalPetObject() {
    widget.pet.name = nameController.text.trim();
    widget.pet.type = tipoController.text.trim();
    widget.pet.breed = razaController.text.trim();
    widget.pet.age = ageController.text.trim();
    widget.pet.size = sizeController.text.trim();
    widget.pet.vaccines = vacunacionController.text.trim();
    widget.pet.condition = condicionController.text.trim();
    widget.pet.contract = contratoController.text.trim();
    widget.pet.specialCare = cuidadosController.text.trim();
    widget.pet.genderInt = sexo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Mascota"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Eliminar mascota",
            onPressed: _isLoading ? null : _deletePetFromBackend,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _input("Nombre", nameController),
            _input("Especie", tipoController),
            _input("Raza", razaController),
            _input("Edad", ageController, keyboardType: TextInputType.number),
            _input("Tamaño/Peso", sizeController),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text("Sexo: "),
                DropdownButton<int>(
                  value: sexo,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("Macho")),
                    DropdownMenuItem(value: 1, child: Text("Hembra")),
                  ],
                  onChanged: (v) => setState(() => sexo = v),
                ),
              ],
            ),
            _input("Vacunación", vacunacionController),
            _input("Condición Médica", condicionController),
            _input("Contrato", contratoController),
            _input("Cuidados Especiales", cuidadosController, maxLines: 3),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: _isLoading ? null : _updatePetInBackend,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Guardar Cambios",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
