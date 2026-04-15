import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../pets/pets_page.dart';
import '../history/history_page.dart'; 
import '../notifications/notifications_page.dart';
import '../profile/profile_page.dart';
import '../history/create_reservation_page.dart';
import '../../../services/auth_service.dart'; 

class HomePage extends StatefulWidget {
  final String userName;

  const HomePage({super.key, required this.userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _currentName = "";
  List<dynamic> _activeReservations = [];
  List<dynamic> _pets = [];
  bool _isLoading = true;

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return "--";

    final value = rawDate.toString();
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    return '$day/$month/$year';
  }

  String? _getDateRangePart(Map<String, dynamic> reservation, {required bool isStart}) {
    final rangeRaw = reservation["date"] ??
        reservation["date_range"] ??
        reservation["reservation_date"];

    if (rangeRaw == null) return null;

    final parts = rangeRaw.toString().split(' - ');
    if (parts.length < 2) return null;

    return isStart ? parts.first.trim() : parts.last.trim();
  }

  String _getCheckInDate(Map<String, dynamic> reservation) {
    final raw = reservation["checkIn"] ??
        reservation["check_in"] ??
        reservation["fecha_ingreso"] ??
        reservation["start_date"] ??
        reservation["startDate"] ??
        reservation["start"] ??
        reservation["start date"] ??
        reservation["fechaInicio"] ??
        _getDateRangePart(reservation, isStart: true);

    return _formatDate(raw);
  }

  String _getCheckOutDate(Map<String, dynamic> reservation) {
    final raw = reservation["checkOut"] ??
        reservation["check_out"] ??
        reservation["fecha_salida"] ??
        reservation["end_date"] ??
        reservation["endDate"] ??
        reservation["end"] ??
        reservation["end date"] ??
        reservation["fechaSalida"] ??
        _getDateRangePart(reservation, isStart: false);

    return _formatDate(raw);
  }

  @override
  void initState() {
    super.initState();
    _currentName = widget.userName;
    _refreshDashboard();
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoading = true);

    try {
      // Verificar si el usuario está autenticado
      final isAuth = await AuthService.isAuthenticated();
      if (!isAuth) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }

      // Obtener Dio con user_id en headers
      final dio = await AuthService.getDioWithAuth();

      final userRes = await dio.get('/users/me');
      final historyRes = await dio.get('/reservations/history');
      final petsRes = await dio.get('/pets');

      if (mounted) {
        setState(() {
          _currentName = userRes.data['nombre'] ?? widget.userName;
          _activeReservations = (historyRes.data as List)
              .where((r) => r["status"] == "Activa")
              .toList();
          _pets = petsRes.data as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando dashboard: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF6A00F4),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) return;

          Widget nextStep;
          if (index == 1) nextStep = const PetsPage();
          else if (index == 2) nextStep = const HistoryPage();
          else if (index == 3) nextStep = const NotificationsPage();
          else nextStep = const ProfilePage();

          Navigator.push(context, MaterialPageRoute(builder: (_) => nextStep))
              .then((_) => _refreshDashboard());
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: "Mascotas"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historial"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Alertas"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: const Color(0xFF6A00F4),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatsRow(),
              const SizedBox(height: 20),
              _buildSectionTitle("Reservas Activas"),
              const SizedBox(height: 8),
              _buildReservationsList(),
              const SizedBox(height: 20),
              _buildSectionTitle("Acciones Rápidas"),
              const SizedBox(height: 10),
              _buildQuickActions(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB23CFF), Color(0xFF6A00F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Hola,", style: TextStyle(color: Colors.white70)),
          Text(
            _currentName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _statCard(Icons.pets, _pets.length.toString(), "Mis Mascotas")),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.calendar_today, _activeReservations.length.toString(), "Reservas Activas")),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String number, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6A00F4)),
          const SizedBox(height: 10),
          Text(number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildReservationsList() {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(color: Color(0xFF6A00F4)),
      ));
    }

    if (_activeReservations.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("No tienes reservas activas")),
      );
    }

    return Column(
      children: _activeReservations.map((r) => _reservationCard(r)).toList(),
    );
  }

  Widget _reservationCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEDE7F6),
                child: Icon(Icons.pets, color: Color(0xFF6A00F4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r["name"] ?? "Mascota", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("${r["type"]} • ${r["room"]}", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("Activa", style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Check-in: ${_getCheckInDate(r)}", style: const TextStyle(fontSize: 12)),
              Text("Check-out: ${_getCheckOutDate(r)}", style: const TextStyle(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReservationPage(
                  onCreate: (_) => _refreshDashboard(),
                )));
              },
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB23CFF), Color(0xFF6A00F4)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white),
                      SizedBox(height: 4),
                      Text(
                        "Nueva Reserva",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PetsPage()));
              },
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pets, color: Color(0xFF6A00F4)),
                      SizedBox(height: 4),
                      Text("Mis Mascotas"),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
