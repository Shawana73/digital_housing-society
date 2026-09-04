import 'dart:typed_data';

import 'package:cloudinary_public/cloudinary_public.dart';

class StorageService {
  static const String _cloudName = 'fptmdkbb';
  static const String _uploadPreset = 'digital_housing_society';

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  Future<String> uploadFile(
      Uint8List fileBytes,
      String fileName,
      ) async {
    final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
        fileBytes,
        identifier: fileName,
      ),
    );

    return response.secureUrl;
  }

  Future<String> uploadImage(
      Uint8List imageBytes,
      String fileName,
      ) {
    return uploadFile(imageBytes, fileName);
  }
}
