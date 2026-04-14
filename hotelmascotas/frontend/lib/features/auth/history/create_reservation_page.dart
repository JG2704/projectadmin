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

  // Variables para la lista de mascotas del backend
  List<dynamic> _myPets = [];
  String? _selectedPetName; // Aquí guardaremos la elección del dropdown
  bool _isLoadingPets = true;

  String selectedRoom = "Habitación 101";
  String selectedType = "Estándar";
  DateTimeRange? selectedDates;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargamos las mascotas disponibles apenas se abre la pantalla
    _fetchMyPets();
  }

  // MÉTODO PARA TRAER LAS MASCOTAS DESDE PYTHON
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

  Future<void> _submitReservation() async {
    // Validación: Ahora verificamos _selectedPetName en lugar del controlador
    if (_selectedPetName == null || selectedDates == null) {
      _showMessage("Por favor, selecciona una mascota y las fechas");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dio = await AuthService.getDioWithAuth();

      final Map<String, dynamic> reservationData = {
        "name": _selectedPetName, // Enviamos el nombre seleccionado
        "room": selectedRoom,
        "type": selectedType,
        "fecha_ingreso": selectedDates!.start.toIso8601String(),
        "fecha_salida": selectedDates!.end.toIso8601String(),
      };

      final response = await dio.post(
        '/reservations',
        data: reservationData,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        notifications.insert(0, {
          "type": "reserva",
          "title": "Reserva confirmada",
          "message": "Reserva creada para $_selectedPetName.",
          "time": "Ahora"
        });

        widget.onCreate?.call(responseData);

        if (!mounted) return;
        _showMessage("¡Reserva confirmada con éxito!");
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      _showMessage("Error al conectar con el servidor del hotel");
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Nueva Reserva"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingPets 
        ? const Center(child: CircularProgressIndicator(color: Colors.purple))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                // DROPDOWN DE MASCOTAS (Reemplaza al TextField)
                _card(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPetName,
                      hint: const Text("Selecciona tu mascota"),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.pets, color: Colors.purple),
                        border: InputBorder.none,
                      ),
                      // Generamos los items dinámicamente desde la lista _myPets
                      items: _myPets.map((pet) {
                        return DropdownMenuItem<String>(
                          value: pet['nombre'],
                          child: Text(pet['nombre']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedPetName = value);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // CARD HABITACIÓN Y TIPO
                _card(
                  child: Column(
                    children: [
                      _dropDown(
                        label: "Seleccionar Habitación",
                        value: selectedRoom,
                        items: ["Habitación 101", "Habitación 102", "Habitación 103"],
                        onChanged: (val) => setState(() => selectedRoom = val!),
                      ),
                      const Divider(),
                      _dropDown(
                        label: "Tipo de Hospedaje",
                        value: selectedType,
                        items: ["Estándar", "Premium"],
                        onChanged: (val) => setState(() => selectedType = val!),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // CARD CALENDARIO
                _card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.purple),
                    title: Text(
                      selectedDates == null
                          ? "Seleccionar Fechas"
                          : "${selectedDates!.start.day}/${selectedDates!.start.month} - ${selectedDates!.end.day}/${selectedDates!.end.month}",
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
                    onPressed: _isLoading ? null : _submitReservation,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Confirmar Reserva",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
          )
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
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
    if (picked != null) {
      setState(() => selectedDates = picked);
    }
  }
}