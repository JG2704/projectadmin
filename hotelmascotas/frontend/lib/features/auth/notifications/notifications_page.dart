import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../home/home_page.dart';
import '../pets/pets_page.dart';
import '../history/history_page.dart'; 
import '../profile/profile_page.dart';
import '../../../services/auth_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Estado para la API
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // MÉTODO PARA TRAER LAS NOTIFICACIONES DEL BACKEND
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.get('/notifications');

      if (response.statusCode == 200) {
        setState(() {
          _notifications = response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = "Error al cargar las notificaciones";
        _isLoading = false;
      });
      debugPrint("Error de red: ${e.message}");
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final dio = await AuthService.getDioWithAuth();
      await dio.patch('/notifications/read-all');

      if (!mounted) return;

      setState(() {
        _notifications.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todas las notificaciones fueron marcadas como leídas")),
      );
    } on DioException catch (e) {
      debugPrint("Error al marcar notificaciones como leídas: ${e.message}");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudieron marcar las notificaciones")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Mis Alertas"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Bandeja limpia")),
                );
                setState(() {
                  _notifications.clear();
                });
              },
              child: const Center(
                child: Text(
                  "Marcar Todas",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),

      // REFRESH INDICATOR PARA EL MODELO "PULL"
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: Colors.purple,
        child: _buildBodyContent(),
      ),

      // NAVBAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // <-- Alertas
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage(userName: "Usuario")));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetsPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
          } else if (index == 3) {
            // Ya estamos aquí
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
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purple));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            TextButton(
              onPressed: _fetchNotifications,
              child: const Text("Reintentar"),
            )
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return ListView( // ListView permite que el RefreshIndicator funcione aunque esté vacío
        children: const [
          SizedBox(height: 150),
          Center(
            child: Column(
              children: [
                Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                SizedBox(height: 15),
                Text("No tienes notificaciones nuevas", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      physics: const AlwaysScrollableScrollPhysics(), // Obliga al scroll para el RefreshIndicator
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        return _notificationCard(_notifications[index]);
      },
    );
  }

  Widget _notificationCard(Map<String, dynamic> n) {
    Color borderColor;
    IconData icon;

    switch (n["type"]) {
      case "reserva":
        borderColor = Colors.purple;
        icon = Icons.calendar_today;
        break;
      case "update":
        borderColor = Colors.blue;
        icon = Icons.pets;
        break;
      case "recordatorio":
        borderColor = Colors.green;
        icon = Icons.notifications;
        break;
      case "mascota":
        borderColor = Colors.orange;
        icon = Icons.pets;
        break;
      default:
        borderColor = Colors.grey;
        icon = Icons.settings;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 3))
        ]
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: borderColor,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n["title"] ?? "Alerta",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(n["message"] ?? "", style: TextStyle(color: Colors.grey[800])),
                const SizedBox(height: 8),
                Text(
                  n["time"] ?? "",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}