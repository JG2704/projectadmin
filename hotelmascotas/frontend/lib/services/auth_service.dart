import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// Obtiene una instancia de Dio con el user_id en los headers
  static Future<Dio> getDioWithAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    return Dio(
      BaseOptions(
        baseUrl: 'http://10.0.2.2:8000',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          if (userId != null) 'X-User-Id': userId.toString(),
        },
      ),
    );
  }

  /// Obtiene el user_id del almacenamiento local
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  /// Guarda el user_id en almacenamiento local
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  /// Guarda el token en almacenamiento local
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  /// Obtiene el token del almacenamiento local
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Limpia la sesión (logout)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('token');
  }

  /// Verifica si el usuario está autenticado
  static Future<bool> isAuthenticated() async {
    final userId = await getUserId();
    return userId != null;
  }
}
