import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controladores para todos los campos de la base de datos
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController(); // Nuevo
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController(); // Nuevo
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    String name = _nameController.text.trim();
    String cedula = _cedulaController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String direccion = _direccionController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validación de campos vacíos
    if (name.isEmpty || cedula.isEmpty || email.isEmpty || phone.isEmpty || direccion.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Todos los campos son obligatorios");
      return;
    }

    // 2. Validaciones de Formato (Requisito de la rúbrica)
    
    // Cédula: Exactamente 9 dígitos numéricos
    if (!RegExp(r'^\d{9}$').hasMatch(cedula)) {
      _showMessage("La cédula debe tener exactamente 9 números (Ej: 101230456)");
      return;
    }

    // Teléfono: Exactamente 8 dígitos numéricos
    if (!RegExp(r'^\d{8}$').hasMatch(phone)) {
      _showMessage("El teléfono debe tener 8 números (sin guiones)");
      return;
    }

    // Correo: Formato válido
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showMessage("Ingresa un correo electrónico válido");
      return;
    }

    // Contraseña: Mínimo 6 caracteres
    if (password.length < 6) {
      _showMessage("La contraseña debe tener al menos 6 caracteres");
      return;
    }

    if (password != confirmPassword) {
      _showMessage("Las contraseñas no coinciden");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio();

      final response = await dio.post(
        'http://10.0.2.2:8000/auth/register',
        //'http://192.168.18.9:8000/auth/register',
        data: {
          "cedula": cedula,
          "nombre": name,
          "email": email,
          "telefono": phone,
          "direccion": direccion,
          "password": password,
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Registro exitoso! Ya puedes iniciar sesión."), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Regresa al Login
      }
    } on DioException catch (e) {
      // Manejo de error si la cédula o correo ya existen en la BD
      if (e.response?.statusCode == 400) {
        _showMessage(e.response?.data['detail'] ?? "El usuario o correo ya existe");
      } else {
        _showMessage("Error de conexión con el servidor");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cedulaController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Crear Cuenta", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 60, color: Colors.purple),
                  const SizedBox(height: 10),
                  const Text("Únete a PetLodge", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
                  const SizedBox(height: 25),

                  // FORMULARIO CON TODOS LOS CAMPOS REQUERIDOS
                  _input(_cedulaController, "Cédula (9 dígitos)", Icons.badge, keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  _input(_nameController, "Nombre Completo", Icons.person),
                  const SizedBox(height: 15),
                  _input(_emailController, "Correo Electrónico", Icons.email, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _input(_phoneController, "Teléfono (8 dígitos)", Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  _input(_direccionController, "Dirección Física", Icons.location_on),
                  const SizedBox(height: 15),
                  _input(_passwordController, "Contraseña", Icons.lock, isPassword: true),
                  const SizedBox(height: 15),
                  _input(_confirmPasswordController, "Confirmar Contraseña", Icons.lock_outline, isPassword: true),
                  
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Registrarse", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: Colors.purple),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}