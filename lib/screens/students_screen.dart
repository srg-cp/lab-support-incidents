import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import '../services/auth_service.dart';
import '../services/incident_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_view.dart';
import '../widgets/image_viewer.dart';
import '../utils/date_formatter.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final AuthService _authService = AuthService();
  final IncidentService _incidentService = IncidentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estudiantes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.lightBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Solo lectura',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.lightBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Lista de estudiantes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _authService.getStudents(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ErrorView(
                    message: 'Error al cargar estudiantes',
                    onRetry: () => setState(() {}),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data?.docs ?? [];

                if (students.isEmpty) {
                  return const EmptyState(
                    icon: Icons.school_outlined,
                    title: 'No hay estudiantes',
                    message: 'Aún no se han registrado estudiantes en el sistema.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final studentData = students[index].data() as Map<String, dynamic>;
                    return _buildStudentCard(studentData, students[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> studentData, String studentId) {
    final String name = studentData['name'] ?? 'Sin nombre';
    final String email = studentData['email'] ?? 'Sin email';
    final DateTime? createdAt = studentData['createdAt']?.toDate();
    final DateTime? lastLogin = studentData['lastLogin']?.toDate();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.lightBlue.withOpacity(0.1),
                  child: Icon(Icons.school, color: AppColors.lightBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Estudiante',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showStudentDashboard(studentId, name),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver Detalles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Registrado: ${createdAt != null ? DateFormatter.formatDate(createdAt) : 'N/A'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(width: 16),
                Icon(Icons.login, size: 16, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Último acceso: ${lastLogin != null ? DateFormatter.formatDate(lastLogin) : 'Nunca'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDashboard(String studentId, String studentName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDashboardScreen(
          studentId: studentId,
          studentName: studentName,
        ),
      ),
    );
  }

  void _showIncidentDetail(Map<String, dynamic> incidentData, String incidentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _StudentIncidentDetailScreen(
          incidentId: incidentId,
          incidentData: incidentData,
        ),
      ),
    );
  }
}

class _StudentIncidentDetailScreen extends StatelessWidget {
  final String incidentId;
  final Map<String, dynamic> incidentData;

  const _StudentIncidentDetailScreen({
    Key? key,
    required this.incidentId,
    required this.incidentData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usar incidentType como título si title está vacío o es null
    final title = (incidentData['title']?.toString().trim().isEmpty ?? true) 
        ? (incidentData['incidentType'] ?? 'Incidente') 
        : incidentData['title'];
    final description = incidentData['description'] ?? 'Sin descripción';
    final status = incidentData['status'] ?? 'unknown';
    final reportedAt = incidentData['reportedAt']?.toDate();
    final computerNumbers = incidentData['computerNumbers'] as List<dynamic>? ?? [];
    final labName = incidentData['labName'] ?? 'N/A';
    final incidentType = incidentData['incidentType'] ?? 'N/A';
    final assignedTo = incidentData['assignedTo'];
    final resolutionMessage = incidentData['resolutionMessage'];
    final resolutionNotes = incidentData['resolutionNotes'];
    final evidenceImage = incidentData['evidenceImage'];
    final resolutionImage = incidentData['resolutionImage'];
    final resolvedAt = incidentData['resolvedAt']?.toDate();

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        statusIcon = Icons.pending;
        break;
      case 'inProgress':
        statusColor = Colors.blue;
        statusText = 'En Progreso';
        statusIcon = Icons.work;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Resuelto';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
        statusIcon = Icons.help;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Incidente'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 16, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Información básica
            _buildSection(
              'Información del Incidente',
              [
                _buildDetailRow(Icons.category, 'Tipo', incidentType),
                _buildDetailRow(Icons.location_on, 'Laboratorio', labName),
                _buildDetailRow(
                  Icons.computer, 
                  'Computadoras', 
                  computerNumbers.isNotEmpty 
                      ? computerNumbers.join(', ') 
                      : 'N/A'
                ),
                if (reportedAt != null)
                  _buildDetailRow(
                    Icons.access_time, 
                    'Reportado', 
                    '${DateFormatter.formatDateTime(reportedAt)}\n${DateFormatter.getTimeAgo(reportedAt)}'
                  ),
              ],
            ),

            // Descripción
            if (description.isNotEmpty && description != 'Sin descripción') ...[
              const SizedBox(height: 24),
              _buildSection(
                'Descripción',
                [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Evidencia del incidente
            if (evidenceImage != null && evidenceImage.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(
                'Evidencia del Incidente',
                [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageViewer(imageBase64: evidenceImage),
                  ),
                ],
              ),
            ],

            // Información de asignación y progreso
            if (assignedTo != null || status != 'pending') ...[
              const SizedBox(height: 24),
              _buildSection(
                'Estado del Incidente',
                [
                  if (assignedTo != null)
                    _buildDetailRow(Icons.person, 'Asignado a', assignedTo['name'] ?? 'N/A'),
                  if (status == 'inProgress')
                    _buildDetailRow(Icons.info, 'Estado', 'El incidente está siendo atendido por el personal de soporte'),
                ],
              ),
            ],

            // Información de resolución
            if (status == 'resolved') ...[
              const SizedBox(height: 24),
              _buildSection(
                'Resolución',
                [
                  if (resolvedAt != null)
                    _buildDetailRow(
                      Icons.check_circle, 
                      'Resuelto el', 
                      '${DateFormatter.formatDateTime(resolvedAt)}\n${DateFormatter.getTimeAgo(resolvedAt)}'
                    ),
                  if (resolutionMessage != null && resolutionMessage.isNotEmpty)
                    _buildDetailRow(Icons.message, 'Mensaje de resolución', resolutionMessage),
                  if (resolutionNotes != null && resolutionNotes.isNotEmpty)
                    _buildDetailRow(Icons.note, 'Notas técnicas', resolutionNotes),
                ],
              ),

              // Evidencia de resolución
              if (resolutionImage != null && resolutionImage.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Evidencia de Resolución',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ImageViewer(imageBase64: resolutionImage),
                ),
              ],
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StudentDashboardScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const StudentDashboardScreen({
    Key? key,
    required this.studentId,
    required this.studentName,
  }) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final IncidentService _incidentService = IncidentService();
  String _selectedFilter = 'general'; // general, day, week, month

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${widget.studentName}'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del estudiante
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.lightBlue.withOpacity(0.1),
                      child: Icon(Icons.school, color: AppColors.lightBlue, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Text(
                            'Estudiante',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Estadísticas de incidentes
            StreamBuilder<QuerySnapshot>(
              stream: _incidentService.getIncidentsByUser(widget.studentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final incidents = snapshot.data?.docs ?? [];
                final totalIncidents = incidents.length;
                final pendingIncidents = incidents.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'pending';
                }).length;
                final resolvedIncidents = incidents.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'resolved';
                }).length;

                // Incidentes reportados esta semana
                final now = DateTime.now();
                final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
                final weekIncidents = incidents.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final reportedAt = data['reportedAt']?.toDate();
                  return reportedAt != null && reportedAt.isAfter(startOfWeek);
                }).length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estadísticas de Incidentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total',
                            totalIncidents.toString(),
                            Icons.report,
                            AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Esta Semana',
                            weekIncidents.toString(),
                            Icons.date_range,
                            AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Resueltos',
                            resolvedIncidents.toString(),
                            Icons.check_circle,
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pendientes',
                            pendingIncidents.toString(),
                            Icons.pending,
                            AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Filtros y lista de incidentes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Historial de Incidentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        DropdownButton<String>(
                          value: _selectedFilter,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedFilter = newValue!;
                            });
                          },
                          items: const [
                            DropdownMenuItem(value: 'general', child: Text('General')),
                            DropdownMenuItem(value: 'day', child: Text('Hoy')),
                            DropdownMenuItem(value: 'week', child: Text('Esta Semana')),
                            DropdownMenuItem(value: 'month', child: Text('Este Mes')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildFilteredIncidentsList(incidents),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredIncidentsList(List<QueryDocumentSnapshot> allIncidents) {
    final filteredIncidents = _filterIncidentsByDate(allIncidents);
    
    if (filteredIncidents.isEmpty) {
      String message = 'Este estudiante no ha reportado incidentes';
      switch (_selectedFilter) {
        case 'day':
          message = 'No hay incidentes reportados hoy.';
          break;
        case 'week':
          message = 'No hay incidentes reportados esta semana.';
          break;
        case 'month':
          message = 'No hay incidentes reportados este mes.';
          break;
      }
      
      return EmptyState(
        icon: Icons.report_outlined,
        title: 'Sin incidentes',
        message: message,
      );
    }

    // Si es filtro general, mostrar en toda la pantalla
    if (_selectedFilter == 'general') {
      return Column(
        children: [
          const Divider(),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredIncidents.length,
            itemBuilder: (context, index) {
              final incidentData = filteredIncidents[index].data() as Map<String, dynamic>;
              return _buildDetailedIncidentCard(incidentData, filteredIncidents[index].id);
            },
          ),
        ],
      );
    }

    // Para otros filtros, mostrar compacto
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredIncidents.length,
      itemBuilder: (context, index) {
        final incidentData = filteredIncidents[index].data() as Map<String, dynamic>;
        return _buildIncidentCard(incidentData, filteredIncidents[index].id);
      },
    );
  }

  List<QueryDocumentSnapshot> _filterIncidentsByDate(List<QueryDocumentSnapshot> incidents) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'day':
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        return incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['reportedAt']?.toDate();
          return createdAt != null && 
                 createdAt.isAfter(startOfDay) && 
                 createdAt.isBefore(endOfDay);
        }).toList();
        
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['reportedAt']?.toDate();
          return createdAt != null && createdAt.isAfter(startOfWeekDay);
        }).toList();
        
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return incidents.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final createdAt = data['reportedAt']?.toDate();
          return createdAt != null && createdAt.isAfter(startOfMonth);
        }).toList();
        
      default: // general
        return incidents;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(Map<String, dynamic> incidentData, String incidentId) {
    // Usar incidentType como título si title está vacío o es null
    final title = (incidentData['title']?.toString().trim().isEmpty ?? true) 
        ? (incidentData['incidentType'] ?? 'Incidente') 
        : incidentData['title'];
    final description = incidentData['description'] ?? 'Sin descripción';
    final status = incidentData['status'] ?? 'unknown';
    final computerNumber = incidentData['computerNumbers']?.isNotEmpty == true 
        ? incidentData['computerNumbers'][0].toString() 
        : 'N/A';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        break;
      case 'inProgress':
        statusColor = Colors.blue;
        statusText = 'En Progreso';
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Resuelto';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showIncidentDetail(incidentData, incidentId),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            Icons.report_outlined,
            color: statusColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.computer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('PC: $computerNumber'),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedIncidentCard(Map<String, dynamic> incidentData, String incidentId) {
    // Usar incidentType como título si title está vacío o es null
    final title = (incidentData['title']?.toString().trim().isEmpty ?? true) 
        ? (incidentData['incidentType'] ?? 'Incidente') 
        : incidentData['title'];
    final description = incidentData['description'] ?? 'Sin descripción';
    final status = incidentData['status'] ?? 'unknown';
    final reportedAt = incidentData['reportedAt']?.toDate();
    final computerNumbers = incidentData['computerNumbers'] as List<dynamic>? ?? [];
    final labName = incidentData['labName'] ?? 'N/A';
    final incidentType = incidentData['incidentType'] ?? 'N/A';
    final assignedTo = incidentData['assignedTo'];
    final resolutionMessage = incidentData['resolutionMessage'];
    final resolutionNotes = incidentData['resolutionNotes'];

    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pendiente';
        statusIcon = Icons.pending;
        break;
      case 'inProgress':
        statusColor = Colors.blue;
        statusText = 'En Progreso';
        statusIcon = Icons.work;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusText = 'Resuelto';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Desconocido';
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showIncidentDetail(incidentData, incidentId),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con título y estado
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Descripción
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            
            // Información detallada
            _buildDetailRow(Icons.category, 'Tipo', incidentType),
            _buildDetailRow(Icons.location_on, 'Laboratorio', labName),
            _buildDetailRow(
              Icons.computer, 
              'Computadoras', 
              computerNumbers.isNotEmpty 
                  ? computerNumbers.join(', ') 
                  : 'N/A'
            ),
            if (reportedAt != null)
              _buildDetailRow(
                Icons.access_time, 
                'Reportado', 
                '${DateFormatter.formatDateTime(reportedAt)} (${DateFormatter.getTimeAgo(reportedAt)})'
              ),
            
            // Información de asignación y resolución
            if (assignedTo != null)
              _buildDetailRow(Icons.person, 'Asignado a', assignedTo['name'] ?? 'N/A'),
            
            if (status == 'resolved') ...[
              const Divider(height: 20),
              if (resolutionMessage != null && resolutionMessage.isNotEmpty)
                _buildDetailRow(Icons.message, 'Mensaje de resolución', resolutionMessage),
              if (resolutionNotes != null && resolutionNotes.isNotEmpty)
                _buildDetailRow(Icons.note, 'Notas de resolución', resolutionNotes),
            ],
          ],
        ),
      ),
      ),
    );
  }

  void _showIncidentDetail(Map<String, dynamic> incidentData, String incidentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _StudentIncidentDetailScreen(
          incidentId: incidentId,
          incidentData: incidentData,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}