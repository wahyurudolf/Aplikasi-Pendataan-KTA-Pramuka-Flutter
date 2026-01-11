import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../input_member_screen.dart'; 

class PendataanDashboard extends StatefulWidget {
  const PendataanDashboard({super.key});

  @override
  State<PendataanDashboard> createState() => _PendataanDashboardState();
}

class _PendataanDashboardState extends State<PendataanDashboard> {
  // Logout
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Sekolah"),
        backgroundColor: Colors.brown[100],
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _confirmLogout)
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'sekolah')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada data sekolah."));
          }

          // --- LOGIC GROUPING (Kota -> Kecamatan -> List Sekolah) ---
          var docs = snapshot.data!.docs;
          
          // Struktur: Map<NamaKota, Map<NamaKecamatan, List<DokumenSekolah>>>
          Map<String, Map<String, List<DocumentSnapshot>>> groupedData = {};

          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            // Pastikan field 'kabupaten'/'kota' dan 'kecamatan' ada di database user sekolah
            // Jika tidak ada, masuk ke kategori 'Lainnya'
            String kota = data['kabupaten'] ?? data['kota'] ?? 'Area Tidak Diketahui'; 
            String kec = data['kecamatan'] ?? 'Kecamatan Tidak Diketahui';

            if (!groupedData.containsKey(kota)) {
              groupedData[kota] = {};
            }
            if (!groupedData[kota]!.containsKey(kec)) {
              groupedData[kota]![kec] = [];
            }
            groupedData[kota]![kec]!.add(doc);
          }

          // Sorting Keys (Supaya urut abjad)
          var sortedKota = groupedData.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedKota.length,
            itemBuilder: (context, index) {
              String kotaName = sortedKota[index];
              var kecamatanMap = groupedData[kotaName]!;
              var sortedKecamatan = kecamatanMap.keys.toList()..sort();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER KOTA
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.brown[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      kotaName.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),

                  // LIST KECAMATAN DALAM KOTA
                  ...sortedKecamatan.map((kecName) {
                    var listSekolah = kecamatanMap[kecName]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.brown),
                              const SizedBox(width: 4),
                              Text("Kec. $kecName", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown[700])),
                            ],
                          ),
                        ),
                        
                        // GRID CARD SEKOLAH
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // 2 Kolom
                            childAspectRatio: 1.1, // Rasio Kotak
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: listSekolah.length,
                          itemBuilder: (ctx, i) {
                            var sekolahDoc = listSekolah[i];
                            var sData = sekolahDoc.data() as Map<String, dynamic>;
                            return _buildSchoolCard(context, sekolahDoc.id, sData);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  }),
                  const Divider(thickness: 2),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSchoolCard(BuildContext context, String id, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // NAVIGASI KE HALAMAN DETAIL (DASHBOARD SEKOLAH)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SchoolDetailView(
                sekolahId: id,
                sekolahNama: data['nama_lengkap'] ?? 'Tanpa Nama',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Sekolah
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school, size: 30, color: Colors.brown[400]),
              ),
              const SizedBox(height: 10),
              // Nama Sekolah
              Text(
                data['nama_lengkap'] ?? 'Tanpa Nama',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              // Jumlah Siswa (Optional: Bisa ditambahkan query count nanti)
              const Text("Tap untuk detail", style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HALAMAN DETAIL: Menampilkan Data Member Sekolah Tertentu (Mirip Dashboard Lama)
// ============================================================================

class SchoolDetailView extends StatefulWidget {
  final String sekolahId;
  final String sekolahNama;

  const SchoolDetailView({
    super.key,
    required this.sekolahId,
    required this.sekolahNama,
  });

  @override
  State<SchoolDetailView> createState() => _SchoolDetailViewState();
}

class _SchoolDetailViewState extends State<SchoolDetailView> {
  // Hapus Data
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
              await FirebaseFirestore.instance.collection('members').doc(docId).delete();
              navigator.pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Data dihapus")),
                );
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Lihat Foto Full
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
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sekolahNama),
        backgroundColor: Colors.brown[100],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('members')
            .where('sekolah_id', isEqualTo: widget.sekolahId)
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
                  Icon(Icons.folder_open, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Belum ada data di sekolah ini."),
                ],
              ),
            );
          }

          var allDocs = snapshot.data!.docs;

          // Sorting Logic
          void sortByName(List<DocumentSnapshot> list) {
            list.sort((a, b) {
              String nameA = (a.data() as Map)['nama_lengkap'] ?? '';
              String nameB = (b.data() as Map)['nama_lengkap'] ?? '';
              return nameA.compareTo(nameB);
            });
          }

          // Grouping
          var listMabigus = allDocs.where((d) => (d['tingkatan'] ?? '') == 'MABIGUS').toList(); 
          sortByName(listMabigus);

          var listPembina = allDocs.where((d) => ['PEMBINA', 'PELATIH'].contains(d['tingkatan'])).toList(); 
          sortByName(listPembina);

          var listSiswa = allDocs.where((d) => !['MABIGUS', 'PEMBINA', 'PELATIH'].contains(d['tingkatan'])).toList();

          Map<String, List<DocumentSnapshot>> siswaByKelas = {};
          for (var doc in listSiswa) {
            String kelas = doc['kelas'] ?? 'Tanpa Kelas';
            if (!siswaByKelas.containsKey(kelas)) {
              siswaByKelas[kelas] = [];
            }
            siswaByKelas[kelas]!.add(doc);
          }
          
          var sortedKelasKeys = siswaByKelas.keys.toList()..sort();
          
          // --- PERBAIKAN DI SINI (Menambahkan Kurung Kurawal { }) ---
          for (var key in sortedKelasKeys) {
            sortByName(siswaByKelas[key]!);
          }

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
        label: const Text("Input Data", style: TextStyle(color: Colors.white)),
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
          child: Text(
            "$title (${list.length})",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
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