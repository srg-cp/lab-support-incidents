import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/computer_model.dart';
import '../services/computer_service.dart';

class ComputerInitializer {
  final ComputerService _computerService = ComputerService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Modelos reales de HP
  final List<String> _cpuModels = [
    'HP EliteDesk 800 G6',
    'HP ProDesk 400 G7',
    'HP EliteDesk 705 G5',
    'HP ProDesk 600 G6',
    'HP EliteOne 800 G6',
    'HP ProOne 440 G6',
    'HP EliteDesk 800 G5',
    'HP ProDesk 400 G6',
  ];

  final List<String> _monitorModels = [
    'HP E24 G5',
    'HP P24h G5',
    'HP E27 G5',
    'HP P27h G4',
    'HP E22 G5',
    'HP P22h G4',
    'HP E24i G4',
    'HP P24v G4',
  ];

  final List<String> _mouseModels = [
    'HP USB Optical Mouse',
    'HP Wireless Mouse 200',
    'HP USB Laser Mouse',
    'HP Comfort Grip Wireless Mouse',
    'HP Z3700 Wireless Mouse',
    'HP USB 1000dpi Laser Mouse',
  ];

  final List<String> _keyboardModels = [
    'HP USB Keyboard',
    'HP Wireless Keyboard',
    'HP USB Slim Keyboard',
    'HP Wireless Desktop 320MK',
    'HP USB Business Slim Keyboard',
    'HP Pavilion Wireless Keyboard',
  ];

  // Generar número de serie realista
  String _generateSerialNumber(String prefix) {
    final year = DateTime.now().year;
    final randomPart = _random.nextInt(999999).toString().padLeft(6, '0');
    return '$prefix$year$randomPart';
  }

  // Crear componente con datos realistas
  ComputerComponent _createComponent(String brand, List<String> models, String serialPrefix) {
    return ComputerComponent(
      brand: brand,
      model: models[_random.nextInt(models.length)],
      serialNumber: _generateSerialNumber(serialPrefix),
    );
  }

  // Crear una computadora completa
  Computer _createComputer(String labName, int computerNumber) {
    final now = DateTime.now();
    
    return Computer(
      id: '', // Se asignará automáticamente
      labName: labName,
      computerNumber: computerNumber,
      cpu: _createComponent('HP', _cpuModels, 'CPU'),
      monitor: _createComponent('HP', _monitorModels, 'MON'),
      mouse: _createComponent('HP', _mouseModels, 'MOU'),
      keyboard: _createComponent('HP', _keyboardModels, 'KEY'),
      createdAt: now,
      isActive: true,
      notes: 'Computadora inicializada automáticamente - Laboratorio $labName',
    );
  }

  // Inicializar computadoras para un laboratorio específico
  Future<void> initializeLabComputers(String labName, {int count = 20}) async {
    try {
      print('Inicializando $count computadoras para Laboratorio $labName...');
      
      // Verificar si ya existen computadoras en este laboratorio
      final existingComputers = await _computerService.getComputerCountByLab();
      final currentCount = existingComputers[labName] ?? 0;
      
      if (currentCount > 0) {
        print('El Laboratorio $labName ya tiene $currentCount computadoras registradas.');
        print('Continuando con la inicialización...');
      }

      int successCount = 0;
      int errorCount = 0;

      for (int i = 1; i <= count; i++) {
        try {
          final computer = _createComputer(labName, i);
          await _computerService.addComputer(computer);
          successCount++;
          print('✓ Computadora $i creada para Laboratorio $labName');
        } catch (e) {
          errorCount++;
          print('✗ Error al crear computadora $i para Laboratorio $labName: $e');
        }
      }

      print('\n=== Resumen Laboratorio $labName ===');
      print('Computadoras creadas exitosamente: $successCount');
      print('Errores: $errorCount');
      print('Total: ${successCount + errorCount}');
      
    } catch (e) {
      print('Error general al inicializar Laboratorio $labName: $e');
    }
  }

  // Inicializar todos los laboratorios
  Future<void> initializeAllLabs({int computersPerLab = 20}) async {
    final labs = ['A', 'B', 'C', 'D', 'E', 'F'];
    
    print('=== INICIANDO INICIALIZACIÓN DE COMPUTADORAS ===');
    print('Laboratorios a procesar: ${labs.join(', ')}');
    print('Computadoras por laboratorio: $computersPerLab');
    print('Total de computadoras a crear: ${labs.length * computersPerLab}');
    print('');

    for (final lab in labs) {
      await initializeLabComputers(lab, count: computersPerLab);
      print(''); // Línea en blanco entre laboratorios
      
      // Pequeña pausa para no sobrecargar Firestore
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Obtener estadísticas finales
    final finalCounts = await _computerService.getComputerCountByLab();
    
    print('=== RESUMEN FINAL ===');
    for (final lab in labs) {
      final count = finalCounts[lab] ?? 0;
      print('Laboratorio $lab: $count computadoras');
    }
    
    print('\nInicialización completada.');
  }

  // Método para limpiar computadoras de un laboratorio (útil para testing)
  Future<void> clearLabComputers(String labName) async {
    try {
      print('Eliminando computadoras del Laboratorio $labName...');
      
      // Obtener todas las computadoras del laboratorio
      final snapshot = await _firestore
          .collection('computers')
          .where('labName', isEqualTo: labName)
          .where('isActive', isEqualTo: true)
          .get();

      int deletedCount = 0;
      for (final doc in snapshot.docs) {
        await _computerService.deleteComputer(doc.id);
        deletedCount++;
      }

      print('✓ $deletedCount computadoras eliminadas del Laboratorio $labName');
    } catch (e) {
      print('Error al limpiar Laboratorio $labName: $e');
    }
  }

  // Método para limpiar todas las computadoras (útil para testing)
  Future<void> clearAllComputers() async {
    final labs = ['A', 'B', 'C', 'D', 'E', 'F'];
    
    print('=== LIMPIANDO TODAS LAS COMPUTADORAS ===');
    
    for (final lab in labs) {
      await clearLabComputers(lab);
    }
    
    print('Limpieza completada.');
  }
}