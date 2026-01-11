import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTaskDialog extends StatefulWidget {
  final Map<String, dynamic> korlapData;
  final String? docId;              // Null = Mode Tambah, Isi = Mode Edit
  final Map<String, dynamic>? data; // Data lama jika mode edit

  const CreateTaskDialog({
    super.key, 
    required this.korlapData,
    this.docId,
    this.data
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedSchoolId;
  String? _selectedSchoolName;
  final _noteController = TextEditingController();
  
  // State untuk Tanggal
  DateTime? _selectedDate;

  // State untuk Multi Staff
  List<Map<String, dynamic>> _selectedStaffs = []; // Menyimpan list staff terpilih

  @override
  void initState() {
    super.initState();
    // JIKA MODE EDIT, ISI DATA LAMA
    if (widget.docId != null && widget.data != null) {
      _selectedSchoolId = widget.data!['sekolah_id'];
      _selectedSchoolName = widget.data!['sekolah_nama'];
      _noteController.text = widget.data!['catatan'] ?? '';
      
      // Load Tanggal
      if (widget.data!['tanggal_tugas'] != null) {
        _selectedDate = (widget.data!['tanggal_tugas'] as Timestamp).toDate();
      }

      // Load Staff (Support format lama single staff & format baru list staff)
      if (widget.data!['staff_list'] != null) {
        // Format Baru (List)
        _selectedStaffs = List<Map<String, dynamic>>.from(widget.data!['staff_list']);
      } else if (widget.data!['staff_id'] != null) {
        // Fallback Format Lama (Single)
        _selectedStaffs.add({
          'uid': widget.data!['staff_id'],
          'nama': widget.data!['staff_nama']
        });
      }
    }
  }

  // --- FUNGSI PILIH TANGGAL ---
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now, // Tidak boleh pilih tanggal lampau
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // --- FUNGSI PILIH STAFF (MULTI SELECT) ---
  void _showMultiStaffPicker() {
    String myKwarcabId = widget.korlapData['kwarcab_id'];
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pilih Petugas (Bisa > 1)"),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users')
                .where('role', isEqualTo: 'staff_pendataan')
                .where('kwarcab_id', isEqualTo: myKwarcabId)
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (snap.data!.docs.isEmpty) return const Text("Tidak ada staff.");

              var allStaff = snap.data!.docs;

              return StatefulBuilder( // Agar Checkbox bisa update realtime dalam dialog
                builder: (context, setInnerState) {
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: allStaff.length,
                    itemBuilder: (context, index) {
                      var data = allStaff[index].data() as Map<String, dynamic>;
                      String uid = allStaff[index].id;
                      String nama = data['nama_lengkap'];
                      
                      // Cek apakah staff ini sudah terpilih?
                      bool isSelected = _selectedStaffs.any((s) => s['uid'] == uid);

                      return CheckboxListTile(
                        title: Text(nama),
                        value: isSelected,
                        onChanged: (val) {
                          setInnerState(() {
                            if (val == true) {
                              _selectedStaffs.add({'uid': uid, 'nama': nama});
                            } else {
                              _selectedStaffs.removeWhere((s) => s['uid'] == uid);
                            }
                          });
                          // Update tampilan di parent widget juga
                          setState(() {}); 
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Selesai")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String myKwarcabId = widget.korlapData['kwarcab_id'];
    bool isEdit = widget.docId != null;

    return AlertDialog(
      title: Text(isEdit ? "Edit Tugas" : "Beri Tugas Staff"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. PILIH SEKOLAH
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('master_sekolah')
                    .where('kwarcab_id', isEqualTo: myKwarcabId)
                    .orderBy('nama_sekolah').snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();
                  
                  // Pastikan ID sekolah yang diedit masih ada di list (Validasi)
                  var items = snap.data!.docs.map((d) => DropdownMenuItem(
                      value: d.id,
                      onTap: () => _selectedSchoolName = d['nama_sekolah'],
                      child: Text(d['nama_sekolah']),
                    )).toList();
                  bool validId = snap.data!.docs.any((d) => d.id == _selectedSchoolId);

                  return DropdownButtonFormField<String>(
                    isExpanded: true,
                    hint: const Text("Pilih Sekolah Target"),
                    initialValue: validId ? _selectedSchoolId : null,
                    items: items,
                    onChanged: (v) => setState(() => _selectedSchoolId = v),
                    validator: (v) => v == null ? "Pilih sekolah" : null,
                  );
                },
              ),
              const SizedBox(height: 15),

              // 2. PILIH TANGGAL (BARU)
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Tanggal Pendataan",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null 
                      ? "Pilih Tanggal" 
                      : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                  ),
                ),
              ),
              if (_selectedDate == null) 
                 const Padding(
                   padding: EdgeInsets.only(top:5, left: 10),
                   child: Text("Wajib isi tanggal", style: TextStyle(color: Colors.red, fontSize: 12)),
                 ),
              
              const SizedBox(height: 15),

              // 3. PILIH STAFF (MULTI) (BARU)
              const Text("Petugas Lapangan:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              InkWell(
                onTap: _showMultiStaffPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _selectedStaffs.isEmpty
                      ? const Text("Klik untuk pilih staff (+)", style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 8.0,
                          children: _selectedStaffs.map((s) => Chip(
                            label: Text(s['nama']),
                            onDeleted: () {
                              setState(() {
                                _selectedStaffs.remove(s);
                              });
                            },
                          )).toList(),
                        ),
                ),
              ),
              if (_selectedStaffs.isEmpty) 
                 const Padding(
                   padding: EdgeInsets.only(top:5, left: 10),
                   child: Text("Minimal pilih 1 staff", style: TextStyle(color: Colors.red, fontSize: 12)),
                 ),

              const SizedBox(height: 15),

              // 4. CATATAN
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: "Catatan Tugas"),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate() && _selectedDate != null && _selectedStaffs.isNotEmpty) {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final taskData = {
                'korlap_id': widget.korlapData['uid'] ?? widget.korlapData['email'],
                'korlap_nama': widget.korlapData['nama_lengkap'],
                'sekolah_id': _selectedSchoolId,
                'sekolah_nama': _selectedSchoolName,
                'staff_list': _selectedStaffs, // Simpan List Map
                'tanggal_tugas': Timestamp.fromDate(_selectedDate!),
                'catatan': _noteController.text,
                'updated_at': Timestamp.now(),
              };

              if (isEdit) {
                // UPDATE
                await FirebaseFirestore.instance.collection('tugas_pendataan').doc(widget.docId).update(taskData);
                messenger.showSnackBar(const SnackBar(content: Text("Tugas diperbarui")));
              } else {
                // CREATE BARU
                taskData['status'] = 'pending';
                taskData['created_at'] = Timestamp.now();
                await FirebaseFirestore.instance.collection('tugas_pendataan').add(taskData);
                messenger.showSnackBar(const SnackBar(content: Text("Tugas berhasil dikirim")));
              }

              navigator.pop();
            }
          },
          child: Text(isEdit ? "Simpan Perubahan" : "Kirim Tugas"),
        ),
      ],
    );
  }
}