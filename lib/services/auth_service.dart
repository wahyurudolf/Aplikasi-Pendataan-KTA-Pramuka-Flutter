import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream untuk memantau status login (Realtime)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Fungsi Login Email & Password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      debugPrint("Error Login: $e");
      rethrow; // Lempar error ke UI biar muncul notifikasi
    }
  }

  // Fungsi Ambil Role User dari Firestore
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc['role'] ?? 'sekolah'; // Default ke sekolah jika error
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