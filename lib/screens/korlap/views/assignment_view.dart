import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/create_task_dialog.dart';

class AssignmentView extends StatelessWidget {
  final Map<String, dynamic> korlapData;
  const AssignmentView({super.key, required this.korlapData});

  @override
  Widget build(BuildContext context) {
    String myId = korlapData['uid'] ?? FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.assignment_add, color: Colors.white),
        label: const Text("Beri Tugas", style: TextStyle(color: Colors.white)),
        onPressed: () => showDialog(context: context, builder: (ctx) => CreateTaskDialog(korlapData: korlapData)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tugas_pendataan')
            .where('korlap_id', isEqualTo: myId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada tugas yang diberikan."));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              String docId = snapshot.data!.docs[index].id;
              
              String status = data['status'] ?? 'pending';
              Color statusColor = status == 'done' ? Colors.green : (status == 'process' ? Colors.blue : Colors.grey);
              
              // Ambil Tanggal
              DateTime? tglTugas;
              if (data['tanggal_tugas'] != null) {
                tglTugas = (data['tanggal_tugas'] as Timestamp).toDate();
              }

              // Ambil Nama Staff (Support multiple)
              String staffNames = "-";
              if (data['staff_list'] != null) {
                var list = data['staff_list'] as List;
                staffNames = list.map((e) => e['nama']).join(", ");
              } else if (data['staff_nama'] != null) {
                staffNames = data['staff_nama']; // Fallback data lama
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Sekolah & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['sekolah_nama'] ?? 'Sekolah', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Chip(
                            label: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
                            backgroundColor: statusColor,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // Body: Detail Tugas
                      Row(children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Text(tglTugas != null ? "${tglTugas.day}/${tglTugas.month}/${tglTugas.year}" : "-"),
                      ]),
                      const SizedBox(height: 5),
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.people, size: 14, color: Colors.grey),
                        const SizedBox(width: 5),
                        Expanded(child: Text("Petugas: $staffNames", style: const TextStyle(fontWeight: FontWeight.w500))),
                      ]),
                      if (data['catatan'] != null && data['catatan'].toString().isNotEmpty) ...[
                         const SizedBox(height: 5),
                         Text("Catatan: ${data['catatan']}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      ],

                      // Footer: Tombol Aksi
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.edit, size: 14),
                            label: const Text("Edit"),
                            onPressed: () {
                              showDialog(
                                context: context, 
                                builder: (ctx) => CreateTaskDialog(
                                  korlapData: korlapData,
                                  docId: docId,
                                  data: data,
                                )
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete, size: 14, color: Colors.red),
                            label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                            onPressed: () => _confirmDelete(context, docId),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Tugas"),
        content: const Text("Yakin ingin membatalkan tugas ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await FirebaseFirestore.instance.collection('tugas_pendataan').doc(docId).delete();
              navigator.pop();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}