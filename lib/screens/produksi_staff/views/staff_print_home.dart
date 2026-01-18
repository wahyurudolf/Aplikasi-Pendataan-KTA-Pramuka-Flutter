import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StaffPrintHome extends StatelessWidget {
  const StaffPrintHome({super.key});

  @override
  Widget build(BuildContext context) {
    String myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tugas Cetak Saya"), 
        backgroundColor: Colors.purple[100],
        actions: [
          // --- TOMBOL LOGOUT ---
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.purple),
            tooltip: "Keluar",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FILTER: Hanya tugas milik staff yang sedang login
        stream: FirebaseFirestore.instance.collection('members')
            .where('assigned_to_staff', isEqualTo: myUid)
            .where('status', isEqualTo: 'printing_process')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.print_disabled, size: 80, color: Colors.purple[100]),
                  const SizedBox(height: 10),
                  const Text("Tidak ada antrean cetak."),
                ],
              ),
            );
          }

          // GROUPING: Kelompokkan berdasarkan Sekolah
          Map<String, List<QueryDocumentSnapshot>> tasks = {};
          for (var doc in docs) {
            String sName = (doc.data() as Map)['sekolah_asal'] ?? 'Unknown';
            if (!tasks.containsKey(sName)) tasks[sName] = [];
            tasks[sName]!.add(doc);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              String sekolahName = tasks.keys.elementAt(index);
              List<QueryDocumentSnapshot> members = tasks[sekolahName]!;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 15),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.purple, child: Icon(Icons.print, color: Colors.white)),
                      title: Text(sekolahName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Antrean: ${members.length} Kartu"),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text("1. Download PDF"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                              onPressed: () => _generatePdf(context, members, sekolahName),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text("2. Selesai Cetak"),
                              onPressed: () => _markAsPrinted(context, members),
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- FUNGSI GENERATE PDF (GRID A4) ---
  Future<void> _generatePdf(BuildContext context, List<QueryDocumentSnapshot> members, String filename) async {
    final pdf = pw.Document();
    List<pw.Widget> cards = [];

    for (var doc in members) {
      var data = doc.data() as Map<String, dynamic>;
      
      pw.MemoryImage? profileImage;
      if (data['foto_url'] != null && data['foto_url'].toString().isNotEmpty) {
        try {
          profileImage = pw.MemoryImage(base64Decode(data['foto_url']));
        } catch (e) { /* Ignore error */ }
      }

      // Desain Kartu Sederhana (8.5 cm x 5.4 cm)
      final cardWidget = pw.Container(
        width: 242, height: 153, 
        margin: const pw.EdgeInsets.all(5),
        decoration: pw.BoxDecoration(border: pw.Border.all(), color: PdfColors.white),
        child: pw.Row(
          children: [
            pw.Container(
              width: 60, height: 80, margin: const pw.EdgeInsets.all(5), color: PdfColors.grey300,
              child: profileImage != null ? pw.Image(profileImage, fit: pw.BoxFit.cover) : null,
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text("KARTU TANDA ANGGOTA", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(data['nama_lengkap'] ?? '-', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Tingkatan: ${data['tingkatan'] ?? '-'}", style: const pw.TextStyle(fontSize: 8)),
                  pw.Text("Gudep: ${data['no_gudep'] ?? '-'}", style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            )
          ],
        ),
      );
      cards.add(cardWidget);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Wrap(spacing: 10, runSpacing: 10, children: cards)
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'KTA_$filename.pdf');
  }

  // --- FUNGSI TANDAI SELESAI ---
  Future<void> _markAsPrinted(BuildContext context, List<QueryDocumentSnapshot> members) async {
    // 1. Tampilkan Dialog Konfirmasi
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Selesai"), 
        content: const Text("Pastikan PDF sudah berhasil dicetak.\nData akan ditandai sebagai 'SELESAI' dan hilang dari daftar ini."),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya, Selesai")),
        ],
      )
    ) ?? false;

    // 2. Cek apakah Context masih valid (mounted) setelah await showDialog
    if (!context.mounted) return; 

    if(confirm) {
      // 3. Proses Database
      var batch = FirebaseFirestore.instance.batch();
      for(var doc in members) {
        batch.update(doc.reference, {
          'status': 'printed', // Status Final
          'printed_at': Timestamp.now(),
        });
      }
      await batch.commit();

      // 4. Cek lagi apakah Context masih valid (mounted) setelah await commit
      if (!context.mounted) return;

      // 5. Tampilkan SnackBar dengan aman
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Batch berhasil diselesaikan!")));
    }
  }
}