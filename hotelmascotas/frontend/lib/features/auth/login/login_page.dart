import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../register/register_page.dart';
import '../home/home_page.dart';
import '../../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Método login - AHORA LLAMA A LA API REAL
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Por favor completa todos los campos");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = Dio();
      
      // Llamada real a la API del backend
      final response = await dio.post(
        'http://10.0.2.2:8000/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Extraer datos de la respuesta
        final token = response.data['token']; // Ej: "token_user_1"
        final userType = response.data['id_tipo_usuario']; // 1 = cliente, 2 = admin

        // Extraer el user ID del token (formato: "token_user_X")
        final userId = int.parse(token.split('_').last);
        
        // Guardar user ID y token en almacenamiento local
        await AuthService.saveUserId(userId);
        await AuthService.saveToken(token);

        // Obtener nombre del usuario de la respuesta o usar email
        final userName = email.split('@').first;

        if (mounted) {
          // Navegar a HomePage con los datos del usuario
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(userName: userName),
            ),
          );
        }
      }
    } on DioException catch (e) {
      String errorMsg = "Error de conexión";
      
      if (e.response != null) {
        // Error del servidor (401, 400, etc.)
        if (e.response?.statusCode == 401) {
          errorMsg = "Credenciales incorrectas";
        } else {
          errorMsg = e.response?.data['detail'] ?? "Error en el servidor";
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = "Conexión expirada. ¿Backend está encendido?";
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = "Servidor tardó demasiado en responder";
      }
      
      if (mounted) {
        _showMessage(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        _showMessage("Error inesperado: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF7B1FA2),
              Color(0xFF9C27B0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),

            // Logo
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.white,
              child: Icon(Icons.pets, size: 40, color: Colors.purple),
            ),

            const SizedBox(height: 20),

            const Text(
              "PetLodge",
              style: TextStyle(
                fontSize: 28,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              "Hotel de Mascotas",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 40),

            // Card blanca
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Bienvenido",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text("Inicia sesión para continuar"),

                    const SizedBox(height: 20),

                    // EMAIL
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // PASSWORD
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BOTÓN LOGIN
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text("Iniciar Sesión"),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // NAVEGACIÓN A REGISTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("¿No tienes cuenta? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Regístrate",
                            style: TextStyle(color: Colors.purple),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}