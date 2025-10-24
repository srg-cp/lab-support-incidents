import 'package:flutter/material.dart';
import '../models/incident_model.dart';
import '../utils/colors.dart';
import '../services/file_handler_service.dart';

class IncidentCard extends StatefulWidget {
  final Incident incident;
  final VoidCallback? onTap;
  final bool showTakeButton;
  final VoidCallback? onTake;
  final bool showDownloadButton;

  const IncidentCard({
    Key? key,
    required this.incident,
    this.onTap,
    this.showTakeButton = false,
    this.onTake,
    this.showDownloadButton = true,
  }) : super(key: key);

  @override
  State<IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<IncidentCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                // Mostrar ícono de descarga para incidentes resueltos
                if (widget.showDownloadButton && widget.incident.status == IncidentStatus.resolved) ...[
                  GestureDetector(
                    onTap: () => _downloadIncidentPdf(widget.incident),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.download,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.incident.getTimeAgo(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Lab ${widget.incident.labName} - PC: ${widget.incident.computerNumbers.join(", ")}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.incident.type,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reportado por: ${widget.incident.reportedBy}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.incident.assignedTo != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_ind,
                          size: 16,
                          color: AppColors.lightBlue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Asignado a: ${widget.incident.assignedTo!.name}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.lightBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (widget.showTakeButton || widget.onTap != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.showTakeButton && widget.onTake != null)
                    ElevatedButton.icon(
                      onPressed: widget.onTake,
                      icon: const Icon(Icons.assignment_ind, size: 16),
                      label: const Text('Tomar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  if (widget.onTap != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver detalles',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.accentGold,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadIncidentPdf(Incident incident) async {
    try {
      // Buscar el PDF correspondiente al incidente
      final pdfFiles = await FileHandlerService.getIncidentReportPdfs();
      
      // Buscar el archivo que corresponde a este incidente
      final matchingPdf = pdfFiles.where((file) {
        final fileName = file.path.split('/').last;
        return fileName.contains('reporte_incidente_${incident.id}_');
      }).toList();

      if (matchingPdf.isEmpty) {
        // No se encontró el PDF
        _showMessage('No se encontró el reporte PDF para este incidente', isError: true);
        return;
      }

      final pdfFile = matchingPdf.first;
      final fileName = pdfFile.path.split('/').last;

      // Copiar archivo a la carpeta de descargas
      final downloadPath = await FileHandlerService.copyToDownloads(pdfFile.path, fileName);
      
      _showMessage(
        downloadPath != pdfFile.path 
          ? 'Reporte descargado en: Downloads/$fileName'
          : 'Reporte disponible: $fileName',
        isError: false
      );

    } catch (e) {
      _showMessage('Error al descargar el reporte: $e', isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    // Buscar el contexto más cercano para mostrar el SnackBar
    final context = this.context;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : AppColors.success,
          duration: Duration(seconds: isError ? 4 : 3),
        ),
      );
    }
  }
}