import 'package:flutter/material.dart';
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
}