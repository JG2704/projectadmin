import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../home/home_page.dart';
import 'reservation_detail_page.dart';
import 'create_reservation_page.dart';
import '../pets/pets_page.dart';
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int selectedTab = 0;
  
  // Variables para el manejo de la API
  List<dynamic> _allReservations = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // MÉTODO PARA TRAER EL HISTORIAL DEL BACKEND
  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final dio = Dio();
      // Llamamos al endpoint que preparamos en Python
      final response = await dio.get('http://10.0.2.2:8000/reservations/history');

      if (response.statusCode == 200) {
        setState(() {
          _allReservations = response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = "No se pudo conectar con el hotel";
        _isLoading = false;
      });
      debugPrint("Error de historial: ${e.message}");
    }
  }

  // FILTRO DINÁMICO (Ahora sobre la data de la API)
  List<dynamic> get filteredReservations {
    String statusToFilter = "";
    if (selectedTab == 0) statusToFilter = "Activa";
    else if (selectedTab == 1) statusToFilter = "Completada";
    else statusToFilter = "Cancelada";

    return _allReservations.where((r) => r["status"] == statusToFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // BOTÓN FLOTANTE (Con actualización automática al volver)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateReservationPage(
                onCreate: (newRes) {
                  // Cuando se crea una reserva, refrescamos todo desde el servidor
                  _fetchHistory();
                },
              ),
            ),
          );
        },
      ),

      appBar: AppBar(
        title: const Text("Historial de Reservas"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
          )
        ],
      ),

      body: Column(
        children: [
          // TABS DE FILTRO
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _tabItem(0, "Activas"),
                _tabItem(1, "Pasadas"),
                _tabItem(2, "Canceladas"),
              ],
            ),
          ),

          // CONTENIDO PRINCIPAL CON REFRESH
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchHistory,
              color: Colors.purple,
              child: _buildListContent(),
            ),
          ),
        ],
      ),

      // NAVBAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage(userName: "Usuario", userId: 0)));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PetsPage()));
          } else if (index == 2) {
            // Ya estamos aquí
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
    );
  }

  // MANEJO DE ESTADOS DE LA LISTA
  Widget _buildListContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purple));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 10),
            Text(_errorMessage),
            TextButton(onPressed: _fetchHistory, child: const Text("Reintentar"))
          ],
        ),
      );
    }

    final list = filteredReservations;

    if (list.isEmpty) {
      return ListView( // Usamos ListView para que el RefreshIndicator funcione aunque esté vacío
        children: const [
          SizedBox(height: 100),
          Center(child: Text("No hay reservas en esta categoría.")),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: list.length,
      itemBuilder: (context, index) => _reservationCard(list[index]),
    );
  }

  Widget _tabItem(int index, String label) {
    bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _reservationCard(Map<String, dynamic> r) {
    // Definimos el color según el estado
    Color statusColor = Colors.green;
    if (r["status"] == "Cancelada") statusColor = Colors.red;
    if (r["status"] == "Completada") statusColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.hotel, color: Colors.white),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r["name"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${r["room"]} • ${r["type"]}"),
                    Text(r["date"], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r["status"], 
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                ),
              )
            ],
          ),
          const Divider(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total: ${r["total"]}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.purple),
                onPressed: () async {
                  // Al volver de detalles, refrescamos por si hubo cancelaciones
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReservationDetailPage(reservation: r),
                    ),
                  );
                  _fetchHistory();
                },
                child: const Text("Ver detalles"),
              )
            ],
          )
        ],
      ),
    );
  }
}