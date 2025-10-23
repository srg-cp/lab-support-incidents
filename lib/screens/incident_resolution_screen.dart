import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../utils/colors.dart';
import '../models/incident_model.dart';
import '../widgets/custom_modal.dart';
import '../widgets/image_viewer.dart';
import '../providers/incident_provider.dart';

class IncidentResolutionScreen extends StatefulWidget {
  final Incident incident;

  const IncidentResolutionScreen({Key? key, required this.incident}) : super(key: key);

  @override
  State<IncidentResolutionScreen> createState() => _IncidentResolutionScreenState();
}

class _IncidentResolutionScreenState extends State<IncidentResolutionScreen> {
  File? _resolutionMedia;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _resolutionMedia = File(pickedFile.path);
      });
    }
  }

  void _showMediaOptions() {
    // No permitir agregar evidencia si el incidente ya está resuelto
    if (widget.incident.status == IncidentStatus.resolved) {
      _showIncidentResolvedMessage();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Agregar Evidencia de Resolución',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
              ),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
              ),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickMedia(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takeIncident() async {
    setState(() => _isSubmitting = true);
    
    try {
      final provider = Provider.of<IncidentProvider>(context, listen: false);
      final success = await provider.takeIncident(widget.incident.id);
      
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        if (success) {
          CustomModal.show(
            context,
            type: ModalType.success,
            title: 'Incidente Tomado',
            message: 'El incidente ha sido asignado a ti. Puedes proceder a resolverlo.',
          );
        } else {
          CustomModal.show(
            context,
            type: ModalType.warning,
            title: 'Error',
            message: provider.error ?? 'Error al tomar el incidente',
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.danger,
          title: 'Error',
          message: 'Error inesperado: $e',
        );
      }
    }
  }

  void _showCancelConfirmation() {
    CustomModal.showConfirmation(
      context,
      type: ModalType.warning,
      title: 'Confirmar Cancelación',
      message: 'Esta acción cancelará el incidente y lo devolverá al estado pendiente para que otro técnico de soporte pueda tomarlo.\n\n¿Estás seguro de que deseas cancelar este incidente?',
      confirmText: 'Sí',
      cancelText: 'No, Mantener',
      onConfirm: () => _resolveIncident(IncidentStatus.cancelled),
    );
  }

  void _showResolveConfirmation() {
    if (_resolutionMedia == null) {
      CustomModal.show(
        context,
        type: ModalType.warning,
        title: 'Evidencia Requerida',
        message: 'Debes adjuntar una foto o video como evidencia de la resolución.',
      );
      return;
    }

    CustomModal.showConfirmation(
      context,
      type: ModalType.warning,
      title: 'Confirmar Resolución',
      message: 'Una vez marcado como resuelto, este incidente no podrá ser modificado por nadie.\n\n¿Estás seguro de que deseas marcar este incidente como resuelto?',
      confirmText: 'Sí, Resolver',
      cancelText: 'Cancelar',
      onConfirm: () => _resolveIncident(IncidentStatus.resolved),
    );
  }

  void _showIncidentResolvedMessage() {
    CustomModal.show(
      context,
      type: ModalType.info,
      title: 'Incidente Resuelto',
      message: 'Este incidente ya ha sido resuelto y no puede ser modificado.',
    );
  }

  Future<void> _resolveIncident(IncidentStatus newStatus) async {
    // Verificar si el incidente ya está resuelto
    if (widget.incident.status == IncidentStatus.resolved) {
      _showIncidentResolvedMessage();
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final provider = Provider.of<IncidentProvider>(context, listen: false);
      
      String statusString = '';
      switch (newStatus) {
        case IncidentStatus.resolved:
          statusString = 'resolved';
          break;
        case IncidentStatus.cancelled:
          statusString = 'cancelled';
          break;
        case IncidentStatus.onHold:
          statusString = 'onHold';
          break;
        case IncidentStatus.inProgress:
          statusString = 'inProgress';
          break;
        case IncidentStatus.pending:
          statusString = 'pending';
          break;
      }
      
      final success = await provider.resolveIncident(
        incidentId: widget.incident.id,
        status: statusString,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        resolutionFile: _resolutionMedia,
      );
      
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        if (success) {
          String message = '';
          switch (newStatus) {
            case IncidentStatus.resolved:
              message = 'El incidente ha sido marcado como resuelto exitosamente.';
              break;
            case IncidentStatus.cancelled:
              message = 'El incidente ha sido cancelado y devuelto al estado pendiente para que otro técnico pueda tomarlo.';
              break;
            case IncidentStatus.onHold:
              message = 'El incidente ha sido puesto en espera.';
              break;
            case IncidentStatus.inProgress:
              message = 'El estado del incidente ha sido actualizado.';
              break;
            case IncidentStatus.pending:
              message = 'El incidente ha sido devuelto a estado pendiente.';
              break;
          }
          
          CustomModal.show(
            context,
            type: ModalType.success,
            title: 'Actualizado',
            message: message,
            onConfirm: () {
              Navigator.of(context).pop();
            },
          );
        } else {
          CustomModal.show(
            context,
            type: ModalType.warning,
            title: 'Error',
            message: provider.error ?? 'Error al actualizar el incidente',
          );
        }
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        CustomModal.show(
          context,
          type: ModalType.danger,
          title: 'Error',
          message: 'Error inesperado: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Incidente'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del incidente
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.lightBlue.withOpacity(0.2)),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: widget.incident.getStatusColor(),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.incident.getStatusText(),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.incident.getTimeAgo(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Título principal
                    Text(
                      'Lab ${widget.incident.labName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PC: ${widget.incident.computerNumbers.join(", ")}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.lightBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Información organizada en tarjetas
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.error_outline, 'Tipo de problema', widget.incident.type),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.person, 'Reportado por', widget.incident.reportedBy),
                          if (widget.incident.assignedTo != null) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.assignment_ind, 'Asignado a', widget.incident.assignedTo!.name),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Mostrar imagen de evidencia si existe
              if (widget.incident.evidenceImage != null) ...[
                const Text(
                  'Evidencia del Incidente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ImageViewer(
                  imageBase64: widget.incident.evidenceImage,
                ),
                const SizedBox(height: 24),
              ],
              
              // Mostrar descripción si existe
              if (widget.incident.description != null && widget.incident.description!.isNotEmpty) ...[
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
                  ),
                  child: Text(
                    widget.incident.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Botón tomar incidente (solo si está pendiente)
              if (widget.incident.status == IncidentStatus.pending) ...[
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _takeIncident,
                  icon: const Icon(Icons.pan_tool),
                  label: const Text('Tomar Incidente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightBlue,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Sección de resolución
              if (widget.incident.status != IncidentStatus.pending) ...[
                const Text(
                  'Resolución',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Mostrar imagen de resolución existente si existe
                if (widget.incident.resolutionImage != null) ...[
                  const Text(
                    'Evidencia de Resolución',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ImageViewer(
                    imageBase64: widget.incident.resolutionImage,
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Mostrar notas de resolución existentes si existen
                if (widget.incident.resolutionNotes != null && widget.incident.resolutionNotes!.isNotEmpty) ...[
                  const Text(
                    'Notas de Resolución',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
                    ),
                    child: Text(
                      widget.incident.resolutionNotes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Solo mostrar opciones de modificación si el incidente NO está resuelto
                if (widget.incident.status != IncidentStatus.resolved) ...[
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Notas sobre la resolución...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_resolutionMedia != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _resolutionMedia!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _resolutionMedia = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: AppColors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: _showMediaOptions,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.lightGray,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.lightBlue.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agregar evidencia',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _resolveIncident(IncidentStatus.onHold),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.orange),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'En Espera',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : _showCancelConfirmation,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Cancelar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : _showResolveConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : const Text('Marcar como Resuelto'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Mensaje para incidentes ya resueltos
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Este incidente ha sido resuelto y no puede ser modificado.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.lightBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}