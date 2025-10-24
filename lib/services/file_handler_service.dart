import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

class FileHandlerService {
  // Obtener la ruta del directorio de documentos
  static Future<String> getDocumentsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Verificar si un archivo existe
  static Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  // Obtener todos los PDFs de reportes de incidentes
  static Future<List<File>> getIncidentReportPdfs() async {
    try {
      final documentsPath = await getDocumentsPath();
      final directory = Directory(documentsPath);
      
      if (!await directory.exists()) {
        return [];
      }

      final files = await directory.list().toList();
      final pdfFiles = files
          .where((file) => 
              file is File && 
              file.path.toLowerCase().endsWith('.pdf') &&
              file.path.contains('reporte_incidente_'))
          .cast<File>()
          .toList();

      // Ordenar por fecha de modificación (más recientes primero)
      pdfFiles.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return bStat.modified.compareTo(aStat.modified);
      });

      return pdfFiles;
    } catch (e) {
      print('Error obteniendo PDFs: $e');
      return [];
    }
  }

  // Obtener información de un PDF
  static Future<Map<String, dynamic>> getPdfInfo(File pdfFile) async {
    try {
      final stat = await pdfFile.stat();
      final fileName = pdfFile.path.split(Platform.pathSeparator).last;
      
      // Extraer ID del incidente del nombre del archivo
      String? incidentId;
      final regex = RegExp(r'reporte_incidente_([^_]+)_');
      final match = regex.firstMatch(fileName);
      if (match != null) {
        incidentId = match.group(1);
      }

      return {
        'fileName': fileName,
        'filePath': pdfFile.path,
        'size': stat.size,
        'lastModified': stat.modified,
        'incidentId': incidentId,
      };
    } catch (e) {
      print('Error obteniendo información del PDF: $e');
      return {
        'fileName': 'Desconocido',
        'filePath': pdfFile.path,
        'size': 0,
        'lastModified': DateTime.now(),
        'incidentId': null,
      };
    }
  }

  // Formatear el tamaño del archivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  // Eliminar un archivo PDF
  static Future<bool> deletePdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error eliminando PDF: $e');
      return false;
    }
  }

  // Abrir un archivo PDF
  static Future<bool> openPdf(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final result = await OpenFile.open(filePath);
        return result.type == ResultType.done;
      }
      return false;
    } catch (e) {
      print('Error abriendo PDF: $e');
      return false;
    }
  }

  // Compartir un archivo PDF
  static Future<bool> sharePdf(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Reporte de incidente: $fileName',
          subject: 'Reporte PDF - $fileName',
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error compartiendo PDF: $e');
      return false;
    }
  }

  // Copiar archivo a la carpeta de descargas (Android)
  static Future<String?> copyToDownloads(String filePath, String fileName) async {
    try {
      if (Platform.isAndroid) {
        // En Android, intentar copiar a la carpeta de descargas
        final downloadsPath = '/storage/emulated/0/Download';
        final downloadsDir = Directory(downloadsPath);
        
        if (await downloadsDir.exists()) {
          final newPath = '$downloadsPath/$fileName';
          final sourceFile = File(filePath);
          final targetFile = File(newPath);
          
          await sourceFile.copy(newPath);
          return newPath;
        }
      }
      
      // Para otras plataformas o si falla, devolver la ruta original
      return filePath;
    } catch (e) {
      print('Error copiando a descargas: $e');
      return filePath;
    }
  }

  // Obtener la ruta de descargas del usuario
  static Future<String?> getDownloadsPath() async {
    try {
      if (Platform.isAndroid) {
        return '/storage/emulated/0/Download';
      } else if (Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          return '$userProfile\\Downloads';
        }
      } else if (Platform.isMacOS || Platform.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          return '$home/Downloads';
        }
      }
      
      // Fallback a documentos
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      print('Error obteniendo ruta de descargas: $e');
      return null;
    }
  }
}