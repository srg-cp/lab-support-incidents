import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'storage_service.dart';
import '../utils/error_handler.dart';

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
        throw ComputerConflictException('Las siguientes computadoras ya tienen incidentes activos: $pcList. '
            'Espera a que se resuelvan antes de reportar nuevos incidentes.');
      }

      // Convertir imagen a base64 si existe
      String? evidenceBase64;
      if (evidenceFile != null) {
        // Validar que sea una imagen
        if (!_storageService.isValidImageFile(evidenceFile)) {
          throw ValidationException('Solo se permiten archivos de imagen (JPG, JPEG, PNG)');
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
    // Para evitar problemas de índices, solo permitir un filtro a la vez
    if (assignedToUid != null) {
      return getAssignedIncidents(assignedToUid);
    }
    
    if (status == 'pending') {
      return getPendingIncidents();
    }
    
    if (labName != null) {
      return getIncidentsByLab(labName);
    }
    
    // Si no hay filtros específicos, devolver todos los incidentes
    return getAllIncidents();
  }

  // Obtener incidentes de un usuario específico
  Stream<QuerySnapshot> getUserIncidents(String uid) {
    return _firestore
        .collection('incidents')
        .where('reportedBy.uid', isEqualTo: uid)
        .orderBy('reportedAt', descending: true)
        .snapshots();
  }

  // Versión temporal sin ordenamiento para evitar problemas de índices
  Stream<QuerySnapshot> getUserIncidentsSimple(String uid) {
    return _firestore
        .collection('incidents')
        .where('reportedBy.uid', isEqualTo: uid)
        .snapshots();
  }

  // Método específico para obtener incidentes pendientes
  Stream<QuerySnapshot> getPendingIncidents() {
    return _firestore
        .collection('incidents')
        .where('status', isEqualTo: 'pending')
        .orderBy('reportedAt', descending: true)
        .snapshots();
  }

  // Método específico para obtener incidentes asignados a un usuario de soporte
  Stream<QuerySnapshot> getAssignedIncidents(String supportUid) {
    return _firestore
        .collection('incidents')
        .where('assignedTo.uid', isEqualTo: supportUid)
        .orderBy('reportedAt', descending: true)
        .snapshots();
  }

  // Método específico para obtener todos los incidentes
  Stream<QuerySnapshot> getAllIncidents() {
    return _firestore
        .collection('incidents')
        .orderBy('reportedAt', descending: true)
        .snapshots();
  }

  // Método específico para obtener incidentes por laboratorio
  Stream<QuerySnapshot> getIncidentsByLab(String labName) {
    return _firestore
        .collection('incidents')
        .where('labName', isEqualTo: labName)
        .orderBy('reportedAt', descending: true)
        .snapshots();
  }

  // Alias para mayor claridad en la pantalla de estudiantes
  Stream<QuerySnapshot> getIncidentsByUser(String uid) {
    return getUserIncidentsSimple(uid);
  }

  // Método de diagnóstico para probar consultas
  Future<void> testQueries() async {
    try {
      print('🔍 Probando consulta básica...');
      final basicQuery = await _firestore
          .collection('incidents')
          .orderBy('reportedAt', descending: true)
          .limit(1)
          .get();
      print('✅ Consulta básica exitosa: ${basicQuery.docs.length} documentos');

      print('🔍 Probando consulta por estado...');
      final statusQuery = await _firestore
          .collection('incidents')
          .where('status', isEqualTo: 'pending')
          .orderBy('reportedAt', descending: true)
          .limit(1)
          .get();
      print('✅ Consulta por estado exitosa: ${statusQuery.docs.length} documentos');

      print('🔍 Probando consulta por usuario asignado...');
      final assignedQuery = await _firestore
          .collection('incidents')
          .where('assignedTo.uid', isEqualTo: 'test-uid')
          .orderBy('reportedAt', descending: true)
          .limit(1)
          .get();
      print('✅ Consulta por usuario asignado exitosa: ${assignedQuery.docs.length} documentos');

    } catch (e) {
      print('❌ Error en consulta: $e');
    }
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

      // Verificar que el usuario sea de soporte
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en la base de datos');
      }
      
      final userData = userDoc.data();
      final userRole = userData?['role'];
      
      if (userRole != 'support') {
        throw Exception('Solo el personal de soporte puede tomar incidentes');
      }

      // Verificar límite de incidentes activos (máximo 2)
      final activeCount = await getActiveIncidentsCount(user.uid);
      if (activeCount >= 2) {
        throw IncidentLimitException('No puedes tomar más incidentes. Ya tienes 2 incidentes activos. Resuelve o cancela alguno antes de tomar otro.');
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
        'resolutionNotes': notes,
        'resolutionImage': resolutionBase64, // Cambiado de resolutionUrl a resolutionImage
      };

      if (status == 'resolved') {
        updateData['status'] = 'resolved';
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      } else if (status == 'cancelled') {
        // Cuando se cancela un incidente, vuelve al estado 'pending' 
        // y se quita la asignación para que otro técnico pueda tomarlo
        updateData['status'] = 'pending';
        updateData['assignedTo'] = null;
        updateData['assignedAt'] = null;
        updateData['cancelledAt'] = FieldValue.serverTimestamp();
        updateData['cancelledBy'] = {
          'uid': _auth.currentUser?.uid,
          'name': _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@')[0] ?? 'Soporte',
        };
      } else if (status == 'onHold') {
        updateData['status'] = 'onHold';
      } else {
        updateData['status'] = status;
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

  // Métodos temporales sin ordenamiento para evitar problemas de índices
  Stream<QuerySnapshot> getPendingIncidentsSimple() {
    return _firestore
        .collection('incidents')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getAssignedIncidentsSimple(String supportUid) {
    return _firestore
        .collection('incidents')
        .where('assignedTo.uid', isEqualTo: supportUid)
        .snapshots();
  }

  Stream<QuerySnapshot> getAllIncidentsSimple() {
    return _firestore
        .collection('incidents')
        .snapshots();
  }

  // Obtener incidentes cancelados por un usuario específico
  

  // Obtener estadísticas específicas para usuario de soporte
  Future<Map<String, int>> getSupportUserStatistics(String supportUid) async {
    try {
      print('🔍 DEBUG ESTADÍSTICAS - Consultando para supportUid: $supportUid');
      final now = DateTime.now();
      
      // Inicio de la semana (lunes)
      final weekStart = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      print('📅 Inicio de semana: $weekStart');
      
      // Obtener TODOS los incidentes asignados al usuario y filtrar en código
      final allAssignedQuery = await _firestore
          .collection('incidents')
          .where('assignedTo.uid', isEqualTo: supportUid)
          .get();
      
      print('📊 Total incidentes asignados: ${allAssignedQuery.docs.length}');
      
      // Filtrar en código para evitar índices complejos
      int resolvedThisWeekCount = 0;
      int totalResolvedCount = 0;
      int onHoldCount = 0;
      int activeCount = 0;
      
      for (var doc in allAssignedQuery.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        
        if (status == 'resolved') {
          totalResolvedCount++;
          
          // Verificar si fue resuelto esta semana
          final resolvedAt = data['resolvedAt'] as Timestamp?;
          if (resolvedAt != null && resolvedAt.toDate().isAfter(weekStart)) {
            resolvedThisWeekCount++;
          }
        } else if (status == 'onHold') {
          onHoldCount++;
          activeCount++;
        } else if (status == 'inProgress') {
          activeCount++;
        }
      }
      
      print('📊 Resueltos esta semana: $resolvedThisWeekCount');
      print('📊 Total resueltos: $totalResolvedCount');
      print('📊 En espera: $onHoldCount');
      print('📊 Activos (inProgress + onHold): $activeCount');
      
      // Debug de cada incidente activo
      for (var doc in allAssignedQuery.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        if (status == 'inProgress' || status == 'onHold') {
          print('   📄 Incidente activo ${doc.id}:');
          print('      - Estado: $status');
          print('      - AssignedTo: ${data['assignedTo']}');
        }
      }

      final result = {
        'resolvedThisWeek': resolvedThisWeekCount,
        'totalResolved': totalResolvedCount,
        'onHold': onHoldCount,
        'active': activeCount,
      };
      
      print('📈 RESULTADO FINAL ESTADÍSTICAS: $result');
      return result;
    } catch (e) {
      print('❌ ERROR en getSupportUserStatistics: $e');
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