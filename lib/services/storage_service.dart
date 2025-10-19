import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Subir imagen
  Future<String> uploadImage(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  // Subir video
  Future<String> uploadVideo(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al subir video: $e');
    }
  }

  // Eliminar archivo
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Error al eliminar archivo: $e');
    }
  }

  // Obtener URL de descarga
  Future<String> getDownloadURL(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al obtener URL: $e');
    }
  }
}
