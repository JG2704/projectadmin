import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class PaymentMethodsPage extends StatefulWidget {
  final int userId; // <-- Recibimos el ID desde el Perfil

  const PaymentMethodsPage({super.key, required this.userId});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<dynamic> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'http://10.0.2.2:8000/payments/methods',
        options: Options(headers: {'X-User-Id': widget.userId}),
      );
      if (mounted) {
        setState(() {
          _cards = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addCard() async {
    try {
      final dio = Dio();
      await dio.post(
        'http://10.0.2.2:8000/payments/methods',
        options: Options(headers: {'X-User-Id': widget.userId}),
        data: {"numero": "**** 9999"}, // Simulación de nueva tarjeta
      );
      _fetchCards(); // Refrescamos
    } catch (e) {
      debugPrint("Error al agregar: $e");
    }
  }

  Future<void> _removeCard(int id) async {
    try {
      final dio = Dio();
      await dio.delete(
        'http://10.0.2.2:8000/payments/methods/$id',
        options: Options(headers: {'X-User-Id': widget.userId}),
      );
      _fetchCards();
    } catch (e) {
      debugPrint("Error al eliminar: $e");
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Método de Pago Actual")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: _cards.isEmpty 
                  ? const Center(child: Text("No has seleccionado un método de pago."))
                  : ListView.builder(
                      itemCount: _cards.length,
                      itemBuilder: (context, index) {
                        final card = _cards[index];
                        return ListTile(
                          leading: const Icon(Icons.credit_card, color: Colors.purple),
                          title: Text(card['numero'] ?? "Método Activo"),
                          subtitle: Text(card['marca'] ?? ""),
                          trailing: TextButton(
                            onPressed: () => _removeCard(card['id']),
                            child: const Text("Quitar", style: TextStyle(color: Colors.red)),
                          ),
                        );
                      },
                    ),
              ),
              
              // 🔥 LA LÓGICA: Solo permitimos agregar si la lista está vacía (o tiene 0 tarjetas)
              if (_cards.isEmpty) 
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: _addCard,
                    child: const Text("Vincular Tarjeta Visa"),
                  ),
                ),
            ],
          ),
    );
  }
}