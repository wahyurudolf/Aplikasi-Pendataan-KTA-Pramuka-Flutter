import 'package:flutter/material.dart';
import '/services/auth_service.dart'; // Nanti kita buat ini

class ProduksiDashboard extends StatelessWidget {
  const ProduksiDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Produksi Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(), // Tombol Logout
          )
        ],
      ),
      body: const Center(child: Text("Selamat Datang Produksi")),
    );
  }
}