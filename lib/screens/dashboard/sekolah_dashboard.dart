import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../input_member_screen.dart'; 

class SekolahDashboard extends StatefulWidget {
  const SekolahDashboard({super.key});

  @override
  State<SekolahDashboard> createState() => _SekolahDashboardState();
}

class _SekolahDashboardState extends State<SekolahDashboard> {
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  // --- LOGIC 1: LOGOUT CONFIRMATION ---
  void _confirmLogout() {
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

  // --- LOGIC 2: HAPUS DATA (HANYA SUBMITTED) ---
  void _deleteMember(String docId, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Data"),
        content: Text("Hapus data '$nama'? Data yang dihapus tidak bisa dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              // --- PERBAIKAN 1: Capture Navigator & Messenger ---
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);

              // Proses Hapus
              await FirebaseFirestore.instance.collection('members').doc(docId).delete();
              
              // Gunakan referensi yang sudah disimpan
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text("Data berhasil dihapus")));
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- LOGIC 3: POP-UP DETAIL & EDIT SEKOLAH ---
  void _showSchoolDetails(BuildContext context, Map<String, dynamic> userData) {
    final namaSekolahCtrl = TextEditingController(text: userData['nama_lengkap'] ?? '');
    final gudepCtrl = TextEditingController(text: userData['kode_gudep'] ?? '');
    final kotakabupatenCtrl = TextEditingController(text: userData['kota_kabupaten'] ?? '');
    final kecCtrl = TextEditingController(text: userData['kecamatan'] ?? '');
    final desakelurahanCtrl = TextEditingController(text: userData['desa_kelurahan'] ?? '');
    final alamatCtrl = TextEditingController(text: userData['alamat'] ?? '');
    final gmapsCtrl = TextEditingController(text: userData['link_gmaps'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Data Sekolah"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Pastikan nama sekolah benar agar tidak typo.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 15),
              
              TextField(controller: namaSekolahCtrl, decoration: const InputDecoration(labelText: "Nama Sekolah", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: gudepCtrl, decoration: const InputDecoration(labelText: "Kode Gudep", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: kotakabupatenCtrl, decoration: const InputDecoration(labelText: "Kota/Kabupaten", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: kecCtrl, decoration: const InputDecoration(labelText: "Kecamatan", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: desakelurahanCtrl, decoration: const InputDecoration(labelText: "Desa/Kelurahan", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: alamatCtrl, decoration: const InputDecoration(labelText: "Alamat Jalan (RT/RW)", border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: gmapsCtrl, decoration: const InputDecoration(labelText: "Link Google Maps", border: OutlineInputBorder(), prefixIcon: Icon(Icons.map))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
            onPressed: () async {
              // Capture Navigator & Messenger
              final navigator = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);

              await FirebaseFirestore.instance.collection('users').doc(_uid).update({
                'nama_lengkap': namaSekolahCtrl.text,
                'kode_gudep': gudepCtrl.text,
                'kota_kabupaten': kotakabupatenCtrl.text,
                'kecamatan': kecCtrl.text,
                'desa_kelurahan': desakelurahanCtrl.text,
                'alamat': alamatCtrl.text,
                'link_gmaps': gmapsCtrl.text,
              });

              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text("Data Sekolah Diperbarui!")));
            },
            child: const Text("SIMPAN PERUBAHAN"),
          )
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Sekolah"),
        backgroundColor: Colors.brown[50],
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout)
        ],
      ),
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
          children: [
            // --- BAGIAN 1: CARD PROFIL SEKOLAH ---
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(20), child: LinearProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text("Data Sekolah Error/Tidak Ditemukan")));
                }

                var data = snapshot.data!.data() as Map<String, dynamic>;
                String namaSekolah = data['nama_lengkap'] ?? 'Nama Sekolah Belum Diisi';
                
                String kotakabupaten = data['kota_kabupaten'] ?? '';
                String kec = data['kecamatan'] ?? '';
                String desakelurahan = data['desa_kelurahan'] ?? '';
                String alamatLengkap = (kotakabupaten.isEmpty && kec.isEmpty && desakelurahan.isEmpty) 
                    ? "Lokasi belum diisi (Klik untuk edit)" 
                    : "$desakelurahan, $kec, $kotakabupaten";

                return Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => _showSchoolDetails(context, data), 
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
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(alamatLengkap, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text("Klik untuk edit profil sekolah", style: TextStyle(fontSize: 11, color: Colors.blue, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
                          const Icon(Icons.edit, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // --- BAGIAN 2: LIST ANGGOTA ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('members')
                  .where('sekolah_id', isEqualTo: _uid) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(padding: EdgeInsets.all(20), child: Text("Belum ada data anggota."));
                }

                var allDocs = snapshot.data!.docs;

                // Helper Sort A-Z
                void sortByName(List<DocumentSnapshot> list) {
                  list.sort((a, b) {
                    String nameA = (a.data() as Map)['nama_lengkap'] ?? '';
                    String nameB = (b.data() as Map)['nama_lengkap'] ?? '';
                    return nameA.compareTo(nameB);
                  });
                }

                // Filter & Sort
                var listMabigus = allDocs.where((d) => (d['tingkatan'] ?? '') == 'MABIGUS').toList();
                sortByName(listMabigus);
                
                var listPembina = allDocs.where((d) {
                  String t = (d['tingkatan'] ?? '');
                  return t == 'PEMBINA' || t == 'PELATIH';
                }).toList();
                sortByName(listPembina);

                var listSiswa = allDocs.where((d) {
                  String t = (d['tingkatan'] ?? '');
                  return t != 'MABIGUS' && t != 'PEMBINA' && t != 'PELATIH';
                }).toList();

                Map<String, List<DocumentSnapshot>> siswaByKelas = {};
                for (var doc in listSiswa) {
                  String kelas = doc['kelas'] ?? 'Tidak Diketahui';
                  if (!siswaByKelas.containsKey(kelas)) {
                    siswaByKelas[kelas] = [];
                  }
                  siswaByKelas[kelas]!.add(doc);
                }

                var sortedKelasKeys = siswaByKelas.keys.toList()..sort();
                for (var key in sortedKelasKeys) {
                  sortByName(siswaByKelas[key]!);
                }

                return Column(
                  children: [
                    if (listMabigus.isNotEmpty) _buildGroupSection("MABIGUS", listMabigus),
                    if (listPembina.isNotEmpty) _buildGroupSection("PEMBINA / PELATIH", listPembina),
                    if (sortedKelasKeys.isNotEmpty) ...sortedKelasKeys.map((kelas) {
                      return _buildGroupSection("KELAS $kelas", siswaByKelas[kelas]!);
                    }),
                    const SizedBox(height: 80), 
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Anggota", style: TextStyle(color: Colors.white)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InputMemberScreen(memberId: null, memberData: null)));
        },
      ),
    );
  }

  // --- WIDGET LIST DATA ---
  Widget _buildGroupSection(String title, List<DocumentSnapshot> dataList) {
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
            
            String nama = data['nama_lengkap'] ?? 'Tanpa Nama';
            String rawTgl = data['tanggal_lahir'] ?? '';
            String tglFormatted = rawTgl;
            
            // --- PERBAIKAN 2: Empty Catch Block ---
            try {
               DateTime date = DateTime.parse(rawTgl);
               tglFormatted = DateFormat('dd-MM-yyyy').format(date);
            } catch (e) {
               // Sengaja kosong: Jika format error, gunakan rawTgl apa adanya
            }

            String status = data['status'] ?? 'draft';
            String base64Foto = data['foto_url'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.only(left: 10, right: 5, top: 5, bottom: 5),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: base64Foto.isNotEmpty ? MemoryImage(base64Decode(base64Foto)) : null,
                  child: base64Foto.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                title: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text("Tanggal Lahir: $tglFormatted", style: const TextStyle(fontSize: 12)),
                
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Status (Tetap)
                    Chip(
                      label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 9)),
                      backgroundColor: _getStatusColor(status),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    
                    // --- UBAH TOMBOL SAMPAH MENJADI POPUP MENU INI ---
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => InputMemberScreen(
                            memberId: doc.id,
                            memberData: data,
                          )));
                        } else if (value == 'delete') {
                          _deleteMember(doc.id, nama);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 20), SizedBox(width: 8), Text('Edit Data')]),
                          ),
                          // Menu Hapus HANYA muncul jika status 'submitted'
                          if (status == 'submitted')
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 20), SizedBox(width: 8), Text('Hapus Data', style: TextStyle(color: Colors.red))]),
                            ),
                        ];
                      },
                    ),
                    // -----------------------------------------------
                  ],
                ),
                
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => InputMemberScreen(
                    memberId: doc.id,
                    memberData: data,
                  )));
                },
              ),
            );
          },
        ),
      ],
    );
  }
}