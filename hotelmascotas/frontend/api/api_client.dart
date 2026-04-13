import 'package:dio/dio.dart';

class ApiClient {
  // Configuramos Dio con la URL base de nuestro servidor local
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:8000', // La IP puente del emulador Android
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // Ejemplo de cómo se verá la función que llamará tu login_page.dart
  Future<Response?> loginUser(String email, String password) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response;
    } on DioException catch (e) {
      // Dio maneja los errores HTTP (como un 401 Unauthorized) muy limpio
      print('Error de conexión: ${e.message}');
      if (e.response != null) {
        print('Respuesta del servidor: ${e.response?.data}');
      }
      return null;
    }
  }
}