import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Fungsi Upload Foto
  // Mengembalikan URL foto yang sudah diupload (String)
  Future<String?> uploadFotoMember(File imageFile, String nik) async {
    try {
      // Nama file di server: members_photo/NIK_filename.jpg
      String fileName = '${nik}_${path.basename(imageFile.path)}';
      Reference ref = _storage.ref().child('members_photo/$fileName');

      // Proses Upload
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      // Ambil URL Download
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error Upload Foto: $e");
      return null;
    }
  }
}