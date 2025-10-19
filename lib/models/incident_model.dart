import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';

enum IncidentStatus { pending, inProgress, resolved }

class Incident {
  final String id;
  final String labName;
  final List<int> computerNumbers;
  final String type;
  final IncidentStatus status;
  final String reportedBy;
  final DateTime reportedAt;
  final String? assignedTo;
  final DateTime? resolvedAt;
  final String? description;
  final String? mediaUrl;

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
    this.mediaUrl,
  });

  String getStatusText() {
    switch (status) {
      case IncidentStatus.pending:
        return 'Pendiente';
      case IncidentStatus.inProgress:
        return 'En Progreso';
      case IncidentStatus.resolved:
        return 'Resuelto';
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
      assignedTo: data['assignedTo']?['name'],
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      description: data['description'],
      mediaUrl: data['evidenceUrl'],
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
    }
  }
}

// Actualizar models/incident_model.dart con fromFirestore
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
      assignedTo: data['assignedTo']?['name'],
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      description: data['description'],
      mediaUrl: data['evidenceUrl'],
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
      'assignedTo': assignedTo != null ? {'name': assignedTo} : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'description': description,
      'evidenceUrl': mediaUrl,
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
    }
  }
}
