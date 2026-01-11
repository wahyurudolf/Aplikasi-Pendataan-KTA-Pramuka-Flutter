import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Pastikan path ini benar mengarah ke file input member screen Anda
import '../../input_member_screen.dart'; 
// Import Dialog Update Status (Pastikan path sesuai)
import '../widgets/update_task_dialog.dart'; 

class SchoolDetailView extends StatefulWidget {
  final String sekolahId;
  final String sekolahNama;
  
  // Parameter Tambahan (Opsional)
  // Diisi jika dibuka dari menu "Tugas Saya", Kosong jika dari "Jelajah Sekolah"
  final String? taskId; 
  final Map<String, dynamic>? taskData;

  const SchoolDetailView({
    super.key,
    required this.sekolahId,
    required this.sekolahNama,
    this.taskId,
    this.taskData,
  });

  @override
  State<SchoolDetailView> createState() => _SchoolDetailViewState();
}

class _SchoolDetailViewState extends State<SchoolDetailView> {
  
  // --- LOGIC: HAPUS DATA ---
  void _deleteMember(String docId, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Data"),
        content: Text("Hapus data '$nama'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              
              await FirebaseFirestore.instance.collection('members').doc(docId).delete();
              
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text("Data dihapus")));
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- LOGIC: LIHAT FOTO ---
  void _showFullImage(String base64Foto) {
    if (base64Foto.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(child: Image.memory(base64Decode(base64Foto))),
            Positioned(
              top: 10, right: 10,
              child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
            )
          ],
        ),
      ),
    );
  }

  // --- LOGIC: BUKA DIALOG LAPOR STATUS (BARU) ---
  void _openReportDialog() {
    if (widget.taskId == null || widget.taskData == null) return;

    showDialog(
      context: context,
      builder: (ctx) => UpdateTaskDialog(
        docId: widget.taskId!,
        currentData: widget.taskData!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.sekolahNama, style: const TextStyle(fontSize: 16)),
            if (widget.taskId != null)
              const Text("Mode Penugasan", style: TextStyle(fontSize: 10, color: Colors.brown)),
          ],
        ),
        backgroundColor: Colors.brown[100],
        actions: [
          // --- TOMBOL LAPOR STATUS (Hanya Muncul Jika Ada Tugas) ---
          if (widget.taskId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.check_circle, size: 16),
                label: const Text("Selesai / Lapor", style: TextStyle(fontSize: 12)),
                onPressed: _openReportDialog,
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('members')
            .where('sekolah_id', isEqualTo: widget.sekolahId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Belum ada data anggota di sekolah ini."),
                ],
              ),
            );
          }

          var allDocs = snapshot.data!.docs;

          void sortByName(List<DocumentSnapshot> list) {
            list.sort((a, b) {
              String nameA = (a.data() as Map)['nama_lengkap'] ?? '';
              String nameB = (b.data() as Map)['nama_lengkap'] ?? '';
              return nameA.compareTo(nameB);
            });
          }

          var listMabigus = allDocs.where((d) => (d['tingkatan'] ?? '') == 'MABIGUS').toList(); sortByName(listMabigus);
          var listPembina = allDocs.where((d) => ['PEMBINA', 'PELATIH'].contains(d['tingkatan'])).toList(); sortByName(listPembina);
          var listSiswa = allDocs.where((d) => !['MABIGUS', 'PEMBINA', 'PELATIH'].contains(d['tingkatan'])).toList();

          Map<String, List<DocumentSnapshot>> siswaByKelas = {};
          for (var doc in listSiswa) {
            String kelas = doc['kelas'] ?? 'Lainnya';
            if (!siswaByKelas.containsKey(kelas)) siswaByKelas[kelas] = [];
            siswaByKelas[kelas]!.add(doc);
          }
          
          var sortedKelasKeys = siswaByKelas.keys.toList()..sort();
          for (var key in sortedKelasKeys) { sortByName(siswaByKelas[key]!); }

          return ListView(
            padding: const EdgeInsets.only(bottom: 80),
            children: [
              if (listMabigus.isNotEmpty) _buildGroup("MABIGUS", listMabigus),
              if (listPembina.isNotEmpty) _buildGroup("PEMBINA / PELATIH", listPembina),
              ...sortedKelasKeys.map((k) => _buildGroup("KELAS $k", siswaByKelas[k]!)),
            ],
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Input Anggota", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InputMemberScreen(
                memberId: null,
                memberData: null,
                forcedSekolahId: widget.sekolahId,
                forcedSekolahNama: widget.sekolahNama,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroup(String title, List<DocumentSnapshot> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text("$title (${list.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
        ),
        ...list.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String nama = data['nama_lengkap'] ?? '-';
          String base64Foto = data['foto_url'] ?? '';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: GestureDetector(
                onTap: () => _showFullImage(base64Foto),
                child: CircleAvatar(
                  backgroundImage: base64Foto.isNotEmpty ? MemoryImage(base64Decode(base64Foto)) : null,
                  child: base64Foto.isEmpty ? const Icon(Icons.person) : null,
                ),
              ),
              title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InputMemberScreen(
                          memberId: doc.id,
                          memberData: data,
                          forcedSekolahId: widget.sekolahId,
                          forcedSekolahNama: widget.sekolahNama,
                        ),
                      ),
                    );
                  } else {
                    _deleteMember(doc.id, nama);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit Data")),
                  const PopupMenuItem(value: 'delete', child: Text("Hapus Data", style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}