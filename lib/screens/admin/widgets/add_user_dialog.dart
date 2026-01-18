import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddUserDialog extends StatefulWidget {
  final String? initialRole; 

  const AddUserDialog({super.key, this.initialRole});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final namaController = TextEditingController(); 
  
  // Controller khusus untuk menampilkan nama sekolah yang dipilih
  final _schoolDisplayController = TextEditingController();

  late String selectedRole;
  bool isLoading = false;
  
  // VARIABLE DROPDOWN LOKASI
  String? _selectedKwardaId, _selectedKwarcabId, _selectedKwarranId;
  String? _selectedKwardaNama, _selectedKwarcabNama, _selectedKwarranNama;

  // VARIABLE SEKOLAH
  String? _selectedSchoolId;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.initialRole ?? 'sekolah';
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    namaController.dispose();
    _schoolDisplayController.dispose(); // Jangan lupa dispose ini
    super.dispose();
  }

  Future<String?> _registerUserWithoutLogout(String email, String password) async {
    final messenger = ScaffoldMessenger.of(context);
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error Auth: ${e.message}")));
      return null;
    } finally {
      await secondaryApp?.delete();
    }
  }

  // --- FUNGSI MEMBUKA POPUP PENCARIAN SEKOLAH ---
  void _openSchoolPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Agar bisa full screen
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9, // Tinggi 90% layar
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => _SchoolSearchSheet(
          scrollController: controller,
          onSelect: (data) {
            // SAAT SEKOLAH DIPILIH, UPDATE SEMUA DATA DI PARENT
            setState(() {
              _selectedSchoolId = data['id'];
              namaController.text = data['nama_sekolah']; // Nama User = Nama Sekolah
              _schoolDisplayController.text = data['nama_sekolah']; // Tampilan di input
              
              // Copy Data Lokasi dari Sekolah
              _selectedKwardaId = data['kwarda_id']; _selectedKwardaNama = data['kwarda'];
              _selectedKwarcabId = data['kwarcab_id']; _selectedKwarcabNama = data['kwarcab'];
              _selectedKwarranId = data['kwarran_id']; _selectedKwarranNama = data['kwarran'];
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool needsManualLocation = ['korlap', 'staff_pendataan'].contains(selectedRole);
    bool isSekolahMode = selectedRole == 'sekolah';

    return AlertDialog(
      title: const Text("Tambah User Baru"),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email Login"),
                validator: (v) => v!.isEmpty ? "Isi Email" : null,
              ),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password", helperText: "Min 6 karakter"),
                validator: (v) => (v == null || v.length < 6) ? "Password min 6 karakter" : null,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: "Role Akun"),
                // --- UPDATE DAFTAR ROLE DI SINI ---
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
                onChanged: (v) => setState(() {
                  selectedRole = v!;
                  namaController.clear();
                  _schoolDisplayController.clear();
                  _selectedSchoolId = null;
                  _selectedKwardaId = null; _selectedKwarcabId = null; _selectedKwarranId = null;
                }),
              ),
              const SizedBox(height: 15),

              // --- INPUT KHUSUS SEKOLAH (DENGAN PENCARIAN) ---
              if (isSekolahMode) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pautkan ke Data Sekolah", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 5),
                      
                      // INI ADALAH INPUT YANG BISA DIKLIK UNTUK CARI
                      TextFormField(
                        controller: _schoolDisplayController,
                        readOnly: true, // Tidak bisa diketik manual
                        decoration: InputDecoration(
                          hintText: "Ketuk untuk cari sekolah...",
                          suffixIcon: const Icon(Icons.search, color: Colors.green),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                        ),
                        onTap: _openSchoolPicker, // Buka Modal Pencarian
                        validator: (v) => _selectedSchoolId == null ? "Wajib pilih sekolah" : null,
                      ),

                      if (_selectedSchoolId != null) ...[
                        const SizedBox(height: 8),
                        Text("Lokasi: ${_selectedKwarranNama ?? '-'}, ${_selectedKwarcabNama ?? '-'}", style: const TextStyle(fontSize: 12)),
                      ]
                    ],
                  ),
                ),
              ]
              // --- INPUT MANUAL UNTUK ROLE LAIN ---
              else 
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: "Nama Lengkap"),
                  validator: (v) => v!.isEmpty ? "Isi Nama" : null,
                ),

              // --- PILIH LOKASI MANUAL (KORLAP/STAFF) ---
              if (needsManualLocation) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                       StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('master_kwarda').orderBy('nama').snapshots(),
                        builder: (ctx, snap) {
                           if(!snap.hasData) return const SizedBox();
                           return DropdownButtonFormField<String>(
                             isExpanded: true, initialValue: _selectedKwardaId, hint: const Text("Pilih Kwarda"),
                             items: snap.data!.docs.map((d)=>DropdownMenuItem(value: d.id, onTap: ()=>_selectedKwardaNama=d['nama'], child: Text(d['nama']))).toList(),
                             onChanged: (v)=>setState((){_selectedKwardaId=v;_selectedKwarcabId=null;_selectedKwarranId=null;})
                           );
                        }
                       ),
                       if(_selectedKwardaId != null)
                         StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('master_kwarcab').where('kwarda_id', isEqualTo: _selectedKwardaId).orderBy('nama').snapshots(),
                          builder: (ctx, snap) {
                             if(!snap.hasData) return const SizedBox();
                             return DropdownButtonFormField<String>(
                               isExpanded: true, initialValue: _selectedKwarcabId, hint: const Text("Pilih Kwarcab"),
                               items: snap.data!.docs.map((d)=>DropdownMenuItem(value: d.id, onTap: ()=>_selectedKwarcabNama=d['nama'], child: Text(d['nama']))).toList(),
                               onChanged: (v)=>setState((){_selectedKwarcabId=v;_selectedKwarranId=null;})
                             );
                          }
                         ),
                       if(_selectedKwarcabId != null)
                         StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('master_kwarran').where('kwarcab_id', isEqualTo: _selectedKwarcabId).orderBy('nama').snapshots(),
                          builder: (ctx, snap) {
                             if(!snap.hasData) return const SizedBox();
                             return DropdownButtonFormField<String>(
                               isExpanded: true, initialValue: _selectedKwarranId, hint: const Text("Pilih Kwarran"),
                               items: snap.data!.docs.map((d)=>DropdownMenuItem(value: d.id, onTap: ()=>_selectedKwarranNama=d['nama'], child: Text(d['nama']))).toList(),
                               onChanged: (v)=>setState((){_selectedKwarranId=v;})
                             );
                          }
                         ),
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        ElevatedButton(
          onPressed: isLoading ? null : () async {
            if (formKey.currentState!.validate()) {
              setState(() => isLoading = true);
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              String? newUid = await _registerUserWithoutLogout(emailController.text.trim(), passwordController.text.trim());

              if (newUid == null) {
                setState(() => isLoading = false);
                return;
              }

              await FirebaseFirestore.instance.collection('users').doc(newUid).set({
                'uid': newUid,
                'email': emailController.text.trim(),
                'nama_lengkap': namaController.text.trim(),
                'role': selectedRole,
                'kwarda_id': _selectedKwardaId, 'kwarda': _selectedKwardaNama,
                'kwarcab_id': _selectedKwarcabId, 'kwarcab': _selectedKwarcabNama,
                'kwarran_id': _selectedKwarranId, 'kwarran': _selectedKwarranNama,
                'master_sekolah_id': _selectedSchoolId, 
                'created_at': Timestamp.now(),
              });

              setState(() => isLoading = false);
              navigator.pop();
              messenger.showSnackBar(const SnackBar(content: Text("Akun berhasil dibuat!")));
            }
          },
          child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()) : const Text("Buat Akun"),
        ),
      ],
    );
  }
}

