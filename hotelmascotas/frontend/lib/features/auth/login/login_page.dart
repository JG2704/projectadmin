import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../register/register_page.dart';
import '../home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Método login
// Variable para controlar si mostramos la bolita de carga
  bool _isLoading = false;

  // Método login
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Por favor completa todos los campos");
      return;
    }

    // Cambiamos el estado para mostrar que está cargando
    setState(() {
      _isLoading = true;
    });

    try {
      final dio = Dio();
      
      // Hacemos la petición al servidor de Python
      final response = await dio.post(
        'http://10.0.2.2:8000/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Si el servidor responde con éxito (Status 200)
if (response.statusCode == 200) {
        final userData = response.data;
        
        // 🔥 Declaramos las variables locales para usarlas abajo
        final String nombreUsuario = userData['nombre'] ?? "Usuario";
        final int idUsuario = userData['user_id']; 

        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              userName: nombreUsuario, 
              userId: idUsuario, // <--- Ahora sí tiene el valor definido arriba
            ),
          ),
        );
      }
    } on DioException catch (e) {
      // Manejo de errores de red o credenciales incorrectas
      if (e.response != null && e.response?.statusCode == 401) {
        _showMessage("Correo o contraseña incorrectos");
      } else {
        _showMessage("Error al conectar con el servidor");
      }
      debugPrint("Error de red: ${e.message}");
    } finally {
      // Sin importar si falló o tuvo éxito, quitamos el estado de carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

            // Card blanca solo para los formularios
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Bienvenido",
                      style: TextStyle(
                        fontSize: 22,
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Inicia sesión para continuar",
                      style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                    ),

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
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Iniciar Sesión", style: TextStyle(color: Colors.white)),
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
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Regístrate",
                            style: TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
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