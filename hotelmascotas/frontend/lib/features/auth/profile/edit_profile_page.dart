import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../services/auth_service.dart'; 

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _loadCurrentData();
  }

  // Cargamos los datos actuales del servidor para que el usuario vea qué está editando
  Future<void> _loadCurrentData() async {
    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.get('/users/me');
      if (response.statusCode == 200) {
        setState(() {
          _nameController.text = response.data['nombre'] ?? "";
          _emailController.text = response.data['email'] ?? "";
          _phoneController.text = response.data['telefono'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
      setState(() => _isLoading = false);
    }
  }

  // MÉTODO PARA GUARDAR
  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.put(
        '/users/me',
        data: {
          "nombre": _nameController.text.trim(),
          "email": _emailController.text.trim(),
          "telefono": _phoneController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Perfil actualizado con éxito")),
        );
        Navigator.pop(context, true); // Regresamos 'true' para refrescar ProfilePage
      }
    } catch (e) {
      debugPrint("Error guardando perfil: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar los cambios")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Nombre Completo",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Correo Electrónico",
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Teléfono",
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Guardar Cambios", style: TextStyle(color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
    );
  }
}