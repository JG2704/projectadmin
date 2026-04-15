import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../services/auth_service.dart';

class ReservationDetailPage extends StatefulWidget {
  final Map<String, dynamic> reservation;

  const ReservationDetailPage({
    super.key,
    required this.reservation,
  });

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  bool _isCancelling = false;

  bool get _isCancelled => widget.reservation["status"] == "Cancelada";
  bool get _isCompleted => widget.reservation["status"] == "Completada";

  Color get _statusColor {
    if (_isCancelled) return Colors.red;
    if (_isCompleted) return Colors.orange;
    return Colors.green;
  }

  Future<void> _cancelReservation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cancelar Reserva?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sí, cancelar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      final dio = await AuthService.getDioWithAuth();
      final resId = widget.reservation["id"];
      final response = await dio.patch('/reservations/$resId/cancel');

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reserva cancelada exitosamente")),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (mounted) {
        final detail = e.response?.data?['detail'] ?? "Error al cancelar la reserva";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(detail)));
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.reservation;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _header(res),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                children: [
                  _petCard(res),
                  _infoCard(res),
                  _servicesCard(),
                  _costCard(res),
                  _updatesCard(),
                  if (!_isCancelled && !_isCompleted) _actions(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Map<String, dynamic> res) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB23CFF), Color(0xFF6A00F4)],
        ),
      ),
      child: Row(
        children: [
          // FIX: was a plain Icon — now a tappable back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Detalles de Reserva",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                Text(
                  "#${res["id"] ?? ''}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              res["status"] ?? "",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _petCard(Map<String, dynamic> res) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFEDE7F6),
            child: Icon(Icons.pets, color: Color(0xFF6A00F4)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                res["name"] ?? "Mascota",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "${res["type"]}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard(Map<String, dynamic> res) {
    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Información de Hospedaje",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _rowItem(Icons.location_on, "Habitación", "${res["room"]} - ${res["type"]}"),
          const SizedBox(height: 10),
          _rowItem(Icons.calendar_today, "Fechas", res["date"] ?? ""),
        ],
      ),
    );
  }

  Widget _servicesCard() {
    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Servicios Incluidos", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _ServiceItem("Baño y Grooming"),
          _ServiceItem("Paseos diarios"),
        ],
      ),
    );
  }

  Widget _costCard(Map<String, dynamic> res) {
    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resumen de Costos", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _CostRow("Hospedaje", res["total"] ?? "\$0"),
          const _CostRow("Servicios adicionales", "\$0"),
          const Divider(),
          _CostRow("Total", res["total"] ?? "\$0", isTotal: true),
        ],
      ),
    );
  }

  Widget _updatesCard() {
    return _cardWrapper(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Actualizaciones", style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          _UpdateItem("15 Mar", "Max disfrutó de su paseo."),
          _UpdateItem("14 Mar", "Grooming completado."),
        ],
      ),
    );
  }

  Widget _actions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.grey),
              ),
              onPressed: () {},
              child: const Text("Contactar al Hotel"),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: _isCancelling ? null : _cancelReservation,
              child: _isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                    )
                  : const Text("Cancelar Reserva"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardWrapper(Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: child,
    );
  }

  Widget _rowItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Small helper widgets ───────────────────────────────────────────────────────

class _ServiceItem extends StatelessWidget {
  final String text;
  const _ServiceItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _UpdateItem extends StatelessWidget {
  final String date;
  final String text;
  const _UpdateItem(this.date, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 10, backgroundColor: Color(0xFFEDE7F6)),
          const SizedBox(width: 10),
          Expanded(child: Text("$date • $text")),
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isTotal;

  const _CostRow(this.title, this.value, {this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF6A00F4) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
