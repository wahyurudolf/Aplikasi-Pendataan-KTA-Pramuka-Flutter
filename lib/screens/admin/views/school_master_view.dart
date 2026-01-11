import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/school_form_dialog.dart'; // Import Dialog yang baru dibuat

class SchoolMasterView extends StatefulWidget {
  const SchoolMasterView({super.key});

  @override
  State<SchoolMasterView> createState() => _SchoolMasterViewState();
}

class _SchoolMasterViewState extends State<SchoolMasterView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey[900],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Sekolah", style: TextStyle(color: Colors.white)),
        onPressed: () => showDialog(context: context, builder: (ctx) => const SchoolFormDialog()),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari Nama Sekolah atau Gudep...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); }) 
                  : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true, fillColor: Colors.grey[50],
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // LIST DATA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('master_sekolah').orderBy('nama_sekolah').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Belum ada data sekolah."));
                }

                var docs = snapshot.data!.docs;

                // Client-side Filtering
                var filteredDocs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String nama = (data['nama_sekolah'] ?? '').toLowerCase();
                  String gudep = (data['no_gudep'] ?? '').toLowerCase();
                  return nama.contains(_searchQuery) || gudep.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) return const Center(child: Text("Sekolah tidak ditemukan."));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var data = filteredDocs[index].data() as Map<String, dynamic>;
                    String docId = filteredDocs[index].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: const Icon(Icons.school, color: Colors.blue),
                        ),
                        title: Text(data['nama_sekolah'] ?? 'Tanpa Nama', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Gudep: ${data['no_gudep'] ?? '-'}"),
                            Text("${data['kwarran'] ?? '-'}, ${data['kwarcab'] ?? '-'}", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => showDialog(context: context, builder: (ctx) => SchoolFormDialog(docId: docId, data: data)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, docId, data['nama_sekolah']),
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
        title: const Text("Hapus Sekolah"),
        content: Text("Hapus data sekolah '$nama'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              // 1. Capture Navigator dari context dialog (ctx) SEBELUM proses await
              final navigator = Navigator.of(ctx);
              
              // 2. Jalankan proses hapus
              await FirebaseFirestore.instance.collection('master_sekolah').doc(docId).delete();
              
              // 3. Gunakan navigator yang sudah disimpan untuk menutup dialog
              navigator.pop();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}