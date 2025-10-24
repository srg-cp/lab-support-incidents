import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/file_handler_service.dart';
import '../utils/colors.dart';

class PdfReportsScreen extends StatefulWidget {
  const PdfReportsScreen({Key? key}) : super(key: key);

  @override
  State<PdfReportsScreen> createState() => _PdfReportsScreenState();
}

class _PdfReportsScreenState extends State<PdfReportsScreen> {
  List<File> _pdfFiles = [];
  List<Map<String, dynamic>> _pdfInfoList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdfReports();
  }

  Future<void> _loadPdfReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pdfFiles = await FileHandlerService.getIncidentReportPdfs();
      final pdfInfoList = <Map<String, dynamic>>[];

      for (final file in pdfFiles) {
        final info = await FileHandlerService.getPdfInfo(file);
        pdfInfoList.add(info);
      }

      if (mounted) {
        setState(() {
          _pdfFiles = pdfFiles;
          _pdfInfoList = pdfInfoList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando reportes: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePdf(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el reporte "${_pdfInfoList[index]['fileName']}"?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await FileHandlerService.deletePdf(_pdfInfoList[index]['filePath']);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reporte eliminado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        await _loadPdfReports(); // Recargar la lista
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al eliminar el reporte'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadPdf(int index) async {
    final pdfInfo = _pdfInfoList[index];
    final filePath = pdfInfo['filePath'] as String;
    final fileName = pdfInfo['fileName'] as String;

    try {
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
                Text('Descargando archivo...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Copiar archivo a la carpeta de descargas
      final downloadPath = await FileHandlerService.copyToDownloads(filePath, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              downloadPath != filePath 
                ? 'Archivo descargado en: Downloads/$fileName'
                : 'Archivo disponible en: $fileName'
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () => _openPdf(index),
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

  Future<void> _openPdf(int index) async {
    final pdfInfo = _pdfInfoList[index];
    final filePath = pdfInfo['filePath'] as String;

    try {
      final success = await FileHandlerService.openPdf(filePath);
      
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

  Future<void> _sharePdf(int index) async {
    final pdfInfo = _pdfInfoList[index];
    final filePath = pdfInfo['filePath'] as String;
    final fileName = pdfInfo['fileName'] as String;

    try {
      final success = await FileHandlerService.sharePdf(filePath, fileName);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir el archivo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Reportes PDF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadPdfReports,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando reportes...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPdfReports,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_pdfFiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            SizedBox(height: 16),
            Text(
              'No hay reportes PDF disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textLight,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Los reportes se generan automáticamente cuando se resuelven incidentes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPdfReports,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pdfInfoList.length,
        itemBuilder: (context, index) => _buildPdfCard(index),
      ),
    );
  }

  Widget _buildPdfCard(int index) {
    final pdfInfo = _pdfInfoList[index];
    final lastModified = pdfInfo['lastModified'] as DateTime;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(lastModified);
    final fileSize = FileHandlerService.formatFileSize(pdfInfo['size']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pdfInfo['fileName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (pdfInfo['incidentId'] != null)
                        Text(
                          'ID Incidente: ${pdfInfo['incidentId']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'download':
                        _downloadPdf(index);
                        break;
                      case 'open':
                        _openPdf(index);
                        break;
                      case 'share':
                        _sharePdf(index);
                        break;
                      case 'delete':
                        _deletePdf(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, color: AppColors.primaryBlue, size: 20),
                          SizedBox(width: 8),
                          Text('Descargar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.open_in_new, color: AppColors.primaryBlue, size: 20),
                          SizedBox(width: 8),
                          Text('Abrir'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, color: AppColors.textLight, size: 20),
                          SizedBox(width: 8),
                          Text('Compartir'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.storage,
                  size: 16,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  fileSize,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadPdf(index),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Descargar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openPdf(index),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Abrir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _sharePdf(index),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Compartir'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}