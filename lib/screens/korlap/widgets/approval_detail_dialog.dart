import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovalDetailDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String verifierUid;

  const ApprovalDetailDialog({
    super.key,
    required this.docId,
    required this.data,
    required this.verifierUid,
  });

  @override
  State<ApprovalDetailDialog> createState() => _ApprovalDetailDialogState();
}

class _ApprovalDetailDialogState extends State<ApprovalDetailDialog> {
  bool _isLoading = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _processApproval(bool isApproved) async {
    // Validasi input alasan jika ditolak
    if (!isApproved && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi alasan penolakan.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // --- PENTING: Capture Context Sebelum Async ---
    // Ini mencegah error "Don't use BuildContext across async gaps"
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      Map<String, dynamic> updateData = {
        'status': isApproved ? 'verified' : 'rejected',
        'verified_at': Timestamp.now(),
        'verified_by': widget.verifierUid,
      };

      if (!isApproved) {
        updateData['alasan_penolakan'] = _reasonController.text.trim();
      } else {
        // Jika diterima, hapus field alasan penolakan lama (jika ada)
        updateData['alasan_penolakan'] = FieldValue.delete();
      }

      // Proses Update ke Firestore
      await FirebaseFirestore.instance.collection('members').doc(widget.docId).update(updateData);

      // --- GUNAKAN VARIABEL YANG SUDAH DI-CAPTURE ---
      
      navigator.pop(); // Cukup pop saja. Halaman belakang otomatis refresh karena pakai StreamBuilder.
      
      messenger.showSnackBar(SnackBar(
        content: Text(isApproved ? "Data Berhasil Diverifikasi" : "Data Ditolak"),
        backgroundColor: isApproved ? Colors.green : Colors.red,
      ));

      // HAPUS BAGIAN Navigator.push(...) DI SINI
      // Karena itu membuat halaman menumpuk (stacking) dan tidak efisien.

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var d = widget.data;
    String base64Foto = d['foto_url'] ?? '';

    return AlertDialog(
      title: const Text("Detail Anggota"),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // FOTO PROFIL
          Center(
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border.all(color: Colors.brown),
                borderRadius: BorderRadius.circular(8),
              ),
              child: base64Foto.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.memory(base64Decode(base64Foto), fit: BoxFit.cover),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 15),

          // INFO UTAMA
          _rowInfo("Nama", d['nama_lengkap']),
          _rowInfo("Tingkatan", d['tingkatan']),
          _rowInfo("Sekolah", d['sekolah_asal']),
          _rowInfo("Kelas", d['kelas'] ?? '-'),
          const Divider(),
          _rowInfo("TTL", "${d['tempat_lahir'] ?? ''}, ${d['tanggal_lahir'] ?? ''}"),
          _rowInfo("JK", d['jenis_kelamin'] == 'L' ? 'Laki-laki' : 'Perempuan'),
          _rowInfo("Alamat", d['alamat'] ?? '-'),
          _rowInfo("No HP", d['no_hp'] ?? '-'),
          
          const SizedBox(height: 15),
          const Divider(thickness: 1),
          
          // INPUT ALASAN (Hanya muncul jika ingin menolak atau user fokus ke tombol tolak)
          const Text("Catatan / Alasan (Isi jika menolak):", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              hintText: "Contoh: Foto buram, Nama tidak sesuai KTP...",
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        // TOMBOL TOLAK
        TextButton(
          onPressed: _isLoading ? null : () => _processApproval(false),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("TOLAK"),
        ),
        // TOMBOL TERIMA
        ElevatedButton(
          onPressed: _isLoading ? null : () => _processApproval(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
              : const Text("VERIFIKASI"),
        ),
      ],
    );
  }

  Widget _rowInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          const Text(": ", style: TextStyle(fontSize: 12)),
          Expanded(child: Text(value ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}