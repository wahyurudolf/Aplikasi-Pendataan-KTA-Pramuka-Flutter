import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String namaLengkap;
  final String role; // 'super_admin', 'korlap', 'sekolah', 'staff_pendataan', 'produksi'
  final String? wilayah; // Opsional
  final String? sekolahId; // Opsional
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.namaLengkap,
    required this.role,
    this.wilayah,
    this.sekolahId,
    required this.createdAt,
  });

  // Data dari Firebase -> ke Object Dart
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      namaLengkap: data['nama_lengkap'] ?? '',
      role: data['role'] ?? 'sekolah', // Default role jika error
      wilayah: data['wilayah'],
      sekolahId: data['sekolah_id'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  // Object Dart -> ke JSON untuk dikirim ke Firebase
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'nama_lengkap': namaLengkap,
      'role': role,
      'wilayah': wilayah,
      'sekolah_id': sekolahId,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}