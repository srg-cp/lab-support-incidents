import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../utils/colors.dart';
import '../utils/equipment_formatter.dart';
import '../models/incident_model.dart';
import '../widgets/custom_modal.dart';
import '../widgets/image_viewer.dart';
import '../providers/incident_provider.dart';
import '../services/auth_service.dart';
import '../services/file_handler_service.dart';

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
  final AuthService _authService = AuthService();
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
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
          // Determinar el tipo de modal según el tipo de error
          final modalType = provider.errorType == 'warning' ? ModalType.warning : ModalType.danger;
          final title = provider.errorType == 'warning' ? 'Límite Alcanzado' : 'Error';
          
          CustomModal.show(
            context,
            type: modalType,
            title: title,
            message: provider.error ?? 'Error al tomar el incidente',
            onConfirm: () {
              // Limpiar el error después de mostrar el modal
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.clearError();
              });
            },
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

  void _showPdfGeneratedModal(File pdfFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Incidente Resuelto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El incidente ha sido resuelto exitosamente.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reporte PDF Generado',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        Text(
                          'Se ha creado automáticamente un reporte del incidente',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¿Qué deseas hacer con el reporte?',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _downloadGeneratedPdf(pdfFile);
                    if (mounted) {
                      Navigator.of(context).pop(); // Cerrar pantalla de resolución
                    }
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Descargar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    side: const BorderSide(color: AppColors.primaryBlue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _openGeneratedPdf(pdfFile);
                    if (mounted) {
                      Navigator.of(context).pop(); // Cerrar pantalla de resolución
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Abrir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Cerrar pantalla de resolución
              },
              child: const Text('Continuar sin descargar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadGeneratedPdf(File pdfFile) async {
    try {
      final fileName = pdfFile.path.split(Platform.pathSeparator).last;
      
      // Mostrar indicador de carga
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 16),
                Text('Descargando reporte...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Copiar archivo a la carpeta de descargas
      final downloadPath = await FileHandlerService.copyToDownloads(pdfFile.path, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              downloadPath != pdfFile.path 
                ? 'Reporte descargado en: Downloads/$fileName'
                : 'Reporte disponible: $fileName'
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () => _openGeneratedPdf(pdfFile),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openGeneratedPdf(File pdfFile) async {
    try {
      final success = await FileHandlerService.openPdf(pdfFile.path);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el archivo. Intenta descargarlo primero.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir archivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      
      final result = await provider.resolveIncident(
        incidentId: widget.incident.id,
        status: statusString,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        resolutionFile: _resolutionMedia,
      );
      
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        if (result['success'] == true) {
          String message = '';
          switch (newStatus) {
            case IncidentStatus.resolved:
              message = result['pdfFile'] != null 
                  ? 'El incidente ha sido marcado como resuelto exitosamente.\n\n📄 Se ha generado automáticamente un reporte PDF que se encuentra guardado en la carpeta de documentos de la aplicación.'
                  : 'El incidente ha sido marcado como resuelto exitosamente.';
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
          
          // Mostrar modal con opciones de descarga si se generó PDF
          if (newStatus == IncidentStatus.resolved && result['pdfFile'] != null) {
            _showPdfGeneratedModal(result['pdfFile'] as File);
          } else {
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
                      'Equipos: ${EquipmentFormatter.formatEquipmentNumbers(widget.incident.computerNumbers)}',
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
              
              // Botón tomar incidente (solo si está pendiente y el usuario es de soporte)
              if (widget.incident.status == IncidentStatus.pending && _userRole == 'support') ...[
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
              
              // Sección de resolución (solo para personal de soporte)
              if (widget.incident.status != IncidentStatus.pending && _userRole == 'support') ...[
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
              
              // Sección de solo lectura para administradores
              if (widget.incident.status != IncidentStatus.pending && _userRole == 'admin') ...[
                const Text(
                  'Información del Incidente',
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
                
                // Mensaje informativo para administradores
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.lightBlue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Como administrador, puedes visualizar la información del incidente pero no realizar acciones sobre él. Solo el personal de soporte puede tomar y resolver incidentes.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.lightBlue,
                            fontWeight: FontWeight.w500,
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