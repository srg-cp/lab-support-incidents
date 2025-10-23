import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/incident_service.dart';
import '../models/incident_model.dart';
import '../utils/error_handler.dart';
import 'dart:io';

class IncidentProvider with ChangeNotifier {
  final IncidentService _incidentService = IncidentService();
  
  List<Incident> _incidents = [];
  bool _isLoading = false;
  String? _error;
  String _errorType = 'danger'; // 'warning' o 'danger'

  List<Incident> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get errorType => _errorType;

  // Limpiar error
  void clearError() {
    _error = null;
    _errorType = 'danger';
    notifyListeners();
  }

  // Obtener incidentes con filtro
  void getIncidents({String? status, String? labName}) {
    // Limpiar error al cargar nuevos datos
    _error = null;
    
    Stream<QuerySnapshot> stream;
    
    if (status == 'pending' && labName == null) {
      // Usar método específico para incidentes pendientes
      stream = _incidentService.getPendingIncidentsSimple();
    } else if (status == null && labName == null) {
      // Usar método específico para todos los incidentes
      stream = _incidentService.getAllIncidentsSimple();
    } else {
      // Para casos complejos, usar el método genérico
      stream = _incidentService.getIncidents(status: status, labName: labName);
    }
    
    stream.listen(
      (snapshot) {
        _incidents = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Incident.fromFirestore(doc.id, data);
        }).toList();
        
        // Filtrar manualmente por laboratorio si es necesario
        if (labName != null) {
          _incidents = _incidents.where((incident) => incident.labName == labName).toList();
        }
        
        // Ordenar manualmente por fecha
        _incidents.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
        
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
    _errorType = 'danger';
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
      _error = ErrorHandler.getErrorMessage(e);
      _errorType = ErrorHandler.getErrorType(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Tomar incidente
  Future<bool> takeIncident(String incidentId) async {
    _isLoading = true;
    _error = null;
    _errorType = 'danger';
    notifyListeners();

    try {
      await _incidentService.takeIncident(incidentId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.getErrorMessage(e);
      _errorType = ErrorHandler.getErrorType(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener incidentes del usuario actual
  void getUserIncidents(String uid) {
    // Limpiar error al cargar nuevos datos
    _error = null;
    
    _incidentService.getUserIncidentsSimple(uid).listen(
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

  // Obtener incidentes pendientes
  void getPendingIncidents() {
    // Limpiar error al cargar nuevos datos
    _error = null;
    
    _incidentService.getPendingIncidentsSimple().listen(
      (snapshot) {
        _incidents = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Incident.fromFirestore(doc.id, data);
        }).toList();
        
        // Ordenar manualmente por fecha
        _incidents.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
        
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Obtener incidentes asignados a un usuario de soporte
  void getSupportIncidents(String supportUid) {
    // Limpiar error al cargar nuevos datos
    _error = null;
    
    _incidentService.getAssignedIncidentsSimple(supportUid).listen(
      (snapshot) {
        _incidents = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Incident.fromFirestore(doc.id, data);
        }).toList();
        
        // Ordenar manualmente por fecha
        _incidents.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
        
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }



  // Obtener estadísticas del usuario de soporte
  Future<Map<String, int>> getSupportUserStatistics(String supportUid) async {
    try {
      return await _incidentService.getSupportUserStatistics(supportUid);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {};
    }
  }

  // Debug: Imprimir información de incidentes
  void debugPrintIncidents() {
    for (var incident in _incidents) {
      print('📄 Incidente ${incident.id}:');
      print('   - Estado: ${incident.status}');
      print('   - Asignado a: ${incident.assignedTo?.name} (${incident.assignedTo?.uid})');
      print('   - Lab: ${incident.labName}');
    }
  }
}