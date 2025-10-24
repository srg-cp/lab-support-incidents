import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../models/incident_model.dart';
import '../widgets/incident_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/custom_modal.dart';
import '../providers/incident_provider.dart';
import 'incident_resolution_screen.dart';
import 'lab_selection_screen.dart';
import 'user_reports_screen.dart';

class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({Key? key}) : super(key: key);

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const SupportIncidentsView(),
    const SupportReportIncident(),
    const SupportMyReports(),
  ];

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
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.accentGold,
        unselectedItemColor: AppColors.textLight,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.support_agent),
            label: 'Incidentes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Reportar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Mis Reportes',
          ),
        ],
      ),
    );
  }
}

// Pantalla principal de incidentes para soporte (código original)
class SupportIncidentsView extends StatefulWidget {
  const SupportIncidentsView({Key? key}) : super(key: key);

  @override
  State<SupportIncidentsView> createState() => _SupportIncidentsViewState();
}

class _SupportIncidentsViewState extends State<SupportIncidentsView> {
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
      final provider = Provider.of<IncidentProvider>(context, listen: false);
      
      if (_filterStatus == 'all') {
        provider.getPendingIncidents();
      } else {
        // Para todos los otros filtros (inProgress, resolved, onHold), 
        // cargar los incidentes asignados al usuario de soporte
        provider.getSupportIncidents(user.uid);
      }
      
      _loadStatistics();
    }
  }

  void _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isLoadingStats = true;
      });
      
      try {
        final provider = Provider.of<IncidentProvider>(context, listen: false);
        final stats = await provider.getSupportUserStatistics(user.uid);
        if (mounted) {
          setState(() {
            _statistics = stats;
            _isLoadingStats = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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

              // Debug: Mostrar información de incidentes
              for (var incident in filteredIncidents) {
                print('📄 Incidente ${incident.id}:');
                print('   - Estado: ${incident.status}');
                print('   - Asignado a: ${incident.assignedTo?.name} (${incident.assignedTo?.uid})');
                print('   - Lab: ${incident.labName}');
              }

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
                      showDownloadButton: true,
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
        final currentUserUid = user.uid;
        return incidents.where((i) => 
          (i.status == IncidentStatus.inProgress || i.status == IncidentStatus.onHold) && 
          i.assignedTo != null && 
          i.assignedTo!.uid == currentUserUid).toList();
      case 'resolved':
        return incidents.where((i) => i.status == IncidentStatus.resolved).toList();
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
        
        // Diferir la limpieza del error y carga de datos hasta después del build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final provider = Provider.of<IncidentProvider>(context, listen: false);
          provider.clearError();
          _loadData();
        });
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
        return 'No tienes incidentes activos (en progreso o en espera)';
      case 'resolved':
        return 'No has resuelto incidentes aún';
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
      CustomModal.show(
        context,
        type: ModalType.success,
        title: 'Incidente Tomado',
        message: 'El incidente ha sido asignado a ti exitosamente. Puedes proceder a resolverlo.',
        onConfirm: () {
          _loadData(); // Recargar datos después de cerrar el modal
        },
      );
    } else {
      // Determinar el tipo de modal según el tipo de error
      final modalType = provider.errorType == 'warning' ? ModalType.warning : ModalType.danger;
      final title = provider.errorType == 'warning' ? 'Límite Alcanzado' : 'Error';
      
      CustomModal.show(
          context,
          type: modalType,
          title: title,
          message: provider.error ?? 'Error al tomar el incidente',
          onConfirm: () {
            // Limpiar el error después de mostrar el modal
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.clearError();
            });
          },
        );
    }
  }
}

// Pantalla para que el personal de soporte reporte incidentes
class SupportReportIncident extends StatelessWidget {
  const SupportReportIncident({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reportar Incidente',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Como personal de soporte, puedes reportar incidentes en cualquier laboratorio',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),
          _buildCard(
            context,
            icon: Icons.report_problem,
            title: 'Reportar Incidente',
            subtitle: 'Informa sobre problemas en los laboratorios',
            color: AppColors.accentGold,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LabSelectionScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
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
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textLight,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// Pantalla para que el personal de soporte vea sus reportes
class SupportMyReports extends StatelessWidget {
  const SupportMyReports({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Reportes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Incidentes que has reportado como personal de soporte',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: UserReportsScreen(),
          ),
        ],
      ),
    );
  }
}