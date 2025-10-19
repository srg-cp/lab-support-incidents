import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../models/incident_model.dart';
import '../widgets/incident_card.dart';
import 'incident_resolution_screen.dart';

class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({Key? key}) : super(key: key);

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  IncidentStatus _filterStatus = IncidentStatus.pending;

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo
    final allIncidents = [
      Incident(
        id: '1',
        labName: 'A',
        computerNumbers: [5, 6],
        type: 'Pantallazo azul',
        status: IncidentStatus.pending,
        reportedBy: 'Juan Pérez',
        reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Incident(
        id: '2',
        labName: 'C',
        computerNumbers: [12],
        type: 'No prende el monitor',
        status: IncidentStatus.inProgress,
        reportedBy: 'María García',
        reportedAt: DateTime.now().subtract(const Duration(hours: 1)),
        assignedTo: 'Carlos Ruiz',
      ),
      Incident(
        id: '3',
        labName: 'B',
        computerNumbers: [3, 4, 7],
        type: 'Sin internet',
        status: IncidentStatus.resolved,
        reportedBy: 'Pedro López',
        reportedAt: DateTime.now().subtract(const Duration(hours: 3)),
        assignedTo: 'Ana Torres',
        resolvedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      Incident(
        id: '4',
        labName: 'D',
        computerNumbers: [15],
        type: 'Teclado no funciona',
        status: IncidentStatus.pending,
        reportedBy: 'Laura Martínez',
        reportedAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
    ];

    final filteredIncidents = allIncidents
        .where((incident) => incident.status == _filterStatus)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte Técnico'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.lightGray,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip(
                    'Pendientes',
                    IncidentStatus.pending,
                    Icons.pending,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    'En Progreso',
                    IncidentStatus.inProgress,
                    Icons.work,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildFilterChip(
                    'Resueltos',
                    IncidentStatus.resolved,
                    Icons.check_circle,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de incidentes
          Expanded(
            child: filteredIncidents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay incidentes ${_getStatusText()}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredIncidents.length,
                    itemBuilder: (context, index) {
                      final incident = filteredIncidents[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IncidentCard(
                          incident: incident,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IncidentResolutionScreen(
                                  incident: incident,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IncidentStatus status, IconData icon) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGold : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.white : AppColors.textLight,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText() {
    switch (_filterStatus) {
      case IncidentStatus.pending:
        return 'pendientes';
      case IncidentStatus.inProgress:
        return 'en progreso';
      case IncidentStatus.resolved:
        return 'resueltos';
    }
  }
}