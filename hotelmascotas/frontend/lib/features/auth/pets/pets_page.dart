import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../home/home_page.dart';
import 'add_pet_form.dart';
import '../../../models/pet_model.dart';
import 'pet_detail_page.dart';
import '../history/history_page.dart'; 
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../../../services/auth_service.dart';

class PetsPage extends StatefulWidget {
  const PetsPage({super.key});

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {

  // La lista ahora inicia vacía porque esperará los datos del servidor
  List<Pet> pets = [];
  
  // Variables para controlar el estado de la pantalla
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Llamamos al backend apenas se abre la pantalla
    _fetchPets();
  }

// Método para traer las mascotas de Python
  Future<void> _fetchPets() async {
    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.get('/pets');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        setState(() {
          pets = data
              .map((item) => Pet.fromBackend(Map<String, dynamic>.from(item)))
              .toList();

          _isLoading = false;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _errorMessage = "No se pudieron cargar las mascotas";
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = "Error al conectar con el servidor";
        _isLoading = false;
      });
      debugPrint("Error de red: ${e.message}");
    } catch (e) {
      setState(() {
        _errorMessage = "Error inesperado al cargar mascotas";
        _isLoading = false;
      });
      debugPrint("Error inesperado: $e");
    }
  }

  //  ABRIR MODAL Y RECIBIR DATOS
  void _showAddPetModal(BuildContext context) async {
    final newPet = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const AddPetForm(),
        );
      },
    );

    // aquí haremos un POST a la API para guardarla en la base de datos
    if (newPet != null) {
      setState(() {
        pets.add(newPet);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      //  NAVBAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // <-- Index correcto para Mascotas
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
          } else if (index == 4) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
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

      appBar: AppBar(
        toolbarHeight: 72,
        foregroundColor: Colors.white,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mis Mascotas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 2),
            Text(
              "Gestiona tus mascotas",
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
      ),

      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // BOTÓN AGREGAR (Siempre visible)
            GestureDetector(
              onTap: () {
                _showAddPetModal(context);
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.deepPurple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    "+ Agregar Nueva Mascota",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // Mostrar Cargando, Error o la Lista
            Expanded(
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
    );
  }

  // Función auxiliar para decidir qué pintar en pantalla
  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purple));
    } 
    
    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)));
    }
    
    if (pets.isEmpty) {
      return const Center(child: Text("Aún no tienes mascotas registradas."));
    }

    // LISTA DINÁMICA
    return ListView.builder(
      itemCount: pets.length,
      itemBuilder: (context, index) {
        return _petCard(pets[index]);
      },
    );
  }

  //  CARD CLICKEABLE
  Widget _petCard(Pet pet) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetDetailPage(pet: pet),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.pets, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text("${pet.type} • ${pet.breed}"),
                  Text("Edad: ${pet.age} años", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _detailTag("Vacunas: ${pet.vaccines}"),
                      _detailTag("Alergias: ${pet.allergies}"),
                      _detailTag("Dieta: ${pet.diet}"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF6A1B9A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}