import 'package:flutter/material.dart';
import '../models/computer_model.dart';
import '../services/computer_service.dart';
import '../utils/colors.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/custom_modal.dart';

class AddComputerScreen extends StatefulWidget {
  final String labName;
  final Computer? computer; // Para edición

  const AddComputerScreen({
    Key? key,
    required this.labName,
    this.computer,
  }) : super(key: key);

  @override
  State<AddComputerScreen> createState() => _AddComputerScreenState();
}

class _AddComputerScreenState extends State<AddComputerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _computerService = ComputerService();
  bool _isLoading = false;

  // Controladores para número de computadora
  late TextEditingController _computerNumberController;

  // Controladores para CPU
  late TextEditingController _cpuBrandController;
  late TextEditingController _cpuModelController;
  late TextEditingController _cpuSerialController;

  // Controladores para Monitor
  late TextEditingController _monitorBrandController;
  late TextEditingController _monitorModelController;
  late TextEditingController _monitorSerialController;

  // Controladores para Mouse
  late TextEditingController _mouseBrandController;
  late TextEditingController _mouseModelController;
  late TextEditingController _mouseSerialController;

  // Controladores para Teclado
  late TextEditingController _keyboardBrandController;
  late TextEditingController _keyboardModelController;
  late TextEditingController _keyboardSerialController;

  // Controlador para notas
  late TextEditingController _notesController;

  bool get isEditing => widget.computer != null;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (!isEditing) {
      _loadNextComputerNumber();
    }
  }

  void _initializeControllers() {
    final computer = widget.computer;

    _computerNumberController = TextEditingController(
      text: computer?.computerNumber.toString() ?? '',
    );

    // CPU
    _cpuBrandController = TextEditingController(text: computer?.cpu.brand ?? '');
    _cpuModelController = TextEditingController(text: computer?.cpu.model ?? '');
    _cpuSerialController = TextEditingController(text: computer?.cpu.serialNumber ?? '');

    // Monitor
    _monitorBrandController = TextEditingController(text: computer?.monitor.brand ?? '');
    _monitorModelController = TextEditingController(text: computer?.monitor.model ?? '');
    _monitorSerialController = TextEditingController(text: computer?.monitor.serialNumber ?? '');

    // Mouse
    _mouseBrandController = TextEditingController(text: computer?.mouse.brand ?? '');
    _mouseModelController = TextEditingController(text: computer?.mouse.model ?? '');
    _mouseSerialController = TextEditingController(text: computer?.mouse.serialNumber ?? '');

    // Teclado
    _keyboardBrandController = TextEditingController(text: computer?.keyboard.brand ?? '');
    _keyboardModelController = TextEditingController(text: computer?.keyboard.model ?? '');
    _keyboardSerialController = TextEditingController(text: computer?.keyboard.serialNumber ?? '');

    // Notas
    _notesController = TextEditingController(text: computer?.notes ?? '');
  }

  Future<void> _loadNextComputerNumber() async {
    try {
      final nextNumber = await _computerService.getNextComputerNumber(widget.labName);
      _computerNumberController.text = nextNumber.toString();
    } catch (e) {
      print('Error al cargar siguiente número: $e');
    }
  }

  @override
  void dispose() {
    _computerNumberController.dispose();
    _cpuBrandController.dispose();
    _cpuModelController.dispose();
    _cpuSerialController.dispose();
    _monitorBrandController.dispose();
    _monitorModelController.dispose();
    _monitorSerialController.dispose();
    _mouseBrandController.dispose();
    _mouseModelController.dispose();
    _mouseSerialController.dispose();
    _keyboardBrandController.dispose();
    _keyboardModelController.dispose();
    _keyboardSerialController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Computadora' : 'Agregar Computadora'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildComputerNumberSection(),
              const SizedBox(height: 24),
              _buildComponentSection(
                title: 'CPU',
                icon: Icons.memory,
                brandController: _cpuBrandController,
                modelController: _cpuModelController,
                serialController: _cpuSerialController,
              ),
              const SizedBox(height: 24),
              _buildComponentSection(
                title: 'Monitor',
                icon: Icons.monitor,
                brandController: _monitorBrandController,
                modelController: _monitorModelController,
                serialController: _monitorSerialController,
              ),
              const SizedBox(height: 24),
              _buildComponentSection(
                title: 'Mouse',
                icon: Icons.mouse,
                brandController: _mouseBrandController,
                modelController: _mouseModelController,
                serialController: _mouseSerialController,
              ),
              const SizedBox(height: 24),
              _buildComponentSection(
                title: 'Teclado',
                icon: Icons.keyboard,
                brandController: _keyboardBrandController,
                modelController: _keyboardModelController,
                serialController: _keyboardSerialController,
              ),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.computer,
              color: AppColors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Laboratorio ${widget.labName}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                Text(
                  isEditing ? 'Modificar información de PC' : 'Registrar nueva PC',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComputerNumberSection() {
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
          Row(
            children: [
              Icon(Icons.tag, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Número de Computadora',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _computerNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Número de PC',
              hintText: 'Ej: 1, 2, 3...',
              prefixIcon: const Icon(Icons.numbers),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El número de computadora es requerido';
              }
              final number = int.tryParse(value);
              if (number == null || number <= 0) {
                return 'Ingrese un número válido mayor a 0';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildComponentSection({
    required String title,
    required IconData icon,
    required TextEditingController brandController,
    required TextEditingController modelController,
    required TextEditingController serialController,
  }) {
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
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: brandController,
            decoration: InputDecoration(
              labelText: 'Marca',
              hintText: 'Ej: HP, Dell, Logitech...',
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La marca es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: modelController,
            decoration: InputDecoration(
              labelText: 'Modelo',
              hintText: 'Ej: OptiPlex 3080, MX Keys...',
              prefixIcon: const Icon(Icons.info_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El modelo es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: serialController,
            decoration: InputDecoration(
              labelText: 'Número de Serie',
              hintText: 'Ej: ABC123456789',
              prefixIcon: const Icon(Icons.qr_code),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El número de serie es requerido';
              }
              if (value.length < 3) {
                return 'El número de serie debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
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
          Row(
            children: [
              Icon(Icons.note_alt, color: AppColors.primaryBlue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Notas Adicionales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notas (Opcional)',
              hintText: 'Información adicional sobre la computadora...',
              prefixIcon: const Icon(Icons.edit_note),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppColors.textLight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _saveComputer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isEditing ? 'Actualizar' : 'Guardar',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveComputer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final computer = Computer(
        id: widget.computer?.id ?? '',
        labName: widget.labName,
        computerNumber: int.parse(_computerNumberController.text),
        cpu: ComputerComponent(
          brand: _cpuBrandController.text.trim(),
          model: _cpuModelController.text.trim(),
          serialNumber: _cpuSerialController.text.trim(),
        ),
        monitor: ComputerComponent(
          brand: _monitorBrandController.text.trim(),
          model: _monitorModelController.text.trim(),
          serialNumber: _monitorSerialController.text.trim(),
        ),
        mouse: ComputerComponent(
          brand: _mouseBrandController.text.trim(),
          model: _mouseModelController.text.trim(),
          serialNumber: _mouseSerialController.text.trim(),
        ),
        keyboard: ComputerComponent(
          brand: _keyboardBrandController.text.trim(),
          model: _keyboardModelController.text.trim(),
          serialNumber: _keyboardSerialController.text.trim(),
        ),
        createdAt: widget.computer?.createdAt ?? DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (isEditing) {
        await _computerService.updateComputer(widget.computer!.id, computer);
      } else {
        await _computerService.addComputer(computer);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing 
                ? 'Computadora actualizada exitosamente'
                : 'Computadora agregada exitosamente',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.danger,
          title: 'Error',
          message: e.toString(),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}