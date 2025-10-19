import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/custom_modal.dart';
import 'incident_detail_screen.dart';

class ComputerSelectionScreen extends StatefulWidget {
  final String labName;
  
  const ComputerSelectionScreen({Key? key, required this.labName}) : super(key: key);

  @override
  State<ComputerSelectionScreen> createState() => _ComputerSelectionScreenState();
}

class _ComputerSelectionScreenState extends State<ComputerSelectionScreen> {
  final Set<int> _selectedComputers = {};
  final TransformationController _transformationController = TransformationController();
  
  // Configuración inicial: 20 computadoras de estudiantes + 1 de docente
  static const int totalStudentComputers = 20;
  static const int teacherComputerIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laboratorio ${widget.labName}'),
        actions: [
          if (_selectedComputers.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  label: Text(
                    '${_selectedComputers.length} seleccionada(s)',
                    style: const TextStyle(color: AppColors.white, fontSize: 12),
                  ),
                  backgroundColor: AppColors.accentGold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Instrucciones
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.skyBlue.withOpacity(0.2),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Usa dos dedos para hacer zoom. Selecciona las computadoras con problemas.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Mapa interactivo con zoom
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 3.0,
              boundaryMargin: const EdgeInsets.all(100),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Computadora del docente (arriba, centrada)
                      _buildTeacherComputer(),
                      const SizedBox(height: 40),
                      
                      // Computadoras de estudiantes (4 filas x 5 columnas)
                      ..._buildStudentRows(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Botón continuar
          if (_selectedComputers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => IncidentDetailScreen(
                        labName: widget.labName,
                        selectedComputers: _selectedComputers.toList(),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Continuar'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeacherComputer() {
    return GestureDetector(
      onTap: () {
        CustomModal.show(
          context,
          type: ModalType.warning,
          title: 'Computadora Restringida',
          message: 'Solo el docente puede reportar un incidente en esta computadora.',
        );
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.warning, AppColors.darkGold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, color: AppColors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              'Docente',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentRows() {
    List<Widget> rows = [];
    
    for (int row = 0; row < 4; row++) {
      List<Widget> computersInRow = [];
      
      for (int col = 0; col < 5; col++) {
        int computerIndex = row * 5 + col + 1;
        computersInRow.add(_buildStudentComputer(computerIndex));
        
        if (col < 4) {
          computersInRow.add(const SizedBox(width: 16));
        }
      }
      
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: computersInRow,
        ),
      );
      
      if (row < 3) {
        rows.add(const SizedBox(height: 16));
      }
    }
    
    return rows;
  }

  Widget _buildStudentComputer(int index) {
    final isSelected = _selectedComputers.contains(index);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedComputers.remove(index);
          } else {
            _selectedComputers.add(index);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [AppColors.accentGold, AppColors.darkGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [AppColors.lightBlue, AppColors.skyBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.white, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: (isSelected ? AppColors.accentGold : AppColors.lightBlue)
                  .withOpacity(0.3),
              blurRadius: isSelected ? 10 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.computer,
              color: AppColors.white,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              'PC $index',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}