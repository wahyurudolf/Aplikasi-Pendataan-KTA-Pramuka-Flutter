import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import Dialog Detail (Pastikan path ini sesuai dengan struktur folder Anda)
import '../widgets/approval_detail_dialog.dart'; 

class KorlapApprovalScreen extends StatefulWidget {
  const KorlapApprovalScreen({super.key});

  @override
  State<KorlapApprovalScreen> createState() => _KorlapApprovalScreenState();
}

class _KorlapApprovalScreenState extends State<KorlapApprovalScreen> {
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  // Helper untuk format tanggal (Sama seperti di SekolahHomeView)
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      DateTime date = (timestamp as Timestamp).toDate();
      return DateFormat('dd MMM HH:mm', 'id_ID').format(date);
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Data Masuk"),
        backgroundColor: Colors.brown[100],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- QUERY UTAMA ---
        // Mengambil semua data di collection 'members' yang statusnya 'submitted'
        // Ini adalah kunci agar data muncul di Korlap
        stream: FirebaseFirestore.instance
            .collection('members')
            .where('status', isEqualTo: 'submitted') 
            .orderBy('updated_at', descending: false) // Yang submit duluan, muncul paling atas
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in, size: 80, color: Colors.brown[100]),
                  const SizedBox(height: 10),
                  const Text("Tidak ada antrean verifikasi.", style: TextStyle(color: Colors.grey)),
                  const Text("Semua data 'submitted' sudah diproses.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              
              // Ambil Data Sesuai Struktur SekolahHomeView
              String nama = data['nama_lengkap'] ?? 'Tanpa Nama';
              String sekolah = data['sekolah_asal'] ?? 'Sekolah Tidak Diketahui';
              String tingkatan = data['tingkatan'] ?? '-';
              String base64Foto = data['foto_url'] ?? '';
              
              // Waktu submit (updated_at saat status jadi submitted)
              String tglInput = _formatDate(data['updated_at']);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  
                  // FOTO PROFIL (Sama logicnya dengan SekolahHomeView)
                  leading: GestureDetector(
                    onTap: () {
                      if (base64Foto.isNotEmpty) {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: InteractiveViewer(child: Image.memory(base64Decode(base64Foto))),
                          ),
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: base64Foto.isNotEmpty ? MemoryImage(base64Decode(base64Foto)) : null,
                      child: base64Foto.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                    ),
                  ),

                  // INFO DATA
                  title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.school, size: 14, color: Colors.brown[400]),
                          const SizedBox(width: 4),
                          Expanded(child: Text(sekolah, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text("$tingkatan • $tglInput", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),

                  // TOMBOL AKSI
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () {
                      // BUKA DIALOG DETAIL (approval_detail_dialog.dart)
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) => ApprovalDetailDialog(
                          docId: doc.id,
                          data: data,
                          verifierUid: _currentUid,
                        ),
                      );
                    },
                    child: const Text("Tinjau", style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}