import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';

class FirestoreService {
  final CollectionReference _membersRef =
      FirebaseFirestore.instance.collection('members');

  // 1. Tambah Data Baru (Draft/Submitted)
  Future<void> addMember(MemberModel member) async {
    try {
      // Kita pakai .doc(nik) agar NIK jadi ID dokumen (mencegah duplikat NIK)
      // Atau pakai .add() kalau mau ID acak. Sesuai requestmu: Auto-generated atau NIK.
      // Kita pakai Auto-Generated biar aman kalau NIK diedit.
      await _membersRef.add(member.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // 2. Ambil Stream Data (Untuk List di Dashboard)
  // Filter berdasarkan User ID (Sekolah hanya bisa lihat datanya sendiri)
  Stream<QuerySnapshot> getMembersBySchool(String uidSekolah) {
    return _membersRef
        .where('diinput_oleh', isEqualTo: uidSekolah)
        .orderBy('updated_at', descending: true)
        .snapshots();
  }
  
  // Nanti kita tambah fungsi updateStatus, delete, dll di sini.
}