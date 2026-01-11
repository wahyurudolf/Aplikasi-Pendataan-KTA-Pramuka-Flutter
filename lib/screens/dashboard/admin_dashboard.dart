import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Index halaman yang aktif (0: Dashboard, 1: Manajemen User)
  int _selectedIndex = 0;

  // --- LOGOUT ---
  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar dari Admin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              // Capture navigator sebelum await
              final navigator = Navigator.of(ctx);
              await AuthService().signOut();
              navigator.pop(); // Gunakan navigator yang sudah di-capture
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI TAMBAH USER ---
  void _showAddUserDialog() {
    // PERBAIKAN 1: Hapus underscore (_) pada variabel lokal
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final namaController = TextEditingController();
    final kotaController = TextEditingController(); 
    final kecamatanController = TextEditingController(); 
    
    String selectedRole = 'sekolah'; // Hapus underscore

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Tambah User Baru"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey, // Gunakan variabel tanpa underscore
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: "Email Login"),
                        validator: (v) => v!.isEmpty ? "Isi Email" : null,
                      ),
                      TextFormField(
                        controller: namaController,
                        decoration: const InputDecoration(labelText: "Nama Lengkap / Nama Sekolah"),
                        validator: (v) => v!.isEmpty ? "Isi Nama" : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        // PERBAIKAN: Gunakan variabel yang sudah direname
                        initialValue: selectedRole, 
                        decoration: const InputDecoration(labelText: "Role Akun"),
                        items: ['sekolah', 'staff'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                        onChanged: (v) => setStateDialog(() => selectedRole = v!),
                      ),
                      
                      if (selectedRole == 'sekolah') ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: kotaController,
                          decoration: const InputDecoration(labelText: "Kabupaten / Kota"),
                        ),
                        TextFormField(
                          controller: kecamatanController,
                          decoration: const InputDecoration(labelText: "Kecamatan"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // PERBAIKAN 2: Capture Navigator & Context Logic
                      final navigator = Navigator.of(ctx); // Simpan Navigator dialog
                      final scaffoldMessenger = ScaffoldMessenger.of(context); // Simpan Messenger (opsional, tp lebih aman)

                      // Simpan ke Firestore
                      await FirebaseFirestore.instance.collection('users').add({
                        'email': emailController.text,
                        'nama_lengkap': namaController.text,
                        'role': selectedRole,
                        'kota': selectedRole == 'sekolah' ? kotaController.text : null,
                        'kecamatan': selectedRole == 'sekolah' ? kecamatanController.text : null,
                        'created_at': Timestamp.now(),
                      });
                      
                      // Gunakan navigator yang sudah dicapture untuk menutup dialog
                      navigator.pop();

                      // Cek mounted sebelum pakai UI
                      if (mounted) {
                         scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Data User berhasil ditambahkan ke Database")));
                      }
                    }
                  },
                  child: const Text("Simpan Data"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
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
              title: const Text("Dashboard & Statistik"),
              selected: _selectedIndex == 0,
              onTap: () { setState(() => _selectedIndex = 0); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Manajemen User"),
              selected: _selectedIndex == 1,
              onTap: () { setState(() => _selectedIndex = 1); Navigator.pop(context); },
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
      body: _selectedIndex == 0 ? _buildDashboardView() : _buildUserManagementView(),
      
      floatingActionButton: _selectedIndex == 1 
          ? FloatingActionButton(
              onPressed: _showAddUserDialog, 
              backgroundColor: Colors.blueGrey[900], 
              child: const Icon(Icons.add, color: Colors.white)
            )
          : null,
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ringkasan Data", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'sekolah').snapshots(),
                  builder: (ctx, snap) => _statCard("Total Sekolah", snap.hasData ? "${snap.data!.docs.length}" : "...", Colors.blue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'staff').snapshots(),
                  builder: (ctx, snap) => _statCard("Total Staff", snap.hasData ? "${snap.data!.docs.length}" : "...", Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('members').snapshots(),
              builder: (ctx, snap) => _statCard("Total Anggota Terdata", snap.hasData ? "${snap.data!.docs.length}" : "...", Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String count, Color color) {
    return Card(
      elevation: 4,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(count, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').orderBy('created_at', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;

        if (docs.isEmpty) return const Center(child: Text("Belum ada user."));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            String role = data['role'] ?? 'user';
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: role == 'admin' ? Colors.red : (role == 'staff' ? Colors.orange : Colors.blue),
                  child: Icon(
                    role == 'admin' ? Icons.admin_panel_settings : (role == 'staff' ? Icons.work : Icons.school),
                    color: Colors.white,
                  ),
                ),
                title: Text(data['nama_lengkap'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['email'] ?? '-'),
                    if (role == 'sekolah') Text("${data['kecamatan'] ?? '-'}, ${data['kota'] ?? '-'}"),
                  ],
                ),
                trailing: role == 'admin' ? null : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Hapus User"),
                        content: const Text("Hapus data user ini dari database?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                          TextButton(
                            onPressed: () async {
                              // PERBAIKAN 3: Capture Navigator
                              final navigator = Navigator.of(ctx);
                              
                              await FirebaseFirestore.instance.collection('users').doc(docs[index].id).delete();
                              
                              // Gunakan navigator yang sudah dicapture
                              navigator.pop();
                            }, 
                            child: const Text("Hapus", style: TextStyle(color: Colors.red))
                          ),
                        ],
                      )
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}