import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class IncidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

      // Subir evidencia si existe
      String? evidenceUrl;
      if (evidenceFile != null) {
        evidenceUrl = await _uploadFile(
          file: evidenceFile,
          path: 'incidents/${DateTime.now().millisecondsSinceEpoch}_${user.uid}',
        );
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
        'evidenceUrl': evidenceUrl,
        'assignedTo': null,
        'assignedAt': null,
        'resolvedAt': null,
        'resolutionUrl': null,
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
        .orderBy('reportedAt', descending: true)
        .snapshots();
  }

  // Tomar incidente (asignar a soporte)
  Future<void> takeIncident(String incidentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

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
    required String status, // 'resolved' o 'inProgress' (en espera)
    String? notes,
    File? resolutionFile,
  }) async {
    try {
      // Subir evidencia de resolución si existe
      String? resolutionUrl;
      if (resolutionFile != null) {
        resolutionUrl = await _uploadFile(
          file: resolutionFile,
          path: 'resolutions/${DateTime.now().millisecondsSinceEpoch}_$incidentId',
        );
      }

      final Map<String, Object?> updateData = {
        'status': status,
        'resolutionNotes': notes,
        'resolutionUrl': resolutionUrl,
      };

      if (status == 'resolved') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('incidents').doc(incidentId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Subir archivo a Storage
  Future<String> _uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
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
}