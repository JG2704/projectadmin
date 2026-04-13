import 'package:flutter/material.dart';
import 'features/auth/login/login_page.dart';
import 'services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await DatabaseHelper.instance.database;

  print(await db.query('usuario'));
  print(await db.query('hotel'));
  print(await db.query('habitacion'));
  print(await db.query('tipo_pago'));
  print(await db.query('tipo_usuario'));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}