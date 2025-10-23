import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'storage_service.dart';

class IncidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Verificar computadoras con incidentes activos
  Future<Map<int, String>> getComputersWithActiveIncidents(String labName) async {
    try {
      final query = await _firestore
          .collection('incidents')
          .where('labName', isEqualTo: labName)
          .where('status', whereIn: ['pending', 'inProgress'])
          .get();

      Map<int, String> computersWithIncidents = {};
      
      for (var doc in query.docs) {
        final data = doc.data();
        final computerNumbers = List<int>.from(data['computerNumbers'] ?? []);
        final status = data['status'] as String;
        
        for (int computerNumber in computerNumbers) {
          computersWithIncidents[computerNumber] = status;
        }
      }
      
      return computersWithIncidents;
    } catch (e) {
      return {};
    }
  }

  // Crear nuevo incidente
  Future<String> createIncident({
    required String labName,
    required List<int> computerNumbers,
    required String incidentType,
    String? description,
    File? evidenceFile,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Verificar si alguna computadora ya tiene un incidente activo
      final computersWithIncidents = await getComputersWithActiveIncidents(labName);
      final conflictingComputers = computerNumbers.where((pc) => 
          computersWithIncidents.containsKey(pc)).toList();
      
      if (conflictingComputers.isNotEmpty) {
        final pcList = conflictingComputers.map((pc) => 'PC $pc').join(', ');
        throw Exception('Las siguientes computadoras ya tienen incidentes activos: $pcList. '
            'Espera a que se resuelvan antes de reportar nuevos incidentes.');
      }

      // Convertir imagen a base64 si existe
      String? evidenceBase64;
      if (evidenceFile != null) {
        // Validar que sea una imagen
        if (!_storageService.isValidImageFile(evidenceFile)) {
          throw Exception('Solo se permiten archivos de imagen (JPG, JPEG, PNG)');
        }
        
        // Comprimir si es necesario
        final compressedFile = await _storageService.compressImageIfNeeded(evidenceFile);
        evidenceBase64 = await _storageService.convertImageToBase64(compressedFile);
      }

      // Crear documento de incidente
      final incidentData = {
        'labName': labName,
        'computerNumbers': computerNumbers,
        'incidentType': incidentType,
        'description': description,
        'status': 'pending',
        'reportedBy': {
          'uid': user.uid,
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'Usuario',
          'email': user.email,
        },
        'reportedAt': FieldValue.serverTimestamp(),
        'evidenceImage': evidenceBase64, // Cambiado de evidenceUrl a evidenceImage
        'assignedTo': null,
        'assignedAt': null,
        'resolvedAt': null,
        'resolutionImage': null, // Cambiado de resolutionUrl a resolutionImage
        'resolutionNotes': null,
      };

      final docRef = await _firestore.collection('incidents').add(incidentData);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Obtener incidentes (con filtros opcionales)
  Stream<QuerySnapshot> getIncidents({
    String? status,
    String? labName,
    String? assignedToUid,
  }) {
    Query query = _firestore.collection('incidents').orderBy('reportedAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    if (labName != null) {
      query = query.where('labName', isEqualTo: labName);
    }

    if (assignedToUid != null) {
      query = query.where('assignedTo.uid', isEqualTo: assignedToUid);
    }

    return query.snapshots();
  }

  // Obtener incidentes de un usuario específico
  Stream<QuerySnapshot> getUserIncidents(String uid) {
    return _firestore
        .collection('incidents')
        .where('reportedBy.uid', isEqualTo: uid)
        .snapshots();
  }

  // Alias para mayor claridad en la pantalla de estudiantes
  Stream<QuerySnapshot> getIncidentsByUser(String uid) {
    return getUserIncidents(uid);
  }

  // Verificar incidentes activos de un usuario de soporte
  Future<int> getActiveIncidentsCount(String supportUid) async {
    try {
      final query = await _firestore
          .collection('incidents')
          .where('assignedTo.uid', isEqualTo: supportUid)
          .where('status', whereIn: ['inProgress', 'onHold'])
          .get();
      
      return query.docs.length;
    } catch (e) {
      return 0;
    }
  }

  // Tomar incidente (asignar a soporte)
  Future<void> takeIncident(String incidentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      // Verificar límite de incidentes activos (máximo 2)
      final activeCount = await getActiveIncidentsCount(user.uid);
      if (activeCount >= 2) {
        throw Exception('No puedes tomar más incidentes. Ya tienes 2 incidentes activos. Resuelve o cancela alguno antes de tomar otro.');
      }

      await _firestore.collection('incidents').doc(incidentId).update({
        'status': 'inProgress',
        'assignedTo': {
          'uid': user.uid,
          'name': user.displayName ?? user.email?.split('@')[0] ?? 'Soporte',
        },
        'assignedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Resolver incidente
  Future<void> resolveIncident({
    required String incidentId,
    required String status, // 'resolved', 'cancelled', 'onHold'
    String? notes,
    File? resolutionFile,
  }) async {
    try {
      // Convertir imagen de resolución a base64 si existe
      String? resolutionBase64;
      if (resolutionFile != null) {
        // Validar que sea una imagen
        if (!_storageService.isValidImageFile(resolutionFile)) {
          throw Exception('Solo se permiten archivos de imagen (JPG, JPEG, PNG)');
        }
        
        // Comprimir si es necesario
        final compressedFile = await _storageService.compressImageIfNeeded(resolutionFile);
        resolutionBase64 = await _storageService.convertImageToBase64(compressedFile);
      }

      final Map<String, Object?> updateData = {
        'status': status,
        'resolutionNotes': notes,
        'resolutionImage': resolutionBase64, // Cambiado de resolutionUrl a resolutionImage
      };

      if (status == 'resolved') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'cancelled') {
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('incidents').doc(incidentId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Obtener estadísticas (para dashboard admin)
  Future<Map<String, int>> getStatistics() async {
    try {
      final pendingQuery = await _firestore
          .collection('incidents')
          .where('status', isEqualTo: 'pending')
          .get();

      final inProgressQuery = await _firestore
          .collection('incidents')
          .where('status', isEqualTo: 'inProgress')
          .get();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      final resolvedTodayQuery = await _firestore
          .collection('incidents')
          .where('status', isEqualTo: 'resolved')
          .where('resolvedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .get();

      final monthStart = DateTime(now.year, now.month, 1);
      
      final totalMonthQuery = await _firestore
          .collection('incidents')
          .where('reportedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .get();

      return {
        'pending': pendingQuery.docs.length,
        'inProgress': inProgressQuery.docs.length,
        'resolvedToday': resolvedTodayQuery.docs.length,
        'totalMonth': totalMonthQuery.docs.length,
      };
    } catch (e) {
      return {
        'pending': 0,
        'inProgress': 0,
        'resolvedToday': 0,
        'totalMonth': 0,
      };
    }
  }

  // Obtener estadísticas específicas para usuario de soporte
  Future<Map<String, int>> getSupportUserStatistics(String supportUid) async {
    try {
      final now = DateTime.now();
      
      // Inicio de la semana (lunes)
      final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      
      // Incidentes resueltos esta semana
      final resolvedThisWeekQuery = await _firestore
          .collection('incidents')
          .where('assignedTo.uid', isEqualTo: supportUid)
          .where('status', isEqualTo: 'resolved')
          .where('resolvedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .get();

      // Total de incidentes resueltos (histórico)
      final totalResolvedQuery = await _firestore
          .collection('incidents')
          .where('assignedTo.uid', isEqualTo: supportUid)
          .where('status', isEqualTo: 'resolved')
          .get();

      // Incidentes cancelados
      final cancelledQuery = await _firestore
          .collection('incidents')
          .where('assignedTo.uid', isEqualTo: supportUid)
          .where('status', isEqualTo: 'cancelled')
          .get();

      // Incidentes en espera
      final onHoldQuery = await _firestore
          .collection('incidents')
          .where('assignedTo.uid', isEqualTo: supportUid)
          .where('status', isEqualTo: 'onHold')
          .get();

      // Incidentes activos (en progreso)
      final activeQuery = await _firestore
          .collection('incidents')
          .where('assignedTo.uid', isEqualTo: supportUid)
          .where('status', isEqualTo: 'inProgress')
          .get();

      return {
        'resolvedThisWeek': resolvedThisWeekQuery.docs.length,
        'totalResolved': totalResolvedQuery.docs.length,
        'cancelled': cancelledQuery.docs.length,
        'onHold': onHoldQuery.docs.length,
        'active': activeQuery.docs.length,
      };
    } catch (e) {
      return {
        'resolvedThisWeek': 0,
        'totalResolved': 0,
        'cancelled': 0,
        'onHold': 0,
        'active': 0,
      };
    }
  }
}