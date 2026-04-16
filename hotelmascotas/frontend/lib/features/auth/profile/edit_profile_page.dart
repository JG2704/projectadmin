import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class EditProfilePage extends StatefulWidget {
  final int userId; // Lo recibimos para saber a quién editar

  const EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Controladores para todos los campos requeridos
  late TextEditingController _nameController;
  late TextEditingController _cedulaController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _direccionController;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _cedulaController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _direccionController = TextEditingController();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        //'http://10.0.2.2:8000/users/me',
        'http://192.168.18.9:8000/users/me',
        options: Options(headers: {'X-User-Id': widget.userId}),
      );
      if (response.statusCode == 200) {
        setState(() {
          _nameController.text = response.data['nombre'] ?? "";
          _cedulaController.text = response.data['cedula'] ?? "";
          _emailController.text = response.data['email'] ?? "";
          _phoneController.text = response.data['telefono'] ?? "";
          _direccionController.text = response.data['direccion'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar datos: $e");
    }
  }

  Future<void> _saveChanges() async {
    // --- VALIDACIONES DE FORMATO (Requisito de Rúbrica) ---
    
    // Cédula: 9 dígitos
    if (!RegExp(r'^\d{9}$').hasMatch(_cedulaController.text)) {
      _showMsg("La cédula debe tener 9 dígitos numéricos");
      return;
    }
    
    // Email: Formato estándar
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showMsg("Ingresa un correo electrónico válido");
      return;
    }

    // Teléfono: 8 dígitos
    if (!RegExp(r'^\d{8}$').hasMatch(_phoneController.text)) {
      _showMsg("El teléfono debe tener 8 números");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final dio = Dio();
      await dio.put(
        'http://10.0.2.2:8000/users/me',
        options: Options(headers: {'X-User-Id': widget.userId}),
        data: {
          "nombre": _nameController.text,
          "cedula": _cedulaController.text,
          "email": _emailController.text,
          "telefono": _phoneController.text,
          "direccion": _direccionController.text,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true); // Retornamos true para refrescar la pantalla anterior
    } catch (e) {
      _showMsg("Error al guardar cambios");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil"), backgroundColor: Colors.purple, foregroundColor: Colors.white),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInput(_nameController, "Nombre Completo", Icons.person),
                const SizedBox(height: 15),
                _buildInput(_cedulaController, "Cédula", Icons.badge, keyboard: TextInputType.number),
                const SizedBox(height: 15),
                _buildInput(_emailController, "Correo Electrónico", Icons.email, keyboard: TextInputType.emailAddress),
                const SizedBox(height: 15),
                _buildInput(_phoneController, "Teléfono", Icons.phone, keyboard: TextInputType.phone),
                const SizedBox(height: 15),
                _buildInput(_direccionController, "Dirección Física", Icons.location_on),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
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

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}