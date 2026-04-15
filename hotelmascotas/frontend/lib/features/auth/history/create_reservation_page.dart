import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../notifications/notifications_data.dart';
import '../../../services/auth_service.dart';

class CreateReservationPage extends StatefulWidget {
  final Function(Map<String, dynamic>)? onCreate;

  const CreateReservationPage({super.key, this.onCreate});

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  // Pet list from backend
  List<dynamic> _myPets = [];
  String? _selectedPetName;
  bool _isLoadingPets = true;

  // Room list from backend (only disponible rooms)
  List<String> _availableRooms = [];
  String? _selectedRoom;
  bool _isLoadingRooms = true;

  String _selectedType = "Estándar";
  DateTimeRange? _selectedDates;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMyPets();
    _fetchRooms();
  }

  Future<void> _fetchMyPets() async {
    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.get('/pets');
      if (response.statusCode == 200) {
        setState(() {
          _myPets = response.data;
          _isLoadingPets = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando mascotas: $e");
      setState(() => _isLoadingPets = false);
    }
  }

  /// Fetch available rooms from the backend and build "Habitación XXX" labels.
  Future<void> _fetchRooms() async {
    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.get('/rooms');
      if (response.statusCode == 200) {
        final rooms = (response.data as List)
            .where((r) => r['estado'] == 'disponible')
            .map<String>((r) => 'Habitación ${r['numero']}')
            .toList();
        setState(() {
          _availableRooms = rooms;
          _selectedRoom = rooms.isNotEmpty ? rooms.first : null;
          _isLoadingRooms = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando habitaciones: $e");
      setState(() => _isLoadingRooms = false);
    }
  }

  Future<void> _submitReservation() async {
    if (_selectedPetName == null || _selectedRoom == null || _selectedDates == null) {
      _showMessage("Por favor, selecciona una mascota, habitación y fechas");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = await AuthService.getDioWithAuth();

      final Map<String, dynamic> reservationData = {
        "name": _selectedPetName,
        "room": _selectedRoom,
        "type": _selectedType,
        "fecha_ingreso": _selectedDates!.start.toIso8601String(),
        "fecha_salida": _selectedDates!.end.toIso8601String(),
      };

      final response = await dio.post('/reservations', data: reservationData);

      if (response.statusCode == 200) {
        final responseData = response.data;

        notifications.insert(0, {
          "type": "reserva",
          "title": "Reserva confirmada",
          "message": "Reserva creada para $_selectedPetName.",
          "time": "Ahora",
        });

        widget.onCreate?.call(responseData);

        if (!mounted) return;
        _showMessage("¡Reserva confirmada con éxito!");
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? "Error al conectar con el servidor";
      _showMessage(detail);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool stillLoading = _isLoadingPets || _isLoadingRooms;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Nueva Reserva"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: stillLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  // Pet dropdown
                  _card(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPetName,
                        hint: const Text("Selecciona tu mascota"),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.pets, color: Colors.purple),
                          border: InputBorder.none,
                        ),
                        items: _myPets.map((pet) {
                          return DropdownMenuItem<String>(
                            value: pet['nombre'] as String,
                            child: Text(pet['nombre'] as String),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedPetName = v),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Room & type dropdowns
                  _card(
                    child: Column(
                      children: [
                        _availableRooms.isEmpty
                            ? const ListTile(
                                leading: Icon(Icons.hotel, color: Colors.grey),
                                title: Text("Sin habitaciones disponibles"),
                              )
                            : _dropDown(
                                label: "Seleccionar Habitación",
                                value: _selectedRoom!,
                                items: _availableRooms,
                                onChanged: (v) => setState(() => _selectedRoom = v),
                              ),
                        const Divider(),
                        _dropDown(
                          label: "Tipo de Hospedaje",
                          value: _selectedType,
                          items: const ["Estándar", "Especial"],
                          onChanged: (v) => setState(() => _selectedType = v!),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Date picker
                  _card(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today, color: Colors.purple),
                      title: Text(
                        _selectedDates == null
                            ? "Seleccionar Fechas"
                            : "${_selectedDates!.start.day}/${_selectedDates!.start.month} - "
                              "${_selectedDates!.end.day}/${_selectedDates!.end.month}",
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _selectDates,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: (_isLoading || _availableRooms.isEmpty)
                          ? null
                          : _submitReservation,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Confirmar Reserva",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dropDown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _selectDates() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDates = picked);
  }
}
