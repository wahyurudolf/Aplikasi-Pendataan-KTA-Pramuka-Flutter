import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await AuthService().signIn(
        _emailController.text.trim(),
        _passController.text.trim(),
      );
      // Login sukses, wrapper akan memindahkan halaman otomatis
    } catch (e) {
      // PERBAIKAN DI SINI:
      // Kita cek dulu: "Apakah halaman ini masih nempel di layar (mounted)?"
      if (!mounted) return; 

      // Kalau masih mounted, baru aman panggil context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal Login: ${e.toString()}")),
      );
    } finally {
      // Cek mounted lagi sebelum setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: Colors.brown),
            const SizedBox(height: 20),
            const Text("SISTEM KTA PRAMUKA", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(
                labelText: "Password", border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("MASUK", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}