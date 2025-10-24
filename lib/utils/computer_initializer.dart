import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/computer_model.dart';
import '../services/computer_service.dart';
import '../services/lab_service.dart';

class ComputerInitializer {
  final ComputerService _computerService = ComputerService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LabService _labService = LabService();
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
      equipmentType: EquipmentType.student,
      createdAt: now,
      isActive: true,
      notes: 'Computadora de estudiante inicializada automáticamente - Laboratorio $labName',
    );
  }

  // Crear PC del docente
  Computer _createTeacherComputer(String labName) {
    final now = DateTime.now();
    
    return Computer(
      id: '', // Se asignará automáticamente
      labName: labName,
      computerNumber: 0, // Índice especial para PC del docente
      cpu: _createComponent('HP', _cpuModels, 'TCPU'),
      monitor: _createComponent('HP', _monitorModels, 'TMON'),
      mouse: _createComponent('HP', _mouseModels, 'TMOU'),
      keyboard: _createComponent('HP', _keyboardModels, 'TKEY'),
      equipmentType: EquipmentType.teacher,
      createdAt: now,
      isActive: true,
      notes: 'PC del docente inicializada automáticamente - Laboratorio $labName',
    );
  }

  // Crear proyector
  Computer _createProjector(String labName) {
    final projectorModels = [
      'HP MP3135',
      'HP MP3220',
      'HP MP3325',
      'HP MP3130',
    ];
    
    final now = DateTime.now();
    
    return Computer(
      id: '', // Se asignará automáticamente
      labName: labName,
      computerNumber: 999, // Índice especial para proyector
      cpu: ComputerComponent(
        brand: 'HP',
        model: 'Projector Control Unit',
        serialNumber: _generateSerialNumber('PCPU'),
      ),
      monitor: ComputerComponent(
        brand: 'HP',
        model: projectorModels[_random.nextInt(projectorModels.length)],
        serialNumber: _generateSerialNumber('PROJ'),
      ),
      mouse: ComputerComponent(
        brand: 'HP',
        model: 'Remote Control',
        serialNumber: _generateSerialNumber('PREM'),
      ),
      keyboard: ComputerComponent(
        brand: 'HP',
        model: 'Control Panel',
        serialNumber: _generateSerialNumber('PCTL'),
      ),
      equipmentType: EquipmentType.projector,
      createdAt: now,
      isActive: true,
      notes: 'Proyector inicializado automáticamente - Laboratorio $labName',
    );
  }

  // Inicializar computadoras para un laboratorio específico
  Future<void> initializeLabComputers(String labName, {
    int count = 20,
    bool includeTeacherPC = true,
    bool includeProjector = true
  }) async {
    try {
      print('Inicializando equipos para Laboratorio $labName...');
      print('- $count computadoras de estudiantes');
      if (includeTeacherPC) print('- 1 PC del docente');
      if (includeProjector) print('- 1 proyector');
      
      // Verificar si ya existen computadoras en este laboratorio
      final existingComputers = await _computerService.getComputerCountByLab();
      final currentCount = existingComputers[labName] ?? 0;
      
      if (currentCount > 0) {
        print('El Laboratorio $labName ya tiene $currentCount equipos registrados.');
        print('Continuando con la inicialización...');
      }

      int successCount = 0;
      int errorCount = 0;

      // Crear computadoras de estudiantes
      for (int i = 1; i <= count; i++) {
        try {
          final computer = _createComputer(labName, i);
          await _computerService.addComputer(computer);
          successCount++;
          print('✓ PC Estudiante $i creada para Laboratorio $labName');
        } catch (e) {
          errorCount++;
          print('✗ Error al crear PC Estudiante $i para Laboratorio $labName: $e');
        }
      }

      // Crear PC del docente
      if (includeTeacherPC) {
        try {
          final teacherPC = _createTeacherComputer(labName);
          await _computerService.addComputer(teacherPC);
          successCount++;
          print('✓ PC del Docente creada para Laboratorio $labName');
        } catch (e) {
          errorCount++;
          print('✗ Error al crear PC del Docente para Laboratorio $labName: $e');
        }
      }

      // Crear proyector
      if (includeProjector) {
        try {
          final projector = _createProjector(labName);
          await _computerService.addComputer(projector);
          successCount++;
          print('✓ Proyector creado para Laboratorio $labName');
        } catch (e) {
          errorCount++;
          print('✗ Error al crear Proyector para Laboratorio $labName: $e');
        }
      }

      print('\n=== Resumen Laboratorio $labName ===');
      print('Equipos creados exitosamente: $successCount');
      print('Errores: $errorCount');
      print('Total: ${successCount + errorCount}');
      
    } catch (e) {
      print('Error general al inicializar Laboratorio $labName: $e');
    }
  }

  // Inicializar laboratorio específico con configuración personalizada
  Future<void> initializeLabWithConfig(String labName, {
    int studentComputers = 20,
    bool includeTeacherPC = true,
    bool includeProjector = true,
    String labType = 'lab'
  }) async {
    try {
      // Crear o actualizar el laboratorio en la colección labs
      await _labService.createLabDynamic(
        labName,
        studentComputers: studentComputers,
        hasTeacherPC: includeTeacherPC,
        hasProjector: includeProjector,
        type: labType,
      );

      // Inicializar las computadoras
      await initializeLabComputers(
        labName,
        count: studentComputers,
        includeTeacherPC: includeTeacherPC,
        includeProjector: includeProjector,
      );

      print('✅ Laboratorio $labName configurado completamente');
    } catch (e) {
      print('❌ Error configurando Laboratorio $labName: $e');
      rethrow;
    }
  }

  // Método para agregar equipos faltantes a laboratorios existentes
  Future<void> addMissingEquipmentToLab(String labName) async {
    try {
      print('Verificando equipos faltantes en Laboratorio $labName...');
      
      // Obtener equipos existentes
      final snapshot = await _firestore
          .collection('computers')
          .where('labName', isEqualTo: labName)
          .where('isActive', isEqualTo: true)
          .get();

      bool hasTeacherPC = false;
      bool hasProjector = false;

      for (final doc in snapshot.docs) {
        final computer = Computer.fromMap(doc.data());
        if (computer.isTeacherComputer) hasTeacherPC = true;
        if (computer.isProjector) hasProjector = true;
      }

      int addedCount = 0;

      // Agregar PC del docente si no existe
      if (!hasTeacherPC) {
        try {
          final teacherPC = _createTeacherComputer(labName);
          await _computerService.addComputer(teacherPC);
          addedCount++;
          print('✓ PC del Docente agregada al Laboratorio $labName');
        } catch (e) {
          print('✗ Error al agregar PC del Docente: $e');
        }
      }

      // Agregar proyector si no existe
      if (!hasProjector) {
        try {
          final projector = _createProjector(labName);
          await _computerService.addComputer(projector);
          addedCount++;
          print('✓ Proyector agregado al Laboratorio $labName');
        } catch (e) {
          print('✗ Error al agregar Proyector: $e');
        }
      }

      if (addedCount == 0) {
        print('ℹ️ El Laboratorio $labName ya tiene todos los equipos necesarios');
      } else {
        print('✅ Se agregaron $addedCount equipos al Laboratorio $labName');
      }

    } catch (e) {
      print('❌ Error verificando equipos del Laboratorio $labName: $e');
    }
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

  // Método para inicializar todos los laboratorios
  Future<void> initializeAllLabs({int computersPerLab = 20}) async {
    final labs = ['A', 'B', 'C', 'D', 'E', 'F'];
    
    print('=== INICIALIZANDO TODOS LOS LABORATORIOS ===');
    print('Laboratorios a configurar: ${labs.join(', ')}');
    print('Computadoras por laboratorio: $computersPerLab');
    print('');
    
    int totalSuccess = 0;
    int totalErrors = 0;
    
    for (final lab in labs) {
      try {
        print('--- Configurando Laboratorio $lab ---');
        await initializeLabWithConfig(
          lab,
          studentComputers: computersPerLab,
          includeTeacherPC: true,
          includeProjector: true,
          labType: 'lab',
        );
        totalSuccess++;
        print('✅ Laboratorio $lab configurado exitosamente');
        print('');
      } catch (e) {
        totalErrors++;
        print('❌ Error configurando Laboratorio $lab: $e');
        print('');
      }
    }
    
    print('=== RESUMEN FINAL ===');
    print('Laboratorios configurados exitosamente: $totalSuccess');
    print('Laboratorios con errores: $totalErrors');
    print('Total de laboratorios: ${totalSuccess + totalErrors}');
    
    if (totalErrors == 0) {
      print('🎉 ¡Todos los laboratorios fueron configurados exitosamente!');
    } else {
      print('⚠️ Algunos laboratorios tuvieron errores. Revisa los logs anteriores.');
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