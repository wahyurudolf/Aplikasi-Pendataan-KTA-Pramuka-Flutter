import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import 'views/korlap_school_view.dart';
import 'views/assignment_view.dart';
import 'views/korlap_approval_view.dart';

class KorlapMainScreen extends StatefulWidget {
  const KorlapMainScreen({super.key});

  @override
  State<KorlapMainScreen> createState() => _KorlapMainScreenState();
}

class _KorlapMainScreenState extends State<KorlapMainScreen> {
  int _selectedIndex = 0;
  
  // Data Profil Korlap
  Map<String, dynamic>? _korlapData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKorlapProfile();
  }

  Future<void> _loadKorlapProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _korlapData = doc.data();
        _isLoading = false;
      });
    }
  }

  void _logout() async {
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Halaman-halaman Korlap
    final List<Widget> pages = [
      KorlapSchoolView(korlapData: _korlapData!), // Menu Sekolah Binaan
      AssignmentView(korlapData: _korlapData!),   // Menu Penugasan Staff
    ];

    final List<String> titles = ["Sekolah Binaan", "Tugas Pendataan"];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        backgroundColor: Colors.purple[800], // Warna khas Korlap
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.purple[800]),
              accountName: Text(_korlapData?['nama_lengkap'] ?? "Korlap"),
              accountEmail: Text("Wilayah: ${_korlapData?['kwarcab'] ?? '-'}"), // Info Wilayah
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, color: Colors.purple)),
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text("Sekolah Binaan"),
              selected: _selectedIndex == 0,
              onTap: () { setState(() => _selectedIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text("Tugas Staff"),
              selected: _selectedIndex == 1,
              onTap: () { setState(() => _selectedIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
                leading: Icon(Icons.verified, color: Colors.brown),
                title: Text("Approval Data"),
                trailing: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text("!", style: TextStyle(color: Colors.white, fontSize: 10)), // Bisa diganti jumlah pending
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KorlapApprovalScreen()));
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Keluar", style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
    );
  }
}