// =================================================================
// WIDGET BARU: SHEET PENCARIAN SEKOLAH (CLIENT-SIDE FILTERING)
// =================================================================
class _SchoolSearchSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Map<String, dynamic>) onSelect;

  const _SchoolSearchSheet({required this.scrollController, required this.onSelect});

  @override
  State<_SchoolSearchSheet> createState() => _SchoolSearchSheetState();
}

class _SchoolSearchSheetState extends State<_SchoolSearchSheet> {
  final _searchController = TextEditingController();
  String _query = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // HEADER (Garis & Judul)
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text("Cari Sekolah", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // KOLOM PENCARIAN
          TextField(
            controller: _searchController,
            autofocus: true, // Keyboard langsung muncul
            decoration: InputDecoration(
              hintText: "Ketik nama sekolah...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16)
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
          const SizedBox(height: 10),

          // LIST DATA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('master_sekolah').orderBy('nama_sekolah').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs;
                
                // FILTERING DI SINI (Client Side)
                var filtered = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var nama = (data['nama_sekolah'] ?? '').toString().toLowerCase();
                  var gudep = (data['no_gudep'] ?? '').toString().toLowerCase();
                  return nama.contains(_query) || gudep.contains(_query);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("Sekolah tidak ditemukan."));
                }

                return ListView.separated(
                  controller: widget.scrollController,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    var doc = filtered[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    // Siapkan data lengkap untuk dikirim balik
                    var fullData = {
                      'id': doc.id,
                      ...data
                    };

                    return ListTile(
                      title: Text(data['nama_sekolah'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${data['kwarran'] ?? '-'} • Gudep: ${data['no_gudep'] ?? '-'}"),
                      onTap: () {
                        widget.onSelect(fullData); // Kirim data
                        Navigator.pop(context); // Tutup Sheet
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}