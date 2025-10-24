import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/colors.dart';
import '../services/lab_service.dart';
import '../services/computer_service.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/empty_state.dart';
import 'computer_selection_screen.dart';

class LabSelectionScreen extends StatefulWidget {
  const LabSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LabSelectionScreen> createState() => _LabSelectionScreenState();
}

class _LabSelectionScreenState extends State<LabSelectionScreen> {
  final LabService _labService = LabService();
  final ComputerService _computerService = ComputerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Laboratorio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _labService.getLabs(),
          builder: (context, labSnapshot) {
            if (labSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.accentGold,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Cargando laboratorios...',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (labSnapshot.hasError) {
              return Center(
                child: Text('Error: ${labSnapshot.error}'),
              );
            }

            if (!labSnapshot.hasData || labSnapshot.data!.docs.isEmpty) {
              return const EmptyState(
                icon: Icons.science,
                title: 'Sin laboratorios',
                message: 'No hay laboratorios configurados en el sistema',
              );
            }

            final labs = labSnapshot.data!.docs;

            // StreamBuilder anidado para obtener conteos de computadoras en tiempo real
            return StreamBuilder<QuerySnapshot>(
              stream: _computerService.getComputersStream(),
              builder: (context, computerSnapshot) {
                // Calcular conteos de computadoras en tiempo real
                Map<String, Map<String, int>> computerCounts = {};
                
                if (computerSnapshot.hasData) {
                  for (final doc in computerSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final labName = data['labName'] as String;
                    final equipmentType = data['equipmentType'] as String? ?? 'student';
                    final isActive = data['isActive'] as bool? ?? true;
                    
                    if (isActive) {
                      if (!computerCounts.containsKey(labName)) {
                        computerCounts[labName] = {'student': 0, 'teacher': 0, 'projector': 0};
                      }
                      computerCounts[labName]![equipmentType] = (computerCounts[labName]![equipmentType] ?? 0) + 1;
                    }
                  }
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: labs.length,
                  itemBuilder: (context, index) {
                    final labData = labs[index].data() as Map<String, dynamic>;
                    final labName = labData['name'] as String;
                    
                    // Combinar datos del laboratorio con conteos en tiempo real
                    final realTimeData = {
                      ...labData,
                      'studentComputers': computerCounts[labName]?['student'] ?? 0,
                      'teacherComputers': computerCounts[labName]?['teacher'] ?? 0,
                      'projectors': computerCounts[labName]?['projector'] ?? 0,
                    };
                    
                    return _buildLabCard(context, labName, realTimeData);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabCard(BuildContext context, String labName, Map<String, dynamic> labData) {
    final totalComputers = labData['totalComputers'] ?? 0;
    final studentComputers = labData['studentComputers'] ?? 0;
    final teacherComputers = labData['teacherComputers'] ?? 0;
    final projectors = labData['projectors'] ?? 0;
    final labType = labData['type'] ?? 'lab';
    
    // Determinar el icono según el tipo
    final icon = labType == 'classroom' ? Icons.meeting_room : Icons.computer;
    final displayName = labType == 'classroom' ? 'Salón $labName' : 'Laboratorio $labName';
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComputerSelectionScreen(labName: labName),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: AppColors.white,
              ),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              if (studentComputers > 0)
                Flexible(
                  child: Text(
                    '$studentComputers PCs estudiantes',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (teacherComputers > 0)
                Flexible(
                  child: Text(
                    '$teacherComputers PC docente',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (projectors > 0)
                Flexible(
                  child: Text(
                    '$projectors proyector${projectors > 1 ? 'es' : ''}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}