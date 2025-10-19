import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../utils/colors.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;

  const IncidentCard({
    Key? key,
    required this.incident,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: incident.getStatusColor(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    incident.getStatusText(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  incident.getTimeAgo(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Lab ${incident.labName} - PC: ${incident.computerNumbers.join(", ")}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    incident.type,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 8),
                Text(
                  incident.reportedBy,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                  ),
                ),
                if (incident.assignedTo != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.assignment_ind,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    incident.assignedTo!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Ver detalles',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.accentGold,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}