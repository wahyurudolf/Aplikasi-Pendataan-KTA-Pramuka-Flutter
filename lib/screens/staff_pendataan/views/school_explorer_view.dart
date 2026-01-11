import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'school_detail_view.dart';

class SchoolExplorerView extends StatelessWidget {
  final String? kwarcabId;
  const SchoolExplorerView({super.key, this.kwarcabId});

  @override
  Widget build(BuildContext context) {
    if (kwarcabId == null) return const Center(child: Text("Data wilayah tidak ditemukan."));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('master_sekolah')
          .where('kwarcab_id', isEqualTo: kwarcabId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Belum ada data sekolah di wilayah ini."));

        var docs = snapshot.data!.docs;
        Map<String, List<DocumentSnapshot>> groupedData = {};
        
        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          String kwarran = data['kwarran'] ?? 'Lainnya';
          if (!groupedData.containsKey(kwarran)) groupedData[kwarran] = [];
          groupedData[kwarran]!.add(doc);
        }

        var sortedKwarran = groupedData.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedKwarran.length,
          itemBuilder: (context, index) {
            String kwarranName = sortedKwarran[index];
            var listSekolah = groupedData[kwarranName]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.map, size: 18, color: Colors.brown),
                      const SizedBox(width: 8),
                      Text("Kwarran $kwarranName", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown)),
                    ],
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: listSekolah.length,
                  itemBuilder: (ctx, i) {
                    var doc = listSekolah[i];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildSchoolCard(context, doc.id, data);
                  },
                ),
                const Divider(height: 30),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSchoolCard(BuildContext context, String id, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SchoolDetailView(
                sekolahId: id,
                sekolahNama: data['nama_sekolah'] ?? 'Tanpa Nama',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 32, color: Colors.brown),
              const SizedBox(height: 8),
              Text(
                data['nama_sekolah'] ?? '-',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(data['no_gudep'] ?? '-', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}