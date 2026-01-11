import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class SchoolFormDialog extends StatefulWidget {
  final String? docId;              // Jika null = Mode Tambah, Ada isi = Mode Edit
  final Map<String, dynamic>? data; // Data lama untuk mode edit
  final Map<String, dynamic>? lockedLocation;

  const SchoolFormDialog({super.key, this.docId, this.data, this.lockedLocation});

  @override
  State<SchoolFormDialog> createState() => _SchoolFormDialogState();
}

class _SchoolFormDialogState extends State<SchoolFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers Data Sekolah
  final _namaController = TextEditingController();
  final _gudepController = TextEditingController();
  final _alamatController = TextEditingController();

  // Controllers Akun Login (Baru)
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _createAccount = false; // Checkbox state

  // Dropdown State
  String? _selectedKwardaId, _selectedKwarcabId, _selectedKwarranId;
  String? _selectedKwardaNama, _selectedKwarcabNama, _selectedKwarranNama;

  @override
  void initState() {
    super.initState();
    if (widget.data != null) {
      _namaController.text = widget.data!['nama_sekolah'] ?? '';
      _gudepController.text = widget.data!['no_gudep'] ?? '';
      _alamatController.text = widget.data!['alamat'] ?? '';
      
      // Load Lokasi Lama
      _selectedKwardaId = widget.data!['kwarda_id'];
      _selectedKwarcabId = widget.data!['kwarcab_id'];
      _selectedKwarranId = widget.data!['kwarran_id'];
      
      _selectedKwardaNama = widget.data!['kwarda'];
      _selectedKwarcabNama = widget.data!['kwarcab'];
      _selectedKwarranNama = widget.data!['kwarran'];
    } else if (widget.lockedLocation != null) {
      // JIKA MODE TAMBAH OLEH KORLAP (LOKASI TERKUNCI OTOMATIS)
      _selectedKwardaId = widget.lockedLocation!['kwarda_id'];
      _selectedKwardaNama = widget.lockedLocation!['kwarda'];
      _selectedKwarcabId = widget.lockedLocation!['kwarcab_id'];
      _selectedKwarcabNama = widget.lockedLocation!['kwarcab'];
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _gudepController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI BUAT USER TANPA LOGOUT (Reuse dari add_user_dialog) ---
  Future<String?> _registerUserWithoutLogout(String email, String password) async {
    final messenger = ScaffoldMessenger.of(context);
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryAppSchool',
        options: Firebase.app().options,
      );
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Gagal Buat Akun: ${e.message}")));
      return null;
    } finally {
      await secondaryApp?.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEdit = widget.docId != null;
    bool isLocked = widget.lockedLocation != null;

    return AlertDialog(
      title: Text(isEdit ? "Edit Data Sekolah" : "Tambah Sekolah Baru"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // NAMA SEKOLAH (TETAP WAJIB)
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Sekolah"),
                validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
              ),
              const SizedBox(height: 15),
              
              // NOMOR GUDEP
              TextFormField(
                controller: _gudepController,
                decoration: const InputDecoration(labelText: "Nomor Gudep (Opsional)", hintText: "Misal: 01.001 - 01.002"),
              ),
              const SizedBox(height: 15),
              
              // --- DROPDOWN LOKASI ---
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Lokasi Sekolah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                    const SizedBox(height: 8),

                    // KORLAP MODE (LOCKED)
                    if (isLocked) ...[
                      Text("Kwarda: $_selectedKwardaNama", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Kwarcab: $_selectedKwarcabNama", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      
                      const Text("Kwarran (Kecamatan):", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('master_kwarran')
                            .where('kwarcab_id', isEqualTo: _selectedKwarcabId)
                            .orderBy('nama').snapshots(),
                        builder: (ctx, snap) {
                          if (!snap.hasData) return const SizedBox();
                          var items = snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, onTap: ()=>_selectedKwarranNama=d['nama'], child: Text(d['nama']))).toList();
                          return DropdownButtonFormField<String>(
                            isExpanded: true, 
                            initialValue: _selectedKwarranId, 
                            hint: const Text("Pilih Kwarran"),
                            items: items,
                            onChanged: (v) => setState(() { _selectedKwarranId=v; }),
                            validator: (v) => v == null ? "Pilih Kwarran" : null,
                          );
                        },
                      ),
                    ] 
                    // ADMIN MODE (UNLOCKED)
                    else ...[
                      // KWARDA
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('master_kwarda').orderBy('nama').snapshots(),
                        builder: (ctx, snap) {
                          if (!snap.hasData) return const SizedBox();
                          var items = snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, onTap: ()=>_selectedKwardaNama=d['nama'], child: Text(d['nama']))).toList();
                          bool validId = snap.data!.docs.any((d) => d.id == _selectedKwardaId);
                          
                          return DropdownButtonFormField<String>(
                            isExpanded: true, 
                            initialValue: validId ? _selectedKwardaId : null, 
                            hint: const Text("Pilih Kwarda"),
                            items: items,
                            onChanged: (v) => setState(() { _selectedKwardaId=v; _selectedKwarcabId=null; _selectedKwarranId=null; }),
                            validator: (v) => v == null ? "Pilih Kwarda" : null,
                          );
                        },
                      ),
                      const SizedBox(height: 8),

                      // KWARCAB
                      if (_selectedKwardaId != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('master_kwarcab').where('kwarda_id', isEqualTo: _selectedKwardaId).orderBy('nama').snapshots(),
                          builder: (ctx, snap) {
                            if (!snap.hasData) return const SizedBox();
                            var items = snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, onTap: ()=>_selectedKwarcabNama=d['nama'], child: Text(d['nama']))).toList();
                            bool validId = snap.data!.docs.any((d) => d.id == _selectedKwarcabId);

                            return DropdownButtonFormField<String>(
                              isExpanded: true, 
                              initialValue: validId ? _selectedKwarcabId : null, 
                              hint: const Text("Pilih Kwarcab"),
                              items: items,
                              onChanged: (v) => setState(() { _selectedKwarcabId=v; _selectedKwarranId=null; }),
                              validator: (v) => v == null ? "Pilih Kwarcab" : null,
                            );
                          },
                        ),
                      const SizedBox(height: 8),

                      // KWARRAN
                      if (_selectedKwarcabId != null)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('master_kwarran').where('kwarcab_id', isEqualTo: _selectedKwarcabId).orderBy('nama').snapshots(),
                          builder: (ctx, snap) {
                            if (!snap.hasData) return const SizedBox();
                            var items = snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, onTap: ()=>_selectedKwarranNama=d['nama'], child: Text(d['nama']))).toList();
                            bool validId = snap.data!.docs.any((d) => d.id == _selectedKwarranId);

                            return DropdownButtonFormField<String>(
                              isExpanded: true, 
                              initialValue: validId ? _selectedKwarranId : null, 
                              hint: const Text("Pilih Kwarran"),
                              items: items,
                              onChanged: (v) => setState(() { _selectedKwarranId=v; }),
                              validator: (v) => v == null ? "Pilih Kwarran" : null,
                            );
                          },
                        ),
                    ], // Tutup Else Block
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // ALAMAT
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: "Alamat Lengkap (Opsional)"),
                maxLines: 2,
              ),

              // ========================================================
              // OPSI BUAT AKUN SEKOLAH (HANYA MUNCUL JIKA TAMBAH BARU)
              // ========================================================
              if (!isEdit) ...[
                const SizedBox(height: 20),
                const Divider(),
                CheckboxListTile(
                  title: const Text("Sekalian Buat Akun Login?"),
                  subtitle: const Text("Centang untuk membuatkan email & password bagi sekolah ini."),
                  value: _createAccount,
                  onChanged: (val) => setState(() => _createAccount = val!),
                  activeColor: Colors.green,
                ),
                
                if (_createAccount) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50], 
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green)
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: "Email Login Sekolah"),
                          validator: (v) => (_createAccount && (v == null || v.isEmpty)) ? "Email wajib diisi" : null,
                        ),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: "Password", helperText: "Min 6 karakter"),
                          validator: (v) => (_createAccount && (v == null || v.length < 6)) ? "Min 6 karakter" : null,
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            if (_formKey.currentState!.validate()) {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              setState(() => _isLoading = true);
              
              // 1. DATA SEKOLAH (MASTER)
              final schoolData = {
                'nama_sekolah': _namaController.text,
                'no_gudep': _gudepController.text,
                'alamat': _alamatController.text,
                'kwarda_id': _selectedKwardaId, 'kwarda': _selectedKwardaNama,
                'kwarcab_id': _selectedKwarcabId, 'kwarcab': _selectedKwarcabNama,
                'kwarran_id': _selectedKwarranId, 'kwarran': _selectedKwarranNama,
                'updated_at': Timestamp.now(),
              };

              String schoolId;

              // 2. SIMPAN / UPDATE MASTER SEKOLAH
              if (isEdit) {
                schoolId = widget.docId!;
                await FirebaseFirestore.instance.collection('master_sekolah').doc(schoolId).update(schoolData);
              } else {
                schoolData['created_at'] = Timestamp.now();
                DocumentReference docRef = await FirebaseFirestore.instance.collection('master_sekolah').add(schoolData);
                schoolId = docRef.id; // Ambil ID sekolah baru
              }

              // 3. JIKA DICENTANG: BUAT AKUN USER
              if (!isEdit && _createAccount) {
                String? newUid = await _registerUserWithoutLogout(
                  _emailController.text.trim(), 
                  _passwordController.text.trim()
                );

                if (newUid != null) {
                  // Simpan ke collection 'users' dengan link ke Master Sekolah
                  await FirebaseFirestore.instance.collection('users').doc(newUid).set({
                    'uid': newUid,
                    'email': _emailController.text.trim(),
                    'nama_lengkap': _namaController.text, // Nama User = Nama Sekolah
                    'role': 'sekolah', // Role otomatis sekolah
                    'master_sekolah_id': schoolId, // LINK PENTING!
                    
                    // Copy Data Lokasi juga ke User agar Profil lengkap
                    'no_gudep': _gudepController.text,
                    'alamat': _alamatController.text,
                    'kwarda_id': _selectedKwardaId, 'kwarda': _selectedKwardaNama,
                    'kwarcab_id': _selectedKwarcabId, 'kwarcab': _selectedKwarcabNama,
                    'kwarran_id': _selectedKwarranId, 'kwarran': _selectedKwarranNama,
                    'created_at': Timestamp.now(),
                  });
                } else {
                  // Jika gagal buat akun, matikan loading & jangan tutup dialog
                  setState(() => _isLoading = false);
                  return; 
                }
              }

              // 4. SELESAI
              navigator.pop();
              messenger.showSnackBar(SnackBar(
                content: Text(isEdit 
                  ? "Data Sekolah Diperbarui" 
                  : (_createAccount ? "Sekolah & Akun Login Berhasil Dibuat" : "Sekolah Ditambahkan")
                )
              ));
            }
          },
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text("Simpan"),
        )
      ],
    );
  }
}