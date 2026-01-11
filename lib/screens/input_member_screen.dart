import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InputMemberScreen extends StatefulWidget {
  final String? memberId;
  final Map<String, dynamic>? memberData;

  // Parameter Wajib agar data tidak nyasar
  final String? forcedSekolahId; 
  final String? forcedSekolahNama; 

  const InputMemberScreen({
    super.key,
    this.memberId,
    this.memberData,
    this.forcedSekolahId,
    this.forcedSekolahNama,
  });

  @override
  State<InputMemberScreen> createState() => _InputMemberScreenState();
}

class _InputMemberScreenState extends State<InputMemberScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _imageFile;

  // Variabel untuk menyimpan preview foto lama (Base64 String)
  String? _existingFoto;

  // --- CONTROLLER ---
  final _namaController = TextEditingController();
  final _tempatLahirController = TextEditingController();
  final _kelasController = TextEditingController();
  final _alamatController = TextEditingController();
  final _agamaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _emailController = TextEditingController();
  final _tkuController = TextEditingController();
  final _tglLahirController = TextEditingController();

  // Kursus (Hanya Guru)
  final _kmdController = TextEditingController();
  final _kmlController = TextEditingController();
  final _kpdController = TextEditingController();
  final _kplController = TextEditingController();

  // --- VARIABEL STATE ---
  String? _jenisKelamin;
  String? _golonganDarah;
  String _tingkatanMurid = 'SIAGA';
  String _tingkatanGuru = 'PEMBINA';
  DateTime _tanggalLahir = DateTime.now();
  bool _isDateSelected = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // --- LOGIC ISI DATA SAAT EDIT ---
    if (widget.memberData != null) {
      var d = widget.memberData!;
      _namaController.text = d['nama_lengkap'] ?? '';
      _tempatLahirController.text = d['tempat_lahir'] ?? '';
      _kelasController.text = d['kelas'] ?? '';
      _alamatController.text = d['alamat'] ?? '';
      _agamaController.text = d['agama'] ?? '';
      _noHpController.text = d['no_hp'] ?? '';
      _emailController.text = d['email'] ?? '';
      _tkuController.text = d['tku'] ?? '';

      // Ambil Foto Lama
      _existingFoto = d['foto_url'];

      if (d['tanggal_lahir'] != null) {
        try {
          // Coba parse format yyyy-mm-dd (default toIso8601String)
          _tanggalLahir = DateTime.parse(d['tanggal_lahir']);
        } catch (e) {
          // Fallback jika format berbeda
          _tanggalLahir = DateTime.now();
        }
        _isDateSelected = true;
        _tglLahirController.text = DateFormat('dd-MM-yyyy').format(_tanggalLahir);
      }

      _jenisKelamin = d['jenis_kelamin'];
      _golonganDarah = d['golongan_darah'];

      String level = d['tingkatan'] ?? 'SIAGA';
      if (['PEMBINA', 'PELATIH', 'MABIGUS'].contains(level)) {
        _tabController.index = 1; // Guru
        _tingkatanGuru = level;
        _kmdController.text = d['tahun_kmd'] ?? '';
        _kmlController.text = d['tahun_kml'] ?? '';
        _kpdController.text = d['tahun_kpd'] ?? '';
        _kplController.text = d['tahun_kpl'] ?? '';
      } else {
        _tabController.index = 0; // Murid
        _tingkatanMurid = level;
      }
    }

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _namaController.dispose();
    _tempatLahirController.dispose();
    _kelasController.dispose();
    _alamatController.dispose();
    _agamaController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    _tkuController.dispose();
    _tglLahirController.dispose();
    _kmdController.dispose();
    _kmlController.dispose();
    _kpdController.dispose();
    _kplController.dispose();
    super.dispose();
  }

  // --- LOGIC DATE & TINGKATAN ---
  void _formatDateInput(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length > 8) value = value.substring(0, 8);

    String formatted = "";
    if (value.length > 4) {
      formatted = "${value.substring(0, 2)}-${value.substring(2, 4)}-${value.substring(4)}";
    } else if (value.length > 2) {
      formatted = "${value.substring(0, 2)}-${value.substring(2)}";
    } else {
      formatted = value;
    }

    _tglLahirController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    if (formatted.length == 10) {
      try {
        DateTime parsed = DateFormat('dd-MM-yyyy').parse(formatted);
        setState(() {
          _tanggalLahir = parsed;
          _isDateSelected = true;
        });
        if (_tabController.index == 0) _hitungTingkatanMurid(parsed);
      } catch (e) {
        // Ignore parsing error while typing
      }
    }
  }

  void _hitungTingkatanMurid(DateTime tglLahir) {
    DateTime now = DateTime.now();
    int age = now.year - tglLahir.year;

    if (now.month < tglLahir.month || (now.month == tglLahir.month && now.day < tglLahir.day)) {
      age--;
    }

    String hasil;
    if (age <= 10) {
      hasil = "SIAGA";
    } else if (age <= 15) {
      hasil = "PENGGALANG";
    } else if (age <= 20) {
      hasil = "PENEGAK";
    } else if (age <= 25) {
      hasil = "PANDEGA";
    } else {
      hasil = "PEMBINA";
    }

    setState(() {
      _tingkatanMurid = hasil;
    });
  }

  Future<void> _pickDate() async {
    bool isGuru = _tabController.index == 1;
    DateTime initial = isGuru ? DateTime(1985) : DateTime(2010);

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendar,
    );

    if (picked != null) {
      setState(() {
        _tanggalLahir = picked;
        _isDateSelected = true;
        _tglLahirController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
      if (!isGuru) {
        _hitungTingkatanMurid(picked);
      }
    }
  }

  // --- LOGIC GAMBAR ---
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 25);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showFullImage(ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image(image: imageProvider),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<String?> _convertImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    return base64Encode(imageBytes);
  }

  // --- LOGIC DATABASE (SANGAT PENTING: DIPERBAIKI) ---
  
  // Fungsi ini mencari ID sekolah yang BENAR
  Future<Map<String, String>> _resolveSekolahInfo(String uid) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      var userData = userDoc.data() as Map<String, dynamic>;
      
      // PERBAIKAN: Cek apakah user punya 'master_sekolah_id'
      // Jika ada, pakai itu. Jika tidak, pakai UID (Fallback).
      String realSchoolId = userData['master_sekolah_id'] ?? uid;
      String schoolName = userData['nama_lengkap'] ?? 'Sekolah Tidak Diketahui';

      return {
        'nama': schoolName,
        'id': realSchoolId 
      };
    } catch (e) {
      return {'nama': 'Error', 'id': uid};
    }
  }

  void _resetFormAndKeepClass() {
    _namaController.clear();
    _tempatLahirController.clear();
    _alamatController.clear();
    _agamaController.clear();
    _noHpController.clear();
    _emailController.clear();
    _tkuController.clear();
    _tglLahirController.clear();
    _kmdController.clear();
    _kmlController.clear();
    _kpdController.clear();
    _kplController.clear();

    setState(() {
      _imageFile = null;
      _existingFoto = null;
      _isDateSelected = false;
      _tingkatanMurid = 'SIAGA';
      _tingkatanGuru = 'PEMBINA';
      _tanggalLahir = DateTime.now();
      _jenisKelamin = null;
    });
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isDateSelected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanggal Lahir Wajib Diisi!')));
      return;
    }
    if (_jenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jenis Kelamin Wajib Dipilih!')));
      return;
    }

    setState(() => _isLoading = true);
    bool isGuru = _tabController.index == 1;

    try {
      String? base64Foto;
      if (_imageFile != null) {
        base64Foto = await _convertImageToBase64(_imageFile!);
      }

      String? finalFoto = base64Foto ?? _existingFoto;

      String targetSekolahId;
      String targetSekolahNama;
      User? currentUser = FirebaseAuth.instance.currentUser;

      // 1. PRIORITAS UTAMA: Gunakan ID yang dipaksa (dari Staff/Dashboard Sekolah Baru)
      if (widget.forcedSekolahId != null) {
        targetSekolahId = widget.forcedSekolahId!;
        targetSekolahNama = widget.forcedSekolahNama ?? 'Sekolah';
      } 
      // 2. FALLBACK: Cari sendiri ID-nya (Hanya jika masuk tanpa parameter)
      else {
        var info = await _resolveSekolahInfo(currentUser!.uid);
        targetSekolahId = info['id']!;
        targetSekolahNama = info['nama']!;
      }

      String finalTingkatan = isGuru ? _tingkatanGuru : _tingkatanMurid;

      Map<String, dynamic> dataMap = {
        'nama_lengkap': _namaController.text,
        'tanggal_lahir': _tanggalLahir.toIso8601String().split('T')[0],
        'tempat_lahir': _tempatLahirController.text.isEmpty ? null : _tempatLahirController.text,
        'jenis_kelamin': _jenisKelamin,
        'golongan_darah': _golonganDarah,
        'agama': _agamaController.text.isEmpty ? null : _agamaController.text,
        'alamat': _alamatController.text.isEmpty ? null : _alamatController.text,
        'no_hp': _noHpController.text.isEmpty ? null : _noHpController.text,
        'email': _emailController.text.isEmpty ? null : _emailController.text,

        // FIELD KUNCI (WAJIB SAMA ANTARA STAFF & SEKOLAH)
        'sekolah_asal': targetSekolahNama,
        'sekolah_id': targetSekolahId, // <--- Ini yang bikin data muncul/tidak

        'kelas': isGuru ? null : (_kelasController.text.isEmpty ? null : _kelasController.text),
        'tingkatan': finalTingkatan,
        'tku': _tkuController.text.isEmpty ? null : _tkuController.text,
        'tahun_kmd': isGuru && _kmdController.text.isNotEmpty ? _kmdController.text : null,
        'tahun_kml': isGuru && _kmlController.text.isNotEmpty ? _kmlController.text : null,
        'tahun_kpd': isGuru && _kpdController.text.isNotEmpty ? _kpdController.text : null,
        'tahun_kpl': isGuru && _kplController.text.isNotEmpty ? _kplController.text : null,
        'foto_url': finalFoto,
        'diinput_oleh': currentUser!.uid,
        'updated_at': Timestamp.now(),
        'status': 'submitted',
      };

      if (widget.memberId != null) {
        await FirebaseFirestore.instance.collection('members').doc(widget.memberId).update(dataMap);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data Berhasil Diperbarui!')));
        Navigator.pop(context);
      } else {
        await FirebaseFirestore.instance.collection('members').add(dataMap);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data Berhasil Disimpan!')));
        _resetFormAndKeepClass();
        if (isGuru) _kelasController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildTextField(String label, TextEditingController controller, {bool required = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label + (required ? "*" : ""),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        ),
        validator: required ? (v) => v!.isEmpty ? "$label wajib diisi" : null : null,
      ),
    );
  }

  Widget _buildFormContent(bool isGuruMode) {
    // Logic Preview Foto
    ImageProvider? avatarImage;
    if (_imageFile != null) {
      avatarImage = FileImage(_imageFile!);
    } else if (_existingFoto != null && _existingFoto!.isNotEmpty) {
      try {
        avatarImage = MemoryImage(base64Decode(_existingFoto!));
      } catch (e) {
        avatarImage = null;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Info
          if (widget.forcedSekolahNama != null)
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Menginput data untuk:\n${widget.forcedSekolahNama}",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                )
              ]),
            ),

          // Foto Profile
          Center(
            child: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Wrap(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Kamera'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.photo),
                        title: const Text('Galeri'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                );
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: avatarImage,
                child: (avatarImage == null) ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) : null,
              ),
            ),
          ),

          if (avatarImage != null)
            Center(
              child: TextButton.icon(
                onPressed: () => _showFullImage(avatarImage!),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text("Lihat Foto Penuh"),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Ketuk ikon kamera (Opsional)", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),

          const SizedBox(height: 10),

          // Field Khusus Murid
          if (!isGuruMode) _buildTextField("Kelas", _kelasController, required: true),

          _buildTextField("Nama Lengkap", _namaController, required: true),

          // Tanggal Lahir
          TextFormField(
            controller: _tglLahirController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Tanggal Lahir (dd-mm-yyyy)*",
              hintText: "Contoh: 17081945",
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: _pickDate),
            ),
            onChanged: _formatDateInput,
            validator: (v) {
              if (v == null || v.isEmpty) return "Tgl Lahir wajib diisi";
              if (v.length < 10) return "Format harus Lengkap (dd-mm-yyyy)";
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Dropdown Tingkatan
          DropdownButtonFormField<String>(
            initialValue: isGuruMode ? _tingkatanGuru : _tingkatanMurid, // Pakai value, bukan initialValue agar reactive
            decoration: const InputDecoration(
              labelText: "Golongan Keanggotaan*",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
            items: isGuruMode
                ? ['PEMBINA', 'PELATIH', 'MABIGUS'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList()
                : ['SIAGA', 'PENGGALANG', 'PENEGAK', 'PANDEGA', 'PEMBINA'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) {
              setState(() {
                if (isGuruMode) {
                  _tingkatanGuru = v!;
                } else {
                  _tingkatanMurid = v!;
                }
              });
            },
          ),
          const SizedBox(height: 15),

          // Dropdown JK
          DropdownButtonFormField<String>(
            initialValue: _jenisKelamin, // Reactive value
            hint: const Text("Pilih Jenis Kelamin"),
            decoration: const InputDecoration(
              labelText: "Jenis Kelamin*",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
            items: ['L', 'P'].map((e) => DropdownMenuItem(value: e, child: Text(e == 'L' ? 'Laki-Laki' : 'Perempuan'))).toList(),
            onChanged: (v) => setState(() => _jenisKelamin = v!),
          ),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(flex: 3, child: _buildTextField("Tempat Lahir", _tempatLahirController)),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: _buildTextField("Agama", _agamaController)),
            ],
          ),

          DropdownButtonFormField<String>(
            initialValue: _golonganDarah,
            decoration: const InputDecoration(
              labelText: "Gol. Darah (Opsional)",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            ),
            items: ['A', 'B', 'AB', 'O'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _golonganDarah = v),
          ),
          const SizedBox(height: 15),

          _buildTextField("Alamat Rumah", _alamatController),
          _buildTextField("Nomor HP", _noHpController, type: TextInputType.phone),
          _buildTextField("Email", _emailController, type: TextInputType.emailAddress),
          _buildTextField("TKU (Tanda Kecakapan Umum)", _tkuController),

          // Field Khusus Guru (Kursus)
          if (isGuruMode) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Tahun Kursus (Isi Tahun Saja)", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Row(children: [
              Expanded(child: _buildTextField("KMD", _kmdController, type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField("KML", _kmlController, type: TextInputType.number)),
            ]),
            Row(children: [
              Expanded(child: _buildTextField("KPD", _kpdController, type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: _buildTextField("KPL", _kplController, type: TextInputType.number)),
            ]),
          ],

          const SizedBox(height: 20),

          // Tombol Simpan
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.brown,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_as, color: Colors.white),
            label: Text(
              _isLoading ? " MENYIMPAN..." : (widget.memberId == null ? " SIMPAN & TAMBAH DATA" : " SIMPAN PERUBAHAN"),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Selesai / Kembali", style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memberId == null ? "Input Data Baru" : "Edit Data Anggota"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.brown,
          labelColor: Colors.brown,
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(icon: Icon(Icons.school), text: "MURID"),
            Tab(icon: Icon(Icons.person_outline), text: "GURU / MABIGUS"),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFormContent(false), // Mode Murid
            _buildFormContent(true),  // Mode Guru
          ],
        ),
      ),
    );
  }
}