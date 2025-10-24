import 'package:cloud_firestore/cloud_firestore.dart';
import 'computer_service.dart';

class LabService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ComputerService _computerService = ComputerService();

  // Obtener todos los laboratorios
  Stream<QuerySnapshot> getLabs() {
    return _firestore.collection('labs').orderBy('name').snapshots();
  }

  // Obtener un laboratorio específico
  Future<DocumentSnapshot> getLab(String labName) {
    return _firestore.collection('labs').doc(labName).get();
  }

  // Obtener información completa del laboratorio con computadoras
  Future<Map<String, dynamic>> getLabWithComputers(String labName) async {
    try {
      final labDoc = await getLab(labName);
      final computerCounts = await _computerService.getComputerCountByLab();
      
      final labData = labDoc.exists ? labDoc.data() as Map<String, dynamic> : {};
      final actualComputerCount = computerCounts[labName] ?? 0;
      
      return {
        ...labData,
        'actualComputerCount': actualComputerCount,
        'registeredComputers': actualComputerCount,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar número de computadoras (mantener compatibilidad)
  Future<void> updateLabComputers(String labName, int newCount) async {
    try {
      await _firestore.collection('labs').doc(labName).update({
        'studentComputers': newCount,
        'totalComputers': newCount + 1, // +1 por la computadora del docente
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Crear laboratorio (si no existe)
  Future<void> createLab(String labName, int studentComputers) async {
    try {
      await _firestore.collection('labs').doc(labName).set({
        'name': labName,
        'studentComputers': studentComputers,
        'teacherComputers': 1,
        'totalComputers': studentComputers + 1,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Crear laboratorio dinámicamente
  Future<void> createLabDynamic(String labName, {
    int studentComputers = 0,
    bool hasTeacherPC = true,
    bool hasProjector = true,
    String type = 'lab'
  }) async {
    try {
      final teacherComputers = hasTeacherPC ? 1 : 0;
      final projectors = hasProjector ? 1 : 0;
      
      await _firestore.collection('labs').doc(labName).set({
        'name': labName,
        'studentComputers': studentComputers,
        'teacherComputers': teacherComputers,
        'projectors': projectors,
        'totalComputers': studentComputers + teacherComputers + projectors,
        'type': type, // 'lab' o 'classroom'
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Actualizar configuración de laboratorio
  Future<void> updateLabConfiguration(String labName, {
    int? studentComputers,
    bool? hasTeacherPC,
    bool? hasProjector,
    String? type,
  }) async {
    try {
      final doc = await _firestore.collection('labs').doc(labName).get();
      if (!doc.exists) {
        throw Exception('El laboratorio $labName no existe');
      }

      final currentData = doc.data() as Map<String, dynamic>;
      final updatedStudentComputers = studentComputers ?? currentData['studentComputers'] ?? 0;
      final updatedTeacherComputers = (hasTeacherPC ?? (currentData['teacherComputers'] ?? 0) > 0) ? 1 : 0;
      final updatedProjectors = (hasProjector ?? (currentData['projectors'] ?? 0) > 0) ? 1 : 0;

      await _firestore.collection('labs').doc(labName).update({
        if (studentComputers != null) 'studentComputers': studentComputers,
        if (hasTeacherPC != null) 'teacherComputers': updatedTeacherComputers,
        if (hasProjector != null) 'projectors': updatedProjectors,
        if (type != null) 'type': type,
        'totalComputers': updatedStudentComputers + updatedTeacherComputers + updatedProjectors,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar laboratorio
  Future<void> deleteLab(String labName) async {
    try {
      await _firestore.collection('labs').doc(labName).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Inicializar laboratorios por defecto
  Future<void> initializeDefaultLabs() async {
    final labs = ['A', 'B', 'C', 'D', 'E', 'F'];
    
    for (final lab in labs) {
      final doc = await _firestore.collection('labs').doc(lab).get();
      if (!doc.exists) {
        await createLab(lab, 20);
      }
    }
  }

  // Obtener estadísticas de todos los laboratorios
  Future<Map<String, Map<String, dynamic>>> getAllLabsStatistics() async {
    try {
      final labsSnapshot = await _firestore.collection('labs').get();
      final computerCounts = await _computerService.getComputerCountByLab();
      final equipmentCounts = await _computerService.getEquipmentCountsByLab();
      
      final statistics = <String, Map<String, dynamic>>{};
      
      for (final doc in labsSnapshot.docs) {
        final labData = doc.data();
        final labName = labData['name'] as String;
        final actualCount = computerCounts[labName] ?? 0;
        final equipment = equipmentCounts[labName] ?? {};
        
        statistics[labName] = {
          ...labData,
          'actualComputerCount': actualCount,
          'hasRegisteredComputers': actualCount > 0,
          'studentComputers': equipment['student'] ?? 0,
          'teacherComputers': equipment['teacher'] ?? 0,
          'projectors': equipment['projector'] ?? 0,
          'type': labData['type'] ?? 'lab',
        };
      }
      
      return statistics;
    } catch (e) {
      rethrow;
    }
  }

  // Obtener estadísticas de todos los laboratorios en tiempo real
  Stream<Map<String, Map<String, dynamic>>> getAllLabsStatisticsStream() {
    // Combinar streams de labs y computers para obtener datos en tiempo real
    return _firestore.collection('labs').snapshots().asyncMap((labsSnapshot) async {
      try {
        // Obtener conteos actuales de computadoras
        final computerSnapshot = await _firestore
            .collection('computers')
            .where('isActive', isEqualTo: true)
            .get();
        
        // Calcular conteos por laboratorio y tipo
        final computerCounts = <String, int>{};
        final equipmentCounts = <String, Map<String, int>>{};
        
        for (final doc in computerSnapshot.docs) {
          final data = doc.data();
          final labName = data['labName'] as String;
          final equipmentType = data['equipmentType'] as String? ?? 'student';
          
          // Conteo total
          computerCounts[labName] = (computerCounts[labName] ?? 0) + 1;
          
          // Conteo por tipo
          if (!equipmentCounts.containsKey(labName)) {
            equipmentCounts[labName] = {'student': 0, 'teacher': 0, 'projector': 0};
          }
          equipmentCounts[labName]![equipmentType] = (equipmentCounts[labName]![equipmentType] ?? 0) + 1;
        }
        
        final statistics = <String, Map<String, dynamic>>{};
        
        for (final doc in labsSnapshot.docs) {
          final labData = doc.data();
          final labName = labData['name'] as String;
          final actualCount = computerCounts[labName] ?? 0;
          final equipment = equipmentCounts[labName] ?? {'student': 0, 'teacher': 0, 'projector': 0};
          
          statistics[labName] = {
            ...labData,
            'actualComputerCount': actualCount,
            'hasRegisteredComputers': actualCount > 0,
            'studentComputers': equipment['student'] ?? 0,
            'teacherComputers': equipment['teacher'] ?? 0,
            'projectors': equipment['projector'] ?? 0,
            'type': labData['type'] ?? 'lab',
          };
        }
        
        return statistics;
      } catch (e) {
        rethrow;
      }
    });
  }

  // Sincronizar conteo de computadoras
  Future<void> syncComputerCounts() async {
    try {
      final computerCounts = await _computerService.getComputerCountByLab();
      
      for (final entry in computerCounts.entries) {
        final labName = entry.key;
        final count = entry.value;
        
        await updateLabComputers(labName, count);
      }
    } catch (e) {
      rethrow;
    }
  }
}