import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import Dialog yang baru dibuat
import '../widgets/update_task_dialog.dart';
// Import Detail View
import 'school_detail_view.dart';

class StaffPendataanTaskView extends StatelessWidget {
  final String staffId;
  const StaffPendataanTaskView({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tugas_pendataan')
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada tugas."));

        // Filter: Hanya tugas milik staff ini
        var myTasks = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['staff_list'] != null) {
            var list = data['staff_list'] as List;
            return list.any((staff) => staff['uid'] == staffId);
          }
          return false;
        }).toList();

        if (myTasks.isEmpty) return const Center(child: Text("Tidak ada tugas aktif."));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myTasks.length,
          itemBuilder: (context, index) {
            var doc = myTasks[index];
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'pending';
            
            // Konfigurasi Warna & Icon berdasarkan Status
            Color statusColor;
            IconData statusIcon;
            String statusText;

            switch (status) {
              case 'done':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                statusText = "SELESAI";
                break;
              case 'reschedule':
                statusColor = Colors.orange;
                statusIcon = Icons.access_time;
                statusText = "RESCHEDULE";
                break;
              case 'rejected':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                statusText = "DITOLAK";
                break;
              default: // pending / process
                statusColor = Colors.blue;
                statusIcon = Icons.priority_high;
                statusText = "MENUNGGU";
            }

            DateTime? tgl;
            if (data['tanggal_tugas'] != null) tgl = (data['tanggal_tugas'] as Timestamp).toDate();

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text(data['sekolah_nama'] ?? 'Sekolah', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(tgl != null) Text("Target: ${tgl.day}/${tgl.month}/${tgl.year}"),
                        const SizedBox(height: 4),
                        // Tampilkan Chip Status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4)),
                          child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    // Jika belum selesai/ditolak, arahkan ke Detail Sekolah untuk input data
                    onTap: () {
                      if (data['sekolah_id'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SchoolDetailView(
                              sekolahId: data['sekolah_id'],
                              sekolahNama: data['sekolah_nama'],
                              taskId: doc.id, // Kirim ID Tugas
                              taskData: data, // Kirim Data Tugas
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  
                  // BAGIAN TOMBOL AKSI (Hanya muncul jika bisa di-update)
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Tombol Info Catatan Korlap
                        if (data['catatan'] != null && data['catatan'].toString().isNotEmpty)
                          Expanded(
                            child: Text(
                              "Korlap: \"${data['catatan']}\"", 
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                              maxLines: 2, overflow: TextOverflow.ellipsis
                            ),
                          )
                        else 
                          const Spacer(),

                        // TOMBOL UPDATE LAPORAN
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.report, size: 16),
                          label: const Text("Lapor Status"),
                          onPressed: () {
                            showDialog(
                              context: context, 
                              builder: (ctx) => UpdateTaskDialog(
                                docId: doc.id,
                                currentData: data
                              )
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // JIKA ADA KETERANGAN LAPANGAN (Hasil Laporan Staff)
                  if (data['keterangan_lapangan'] != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Colors.grey[50],
                      child: Text("Laporan Anda: ${data['keterangan_lapangan']}", style: TextStyle(fontSize: 11, color: statusColor)),
                    )
                ],
              ),
            );
          },
        );
      },
    );
  }
}