import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
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
        title: const Text("Cetak KTA Pramuka"),
        backgroundColor: Colors.purple[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.purple),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Mengambil data yang ditugaskan ke staff ini
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
                  Icon(Icons.print, size: 80, color: Colors.purple[100]),
                  const SizedBox(height: 10),
                  const Text("Tidak ada antrean cetak."),
                ],
              ),
            );
          }

          // Grouping berdasarkan Sekolah
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
                      subtitle: Text("Siap Cetak: ${members.length} Kartu"),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text("Generate KTA (PDF)"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                              onPressed: () => _generateKtaPdf(context, members, sekolahName),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text("Selesai"),
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

  // --- LOGIC GENERATE KTA ---
  // --- LOGIC GENERATE KTA FINAL (SESUAI DESAIN) ---
  Future<void> _generateKtaPdf(BuildContext context, List<QueryDocumentSnapshot> members, String filename) async {
    final pdf = pw.Document();

    // 1. SETUP ASSETS (Gunakan try-catch agar tidak crash app jika gambar 404)
    pw.ImageProvider? frontBg;
    pw.ImageProvider? backBg;

    try {
      // Sesuai screenshot Anda, ekstensinya adalah .jpeg
      frontBg = await imageFromAssetBundle('assets/images/KTAP-front.jpeg');
      backBg = await imageFromAssetBundle('assets/images/KTAP-back.jpeg');
    } catch (e) {
      debugPrint("ERROR ASSET: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Gagal memuat gambar background. Cek pubspec.yaml"), backgroundColor: Colors.red),
        );
      }
      return; // Stop proses jika aset background hilang
    }

    // 2. Variable Helper
    Map<String, int> dobCounter = {}; // Untuk menghitung urutan 0001, 0002
    
    // Format Tanggal Cetak: "Jakarta, 17 Agustus 1945"
    String todayStr = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

    for (var doc in members) {
      var data = doc.data() as Map<String, dynamic>;

      // --- LOGIC 1: NTA (28.03.01.ddmmyy.xxxx) ---
      String rawTgl = data['tanggal_lahir'] ?? '2000-01-01';
      DateTime tglLahirDate;
      try {
         tglLahirDate = DateTime.parse(rawTgl);
      } catch (e) {
         tglLahirDate = DateTime(2000, 1, 1);
      }
      
      // Format ddmmyy untuk NTA
      String dobCode = DateFormat('ddMMyy').format(tglLahirDate);
      
      // Hitung Nomor Urut (Reset per tanggal lahir dalam batch ini)
      int currentCount = dobCounter[dobCode] ?? 0;
      currentCount++;
      dobCounter[dobCode] = currentCount;
      
      String sequence = currentCount.toString().padLeft(4, '0');
      String ntaFinal = "28.03.01.$dobCode.$sequence";

      // --- LOGIC 2: MASA BERLAKU ---
      String tingkatan = (data['tingkatan'] ?? '').toString().toUpperCase();
      String masaBerlaku = "Berlaku s.d Akhir Masa Golongan"; // Default Siaga/Penggalang/Penegak
      
      if (tingkatan.contains("PEMBINA") || tingkatan.contains("PELATIH")) {
        masaBerlaku = "Berlaku Seumur Hidup";
      } else if (tingkatan.contains("MABIGUS")) {
        masaBerlaku = "Berlaku s.d. Akhir Masa Jabatan";
      }

      // --- LOGIC 3: FOTO PROFIL ---
      pw.MemoryImage? avatarImage;
      if (data['foto_url'] != null && data['foto_url'].toString().isNotEmpty) {
        try {
          avatarImage = pw.MemoryImage(base64Decode(data['foto_url']));
        } catch (e) { 
           debugPrint("Error decode foto: $e");
        }
      }

      // ==========================================
      // HALAMAN 1: BAGIAN DEPAN (DATA UTAMA)
      // ==========================================
      pdf.addPage(
        pw.Page(
          // Ukuran ID Card (CR-80)
          pageFormat: const PdfPageFormat(85.6 * PdfPageFormat.mm, 53.98 * PdfPageFormat.mm),
          margin: const pw.EdgeInsets.all(0),
          build: (context) {
            return pw.Stack(
              children: [
                // Layer 1: Background Merah Putih
                pw.Positioned.fill(child: pw.Image(frontBg!, fit: pw.BoxFit.cover)),

                // Layer 2: Foto Profil (Kiri, ada siluet jika kosong)
                pw.Positioned(
                  left: 6.5 * PdfPageFormat.mm,  // Sesuaikan geser kiri/kanan
                  top: 19 * PdfPageFormat.mm,    // Sesuaikan geser atas/bawah
                  child: pw.Container(
                    width: 20 * PdfPageFormat.mm, 
                    height: 25 * PdfPageFormat.mm,
                    color: PdfColors.grey300,
                    child: avatarImage != null 
                      ? pw.Image(avatarImage, fit: pw.BoxFit.cover)
                      : pw.Center(child: pw.Text("FOTO", style: const pw.TextStyle(fontSize: 6))),
                  ),
                ),

                // Layer 3: Data Teks (Sebelah Kanan Foto)
                pw.Positioned(
                  left: 29 * PdfPageFormat.mm, 
                  top: 18 * PdfPageFormat.mm,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // NTA
                      pw.Text(ntaFinal, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      
                      // NAMA (Bold Besar)
                      pw.Text(
                        (data['nama_lengkap'] ?? 'NAMA ANGGOTA').toString().toUpperCase(), 
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)
                      ),
                      pw.SizedBox(height: 2),

                      // GOLONGAN / JABATAN
                      pw.Text(tingkatan, style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(height: 2),

                      // PANGKALAN (SEKOLAH)
                      pw.Text(
                        (data['sekolah_asal'] ?? 'PANGKALAN').toString().toUpperCase(), 
                         style: const pw.TextStyle(fontSize: 9)
                      ),
                    ],
                  ),
                ),

                // Layer 4: QR Code (Kanan Tengah)
                pw.Positioned(
                  right: 12 * PdfPageFormat.mm,
                  top: 24 * PdfPageFormat.mm,
                  child: pw.Container(
                    width: 14 * PdfPageFormat.mm,
                    height: 14 * PdfPageFormat.mm,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: ntaFinal, 
                      drawText: false,
                    ),
                  ),
                ),

                // Layer 5: Masa Berlaku (Kotak Kiri Bawah)
                pw.Positioned(
                  left: 10 * PdfPageFormat.mm,
                  bottom: 7 * PdfPageFormat.mm,
                  child: pw.Container(
                    width: 35 * PdfPageFormat.mm,
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      masaBerlaku, 
                      style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center
                    ),
                  )
                ),

                // Layer 6: Tanggal & TTD (Kanan Bawah)
                pw.Positioned(
                  right: 5 * PdfPageFormat.mm,
                  bottom: 12 * PdfPageFormat.mm, 
                  child: pw.Text("Jakarta, $todayStr", style: const pw.TextStyle(fontSize: 5)),
                ),
              ],
            );
          },
        ),
      );

      // ==========================================
      // HALAMAN 2: BAGIAN BELAKANG
      // ==========================================
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(85.6 * PdfPageFormat.mm, 53.98 * PdfPageFormat.mm),
          margin: const pw.EdgeInsets.all(0),
          build: (context) {
             return pw.Image(backBg!, fit: pw.BoxFit.cover);
          },
        ),
      );
    } // End Loop

    // Tampilkan Preview
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'KTA_Cetak_${filename.replaceAll(' ', '_')}.pdf',
    );
  }

  // --- FUNGSI TANDAI SELESAI (Tetap Sama) ---
  Future<void> _markAsPrinted(BuildContext context, List<QueryDocumentSnapshot> members) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Selesai"), 
        content: const Text("Tandai data ini sebagai SUDAH DICETAK?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya")),
        ],
      )
    ) ?? false;

    if (!context.mounted) return;
    
    if(confirm) {
      var batch = FirebaseFirestore.instance.batch();
      for(var doc in members) {
        batch.update(doc.reference, {
          'status': 'printed',
          'printed_at': Timestamp.now(),
        });
      }
      await batch.commit();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil ditandai selesai!")));
    }
  }
}