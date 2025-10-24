import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/computer_model.dart';
import '../services/computer_service.dart';
import '../services/incident_service.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/equipment_formatter.dart';
import '../widgets/custom_modal.dart';
import 'incident_detail_screen.dart';

enum ComputerStatus { available, hasIncident, disabled, restricted }

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
  final ComputerService _computerService = ComputerService();
  final AuthService _authService = AuthService();
  String? _userRole;
  Map<int, String> _computersWithIncidents = {};
  List<Computer> _availableComputers = [];
  bool _isLoading = true;
  int _totalStudentComputers = 0; // Se calculará dinámicamente desde la BD

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadComputerStatuses();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final role = await _authService.getUserRole(user.uid);
        setState(() {
          _userRole = role;
        });
      }
    } catch (e) {
      print('Error al obtener rol del usuario: $e');
    }
  }

  Future<void> _loadComputerStatuses() async {
    try {
      // Cargar computadoras desde la base de datos
      final computersSnapshot = await FirebaseFirestore.instance
          .collection('computers')
          .where('labName', isEqualTo: widget.labName)
          .where('isActive', isEqualTo: true)
          .get();

      final computers = computersSnapshot.docs
          .map((doc) => Computer.fromMap(doc.data()))
          .toList();

      // Ordenar por número de computadora
      computers.sort((a, b) => a.computerNumber.compareTo(b.computerNumber));

      // Calcular el número total de computadoras de estudiantes dinámicamente
      final studentComputers = computers.where((c) => c.isStudentComputer).toList();
      final maxComputerNumber = studentComputers.isNotEmpty 
          ? studentComputers.map((c) => c.computerNumber).reduce((a, b) => a > b ? a : b)
          : 0;
      
      print('DEBUG: Total computadoras encontradas: ${computers.length}');
      print('DEBUG: Computadoras de estudiantes: ${studentComputers.length}');
      print('DEBUG: Números de computadoras: ${studentComputers.map((c) => c.computerNumber).toList()}');
      print('DEBUG: Número máximo calculado: $maxComputerNumber');

      // Cargar incidentes activos
      final computersWithIncidents = await _incidentService.getComputersWithActiveIncidents(widget.labName);
      
      setState(() {
        _availableComputers = computers;
        _computersWithIncidents = computersWithIncidents;
        _totalStudentComputers = maxComputerNumber; // Usar el número más alto encontrado
        _isLoading = false;
      });
      
      print('DEBUG: _totalStudentComputers establecido en: $_totalStudentComputers');
    } catch (e) {
      print('Error cargando computadoras: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  ComputerStatus _getComputerStatus(int computerNumber) {
    // Manejar casos especiales
    if (computerNumber == EquipmentFormatter.teacherPCIndex) {
      // PC del docente
      if (_userRole == 'student') {
        return ComputerStatus.restricted;
      }
      // Verificar si tiene incidentes activos
      if (_computersWithIncidents.containsKey(EquipmentFormatter.teacherPCIndex)) {
        return ComputerStatus.hasIncident;
      }
      return ComputerStatus.available;
    }
    
    if (computerNumber == EquipmentFormatter.projectorIndex) {
      // Proyector
      if (_userRole == 'student') {
        return ComputerStatus.restricted;
      }
      // Verificar si tiene incidentes activos
      if (_computersWithIncidents.containsKey(EquipmentFormatter.projectorIndex)) {
        return ComputerStatus.hasIncident;
      }
      return ComputerStatus.available;
    }

    // Verificar si la computadora existe en la base de datos
    final computer = _availableComputers.where((c) => c.computerNumber == computerNumber).firstOrNull;
    
    if (computer == null) {
      return ComputerStatus.disabled; // No existe en la BD
    }
    
    // Verificar restricciones de acceso basadas en el rol del usuario
    if (_userRole == 'student') {
      if (computer.isTeacherComputer || computer.isProjector) {
        return ComputerStatus.restricted;
      }
    }
    
    if (_computersWithIncidents.containsKey(computerNumber)) {
      return ComputerStatus.hasIncident;
    }
    
    return ComputerStatus.available;
  }

  // Método para obtener información de la computadora desde la BD
  Computer? _getComputerInfo(int computerNumber) {
    // Manejar casos especiales
    if (computerNumber == EquipmentFormatter.teacherPCIndex) {
      // PC del docente - crear un objeto virtual
      return Computer(
        id: 'teacher_pc',
        labName: widget.labName,
        computerNumber: EquipmentFormatter.teacherPCIndex,
        cpu: ComputerComponent(brand: 'Virtual', model: 'Teacher PC', serialNumber: 'TEACHER-001'),
        monitor: ComputerComponent(brand: 'Virtual', model: 'Teacher Monitor', serialNumber: 'TEACHER-MON-001'),
        mouse: ComputerComponent(brand: 'Virtual', model: 'Teacher Mouse', serialNumber: 'TEACHER-MOUSE-001'),
        keyboard: ComputerComponent(brand: 'Virtual', model: 'Teacher Keyboard', serialNumber: 'TEACHER-KB-001'),
        createdAt: DateTime.now(),
        isActive: true,
        equipmentType: EquipmentType.teacher,
      );
    }
    
    if (computerNumber == EquipmentFormatter.projectorIndex) {
      // Proyector - crear un objeto virtual
      return Computer(
        id: 'projector',
        labName: widget.labName,
        computerNumber: EquipmentFormatter.projectorIndex,
        cpu: ComputerComponent(brand: 'Virtual', model: 'Projector CPU', serialNumber: 'PROJ-CPU-001'),
        monitor: ComputerComponent(brand: 'Virtual', model: 'Projector Display', serialNumber: 'PROJ-DISPLAY-001'),
        mouse: ComputerComponent(brand: 'Virtual', model: 'Projector Remote', serialNumber: 'PROJ-REMOTE-001'),
        keyboard: ComputerComponent(brand: 'Virtual', model: 'Projector Control', serialNumber: 'PROJ-CTRL-001'),
        projector: ComputerComponent(brand: 'Virtual', model: 'Projector', serialNumber: 'PROJ-001'),
        createdAt: DateTime.now(),
        isActive: true,
        equipmentType: EquipmentType.projector,
      );
    }

    try {
      return _availableComputers.firstWhere((c) => c.computerNumber == computerNumber);
    } catch (e) {
      return null;
    }
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
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.primaryBlue),
            onPressed: _showLabComputersInfo,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primaryBlue),
            onPressed: _loadComputerStatuses,
          ),
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
          : _totalStudentComputers == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.computer, size: 64, color: AppColors.lightGray),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron computadoras',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El laboratorio ${widget.labName} no tiene computadoras registradas.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadComputerStatuses,
                        child: Text('Recargar'),
                      ),
                    ],
                  ),
                )
              : Column(
        children: [
          // Instrucciones
          Container(
            padding: const EdgeInsets.all(12),
            color: AppColors.skyBlue.withOpacity(0.2),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primaryBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usa dos dedos para hacer zoom. Selecciona las computadoras con problemas.',
                    style: TextStyle(
                      fontSize: 12,
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
              boundaryMargin: EdgeInsets.all(isTablet ? 100 : 60),
              child: SingleChildScrollView(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 40 : 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Equipos del docente (arriba, centrados)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildProjector(screenSize, isTablet),
                            SizedBox(width: isTablet ? 30 : 16),
                            _buildTeacherComputer(screenSize, isTablet),
                          ],
                        ),
                        SizedBox(height: isTablet ? 40 : 24),
                        
                        // Computadoras de estudiantes (layout responsive)
                        ..._buildStudentRows(screenSize, isTablet, isLandscape),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Leyenda de estados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: AppColors.lightGray, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Leyenda:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildLegendItem(
                      color: AppColors.lightBlue,
                      label: 'PC Estudiante',
                      icon: Icons.computer,
                    ),
                    _buildLegendItem(
                      color: AppColors.warning,
                      label: 'PC Docente',
                      icon: Icons.school,
                    ),
                    _buildLegendItem(
                      color: Colors.purple,
                      label: 'Proyector',
                      icon: Icons.videocam,
                    ),
                    _buildLegendItem(
                      color: AppColors.danger,
                      label: 'En Incidente',
                      icon: Icons.error,
                    ),
                    _buildLegendItem(
                      color: Colors.orange,
                      label: 'Restringido',
                      icon: Icons.lock,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
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
    final canAccess = _userRole == 'admin' || _userRole == 'support' || _userRole == 'teacher';
    
    return GestureDetector(
      onTap: () {
        if (canAccess) {
          _onComputerTap(EquipmentFormatter.teacherPCIndex); // Usar índice especial para la PC del docente
        } else {
          _showRestrictedAccessDialog(null);
        }
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
              'PC Docente',
              style: TextStyle(
                color: AppColors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjector(Size screenSize, bool isTablet) {
    final computerSize = _getComputerSize(screenSize, isTablet, isTeacher: true);
    final iconSize = computerSize * 0.4;
    final fontSize = computerSize * 0.14;
    final canAccess = _userRole == 'admin' || _userRole == 'support' || _userRole == 'teacher';
    
    return GestureDetector(
      onTap: () {
        if (canAccess) {
          _onComputerTap(EquipmentFormatter.projectorIndex); // Usar índice especial para proyector
        } else {
          _showRestrictedAccessDialog(null);
        }
      },
      child: Container(
        width: computerSize,
        height: computerSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(computerSize * 0.17),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: computerSize * 0.11,
              offset: Offset(0, computerSize * 0.06),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, color: AppColors.white, size: iconSize),
            SizedBox(height: computerSize * 0.06),
            Text(
              'Proyector',
              style: TextStyle(
                color: AppColors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
    
    if (isTablet) {
      computersPerRow = isLandscape ? 6 : 5;
    } else {
      computersPerRow = isLandscape ? 5 : 4;
    }
    
    // Calcular el número de filas necesarias dinámicamente basado en el total de computadoras
    int totalRows = (_totalStudentComputers / computersPerRow).ceil();
    
    print('DEBUG: computersPerRow: $computersPerRow, totalRows: $totalRows, _totalStudentComputers: $_totalStudentComputers');
    
    final spacing = _getSpacing(screenSize, isTablet);
    
    for (int row = 0; row < totalRows; row++) {
      List<Widget> computersInRow = [];
      
      for (int col = 0; col < computersPerRow; col++) {
        int computerIndex = row * computersPerRow + col + 1;
        
        // Solo agregar si no excede el total de computadoras
        if (computerIndex <= _totalStudentComputers) {
          computersInRow.add(_buildStudentComputer(computerIndex, screenSize, isTablet));
          
          if (col < computersPerRow - 1 && computerIndex < _totalStudentComputers) {
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
    final computer = _getComputerInfo(index);
    final computerSize = _getComputerSize(screenSize, isTablet);
    final iconSize = computerSize * 0.4;
    final fontSize = computerSize * 0.17;
    final borderWidth = computerSize * 0.05;
    
    // Determinar colores según el estado
    List<Color> gradientColors;
    Color shadowColor;
    IconData iconData;
    bool isInteractable = true;
    String displayText = 'PC $index';

    if (computerStatus == ComputerStatus.disabled) {
      gradientColors = [AppColors.lightGray, AppColors.lightGray.withOpacity(0.8)];
      shadowColor = AppColors.lightGray;
      iconData = Icons.block;
      isInteractable = false;
    } else if (computerStatus == ComputerStatus.restricted) {
      gradientColors = [Colors.orange, Colors.orange.withOpacity(0.8)];
      shadowColor = Colors.orange;
      iconData = Icons.lock;
      isInteractable = false;
      displayText = computer?.equipmentTypeDisplayName ?? 'Restringido';
    } else if (computerStatus == ComputerStatus.hasIncident) {
      gradientColors = [AppColors.danger, AppColors.danger.withOpacity(0.8)];
      shadowColor = AppColors.danger;
      iconData = Icons.error;
      isInteractable = false;
    } else if (isSelected) {
      gradientColors = [AppColors.accentGold, AppColors.darkGold];
      shadowColor = AppColors.accentGold;
      iconData = Icons.check_circle;
    } else {
      // Determinar icono según el tipo de equipo
      if (computer?.isProjector == true) {
        gradientColors = [Colors.purple, Colors.purple.withOpacity(0.8)];
        shadowColor = Colors.purple;
        iconData = Icons.videocam;
        displayText = 'Proyector';
      } else if (computer?.isTeacherComputer == true) {
        gradientColors = [AppColors.warning, AppColors.darkGold];
        shadowColor = AppColors.warning;
        iconData = Icons.school;
        displayText = 'PC Docente';
      } else {
        gradientColors = [AppColors.lightBlue, AppColors.skyBlue];
        shadowColor = AppColors.lightBlue;
        iconData = Icons.computer;
      }
    }
    
    return GestureDetector(
      onTap: () => _onComputerTap(index),
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
              displayText,
              style: TextStyle(
                color: AppColors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 10,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
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

  void _onComputerTap(int computerNumber) {
    final status = _getComputerStatus(computerNumber);
    final computerInfo = _getComputerInfo(computerNumber);
    
    if (status == ComputerStatus.disabled) {
      _showComputerNotFoundDialog(computerNumber);
    } else if (status == ComputerStatus.restricted) {
      _showRestrictedAccessDialog(computerInfo);
    } else if (status == ComputerStatus.hasIncident) {
      _showIncidentInfo(computerNumber, computerInfo);
    } else if (status == ComputerStatus.available) {
      setState(() {
        if (_selectedComputers.contains(computerNumber)) {
          _selectedComputers.remove(computerNumber);
        } else {
          _selectedComputers.add(computerNumber);
        }
      });
    }
  }

  void _showComputerNotFoundDialog(int computerNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Computadora no encontrada'),
          content: Text(
            'La computadora #$computerNumber no existe en la base de datos del laboratorio ${widget.labName}.\n\n'
            'Por favor, contacte al administrador para agregar esta computadora al sistema.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _showRestrictedAccessDialog(Computer? computer) {
    String equipmentType = computer?.equipmentTypeDisplayName ?? 'equipo';
    String message;
    
    if (computer?.isTeacherComputer == true) {
      message = 'Solo el docente, personal de soporte y administradores pueden reportar incidentes en la computadora del docente.';
    } else if (computer?.isProjector == true) {
      message = 'Solo el docente, personal de soporte y administradores pueden reportar incidentes en el proyector.';
    } else {
      message = 'No tienes permisos para reportar incidentes en este equipo.';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Acceso Restringido'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _showLabComputersInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Computadoras del Laboratorio ${widget.labName}'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: _availableComputers.isEmpty
                ? Center(
                    child: Text(
                      'No hay computadoras registradas en este laboratorio.\n\n'
                      'Contacte al administrador para inicializar las computadoras.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: _availableComputers.length,
                    itemBuilder: (context, index) {
                      final computer = _availableComputers[index];
                      final hasIncident = _computersWithIncidents.containsKey(computer.computerNumber);
                      
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: hasIncident ? Colors.red : Colors.green,
                            child: Text(
                              '${computer.computerNumber}',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('PC ${computer.computerNumber}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CPU: ${computer.cpu.brand} ${computer.cpu.model}'),
                              Text('Monitor: ${computer.monitor.brand} ${computer.monitor.model}'),
                              if (hasIncident)
                                Text(
                                  'Con incidente activo',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                          trailing: Icon(
                            hasIncident ? Icons.error : Icons.check_circle,
                            color: hasIncident ? Colors.red : Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  void _showIncidentInfo(int computerNumber, Computer? computerInfo) {
    final incidentId = _computersWithIncidents[computerNumber];
    
    String computerDetails = '';
    if (computerInfo != null) {
      computerDetails = '\n\nDetalles de la computadora:'
          '\n• CPU: ${computerInfo.cpu.brand} ${computerInfo.cpu.model}'
          '\n• Monitor: ${computerInfo.monitor.brand} ${computerInfo.monitor.model}'
          '\n• Mouse: ${computerInfo.mouse.brand} ${computerInfo.mouse.model}'
          '\n• Teclado: ${computerInfo.keyboard.brand} ${computerInfo.keyboard.model}';
      
      computerDetails += '\n\nNúmeros de serie:'
          '\n• CPU: ${computerInfo.cpu.serialNumber}'
          '\n• Monitor: ${computerInfo.monitor.serialNumber}'
          '\n• Mouse: ${computerInfo.mouse.serialNumber}'
          '\n• Teclado: ${computerInfo.keyboard.serialNumber}';
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Computadora con incidente'),
          content: SingleChildScrollView(
            child: Text(
              'La computadora #$computerNumber tiene un incidente activo.\n'
              'ID del incidente: $incidentId\n\n'
              'No se puede seleccionar para reportar nuevos incidentes.'
              '$computerDetails'
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _onContinue() {
    if (_selectedComputers.isNotEmpty) {
      // Validar que todas las computadoras seleccionadas existan en la BD
      final invalidComputers = _selectedComputers.where((computerNumber) {
        return !_availableComputers.any((c) => c.computerNumber == computerNumber);
      }).toList();

      if (invalidComputers.isNotEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error de selección'),
              content: Text(
                'Las siguientes computadoras no existen en la base de datos:\n'
                '${invalidComputers.map((n) => '#$n').join(', ')}\n\n'
                'Por favor, seleccione solo computadoras válidas.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Entendido'),
                ),
              ],
            );
          },
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IncidentDetailScreen(
            labName: widget.labName,
            selectedComputers: _selectedComputers.toList(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }
}