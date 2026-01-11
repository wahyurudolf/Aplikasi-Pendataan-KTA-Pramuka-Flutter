import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
// Import semua dashboard
import 'screens/admin/admin_main_screen.dart';
import 'screens/korlap/korlap_main_screen.dart';
import 'screens/staff_pendataan/staff_pendataan_main_sreen.dart';
import 'screens/sekolah/sekolah_main_screen.dart';
import 'screens/dashboard/produksi_dashboard.dart';

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Jika sedang loading status login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Jika user BELUM login -> Tampilkan Login Screen
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 3. Jika user SUDAH login -> Cek Role di Firestore
        User user = snapshot.data!;
        return FutureBuilder<String>(
          future: authService.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            String role = roleSnapshot.data ?? 'sekolah';

            // 4. Arahkan sesuai Role (Switch Case)
            switch (role) {
              case 'super_admin':
                return const AdminMainScreen();
              case 'korlap':
                return const KorlapMainScreen();
              case 'staff_pendataan':
                return const StaffPendataanMainScreen();
              case 'produksi':
                return const ProduksiDashboard();
              case 'sekolah':
              default:
                return const SekolahMainScreen();
            }
          },
        );
      },
    );
  }
}