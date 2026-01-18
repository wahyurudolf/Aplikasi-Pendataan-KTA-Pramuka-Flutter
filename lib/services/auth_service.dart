import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk memantau status login (Realtime)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fungsi Login Email & Password (DIPERBAIKI)
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Menangani kode error spesifik dari Firebase
      String message = '';
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak ditemukan.';
          break;
        case 'wrong-password':
          message = 'Password salah.';
          break;
        case 'invalid-credential': // <--- INI PENYEBAB ERROR KEMARIN
          message = 'Email atau Password salah.';
          break;
        case 'user-disabled':
          message = 'Akun telah dinonaktifkan.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan login. Tunggu sebentar.';
          break;
        default:
          message = 'Login Gagal: ${e.message}';
      }
      
      // Lempar pesan bahasa Indonesia ini ke UI (SnackBar)
      throw message; 
    } catch (e) {
      // Error lain (koneksi internet, dll)
      throw 'Terjadi kesalahan sistem. Periksa koneksi internet.';
    }
  }

  // Fungsi Ambil Role User dari Firestore
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        // Data role diambil dari sini (termasuk role baru supervisor_produksi)
        return doc['role'] ?? 'sekolah'; 
      }
      return 'sekolah';
    } catch (e) {
      return 'sekolah';
    }
  }

  // Fungsi Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}