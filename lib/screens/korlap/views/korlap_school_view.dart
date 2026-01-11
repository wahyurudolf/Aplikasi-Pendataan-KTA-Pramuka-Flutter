import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../admin/widgets/school_form_dialog.dart';

class KorlapSchoolView extends StatelessWidget {
  final Map<String, dynamic> korlapData;

  const KorlapSchoolView({super.key, required this.korlapData});

  @override
  Widget build(BuildContext context) {
    String myKwarcabId = korlapData['kwarcab_id'];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Sekolah", style: TextStyle(color: Colors.white)),
        onPressed: () {
          showDialog(
            context: context, 
            builder: (ctx) => SchoolFormDialog(
              lockedLocation: {
                'kwarda_id': korlapData['kwarda_id'], 'kwarda': korlapData['kwarda'],
                'kwarcab_id': korlapData['kwarcab_id'], 'kwarcab': korlapData['kwarcab'],
              },
            )
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('master_sekolah')
            .where('kwarcab_id', isEqualTo: myKwarcabId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Belum ada sekolah di wilayah Anda."));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.school, color: Colors.white)),
                  title: Text(data['nama_sekolah']),
                  subtitle: Text("Gudep: ${data['no_gudep'] ?? '-'}\n${data['kwarran'] ?? '-'}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOMBOL EDIT
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          showDialog(
                            context: context, 
                            builder: (ctx) => SchoolFormDialog(
                              docId: docId, 
                              data: data,
                              lockedLocation: {
                                 'kwarda_id': korlapData['kwarda_id'], 'kwarda': korlapData['kwarda'],
                                 'kwarcab_id': korlapData['kwarcab_id'], 'kwarcab': korlapData['kwarcab'],
                              },
                            )
                          );
                        },
                      ),
                      // TOMBOL HAPUS (BARU)
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
    );
  }

  void _confirmDelete(BuildContext context, String docId, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Sekolah"),
        content: Text("Hapus data sekolah '$nama'?\nData yang sudah terlanjur didata mungkin akan kehilangan referensi nama sekolah."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              await FirebaseFirestore.instance.collection('master_sekolah').doc(docId).delete();
              navigator.pop();
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}