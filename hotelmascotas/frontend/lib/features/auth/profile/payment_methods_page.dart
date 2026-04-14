import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../services/auth_service.dart'; 

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  // Lista dinámica que vendrá del servidor
  List<dynamic> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  // LEER TARJETAS
  Future<void> _fetchCards() async {
    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.get('/payments/methods');
      if (response.statusCode == 200) {
        setState(() {
          _cards = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // AGREGAR TARJETA
  Future<void> _addCard() async {
    // Simulamos la entrada de datos por ahora
    String nuevoNumero = "**** ${1000 + _cards.length + 1}";
    
    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.post(
        '/payments/methods',
        data: {"numero": nuevoNumero},
      );
      if (response.statusCode == 200) {
        _fetchCards(); // Refrescamos la lista
      }
    } catch (e) {
      debugPrint("Error al agregar: $e");
    }
  }

  // ELIMINAR TARJETA
  Future<void> _removeCard(int id) async {
    try {
      final dio = await AuthService.getDioWithAuth();
      final response = await dio.delete('/payments/methods/$id');
      if (response.statusCode == 200) {
        _fetchCards(); // Refrescamos la lista
      }
    } catch (e) {
      debugPrint("Error al eliminar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Métodos de Pago"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return ListTile(
                      leading: const Icon(Icons.credit_card, color: Colors.purple),
                      title: Text(card['numero']),
                      subtitle: Text(card['marca'] ?? "Tarjeta"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeCard(card['id']),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _addCard,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Agregar Nueva Tarjeta", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
    );
  }
}