import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';

enum IncidentStatus { pending, inProgress, resolved, cancelled, onHold }

class AssignedUser {
  final String uid;
  final String name;

  AssignedUser({
    required this.uid,
    required this.name,
  });

  static AssignedUser? fromMap(Map<String, dynamic>? data) {
    if (data == null) return null;
    return AssignedUser(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
    };
  }
}

class Incident {
  final String id;
  final String labName;
  final List<int> computerNumbers;
  final String type;
  final IncidentStatus status;
  final String reportedBy;
  final DateTime reportedAt;
  final AssignedUser? assignedTo;
  final DateTime? resolvedAt;
  final String? description;
  final String? evidenceImage; // Cambiado de mediaUrl a evidenceImage (base64)
  final String? resolutionImage; // Agregado para imagen de resolución (base64)
  final String? resolutionNotes; // Agregado para notas de resolución
  final String? cancelledBy; // Agregado para rastrear quién canceló el incidente

  Incident({
    required this.id,
    required this.labName,
    required this.computerNumbers,
    required this.type,
    required this.status,
    required this.reportedBy,
    required this.reportedAt,
    this.assignedTo,
    this.resolvedAt,
    this.description,
    this.evidenceImage,
    this.resolutionImage,
    this.resolutionNotes,
    this.cancelledBy,
  });

  String getStatusText() {
    switch (status) {
      case IncidentStatus.pending:
        return 'Pendiente';
      case IncidentStatus.inProgress:
        return 'En Progreso';
      case IncidentStatus.resolved:
        return 'Resuelto';
      case IncidentStatus.cancelled:
        return 'Cancelado';
      case IncidentStatus.onHold:
        return 'En Espera';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case IncidentStatus.pending:
        return AppColors.warning;
      case IncidentStatus.inProgress:
        return AppColors.lightBlue;
      case IncidentStatus.resolved:
        return AppColors.success;
      case IncidentStatus.cancelled:
        return Colors.red;
      case IncidentStatus.onHold:
        return Colors.orange;
    }
  }

  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(reportedAt);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? "s" : ""}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? "s" : ""}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? "s" : ""}';
    } else {
      return 'Hace un momento';
    }
  }

  // Factory constructor para crear desde Firestore
  static Incident fromFirestore(String id, Map<String, dynamic> data) {
    return Incident(
      id: id,
      labName: data['labName'] ?? '',
      computerNumbers: List<int>.from(data['computerNumbers'] ?? []),
      type: data['incidentType'] ?? '',
      status: _parseStatus(data['status']),
      reportedBy: data['reportedBy']?['name'] ?? 'Usuario',
      reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTo: AssignedUser.fromMap(data['assignedTo']),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      description: data['description'],
      evidenceImage: data['evidenceImage'], // Cambiado de evidenceUrl
      resolutionImage: data['resolutionImage'], // Agregado
      resolutionNotes: data['resolutionNotes'], // Agregado
      cancelledBy: data['cancelledBy']?['name'], // Agregado
    );
  }

  static IncidentStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return IncidentStatus.pending;
      case 'inProgress':
        return IncidentStatus.inProgress;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'cancelled':
        return IncidentStatus.cancelled;
      case 'onHold':
        return IncidentStatus.onHold;
      default:
        return IncidentStatus.pending;
    }
  }

  static String _statusToString(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.pending:
        return 'pending';
      case IncidentStatus.inProgress:
        return 'inProgress';
      case IncidentStatus.resolved:
        return 'resolved';
      case IncidentStatus.cancelled:
        return 'cancelled';
      case IncidentStatus.onHold:
        return 'onHold';
    }
  }
}

// Extensión para conversión con Firestore
extension IncidentFirestore on Incident {
  static Incident fromFirestore(String id, Map<String, dynamic> data) {
    return Incident(
      id: id,
      labName: data['labName'] ?? '',
      computerNumbers: List<int>.from(data['computerNumbers'] ?? []),
      type: data['incidentType'] ?? '',
      status: _parseStatus(data['status']),
      reportedBy: data['reportedBy']?['name'] ?? 'Usuario',
      reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTo: AssignedUser.fromMap(data['assignedTo']),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      description: data['description'],
      evidenceImage: data['evidenceImage'],
      resolutionImage: data['resolutionImage'],
      resolutionNotes: data['resolutionNotes'],
      cancelledBy: data['cancelledBy']?['name'],
    );
  }

  static IncidentStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return IncidentStatus.pending;
      case 'inProgress':
        return IncidentStatus.inProgress;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'cancelled':
        return IncidentStatus.cancelled;
      case 'onHold':
        return IncidentStatus.onHold;
      default:
        return IncidentStatus.pending;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'labName': labName,
      'computerNumbers': computerNumbers,
      'incidentType': type,
      'status': _statusToString(status),
      'reportedBy': {
        'name': reportedBy,
      },
      'reportedAt': Timestamp.fromDate(reportedAt),
      'assignedTo': assignedTo?.toMap(),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'description': description,
      'evidenceImage': evidenceImage,
      'resolutionImage': resolutionImage,
      'resolutionNotes': resolutionNotes,
    };
  }

  static String _statusToString(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.pending:
        return 'pending';
      case IncidentStatus.inProgress:
        return 'inProgress';
      case IncidentStatus.resolved:
        return 'resolved';
      case IncidentStatus.cancelled:
        return 'cancelled';
      case IncidentStatus.onHold:
        return 'onHold';
    }
  }
}
