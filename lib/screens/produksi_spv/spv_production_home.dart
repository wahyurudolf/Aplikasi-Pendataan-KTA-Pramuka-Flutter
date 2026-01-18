import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- TAMBAHKAN IMPORT INI

class SpvProductionHome extends StatelessWidget {
  const SpvProductionHome({super.key});

  void _assignTask(BuildContext context, String sekolahId, String sekolahNama, int totalData) {
    showDialog(
      context: context,
      builder: (context) => _AssignStaffDialog(
        sekolahId: sekolahId, 
        sekolahNama: sekolahNama,
        totalData: totalData
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Supervisor Produksi"), 
        backgroundColor: Colors.indigo[100],
        actions: [
          // --- TOMBOL LOGOUT ---
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.indigo),
            tooltip: "Keluar",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FILTER: Ambil data status 'verified' (Siap Cetak)
        stream: FirebaseFirestore.instance.collection('members')
            .where('status', isEqualTo: 'verified') 
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Tidak ada data baru (Verified)."));
          }

          var docs = snapshot.data!.docs;
          
          // GROUPING: Gabungkan data berdasarkan Sekolah
          Map<String, Map<String, dynamic>> schoolGroups = {};
          
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            String sId = data['sekolah_id'] ?? 'unknown';
            String sName = data['sekolah_asal'] ?? 'Sekolah Unknown';

            if (!schoolGroups.containsKey(sId)) {
              schoolGroups[sId] = { 'nama': sName, 'count': 0, 'id': sId };
            }
            schoolGroups[sId]!['count'] = schoolGroups[sId]!['count'] + 1;
          }

          var listSekolah = schoolGroups.values.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: listSekolah.length,
            itemBuilder: (context, index) {
              var item = listSekolah[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Text("${item['count']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  title: Text(item['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Status: Terverifikasi Korlap"),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    onPressed: () => _assignTask(context, item['id'], item['nama'], item['count']),
                    child: const Text("Tugaskan"),
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

// --- WIDGET DIALOG PILIH STAFF ---
class _AssignStaffDialog extends StatefulWidget {
  final String sekolahId;
  final String sekolahNama;
  final int totalData;

  const _AssignStaffDialog({required this.sekolahId, required this.sekolahNama, required this.totalData});

  @override
  State<_AssignStaffDialog> createState() => _AssignStaffDialogState();
}

class _AssignStaffDialogState extends State<_AssignStaffDialog> {
  String? _selectedStaffId;
  String? _selectedStaffName;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pilih Staff Produksi"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Sekolah: ${widget.sekolahNama}"),
          Text("Jumlah: ${widget.totalData} Anggota"),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            // AMBIL LIST USER DENGAN ROLE 'staff_produksi'
            stream: FirebaseFirestore.instance.collection('users')
                .where('role', isEqualTo: 'staff_produksi')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              
              var staffList = snapshot.data!.docs.map<DropdownMenuItem<String>>((d) {
                 var data = d.data() as Map<String, dynamic>;
                 return DropdownMenuItem<String>( 
                    value: d['uid'] as String,    
                    onTap: () => _selectedStaffName = data['nama_lengkap'],
                    child: Text(data['nama_lengkap'] ?? 'No Name'),
                 );
              }).toList();

              if (staffList.isEmpty) return const Text("Belum ada akun Staff Produksi.");

              return DropdownButtonFormField<String>( 
                items: staffList,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                hint: const Text("Pilih Staff"),
                onChanged: (v) => setState(() => _selectedStaffId = v),
              );
            },
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          onPressed: (_selectedStaffId == null || _isLoading) ? null : () async {
            setState(() => _isLoading = true);
            
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);
            
            try {
              var batch = FirebaseFirestore.instance.batch();
              var query = await FirebaseFirestore.instance.collection('members')
                  .where('sekolah_id', isEqualTo: widget.sekolahId)
                  .where('status', isEqualTo: 'verified')
                  .get();

              for (var doc in query.docs) {
                batch.update(doc.reference, {
                  'status': 'printing_process',
                  'assigned_to_staff': _selectedStaffId,
                  'assigned_staff_name': _selectedStaffName,
                  'assigned_at': Timestamp.now(),
                });
              }

              await batch.commit();
              
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text("Tugas berhasil dikirim ke Staff!")));

            } catch (e) {
              if (mounted) setState(() => _isLoading = false);
              messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
            }
          },
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text("Kirim Tugas"),
        )
      ],
    );
  }
}