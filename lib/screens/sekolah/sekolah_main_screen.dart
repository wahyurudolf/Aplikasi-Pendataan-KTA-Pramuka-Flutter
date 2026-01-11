import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'views/sekolah_home_view.dart';

class SekolahMainScreen extends StatelessWidget {
  const SekolahMainScreen({super.key});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AuthService().signOut();
            },
            child: const Text("Ya, Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Sekolah"),
        backgroundColor: Colors.brown[50],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: () => _confirmLogout(context)
          )
        ],
      ),
      // Memanggil View Utama
      body: const SekolahHomeView(),
    );
  }
}