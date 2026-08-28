import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final task = await ref
          .putFile(file)
          .timeout(const Duration(seconds: 45), onTimeout: () => throw TimeoutException('Upload took too long. Please check internet and Firebase Storage rules.'));
      return await task.ref
          .getDownloadURL()
          .timeout(const Duration(seconds: 20), onTimeout: () => throw TimeoutException('Uploaded, but download URL was not received.'));
    } on FirebaseException catch (e) {
      throw Exception('Firebase Storage upload failed: ${e.message ?? e.code}. Please check Storage rules and bucket setup.');
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Upload timeout. Please try again with a stable internet connection.');
    }
  }

  Future<String> uploadImage(File image, String path) {
    return uploadFile(image, path);
  }
}
