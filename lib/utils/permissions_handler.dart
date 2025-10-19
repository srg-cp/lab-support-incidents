import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_modal.dart';

class PermissionsHandler {
  // Solicitar permiso de cámara
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        CustomModal.show(
          context,
          type: ModalType.warning,
          title: 'Permiso Requerido',
          message: 'La aplicación necesita acceso a la cámara. Por favor, habilítalo en la configuración.',
          buttonText: 'Abrir Configuración',
          onConfirm: () {
            openAppSettings();
          },
        );
      }
      return false;
    }
    
    return false;
  }
  
  // Solicitar permiso de almacenamiento
  static Future<bool> requestStoragePermission(BuildContext context) async {
    final status = await Permission.storage.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.storage.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        CustomModal.show(
          context,
          type: ModalType.warning,
          title: 'Permiso Requerido',
          message: 'La aplicación necesita acceso al almacenamiento. Por favor, habilítalo en la configuración.',
          buttonText: 'Abrir Configuración',
          onConfirm: () {
            openAppSettings();
          },
        );
      }
      return false;
    }
    
    return false;
  }
  
  // Solicitar permiso de fotos (iOS)
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    final status = await Permission.photos.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        CustomModal.show(
          context,
          type: ModalType.warning,
          title: 'Permiso Requerido',
          message: 'La aplicación necesita acceso a tus fotos. Por favor, habilítalo en la configuración.',
          buttonText: 'Abrir Configuración',
          onConfirm: () {
            openAppSettings();
          },
        );
      }
      return false;
    }
    
    return false;
  }
}