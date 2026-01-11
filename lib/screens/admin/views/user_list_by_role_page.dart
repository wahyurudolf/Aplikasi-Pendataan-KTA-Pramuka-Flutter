import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/edit_user_dialog.dart';
// Import AddUserDialog untuk tombol tambah
import '../widgets/add_user_dialog.dart'; 

class UserListByRolePage extends StatefulWidget {
  final String roleId;
  final String roleLabel;

  const UserListByRolePage({
    super.key,
    required this.roleId,
    required this.roleLabel,
  });

  @override
  State<UserListByRolePage> createState() => _UserListByRolePageState();
}

class _UserListByRolePageState extends State<UserListByRolePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data ${widget.roleLabel}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      
      // --- TOMBOL TAMBAH USER DI SINI ---
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey[900],
        onPressed: () {
          // Buka Dialog dengan Role yang otomatis terpilih sesuai halaman ini
          showDialog(
            context: context, 
            builder: (ctx) => AddUserDialog(initialRole: widget.roleId)
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah User", style: TextStyle(color: Colors.white)),
      ),

      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari nama atau email...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); }) 
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                fillColor: Colors.white, filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // List User
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: widget.roleId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada data."));

                var docs = snapshot.data!.docs;
                var filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = (data['nama_lengkap'] ?? '').toLowerCase();
                  String email = (data['email'] ?? '').toLowerCase();
                  String lokasi = (data['kwarcab'] ?? '').toLowerCase();
                  return nama.contains(_searchQuery) || email.contains(_searchQuery) || lokasi.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) return const Center(child: Text("Data tidak ditemukan."));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Tambah padding bawah agar tidak tertutup FAB
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    String docId = filteredDocs[index].id;
                    String nama = data['nama_lengkap'] ?? 'Tanpa Nama';
                    String email = data['email'] ?? '-';
                    
                    String lokasi = "";
                    if (widget.roleId == 'sekolah') {
                      String kc = data['kwarcab'] ?? '-';
                      String kr = data['kwarran'] ?? '-';
                      lokasi = "\n$kr, $kc"; 
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : "?"),
                        ),
                        title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$email$lokasi"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showDialog(context: context, builder: (ctx) => EditUserDialog(docId: docId, currentData: data, role: widget.roleId)),
                            ),
                            if (widget.roleId != 'super_admin')
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmDelete(context, docId, nama),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus User"),
        content: Text("Yakin ingin menghapus akun '$nama'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              navigator.pop();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}