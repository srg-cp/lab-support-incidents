import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/computer_model.dart';
import '../services/computer_service.dart';
import '../utils/colors.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/empty_state.dart';
import '../widgets/custom_modal.dart';
import 'add_computer_screen.dart';

class LabDetailScreen extends StatefulWidget {
  final String labName;

  const LabDetailScreen({Key? key, required this.labName}) : super(key: key);

  @override
  State<LabDetailScreen> createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<LabDetailScreen> {
  final ComputerService _computerService = ComputerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laboratorio ${widget.labName}'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: () => _navigateToAddComputer(),
            icon: const Icon(Icons.add),
            tooltip: 'Agregar PC',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _computerService.getComputersByLab(widget.labName),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final computers = snapshot.data!.docs
                      .map((doc) => Computer.fromMap(doc.data() as Map<String, dynamic>))
                      .where((computer) => _matchesSearch(computer))
                      .toList();

                  computers.sort((a, b) => a.computerNumber.compareTo(b.computerNumber));

                  if (computers.isEmpty) {
                    return EmptyState(
                      icon: Icons.computer,
                      title: _searchQuery.isEmpty 
                          ? 'Sin computadoras registradas'
                          : 'Sin resultados',
                      message: _searchQuery.isEmpty
                          ? 'Agrega la primera computadora para el Laboratorio ${widget.labName}'
                          : 'No se encontraron computadoras que coincidan con "$_searchQuery"',
                      actionText: _searchQuery.isEmpty ? 'Agregar PC' : null,
                      onAction: _searchQuery.isEmpty ? _navigateToAddComputer : null,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: computers.length,
                    itemBuilder: (context, index) {
                      return _buildComputerCard(computers[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddComputer,
        backgroundColor: AppColors.accentGold,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.skyBlue.withOpacity(0.1),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por número, marca, modelo o S/N...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.white,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value.toLowerCase());
        },
      ),
    );
  }

  Widget _buildComputerCard(Computer computer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showComputerDetails(computer),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
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
                        computer.computerNumber.toString(),
                        style: const TextStyle(
                          fontSize: 18,
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
                          'PC ${computer.computerNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Laboratorio ${computer.labName}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, computer),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildComponentSummary(computer),
              if (computer.notes != null && computer.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, color: AppColors.primaryBlue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          computer.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textDark,
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
      ),
    );
  }

  Widget _buildComponentSummary(Computer computer) {
    return Column(
      children: [
        _buildComponentRow('CPU', computer.cpu, Icons.memory),
        const SizedBox(height: 8),
        _buildComponentRow('Monitor', computer.monitor, Icons.monitor),
        const SizedBox(height: 8),
        _buildComponentRow('Mouse', computer.mouse, Icons.mouse),
        const SizedBox(height: 8),
        _buildComponentRow('Teclado', computer.keyboard, Icons.keyboard),
      ],
    );
  }

  Widget _buildComponentRow(String title, ComputerComponent component, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
        ),
        Expanded(
          child: Text(
            '${component.brand} ${component.model}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          'S/N: ${component.serialNumber}',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textLight,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  bool _matchesSearch(Computer computer) {
    if (_searchQuery.isEmpty) return true;

    final searchTerms = [
      computer.computerNumber.toString(),
      computer.cpu.brand,
      computer.cpu.model,
      computer.cpu.serialNumber,
      computer.monitor.brand,
      computer.monitor.model,
      computer.monitor.serialNumber,
      computer.mouse.brand,
      computer.mouse.model,
      computer.mouse.serialNumber,
      computer.keyboard.brand,
      computer.keyboard.model,
      computer.keyboard.serialNumber,
      computer.notes ?? '',
    ];

    return searchTerms.any((term) => 
        term.toLowerCase().contains(_searchQuery));
  }

  Future<void> _navigateToAddComputer([Computer? computer]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddComputerScreen(
          labName: widget.labName,
          computer: computer,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _handleMenuAction(String action, Computer computer) {
    switch (action) {
      case 'edit':
        _navigateToAddComputer(computer);
        break;
      case 'delete':
        _showDeleteConfirmation(computer);
        break;
    }
  }

  void _showDeleteConfirmation(Computer computer) {
    CustomModal.showConfirmation(
      context,
      type: ModalType.warning,
      title: 'Eliminar Computadora',
      message: '¿Estás seguro de que deseas eliminar la PC ${computer.computerNumber}? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      onConfirm: () => _deleteComputer(computer),
    );
  }

  Future<void> _deleteComputer(Computer computer) async {
    setState(() => _isLoading = true);

    try {
      await _computerService.deleteComputer(computer.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PC ${computer.computerNumber} eliminada exitosamente'),
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
          message: 'No se pudo eliminar la computadora: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showComputerDetails(Computer computer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildComputerDetailsModal(computer),
    );
  }

  Widget _buildComputerDetailsModal(Computer computer) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      computer.computerNumber.toString(),
                      style: const TextStyle(
                        fontSize: 20,
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
                        'PC ${computer.computerNumber}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        'Laboratorio ${computer.labName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildDetailedComponentCard('CPU', computer.cpu, Icons.memory),
                const SizedBox(height: 16),
                _buildDetailedComponentCard('Monitor', computer.monitor, Icons.monitor),
                const SizedBox(height: 16),
                _buildDetailedComponentCard('Mouse', computer.mouse, Icons.mouse),
                const SizedBox(height: 16),
                _buildDetailedComponentCard('Teclado', computer.keyboard, Icons.keyboard),
                if (computer.notes != null && computer.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(computer.notes!),
                ],
                const SizedBox(height: 16),
                _buildMetadataCard(computer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedComponentCard(String title, ComputerComponent component, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Marca', component.brand),
          _buildDetailRow('Modelo', component.model),
          _buildDetailRow('Número de Serie', component.serialNumber),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.skyBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.skyBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Notas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataCard(Computer computer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Sistema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Registrado', _formatDate(computer.createdAt)),
          if (computer.lastUpdated != null)
            _buildDetailRow('Última actualización', _formatDate(computer.lastUpdated!)),
          _buildDetailRow('Estado', computer.isActive ? 'Activo' : 'Inactivo'),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}