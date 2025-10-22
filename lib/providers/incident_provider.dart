import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/incident_service.dart';
import '../models/incident_model.dart';
import 'dart:io';

class IncidentProvider with ChangeNotifier {
  final IncidentService _incidentService = IncidentService();
  
  List<Incident> _incidents = [];
  bool _isLoading = false;
  String? _error;

  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Obtener incidentes con filtro
  void getIncidents({String? status, String? labName}) {
    _incidentService.getIncidents(status: status, labName: labName).listen(
      (snapshot) {
        _incidents = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Incident.fromFirestore(doc.id, data);
        }).toList();
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Crear incidente
  Future<bool> createIncident({
    required String labName,
    required List<int> computerNumbers,
    required String incidentType,
    String? description,
    File? evidenceFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _incidentService.createIncident(
        labName: labName,
        computerNumbers: computerNumbers,
        incidentType: incidentType,
        description: description,
        evidenceFile: evidenceFile,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Tomar incidente
  Future<bool> takeIncident(String incidentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _incidentService.takeIncident(incidentId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener incidentes del usuario actual
  void getUserIncidents(String uid) {
    _incidentService.getUserIncidents(uid).listen(
      (snapshot) {
        _incidents = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Incident.fromFirestore(doc.id, data);
        }).toList();
        
        // Ordenar por fecha de reporte (más reciente primero)
        _incidents.sort((a, b) {
          if (a.reportedAt == null && b.reportedAt == null) return 0;
          if (a.reportedAt == null) return 1;
          if (b.reportedAt == null) return -1;
          return b.reportedAt!.compareTo(a.reportedAt!);
        });
        
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Resolver incidente
  Future<bool> resolveIncident({
    required String incidentId,
    required String status,
    String? notes,
    File? resolutionFile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _incidentService.resolveIncident(
        incidentId: incidentId,
        status: status,
        notes: notes,
        resolutionFile: resolutionFile,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}