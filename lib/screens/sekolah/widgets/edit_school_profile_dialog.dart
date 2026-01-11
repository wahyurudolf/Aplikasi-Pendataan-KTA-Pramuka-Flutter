import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSchoolProfileDialog extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> currentData;

  const EditSchoolProfileDialog({
    super.key,
    required this.uid,
    required this.currentData,
  });

  @override
  State<EditSchoolProfileDialog> createState() => _EditSchoolProfileDialogState();
}

class _EditSchoolProfileDialogState extends State<EditSchoolProfileDialog> {
  // Field yang bisa diedit terbatas, karena nama & wilayah dikunci dari Master Data
  late TextEditingController alamatCtrl;
  late TextEditingController gmapsCtrl;
  late TextEditingController gudepCtrl;

  @override
  void initState() {
    super.initState();
    alamatCtrl = TextEditingController(text: widget.currentData['alamat'] ?? '');
    gmapsCtrl = TextEditingController(text: widget.currentData['link_gmaps'] ?? '');
    // Support field lama 'kode_gudep' atau field baru 'no_gudep'
    gudepCtrl = TextEditingController(text: widget.currentData['no_gudep'] ?? widget.currentData['kode_gudep'] ?? '');
  }

  @override
  void dispose() {
    alamatCtrl.dispose();
    gmapsCtrl.dispose();
    gudepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Update Info Sekolah"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.yellow[100],
              child: const Text(
                "Info: Nama Sekolah dan Wilayah (Kwarda/Kwarcab/Kwarran) dikelola oleh Admin/Korlap. Hubungi admin jika ada kesalahan nama.",
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: gudepCtrl, 
              decoration: const InputDecoration(labelText: "Nomor Gudep", border: OutlineInputBorder())
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: alamatCtrl, 
              decoration: const InputDecoration(labelText: "Alamat Lengkap (Jalan/RT/RW)", border: OutlineInputBorder()), 
              maxLines: 3
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: gmapsCtrl, 
              decoration: const InputDecoration(labelText: "Link Google Maps", border: OutlineInputBorder(), prefixIcon: Icon(Icons.map))
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
          onPressed: () async {
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);

            // Update user profile
            await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
              'no_gudep': gudepCtrl.text, // Standarisasi ke no_gudep
              'alamat': alamatCtrl.text,
              'link_gmaps': gmapsCtrl.text,
            });

            // OPSI TAMBAHAN: Update juga di master_sekolah jika admin mengizinkan sinkronisasi dua arah
            // Tapi demi keamanan data master, sebaiknya edit master hanya via Admin.
            
            navigator.pop();
            messenger.showSnackBar(const SnackBar(content: Text("Profil Diperbarui")));
          },
          child: const Text("Simpan"),
        )
      ],
    );
  }
}