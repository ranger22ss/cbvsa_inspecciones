import 'package:flutter/material.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administración')),
      body: const Center(
        child: Text('Gestión de plantillas (solo admin) — próximamente'),
      ),
    );
  }
}
