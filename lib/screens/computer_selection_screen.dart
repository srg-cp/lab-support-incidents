import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../widgets/custom_modal.dart';
import '../services/incident_service.dart';
import 'incident_detail_screen.dart';

enum ComputerStatus { available, hasIncident, disabled }

class ComputerSelectionScreen extends StatefulWidget {
  final String labName;
  
  const ComputerSelectionScreen({Key? key, required this.labName}) : super(key: key);

  @override
  State<ComputerSelectionScreen> createState() => _ComputerSelectionScreenState();
}

class _ComputerSelectionScreenState extends State<ComputerSelectionScreen> {
  final Set<int> _selectedComputers = {};
  final TransformationController _transformationController = TransformationController();
  final IncidentService _incidentService = IncidentService();
  Map<int, String> _computersWithIncidents = {};
  bool _isLoading = true;
  
  // Configuración inicial: 20 computadoras de estudiantes + 1 de docente
  static const int totalStudentComputers = 20;
  static const int teacherComputerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadComputerStatuses();
  }

  Future<void> _loadComputerStatuses() async {
    try {
      final computersWithIncidents = await _incidentService.getComputersWithActiveIncidents(widget.labName);
      setState(() {
        _computersWithIncidents = computersWithIncidents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ComputerStatus _getComputerStatus(int computerNumber) {
    if (_computersWithIncidents.containsKey(computerNumber)) {
      return ComputerStatus.hasIncident;
    }
    return ComputerStatus.available;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLandscape = screenSize.width > screenSize.height;
    
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
              minScale: 0.3,
              maxScale: 4.0,
              boundaryMargin: EdgeInsets.all(isTablet ? 150 : 80),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 60 : 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Computadora del docente (arriba, centrada)
                      _buildTeacherComputer(screenSize, isTablet),
                      SizedBox(height: isTablet ? 50 : 30),
                      
                      // Computadoras de estudiantes (layout responsive)
                      ..._buildStudentRows(screenSize, isTablet, isLandscape),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Leyenda de estados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: AppColors.lightGray, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leyenda:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(
                      color: AppColors.lightBlue,
                      label: 'Disponible',
                      icon: Icons.computer,
                    ),
                    _buildLegendItem(
                      color: AppColors.danger,
                      label: 'En Incidente',
                      icon: Icons.error,
                    ),
                    _buildLegendItem(
                      color: AppColors.accentGold,
                      label: 'Seleccionado',
                      icon: Icons.check_circle,
                    ),
                  ],
                ),
              ],
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

  Widget _buildTeacherComputer(Size screenSize, bool isTablet) {
    final computerSize = _getComputerSize(screenSize, isTablet, isTeacher: true);
    final iconSize = computerSize * 0.4;
    final fontSize = computerSize * 0.14;
    
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
        width: computerSize,
        height: computerSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.warning, AppColors.darkGold],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(computerSize * 0.17),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withOpacity(0.3),
              blurRadius: computerSize * 0.11,
              offset: Offset(0, computerSize * 0.06),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, color: AppColors.white, size: iconSize),
            SizedBox(height: computerSize * 0.06),
            Text(
              'Docente',
              style: TextStyle(
                color: AppColors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStudentRows(Size screenSize, bool isTablet, bool isLandscape) {
    List<Widget> rows = [];
    
    // Determinar el layout según el tamaño de pantalla
    int computersPerRow;
    int totalRows;
    
    if (isTablet) {
      computersPerRow = isLandscape ? 6 : 5;
      totalRows = isLandscape ? 4 : 4;
    } else {
      computersPerRow = isLandscape ? 5 : 4;
      totalRows = isLandscape ? 4 : 5;
    }
    
    final spacing = _getSpacing(screenSize, isTablet);
    
    for (int row = 0; row < totalRows; row++) {
      List<Widget> computersInRow = [];
      
      for (int col = 0; col < computersPerRow; col++) {
        int computerIndex = row * computersPerRow + col + 1;
        
        // Solo agregar si no excede el total de computadoras
        if (computerIndex <= totalStudentComputers) {
          computersInRow.add(_buildStudentComputer(computerIndex, screenSize, isTablet));
          
          if (col < computersPerRow - 1 && computerIndex < totalStudentComputers) {
            computersInRow.add(SizedBox(width: spacing));
          }
        }
      }
      
      if (computersInRow.isNotEmpty) {
        rows.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: computersInRow,
          ),
        );
        
        if (row < totalRows - 1) {
          rows.add(SizedBox(height: spacing));
        }
      }
    }
    
    return rows;
  }

  Widget _buildStudentComputer(int index, Size screenSize, bool isTablet) {
    final isSelected = _selectedComputers.contains(index);
    final computerStatus = _getComputerStatus(index);
    final computerSize = _getComputerSize(screenSize, isTablet);
    final iconSize = computerSize * 0.4;
    final fontSize = computerSize * 0.17;
    final borderWidth = computerSize * 0.05;
    
    // Determinar colores según el estado
    List<Color> gradientColors;
    Color shadowColor;
    IconData iconData;
    bool isInteractable = true;

    if (computerStatus == ComputerStatus.hasIncident) {
      gradientColors = [AppColors.danger, AppColors.danger.withOpacity(0.8)];
      shadowColor = AppColors.danger;
      iconData = Icons.error;
      isInteractable = false;
    } else if (isSelected) {
      gradientColors = [AppColors.accentGold, AppColors.darkGold];
      shadowColor = AppColors.accentGold;
      iconData = Icons.check_circle;
    } else {
      gradientColors = [AppColors.lightBlue, AppColors.skyBlue];
      shadowColor = AppColors.lightBlue;
      iconData = Icons.computer;
    }
    
    return GestureDetector(
      onTap: isInteractable ? () {
        setState(() {
          if (isSelected) {
            _selectedComputers.remove(index);
          } else {
            _selectedComputers.add(index);
          }
        });
      } : () {
        // Mostrar mensaje para computadoras con incidentes
        CustomModal.show(
          context,
          type: ModalType.warning,
          title: 'Computadora No Disponible',
          message: 'La PC $index ya tiene un incidente activo. '
              'Espera a que se resuelva antes de reportar un nuevo problema.',
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: computerSize,
        height: computerSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(computerSize * 0.17),
          border: isSelected
              ? Border.all(color: AppColors.white, width: borderWidth)
              : null,
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.3),
              blurRadius: isSelected ? computerSize * 0.17 : computerSize * 0.1,
              offset: Offset(0, computerSize * 0.07),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: AppColors.white,
              size: iconSize,
            ),
            SizedBox(height: computerSize * 0.03),
            Text(
              'PC $index',
              style: TextStyle(
                color: AppColors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 12,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Métodos auxiliares para cálculos responsive
  double _getComputerSize(Size screenSize, bool isTablet, {bool isTeacher = false}) {
    double baseSize;
    
    if (isTablet) {
      baseSize = isTeacher ? 90.0 : 75.0;
    } else {
      baseSize = isTeacher ? 70.0 : 55.0;
    }
    
    // Ajustar según el ancho de pantalla
    final screenFactor = (screenSize.width / 400).clamp(0.7, 1.5);
    return baseSize * screenFactor;
  }

  double _getSpacing(Size screenSize, bool isTablet) {
    double baseSpacing = isTablet ? 20.0 : 12.0;
    final screenFactor = (screenSize.width / 400).clamp(0.7, 1.3);
    return baseSpacing * screenFactor;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}