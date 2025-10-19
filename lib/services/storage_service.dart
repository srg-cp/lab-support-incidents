import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class StorageService {
  
  // Convertir imagen a base64
  Future<String> convertImageToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      
      // Verificar que el archivo no sea demasiado grande (máximo 1MB)
      if (bytes.length > 1024 * 1024) {
        throw Exception('La imagen es demasiado grande. Máximo 1MB permitido.');
      }
      
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Error al procesar imagen: $e');
    }
  }

  // Convertir base64 a bytes para mostrar imagen
  Uint8List base64ToBytes(String base64String) {
    try {
      // Remover el prefijo data:image/jpeg;base64, si existe
      final cleanBase64 = base64String.replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '');
      return base64Decode(cleanBase64);
    } catch (e) {
      throw Exception('Error al decodificar imagen: $e');
    }
  }

  // Validar que el archivo sea una imagen
  bool isValidImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  // Obtener el tamaño del archivo en MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Comprimir imagen si es necesario (función auxiliar)
  Future<File> compressImageIfNeeded(File file) async {
    try {
      final sizeInMB = getFileSizeInMB(file);
      
      if (sizeInMB <= 1.0) {
        return file; // No necesita compresión
      }
      
      // Si es mayor a 1MB, lanzar error pidiendo al usuario que use una imagen más pequeña
      throw Exception('La imagen es demasiado grande (${sizeInMB.toStringAsFixed(2)}MB). Por favor, usa una imagen menor a 1MB.');
    } catch (e) {
      rethrow;
    }
  }
}
