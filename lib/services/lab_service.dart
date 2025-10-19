import 'package:cloud_firestore/cloud_firestore.dart';

class LabService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener todos los laboratorios
  Stream<QuerySnapshot> getLabs() {
    return _firestore.collection('labs').orderBy('name').snapshots();
  }

  // Obtener un laboratorio específico
  Future<DocumentSnapshot> getLab(String labName) {
    return _firestore.collection('labs').doc(labName).get();
  }

  // Actualizar número de computadoras
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
}