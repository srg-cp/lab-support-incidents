import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../models/incident_model.dart';
import '../widgets/incident_card.dart';
import '../services/incident_service.dart';
import '../services/lab_service.dart';
import '../services/computer_service.dart';
import '../utils/setup_computers.dart';
import 'user_management_screen.dart';
import 'students_screen.dart';
import 'incident_resolution_screen.dart';
import 'add_computer_screen.dart';
import 'lab_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminIncidentsView(),
    const AdminLabManagement(),
    const UserManagementScreen(),
    const StudentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrador'),
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Incidentes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.computer),
            label: 'Laboratorios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Estudiantes',
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final IncidentService _incidentService = IncidentService();
  Map<String, int> _statistics = {
    'pending': 0,
    'inProgress': 0,
    'resolvedToday': 0,
    'totalMonth': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _incidentService.getStatistics();
      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumen General',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadStatistics,
                icon: _isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
                tooltip: 'Actualizar estadísticas',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pendientes',
                    '${_statistics['pending']}',
                    Icons.pending,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'En Progreso',
                    '${_statistics['inProgress']}',
                    Icons.work,
                    AppColors.lightBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Resueltos Hoy',
                    '${_statistics['resolvedToday']}',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Mes',
                    '${_statistics['totalMonth']}',
                    Icons.analytics,
                    AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminIncidentsView extends StatefulWidget {
  const AdminIncidentsView({Key? key}) : super(key: key);

  @override
  State<AdminIncidentsView> createState() => _AdminIncidentsViewState();
}

class _AdminIncidentsViewState extends State<AdminIncidentsView> {
  final IncidentService _incidentService = IncidentService();
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con filtros
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestión de Incidentes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Todos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('pending', 'Pendientes'),
                    const SizedBox(width: 8),
                    _buildFilterChip('inProgress', 'En Progreso'),
                    const SizedBox(width: 8),
                    _buildFilterChip('resolved', 'Resueltos'),
                    const SizedBox(width: 8),
                    _buildFilterChip('onHold', 'En Espera'),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Lista de incidentes
        Expanded(
          child: StreamBuilder(
            stream: _incidentService.getAllIncidentsSimple(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar incidentes',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Verifica tu conexión a internet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay incidentes registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Convertir documentos a objetos Incident
              final incidents = snapshot.data!.docs.map((doc) {
                return Incident.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
              }).toList();

              // Filtrar incidentes según el filtro seleccionado
              final filteredIncidents = _filterIncidents(incidents);

              // Ordenar por fecha de reporte (más recientes primero)
              filteredIncidents.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));

              if (filteredIncidents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.filter_list_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay incidentes con el filtro seleccionado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: AppColors.primaryBlue.withOpacity(0.2),
      checkmarkColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryBlue : AppColors.textLight,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  List<Incident> _filterIncidents(List<Incident> incidents) {
    if (_selectedFilter == 'all') {
      return incidents;
    }

    return incidents.where((incident) {
      switch (_selectedFilter) {
        case 'pending':
          return incident.status == IncidentStatus.pending;
        case 'inProgress':
          return incident.status == IncidentStatus.inProgress;
        case 'resolved':
          return incident.status == IncidentStatus.resolved;
        case 'onHold':
          return incident.status == IncidentStatus.onHold;
        default:
          return true;
      }
    }).toList();
  }
}

class AdminLabManagement extends StatefulWidget {
  const AdminLabManagement({Key? key}) : super(key: key);

  @override
  State<AdminLabManagement> createState() => _AdminLabManagementState();
}

class _AdminLabManagementState extends State<AdminLabManagement> {
  final LabService _labService = LabService();
  final ComputerService _computerService = ComputerService();
  Map<String, Map<String, dynamic>> _labsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLabsData();
  }

  Future<void> _loadLabsData() async {
    try {
      setState(() => _isLoading = true);
      
      // Inicializar laboratorios por defecto si no existen
      await _labService.initializeDefaultLabs();
      
      // Cargar estadísticas de laboratorios
      final statistics = await _labService.getAllLabsStatistics();
      
      setState(() {
        _labsData = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar laboratorios: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _navigateToAddComputer(String labName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddComputerScreen(labName: labName),
      ),
    );
    
    if (result == true) {
      _loadLabsData(); // Recargar datos después de agregar
    }
  }

  Future<void> _navigateToLabDetails(String labName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabDetailScreen(labName: labName),
      ),
    );
    
    if (result == true) {
      _loadLabsData(); // Recargar datos después de modificaciones
    }
  }

  Future<void> _initializeComputers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Inicializar Computadoras HP'),
        content: const Text(
          'Esto creará 20 computadoras HP para cada laboratorio (A, B, C, D, E, F) con datos realistas.\n\n'
          '¿Estás seguro de que deseas continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Inicializar', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        await ComputerSetup.setupComputers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Computadoras HP inicializadas exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        
        await _loadLabsData(); // Recargar datos
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error al inicializar computadoras: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadLabsData,
        child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión de Laboratorios',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                onPressed: _loadLabsData,
                icon: const Icon(Icons.refresh),
                color: AppColors.primaryBlue,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gestiona las computadoras de cada laboratorio con información detallada de componentes',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 24),
          ..._labsData.entries.map((entry) {
            final labName = entry.key;
            final labData = entry.value;
            final computerCount = labData['actualComputerCount'] ?? 0;
            final hasRegisteredComputers = labData['hasRegisteredComputers'] ?? false;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primaryBlue, AppColors.lightBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              labName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Laboratorio $labName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$computerCount computadoras registradas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: hasRegisteredComputers 
                                      ? AppColors.success 
                                      : AppColors.textLight,
                                  fontWeight: hasRegisteredComputers 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                ),
                              ),
                              if (!hasRegisteredComputers)
                                Text(
                                  'Sin computadoras registradas',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.warning,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _navigateToAddComputer(labName),
                              icon: const Icon(Icons.add_circle),
                              color: AppColors.accentGold,
                              iconSize: 28,
                              tooltip: 'Agregar PC',
                            ),
                            IconButton(
                              onPressed: () => _navigateToLabDetails(labName),
                              icon: const Icon(Icons.list_alt),
                              color: AppColors.primaryBlue,
                              iconSize: 28,
                              tooltip: 'Ver detalles',
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (hasRegisteredComputers) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.skyBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.skyBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primaryBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Toca "Ver detalles" para gestionar las computadoras existentes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _initializeComputers,
        backgroundColor: AppColors.accentGold,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.computer),
        label: const Text('Inicializar HP'),
        tooltip: 'Inicializar 20 computadoras HP por laboratorio',
      ),
    );
  }
}