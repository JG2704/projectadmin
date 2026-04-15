import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../services/auth_service.dart';

import 'edit_profile_page.dart';
import 'help_page.dart';
import 'terms_page.dart';
import 'privacy_page.dart';
import 'payment_methods_page.dart';
import 'settings_page.dart';
import '../pets/pets_page.dart';
import '../history/history_page.dart'; 
import '../notifications/notifications_page.dart';
import '../home/home_page.dart';
import '../login/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Variables de estado para controlar la red
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Ejecutamos la llamada a la API apenas se crea la pantalla
    _fetchUserProfile();
  }

  // Método asíncrono para traer los datos del backend
  Future<void> _fetchUserProfile() async {
    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.get('/users/me');

      if (response.statusCode == 200) {
        setState(() {
          _userData = response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = "Error al conectar con el servidor";
        _isLoading = false;
      });
      debugPrint("Error de red: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mi Perfil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Gestiona tu cuenta",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Mostrar estado de carga, error o la Card de Usuario
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator(color: Colors.purple)),
              )
            else if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              )
            else if (_userData != null)
              _buildUserCard(_userData!),

            const SizedBox(height: 20),

            // Opciones
            _buildOption(
              context,
              icon: Icons.person,
              title: "Información Personal",
              subtitle: "Editar perfil y datos",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()));
              },
            ),

            _buildOption(
              context, 
              icon: Icons.credit_card, 
              title: "Métodos de Pago", 
              subtitle: "Gestionar tarjetas", 
              onTap: () {
                // Verificamos que los datos ya hayan cargado para evitar errores de nulo
                if (_userData != null && _userData!['id'] != null) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (_) => PaymentMethodsPage(
                        userId: _userData!['id'], // <-- Aquí pasamos el ID real del usuario
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Cargando datos del usuario...")),
                  );
                }
              },
            ),

            _buildOption(
              context,
              icon: Icons.settings,
              title: "Configuración",
              subtitle: "Preferencias de la app",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()));
              },
            ),

            _buildOption(
              context,
              icon: Icons.help_outline,
              title: "Ayuda y Soporte",
              subtitle: "Preguntas frecuentes",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HelpPage()));
              },
            ),

            const SizedBox(height: 20),

            // Estadísticas
            if (_userData != null)
              _buildStats(_userData!['stats'] ?? {}), // Asumiendo que el backend envía un campo 'stats' con la info relevante

            const SizedBox(height: 20),

            // Legal
            _buildOption(
              context,
              icon: Icons.description,
              title: "Términos y Condiciones",
              subtitle: "",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const TermsPage()));
              },
            ),

            _buildOption(
              context,
              icon: Icons.privacy_tip,
              title: "Política de Privacidad",
              subtitle: "",
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PrivacyPage()));
              },
            ),

            const SizedBox(height: 20),

            // Cerrar sesión
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar Sesión"),
                onPressed: () {

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()), // Se limpia la login page
                  (route) => false, // Esta condición 'false' le dice a Flutter: "Borra todo lo que había antes"
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Sesión cerrada correctamente")),
                );
              },
              ),
            ),

            const SizedBox(height: 20),

            const Text("Versión 1.0.0", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage(userName: "Usuario")));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetsPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
          } 
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: "Mascotas"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historial"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alertas"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),
    );
  }

  // Ahora recibe un Map dinámico con la data de la API en lugar de ser estático
  Widget _buildUserCard(Map<String, dynamic> user) {
    // Tomamos la inicial del nombre para el Avatar
    String iniciales = user['nombre'] != null && user['nombre'].toString().isNotEmpty 
        ? user['nombre'].toString().substring(0, 1).toUpperCase() 
        : "U";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
               CircleAvatar(
                radius: 30,
                backgroundColor: Colors.purple,
                child: Text(iniciales, style: const TextStyle(color: Colors.white, fontSize: 20)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['nombre'] ?? 'Sin nombre',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text("Cliente"),
                    const SizedBox(height: 10),
                    Text(user['email'] ?? 'Sin email'),
                    Text(user['telefono'] ?? 'Sin teléfono'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: Icon(icon, color: Colors.purple),
          title: Text(title),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  // Widget de estadísticas ahora recibe datos dinámicos
  Widget _buildStats(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tu actividad en PetLodge", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatCard(title: "Reservas", value: (stats['reservas'] ?? 0).toString()),
              _StatCard(title: "Mascotas", value: (stats['mascotas'] ?? 0).toString()),
              _StatCard(title: "Noches", value: (stats['dias'] ?? 0).toString()),
            ],
          )
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.purple,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}