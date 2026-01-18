import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserDialog extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentData;
  final String role; // Role saat ini

  const EditUserDialog({
    super.key,
    required this.docId,
    required this.currentData,
    required this.role,
  });

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  
  // State untuk Role (bisa diubah)
  late String _selectedRole;

  // State untuk Dropdown Lokasi
  String? _selectedKwardaId;
  String? _selectedKwarcabId;
  String? _selectedKwarranId;

  String? _selectedKwardaNama;
  String? _selectedKwarcabNama;
  String? _selectedKwarranNama;

  @override
  void initState() {
    super.initState();
    // 1. Isi Controller Nama
    _namaController = TextEditingController(text: widget.currentData['nama_lengkap'] ?? '');
    
    // 2. Isi Role Awal
    _selectedRole = widget.currentData['role'] ?? 'sekolah';

    // 3. Isi Lokasi Awal (Jika ada datanya)
    _selectedKwardaId = widget.currentData['kwarda_id'];
    _selectedKwarcabId = widget.currentData['kwarcab_id'];
    _selectedKwarranId = widget.currentData['kwarran_id'];
    
    _selectedKwardaNama = widget.currentData['kwarda'];
    _selectedKwarcabNama = widget.currentData['kwarcab'];
    _selectedKwarranNama = widget.currentData['kwarran'];
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cek apakah role yang dipilih membutuhkan lokasi?
    bool needsLocation = ['sekolah', 'korlap', 'staff_pendataan'].contains(_selectedRole);

    return AlertDialog(
      title: const Text("Edit Data User"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. EDIT NAMA
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Lengkap"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 10),

              // 2. EDIT ROLE
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: "Role Akun"),
                // --- UPDATE DAFTAR ROLE DI SINI JUGA ---
                items: [
                    'sekolah', 
                    'staff_pendataan', 
                    'korlap', 
                    'supervisor_produksi', // <--- BARU
                    'staff_produksi',      // <--- BARU
                    'super_admin'
                  ]
                    .map((r) => DropdownMenuItem(
                      value: r, 
                      child: Text(r.toUpperCase().replaceAll('_', ' ')))
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedRole = v!;
                    // Jika role berubah jadi yg gak butuh lokasi, reset data lokasi visual
                    if (!['sekolah', 'korlap', 'staff_pendataan'].contains(v)) {
                      _selectedKwardaId = null;
                      _selectedKwarcabId = null;
                      _selectedKwarranId = null;
                    }
                  });
                },
              ),

              // 3. EDIT LOKASI (Cascading Dropdown)
              if (needsLocation) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[50], // Warna beda biar ketauan mode edit
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade100)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Edit Wilayah Kerja", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900], fontSize: 12)
                      ),
                      const SizedBox(height: 8),

                      // DROPDOWN KWARDA
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('master_kwarda').orderBy('nama').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const LinearProgressIndicator();
                          
                          // Pastikan ID yang tersimpan ada di list, kalau tidak (misal terhapus), set null
                          var items = snapshot.data!.docs.map((doc) => DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['nama']),
                            onTap: () => _selectedKwardaNama = doc['nama'],
                          )).toList();

                          // Validasi value agar tidak crash jika ID lama tidak ditemukan di master
                          var isValidValue = snapshot.data!.docs.any((d) => d.id == _selectedKwardaId);

                          return DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: isValidValue ? _selectedKwardaId : null,
                            hint: const Text("Pilih Kwarda"),
                            items: items,
                            onChanged: (val) {
                              setState(() {
                                _selectedKwardaId = val;
                                // Reset bawahnya jika Kwarda berubah
                                _selectedKwarcabId = null; 
                                _selectedKwarranId = null;
                                _selectedKwarcabNama = null;
                                _selectedKwarranNama = null;
                              });
                            },
                            validator: (v) => v == null ? "Wajib pilih Kwarda" : null,
                          );
                        },
                      ),

                      // DROPDOWN KWARCAB (Filter by Kwarda)
                      if (_selectedKwardaId != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('master_kwarcab')
                              .where('kwarda_id', isEqualTo: _selectedKwardaId)
                              .orderBy('nama')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
                            
                            var items = snapshot.data!.docs.map((doc) => DropdownMenuItem(
                              value: doc.id,
                              child: Text(doc['nama']),
                              onTap: () => _selectedKwarcabNama = doc['nama'],
                            )).toList();

                            var isValidValue = snapshot.data!.docs.any((d) => d.id == _selectedKwarcabId);

                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: isValidValue ? _selectedKwarcabId : null,
                              hint: const Text("Pilih Kwarcab"),
                              items: items,
                              onChanged: (val) {
                                setState(() {
                                  _selectedKwarcabId = val;
                                  // Reset bawahnya jika Kwarcab berubah
                                  _selectedKwarranId = null;
                                  _selectedKwarranNama = null;
                                });
                              },
                              validator: (v) => v == null ? "Wajib pilih Kwarcab" : null,
                            );
                          },
                        ),

                      // DROPDOWN KWARRAN (Filter by Kwarcab)
                      if (_selectedKwarcabId != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('master_kwarran')
                              .where('kwarcab_id', isEqualTo: _selectedKwarcabId)
                              .orderBy('nama')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator());
                            
                            var items = snapshot.data!.docs.map((doc) => DropdownMenuItem(
                              value: doc.id,
                              child: Text(doc['nama']),
                              onTap: () => _selectedKwarranNama = doc['nama'],
                            )).toList();

                            var isValidValue = snapshot.data!.docs.any((d) => d.id == _selectedKwarranId);

                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: isValidValue ? _selectedKwarranId : null,
                              hint: const Text("Pilih Kwarran"),
                              items: items,
                              onChanged: (val) {
                                setState(() => _selectedKwarranId = val);
                              },
                              validator: (v) {
                                if (_selectedRole == 'sekolah' && v == null) return "Sekolah wajib pilih Kwarran";
                                return null;
                              },
                            );
                          },
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
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              // Cek lagi apakah role butuh lokasi
              bool needsLoc = ['sekolah', 'korlap', 'staff_pendataan'].contains(_selectedRole);

              await FirebaseFirestore.instance.collection('users').doc(widget.docId).update({
                'nama_lengkap': _namaController.text,
                'role': _selectedRole,
                
                // Update Lokasi (Jika tidak butuh lokasi, set null agar bersih)
                'kwarda_id': needsLoc ? _selectedKwardaId : null,
                'kwarda': needsLoc ? _selectedKwardaNama : null,
                'kwarcab_id': needsLoc ? _selectedKwarcabId : null,
                'kwarcab': needsLoc ? _selectedKwarcabNama : null,
                'kwarran_id': needsLoc ? _selectedKwarranId : null,
                'kwarran': needsLoc ? _selectedKwarranNama : null,
              });

              navigator.pop();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text("Data user berhasil diperbarui")),
                );
              }
            }
          },
          child: const Text("Simpan Perubahan"),
        ),
      ],
    );
  }
}