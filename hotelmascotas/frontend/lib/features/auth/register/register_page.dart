import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Completa todos los campos");
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
        data: {
          "nombre": name,
          "email": email,
          "telefono": phone,
          "password": password,
        },
      );

      if (response.statusCode == 200 && mounted) {
        _showMessage("¡Registro exitoso!");
        Navigator.pop(context);
      }
    } catch (_) {
      _showMessage("Error de red");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _gradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _logoSection(),
                  const SizedBox(height: 20),
                  _formCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB23CFF), Color(0xFF6A00F4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _logoSection() {
    return Column(
      children: const [
        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.white,
          child: Icon(Icons.pets, color: Color(0xFF6A00F4), size: 40),
        ),
        SizedBox(height: 10),
        Text("PetLodge", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        Text("Hotel de Mascotas", style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _formCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Crear Cuenta", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Completa tus datos para registrarte", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          _input(_nameController, "Nombre completo", Icons.person),
          const SizedBox(height: 12),
          _input(_emailController, "Email", Icons.email),
          const SizedBox(height: 12),
          _input(_phoneController, "Teléfono", Icons.phone),
          const SizedBox(height: 12),
          _input(_passwordController, "Contraseña", Icons.lock, isPassword: true),
          const SizedBox(height: 12),
          _input(_confirmPasswordController, "Confirmar contraseña", Icons.lock_outline, isPassword: true),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB23CFF), Color(0xFF6A00F4)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Registrarse", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text.rich(
                TextSpan(
                  text: "¿Ya tienes cuenta? ",
                  children: [
                    TextSpan(
                      text: "Inicia sesión",
                      style: TextStyle(color: Color(0xFF6A00F4), fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
