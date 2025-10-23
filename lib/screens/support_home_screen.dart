import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../models/incident_model.dart';
import '../widgets/incident_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_overlay.dart';
import '../providers/incident_provider.dart';
import 'incident_resolution_screen.dart';

class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({Key? key}) : super(key: key);

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  String _filterStatus = 'all';
  Map<String, int> _statistics = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Cargar incidentes
      final provider = Provider.of<IncidentProvider>(context, listen: false);
      if (_filterStatus == 'all') {
        // Cargar todos los incidentes pendientes para tomar
        provider.getIncidents(status: 'pending');
      } else {
        // Cargar incidentes asignados al usuario de soporte
        provider.getSupportIncidents(user.uid);
      }
      
      // Cargar estadísticas
      _loadStatistics();
    }
  }

  void _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final provider = Provider.of<IncidentProvider>(context, listen: false);
      final stats = await provider.getSupportUserStatistics(user.uid);
      setState(() {
        _statistics = stats;
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // Estadísticas del usuario de soporte
          _buildStatisticsCard(),
          
          // Filtros
          _buildFilterTabs(),
          
          // Lista de incidentes
          Expanded(
            child: Consumer<IncidentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredIncidents = _getFilteredIncidents(provider.incidents);

                if (filteredIncidents.isEmpty) {
                  return EmptyState(
                    icon: Icons.inbox,
                    title: 'No hay incidentes',
                    message: _getEmptyMessage(),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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
                          ).then((_) => _loadData());
                        },
                        showTakeButton: _filterStatus == 'all' && 
                                      incident.status == IncidentStatus.pending,
                        onTake: () => _takeIncident(incident.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Incident> _getFilteredIncidents(List<Incident> incidents) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    switch (_filterStatus) {
      case 'all':
        // Mostrar solo incidentes pendientes para tomar
        return incidents.where((i) => i.status == IncidentStatus.pending).toList();
      case 'inProgress':
        return incidents.where((i) => 
          i.status == IncidentStatus.inProgress && 
          i.assignedTo != null).toList();
      case 'resolved':
        return incidents.where((i) => i.status == IncidentStatus.resolved).toList();
      case 'cancelled':
        return incidents.where((i) => i.status == IncidentStatus.cancelled).toList();
      case 'onHold':
        return incidents.where((i) => i.status == IncidentStatus.onHold).toList();
      default:
        return incidents;
    }
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Esta Semana',
                    _statistics['resolvedThisWeek']?.toString() ?? '0',
                    Icons.date_range,
                    AppColors.success,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Resueltos',
                    _statistics['totalResolved']?.toString() ?? '0',
                    Icons.check_circle,
                    AppColors.lightBlue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Activos',
                    _statistics['active']?.toString() ?? '0',
                    Icons.work,
                    AppColors.warning,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'En Espera',
                    _statistics['onHold']?.toString() ?? '0',
                    Icons.pause,
                    Colors.orange,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterTab('Disponibles', 'all', Icons.inbox),
            _buildFilterTab('Mis Activos', 'inProgress', Icons.work),
            _buildFilterTab('Resueltos', 'resolved', Icons.check_circle),
            _buildFilterTab('En Espera', 'onHold', Icons.pause),
            _buildFilterTab('Cancelados', 'cancelled', Icons.cancel),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String status, IconData icon) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = status;
        });
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGold : AppColors.lightGray,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.white : AppColors.textLight,
            ),
            const SizedBox(width: 4),
            Text(
              label,
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

  String _getEmptyMessage() {
    switch (_filterStatus) {
      case 'all':
        return 'No hay incidentes pendientes para tomar';
      case 'inProgress':
        return 'No tienes incidentes activos';
      case 'resolved':
        return 'No has resuelto incidentes aún';
      case 'cancelled':
        return 'No tienes incidentes cancelados';
      case 'onHold':
        return 'No tienes incidentes en espera';
      default:
        return 'No hay incidentes';
    }
  }

  void _takeIncident(String incidentId) async {
    final provider = Provider.of<IncidentProvider>(context, listen: false);
    
    final success = await provider.takeIncident(incidentId);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incidente tomado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      _loadData(); // Recargar datos
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al tomar el incidente'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}