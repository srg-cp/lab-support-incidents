import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'computer_initializer.dart';

/// Script para inicializar computadoras en la base de datos
/// 
/// Para ejecutar este script:
/// 1. Asegúrate de que Firebase esté configurado
/// 2. Llama a setupComputers() desde main.dart o desde una pantalla de administración
/// 3. El script creará 20 computadoras HP para cada laboratorio (A, B, C, D, E, F)

class ComputerSetup {
  static Future<void> setupComputers() async {
    try {
      // Inicializar Firebase si no está inicializado
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final initializer = ComputerInitializer();
      
      print('🚀 Iniciando configuración de computadoras...');
      print('');
      
      // Inicializar todas las computadoras
      await initializer.initializeAllLabs(computersPerLab: 20);
      
      print('');
      print('✅ Configuración completada exitosamente!');
      
    } catch (e) {
      print('❌ Error durante la configuración: $e');
      rethrow;
    }
  }

  /// Método para limpiar todas las computadoras (útil para testing)
  static Future<void> clearAllComputers() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final initializer = ComputerInitializer();
      
      print('🧹 Limpiando todas las computadoras...');
      await initializer.clearAllComputers();
      print('✅ Limpieza completada!');
      
    } catch (e) {
      print('❌ Error durante la limpieza: $e');
      rethrow;
    }
  }

  /// Método para inicializar un laboratorio específico
  static Future<void> setupSingleLab(String labName, {int count = 20}) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final initializer = ComputerInitializer();
      
      print('🚀 Configurando Laboratorio $labName...');
      await initializer.initializeLabComputers(labName, count: count);
      print('✅ Laboratorio $labName configurado!');
      
    } catch (e) {
      print('❌ Error configurando Laboratorio $labName: $e');
      rethrow;
    }
  }
}