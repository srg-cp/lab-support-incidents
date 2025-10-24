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
      
      final statistics = <String, Map<String, dynamic>>{};
      
      for (final doc in labsSnapshot.docs) {
        final labData = doc.data();
        final labName = labData['name'] as String;
        final actualCount = computerCounts[labName] ?? 0;
        
        statistics[labName] = {
          ...labData,
          'actualComputerCount': actualCount,
          'hasRegisteredComputers': actualCount > 0,
        };
      }
      
      return statistics;
    } catch (e) {
      rethrow;
    }
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