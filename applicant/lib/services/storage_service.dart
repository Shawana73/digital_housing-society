class StorageService {
  Future<String> uploadFile(Object file, String path) async {
    throw UnsupportedError('Direct file storage is not configured in this build. Document records are saved in Firestore.');
  }

  Future<String> uploadImage(Object image, String path) => uploadFile(image, path);
}
