import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';

// IMPORT VIEWS
import 'views/staff_pendataan_task_view.dart';
import 'views/school_explorer_view.dart';

class StaffPendataanMainScreen extends StatefulWidget {
  const StaffPendataanMainScreen({super.key});

  @override
  State<StaffPendataanMainScreen> createState() => _StaffPendataanMainScreenState();
}

class _StaffPendataanMainScreenState extends State<StaffPendataanMainScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _staffData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffProfile();
  }

  Future<void> _loadStaffProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _staffData = doc.data();
          _isLoading = false;
        });
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final List<Widget> pages = [
      StaffPendataanTaskView(staffId: FirebaseAuth.instance.currentUser!.uid),
      SchoolExplorerView(kwarcabId: _staffData?['kwarcab_id']),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "Tugas Saya" : "Jelajah Sekolah"),
        backgroundColor: Colors.brown[100],
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout)
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown[800],
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Tugas"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Semua Sekolah"),
        ],
      ),
    );
  }
}