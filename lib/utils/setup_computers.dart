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

  /// Método para agregar equipos faltantes a laboratorios existentes
  static Future<void> addMissingEquipmentToAllLabs() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final initializer = ComputerInitializer();
      
      print('🔧 Agregando equipos faltantes a todos los laboratorios...');
      
      // Lista de laboratorios existentes (se puede obtener dinámicamente de Firebase)
      final labs = ['A', 'B', 'C', 'D', 'E', 'F'];
      
      for (final lab in labs) {
        await initializer.addMissingEquipmentToLab(lab);
        await Future.delayed(const Duration(milliseconds: 500)); // Pausa entre laboratorios
      }
      
      print('✅ Equipos faltantes agregados a todos los laboratorios!');
      
    } catch (e) {
      print('❌ Error agregando equipos faltantes: $e');
      rethrow;
    }
  }

  /// Método para crear un salón (solo proyector y PC docente)
  static Future<void> setupClassroom(String classroomName) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final initializer = ComputerInitializer();
      
      print('🏫 Configurando Salón $classroomName...');
      await initializer.initializeLabWithConfig(
        classroomName,
        studentComputers: 0,
        includeTeacherPC: true,
        includeProjector: true,
        labType: 'classroom',
      );
      print('✅ Salón $classroomName configurado!');
      
    } catch (e) {
      print('❌ Error configurando Salón $classroomName: $e');
      rethrow;
    }
  }

  /// Método para configurar todos los salones Q
  static Future<void> setupAllClassrooms() async {
    try {
      final classrooms = ['Q301', 'Q305', 'Q307', 'Q309', 'Q312'];
      
      print('🏫 Configurando todos los salones...');
      
      for (final classroom in classrooms) {
        await setupClassroom(classroom);
        await Future.delayed(const Duration(milliseconds: 500)); // Pausa entre salones
      }
      
      print('✅ Todos los salones configurados!');
      
    } catch (e) {
      print('❌ Error configurando salones: $e');
      rethrow;
    }
  }
}