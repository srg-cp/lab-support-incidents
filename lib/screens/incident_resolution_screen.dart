import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/colors.dart';
import '../models/incident_model.dart';
import '../widgets/custom_modal.dart';
import '../widgets/image_viewer.dart';

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
    
    // Simular asignación
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isSubmitting = false);
    
    if (mounted) {
      CustomModal.show(
        context,
        type: ModalType.success,
        title: 'Incidente Tomado',
        message: 'El incidente ha sido asignado a ti. Puedes proceder a resolverlo.',
      );
    }
  }

  Future<void> _resolveIncident(IncidentStatus newStatus) async {
    if (newStatus == IncidentStatus.resolved && _resolutionMedia == null) {
      CustomModal.show(
        context,
        type: ModalType.warning,
        title: 'Evidencia Requerida',
        message: 'Debes adjuntar una foto o video como evidencia de la resolución.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Simular guardado en Firebase
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isSubmitting = false);
    
    if (mounted) {
      String message = '';
      switch (newStatus) {
        case IncidentStatus.resolved:
          message = 'El incidente ha sido marcado como resuelto exitosamente.';
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
                    const SizedBox(height: 16),
                    Text(
                      'Lab ${widget.incident.labName} - PC: ${widget.incident.computerNumbers.join(", ")}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.error_outline, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 8),
                        Text(
                          widget.incident.type,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: AppColors.textLight),
                        const SizedBox(width: 8),
                        Text(
                          'Reportado por: ${widget.incident.reportedBy}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    if (widget.incident.assignedTo != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.assignment_ind, size: 16, color: AppColors.textLight),
                          const SizedBox(width: 8),
                          Text(
                            'Asignado a: ${widget.incident.assignedTo}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _resolveIncident(IncidentStatus.inProgress),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.warning),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'En Espera',
                          style: TextStyle(color: AppColors.warning),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _resolveIncident(IncidentStatus.resolved),
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
                            : const Text('Resuelto'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}