import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colors.dart';
import '../models/incident_model.dart';
import '../widgets/incident_card.dart';

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
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen General',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pendientes',
                  '12',
                  Icons.pending,
                  AppColors.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'En Progreso',
                  '5',
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
                  '8',
                  Icons.check_circle,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total Mes',
                  '156',
                  Icons.analytics,
                  AppColors.primaryBlue,
                ),
              ),
            ],
          ),
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

class AdminIncidentsView extends StatelessWidget {
  const AdminIncidentsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo
    final incidents = [
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
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: IncidentCard(incident: incidents[index]),
        );
      },
    );
  }
}

class AdminLabManagement extends StatefulWidget {
  const AdminLabManagement({Key? key}) : super(key: key);

  @override
  State<AdminLabManagement> createState() => _AdminLabManagementState();
}

class _AdminLabManagementState extends State<AdminLabManagement> {
  final Map<String, int> labComputers = {
    'A': 20,
    'B': 20,
    'C': 20,
    'D': 20,
    'E': 20,
    'F': 20,
  };

  void _addComputer(String lab) {
    setState(() {
      labComputers[lab] = (labComputers[lab] ?? 20) + 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Computadora añadida al Laboratorio $lab'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Gestión de Laboratorios',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 24),
        ...labComputers.entries.map((entry) {
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
              child: Row(
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
                        entry.key,
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
                          'Laboratorio ${entry.key}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.value} computadoras + 1 docente',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _addComputer(entry.key),
                    icon: const Icon(Icons.add_circle),
                    color: AppColors.accentGold,
                    iconSize: 32,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}