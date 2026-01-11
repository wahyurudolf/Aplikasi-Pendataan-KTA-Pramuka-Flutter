import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  String? id;
  String namaLengkap;
  // NIK Dihapus
  DateTime tanggalLahir;
  String? tempatLahir; // Baru (Nullable)
  String jenisKelamin; // L/P
  String? golonganDarah; // Nullable
  String? agama; // Baru (Nullable)
  String? alamat; // Baru (Nullable)
  String? noHp; // Baru (Nullable)
  String? email; // Baru (Nullable)
  String? sekolahAsal; // Diisi otomatis dari profil akun sekolah
  String? kelas; // Baru (Nullable)
  
  // Data Kepramukaan
  String tingkatan; // Siaga/Penggalang/dll (Otomatis by Umur)
  String? tku; // Baru (Nullable)
  // Kursus (Tahun) - Nullable
  String? tahunKMD;
  String? tahunKML;
  String? tahunKPD;
  String? tahunKPL;

  String? fotoUrl; // Base64
  String status; 
  String diinputOleh;
  DateTime updatedAt;

  MemberModel({
    this.id,
    required this.namaLengkap,
    required this.tanggalLahir,
    this.tempatLahir,
    required this.jenisKelamin,
    this.golonganDarah,
    this.agama,
    this.alamat,
    this.noHp,
    this.email,
    this.sekolahAsal,
    this.kelas,
    required this.tingkatan,
    this.tku,
    this.tahunKMD,
    this.tahunKML,
    this.tahunKPD,
    this.tahunKPL,
    this.fotoUrl,
    this.status = 'submitted', // Default submitted agar langsung masuk ke Korlap
    required this.diinputOleh,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'nama_lengkap': namaLengkap.toUpperCase(), // Paksa Huruf Kapital
      'tanggal_lahir': tanggalLahir.toIso8601String().split('T')[0],
      'tempat_lahir': tempatLahir?.toUpperCase(),
      'jenis_kelamin': jenisKelamin,
      'golongan_darah': golonganDarah,
      'agama': agama?.toUpperCase(),
      'alamat': alamat?.toUpperCase(),
      'no_hp': noHp,
      'email': email, // Email biasanya huruf kecil, tapi kalau mau kapital silakan
      'sekolah_asal': sekolahAsal,
      'kelas': kelas?.toUpperCase(),
      'tingkatan': tingkatan.toUpperCase(),
      'tku': tku?.toUpperCase(),
      'tahun_kmd': tahunKMD,
      'tahun_kml': tahunKML,
      'tahun_kpd': tahunKPD,
      'tahun_kpl': tahunKPL,
      'foto_url': fotoUrl,
      'status': status,
      'diinput_oleh': diinputOleh,
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Factory fromMap juga perlu disesuaikan jika nanti mau baca data (Skip dulu biar fokus input)
}