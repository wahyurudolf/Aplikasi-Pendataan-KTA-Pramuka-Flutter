import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Pastikan package intl sudah ada di pubspec.yaml

class UpdateTaskDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;

  const UpdateTaskDialog({super.key, required this.docId, required this.currentData});

  @override
  State<UpdateTaskDialog> createState() => _UpdateTaskDialogState();
}

class _UpdateTaskDialogState extends State<UpdateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _catatanController = TextEditingController();
  
  String _selectedStatus = 'done'; // Default
  File? _evidenceImage;
  DateTime? _rescheduleDate; // Variabel Tanggal Reschedule
  bool _isLoading = false;

  // Opsi Status
  final Map<String, String> _statusOptions = {
    'done': 'Selesai (Berhasil)',
    'reschedule': 'Reschedule (Ubah Jadwal)',
    'rejected': 'Ditolak (Sekolah Menolak)',
  };

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  // --- LOGIC KAMERA ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 30);
    if (pickedFile != null) setState(() => _evidenceImage = File(pickedFile.path));
  }

  // --- LOGIC TANGGAL RESCHEDULE (BARU) ---
  Future<void> _pickRescheduleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)), // Default besok
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _rescheduleDate = picked);
  }

  Future<String> _convertImageToBase64(File image) async {
    List<int> imageBytes = await image.readAsBytes();
    return base64Encode(imageBytes);
  }

  @override
  Widget build(BuildContext context) {
    bool isDone = _selectedStatus == 'done';
    bool isReschedule = _selectedStatus == 'reschedule';

    return AlertDialog(
      title: const Text("Update Status Tugas"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PILIH STATUS
              const Text("Status Pengerjaan:", style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                items: _statusOptions.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedStatus = val!;
                    // Reset field jika ganti status
                    _evidenceImage = null; 
                    _rescheduleDate = null;
                    _catatanController.clear();
                  });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              // 2. KONDISI JIKA STATUS = SELESAI
              if (isDone) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    children: [
                      const Text("Wajib lampirkan foto PIC atau Plang Sekolah.", style: TextStyle(fontSize: 12, color: Colors.green)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: _evidenceImage != null
                              ? Image.file(_evidenceImage!, fit: BoxFit.cover)
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                    Text("Ketuk Buka Kamera", style: TextStyle(color: Colors.grey)),
                                  ],
                                ),
                        ),
                      ),
                      if (_evidenceImage == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text("* Foto wajib diambil", style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ]
              
              // 3. KONDISI JIKA STATUS = RESCHEDULE
              else if (isReschedule) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pilih Tanggal Baru:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: _pickRescheduleDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            suffixIcon: Icon(Icons.calendar_today, size: 20),
                          ),
                          child: Text(
                            _rescheduleDate == null 
                              ? "Pilih Tanggal..." 
                              : DateFormat('dd MMMM yyyy', 'id_ID').format(_rescheduleDate!), // Format Indo
                            style: TextStyle(color: _rescheduleDate == null ? Colors.grey : Colors.black),
                          ),
                        ),
                      ),
                      if (_rescheduleDate == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Text("* Tanggal wajib diisi", style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      
                      const SizedBox(height: 10),
                      const Text("Alasan Reschedule:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: "Contoh: Kepsek sedang dinas luar...",
                          border: OutlineInputBorder(),
                          fillColor: Colors.white, filled: true,
                        ),
                        validator: (v) => v!.isEmpty ? "Alasan wajib diisi" : null,
                      ),
                    ],
                  ),
                ),
              ]

              // 4. KONDISI JIKA STATUS = DITOLAK
              else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Alasan Penolakan:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      TextFormField(
                        controller: _catatanController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: "Kenapa sekolah menolak?",
                          border: OutlineInputBorder(),
                          fillColor: Colors.white, filled: true,
                        ),
                        validator: (v) => v!.isEmpty ? "Alasan wajib diisi" : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            // --- VALIDASI MANUAL SEBELUM SUBMIT ---
            if (isDone && _evidenceImage == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto bukti wajib diambil!")));
              return;
            }
            if (isReschedule && _rescheduleDate == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tanggal pengganti wajib diisi!")));
              return;
            }
            if (!isDone && !_formKey.currentState!.validate()) {
              return; // Alasan wajib diisi untuk reschedule/reject
            }

            setState(() => _isLoading = true);
            final navigator = Navigator.of(context);
            final messenger = ScaffoldMessenger.of(context);

            try {
              String? base64Foto;
              if (_evidenceImage != null) {
                base64Foto = await _convertImageToBase64(_evidenceImage!);
              }

              // SIAPKAN DATA UPDATE
              Map<String, dynamic> updateData = {
                'status': _selectedStatus,
                'keterangan_lapangan': _catatanController.text,
                'updated_at': Timestamp.now(),
              };

              // KHUSUS JIKA SELESAI
              if (isDone) {
                updateData['bukti_foto'] = base64Foto;
                updateData['tanggal_selesai'] = Timestamp.now();
              }

              // KHUSUS JIKA RESCHEDULE (UPDATE TANGGAL TARGET)
              if (isReschedule && _rescheduleDate != null) {
                updateData['tanggal_tugas'] = Timestamp.fromDate(_rescheduleDate!);
              }

              // EKSEKUSI UPDATE KE FIRESTORE
              await FirebaseFirestore.instance.collection('tugas_pendataan').doc(widget.docId).update(updateData);

              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text("Status berhasil diubah menjadi ${_statusOptions[_selectedStatus]}")),
              );

            } catch (e) {
              messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
            } finally {
              if (mounted) setState(() => _isLoading = false);
            }
          },
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text("Simpan Laporan"),
        )
      ],
    );
  }
}