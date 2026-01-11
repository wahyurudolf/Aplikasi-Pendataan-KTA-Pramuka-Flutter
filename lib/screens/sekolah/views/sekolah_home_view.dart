import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../widgets/edit_school_profile_dialog.dart';
import '../../input_member_screen.dart'; 

class SekolahHomeView extends StatefulWidget {
  const SekolahHomeView({super.key});

  @override
  State<SekolahHomeView> createState() => _SekolahHomeViewState();
}

class _SekolahHomeViewState extends State<SekolahHomeView> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // --- LOGIC HAPUS MEMBER ---
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
              messenger.showSnackBar(const SnackBar(content: Text("Data berhasil dihapus")));
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified': return Colors.green;
      case 'rejected': return Colors.red;
      case 'printed': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. STREAM PERTAMA: LOAD PROFIL USER DULU
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        var userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        
        // --- PERBAIKAN UTAMA ADA DI SINI ---
        // Ambil ID Master Sekolah. Jika belum diset (akun lama), fallback ke UID login.
        String realSchoolId = userData['master_sekolah_id'] ?? _uid;
        String namaSekolah = userData['nama_lengkap'] ?? 'Tanpa Nama';
        String gudep = userData['no_gudep'] ?? '-';
        
        String kwarran = userData['kwarran'] ?? '';
        String kwarcab = userData['kwarcab'] ?? '';
        String lokasi = (kwarran.isEmpty) ? "Lokasi belum diset" : "$kwarran, $kwarcab";

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: Colors.brown,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Tambah Anggota", style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => InputMemberScreen(
                  memberId: null, 
                  memberData: null,
                  // PENTING: Kirim ID yang benar ke form input
                  forcedSekolahId: realSchoolId, 
                  forcedSekolahNama: namaSekolah,
                )
              ));
            },
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // --- KARTU PROFIL ---
                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      showDialog(
                        context: context, 
                        builder: (ctx) => EditSchoolProfileDialog(uid: _uid, currentData: userData)
                      );
                    }, 
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.brown[100], shape: BoxShape.circle),
                            child: const Icon(Icons.school, size: 30, color: Colors.brown),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(namaSekolah, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("Gudep: $gudep", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(lokasi, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- 2. STREAM KEDUA: LOAD MEMBER PAKAI ID YANG BENAR ---
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('members')
                      .where('sekolah_id', isEqualTo: realSchoolId) // <--- SUDAH DIPERBAIKI (Bukan _uid lagi)
                      .snapshots(),
                  builder: (context, memberSnap) {
                    if (memberSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!memberSnap.hasData || memberSnap.data!.docs.isEmpty) {
                      return const Padding(padding: EdgeInsets.all(30), child: Text("Belum ada data anggota."));
                    }

                    var allDocs = memberSnap.data!.docs;

                    // Helper Sort
                    void sortByName(List<DocumentSnapshot> list) {
                      list.sort((a, b) {
                        String nameA = (a.data() as Map)['nama_lengkap'] ?? '';
                        String nameB = (b.data() as Map)['nama_lengkap'] ?? '';
                        return nameA.compareTo(nameB);
                      });
                    }

                    // Grouping Logic
                    var listMabigus = allDocs.where((d) => (d['tingkatan'] ?? '') == 'MABIGUS').toList(); 
                    sortByName(listMabigus);
                    
                    var listPembina = allDocs.where((d) => ['PEMBINA', 'PELATIH'].contains(d['tingkatan'])).toList(); 
                    sortByName(listPembina);
                    
                    var listSiswa = allDocs.where((d) => !['MABIGUS', 'PEMBINA', 'PELATIH'].contains(d['tingkatan'])).toList();

                    Map<String, List<DocumentSnapshot>> siswaByKelas = {};
                    for (var doc in listSiswa) {
                      String kelas = doc['kelas'] ?? 'Lainnya';
                      // Tambahkan kurung kurawal {} juga di sini agar rapi
                      if (!siswaByKelas.containsKey(kelas)) {
                        siswaByKelas[kelas] = [];
                      }
                      siswaByKelas[kelas]!.add(doc);
                    }

                    var sortedKelasKeys = siswaByKelas.keys.toList()..sort();
                    
                    // --- PERBAIKAN DI SINI (Baris 175) ---
                    // Gunakan blok { } untuk membungkus statement
                    for (var key in sortedKelasKeys) {
                      sortByName(siswaByKelas[key]!);
                    }

                    return Column(
                      children: [
                        if (listMabigus.isNotEmpty) _buildGroupSection("MABIGUS", listMabigus, realSchoolId, namaSekolah),
                        if (listPembina.isNotEmpty) _buildGroupSection("PEMBINA / PELATIH", listPembina, realSchoolId, namaSekolah),
                        ...sortedKelasKeys.map((k) => _buildGroupSection("KELAS $k", siswaByKelas[k]!, realSchoolId, namaSekolah)),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupSection(String title, List<DocumentSnapshot> dataList, String schoolId, String schoolName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.brown[100], borderRadius: BorderRadius.circular(8)),
                child: Text("${dataList.length} Data", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true, 
          physics: const NeverScrollableScrollPhysics(), 
          itemCount: dataList.length,
          itemBuilder: (context, index) {
            var doc = dataList[index];
            var data = doc.data() as Map<String, dynamic>;
            
            String nama = data['nama_lengkap'] ?? '-';
            String status = data['status'] ?? 'draft';
            String base64Foto = data['foto_url'] ?? '';
            String rawTgl = data['tanggal_lahir'] ?? '';
            String tglFormatted = rawTgl;
            try { tglFormatted = DateFormat('dd-MM-yyyy').format(DateTime.parse(rawTgl)); } catch (e) {
              //
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  backgroundImage: base64Foto.isNotEmpty ? MemoryImage(base64Decode(base64Foto)) : null,
                  child: base64Foto.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Lahir: $tglFormatted"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Chip(
                      label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9)),
                      backgroundColor: _getStatusColor(status),
                      visualDensity: VisualDensity.compact,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => InputMemberScreen(
                              memberId: doc.id, 
                              memberData: data,
                              forcedSekolahId: schoolId,
                              forcedSekolahNama: schoolName,
                            )
                          ));
                        } else if (v == 'delete') {
                          _deleteMember(doc.id, nama);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text("Edit")),
                        if(status == 'draft' || status == 'submitted')
                          const PopupMenuItem(value: 'delete', child: Text("Hapus", style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(
                    builder: (context) => InputMemberScreen(
                      memberId: doc.id, 
                      memberData: data,
                      forcedSekolahId: schoolId,
                      forcedSekolahNama: schoolName,
                    )
                  ));
                },
              ),
            );
          },
        ),
      ],
    );
  }
}