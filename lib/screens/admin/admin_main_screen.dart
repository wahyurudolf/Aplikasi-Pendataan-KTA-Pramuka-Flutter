import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

// IMPORT PAGES
import 'views/dashboard_stats_view.dart';
import 'views/user_management_view.dart';
import 'views/location_master_view.dart'; 
import 'views/school_master_view.dart';
import 'widgets/add_user_dialog.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  
  // Controller khusus untuk halaman Master Data (Karena dia punya TabBar)
  late TabController _masterDataTabController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi TabController (3 Tabs: Kwarda, Kwarcab, Kwarran)
    _masterDataTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _masterDataTabController.dispose();
    super.dispose();
  }

  // DAFTAR JUDUL SESUAI HALAMAN
  final List<String> _titles = [
    "Dashboard & Statistik",
    "Manajemen User",
    "Master Data Wilayah",
    "Daftar Sekolah", // <--- Tambah ini
  ];

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await AuthService().signOut();
              navigator.pop();
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // DAFTAR HALAMAN (BODY)
    final List<Widget> pages = [
      const DashboardStatsView(),
      const UserManagementView(),
      // Halaman Master Data kita pasang di sini, kirim controller-nya
      LocationMasterContent(tabController: _masterDataTabController),
      const SchoolMasterView(),
    ];

    return Scaffold(
      appBar: AppBar(
        // JUDUL DINAMIS BERDASARKAN INDEX
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        
        // LOGIKA TAB BAR: Hanya muncul jika sedang di halaman Master Data (Index 2)
        bottom: _selectedIndex == 2 
            ? TabBar(
                controller: _masterDataTabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: "Kwarda"),
                  Tab(text: "Kwarcab"),
                  Tab(text: "Kwarran"),
                ],
              )
            : null,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey[900]),
              accountName: const Text("Administrator"),
              accountEmail: Text(FirebaseAuth.instance.currentUser?.email ?? "-"),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.admin_panel_settings, color: Colors.blueGrey)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              selected: _selectedIndex == 0,
              onTap: () { setState(() => _selectedIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Manajemen User"),
              selected: _selectedIndex == 1,
              onTap: () { setState(() => _selectedIndex = 1); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.map), // Icon Peta
              title: const Text("Master Data Wilayah"),
              selected: _selectedIndex == 2,
              onTap: () { setState(() => _selectedIndex = 2); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.school),
              title: const Text("Daftar Sekolah"),
              selected: _selectedIndex == 3,
              onTap: () { setState(() => _selectedIndex = 3); Navigator.pop(context); },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),
      
      body: pages[_selectedIndex],
      
      // Floating Action Button hanya muncul di halaman Manajemen User (index 1)
      floatingActionButton: _selectedIndex == 1 
          ? FloatingActionButton(
              onPressed: () {
                showDialog(context: context, builder: (ctx) => const AddUserDialog());
              }, 
              backgroundColor: Colors.blueGrey[900], 
              child: const Icon(Icons.add, color: Colors.white)
            )
          : null,
    );
  }
}