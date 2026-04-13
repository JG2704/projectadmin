import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;
  bool location = true;

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cache eliminado")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configuración"), backgroundColor: Colors.purple, foregroundColor: Colors.white),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Notificaciones"),
            value: notifications,
            onChanged: (value) {
              setState(() {
                notifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text("Ubicación"),
            value: location,
            onChanged: (value) {
              setState(() {
                location = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Eliminar cache"),
            onTap: _clearCache,
          )
        ],
      ),
    );
  }
}