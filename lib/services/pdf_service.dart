import 'dart:io';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../models/incident_model.dart';
import '../models/computer_model.dart';

class PdfService {
  static const String _organizationName = 'Universidad Privada de Tacna';
  static const String _departmentName = 'Departamento de Sistemas';
  
  /// Genera un PDF de reporte de incidente resuelto
  static Future<File> generateIncidentResolutionReport({
    required Incident incident,
    required Computer? computer,
    required String supportUserName,
  }) async {
    final pdf = pw.Document();
    
    // Procesar imagen de evidencia si existe
    pw.ImageProvider? evidenceImage;
    if (incident.resolutionImage != null && incident.resolutionImage!.isNotEmpty) {
      try {
        final imageBytes = base64Decode(incident.resolutionImage!);
        final decodedImage = img.decodeImage(imageBytes);
        if (decodedImage != null) {
          // Redimensionar imagen si es muy grande
          final resizedImage = img.copyResize(decodedImage, width: 400);
          final resizedBytes = img.encodePng(resizedImage);
          evidenceImage = pw.MemoryImage(resizedBytes);
        }
      } catch (e) {
        print('Error procesando imagen: $e');
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Encabezado
            _buildHeader(),
            pw.SizedBox(height: 30),
            
            // Título del documento
            _buildTitle(),
            pw.SizedBox(height: 20),
            
            // Información del incidente
            _buildIncidentInfo(incident, supportUserName),
            pw.SizedBox(height: 20),
            
            // Descripción del problema y resolución
            _buildProblemDescription(incident),
            pw.SizedBox(height: 20),
            
            // Detalles del equipo
            if (computer != null) ...[
              _buildEquipmentDetails(computer, incident),
              pw.SizedBox(height: 20),
            ],
            
            // Imagen de evidencia de resolución
            if (evidenceImage != null) ...[
              _buildResolutionEvidence(evidenceImage),
              pw.SizedBox(height: 20),
            ],
            
            // Pie de página con firmas
            _buildFooter(supportUserName, incident),
          ];
        },
      ),
    );

    // Guardar el archivo
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'reporte_incidente_${incident.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            _organizationName,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _departmentName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 2,
            width: double.infinity,
            color: PdfColors.blue900,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTitle() {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'REPORTE DE RESOLUCIÓN DE INCIDENCIA',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'LABORATORIO DE CÓMPUTO',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildIncidentInfo(Incident incident, String supportUserName) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL INCIDENTE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              _buildTableRow('ID del Incidente:', incident.id),
              _buildTableRow('Fecha de Reporte:', DateFormat.yMd().add_jm().format(incident.reportedAt)),
              _buildTableRow('Fecha de Resolución:', 
              incident.resolvedAt != null 
                ? DateFormat.yMd().add_jm().format(incident.resolvedAt!)
                : 'No resuelto'),
              _buildTableRow('Reportado por:', incident.reportedBy),
              _buildTableRow('Resuelto por:', supportUserName),
              _buildTableRow('Laboratorio:', incident.labName),
              _buildTableRow('Tipo de Incidencia:', incident.type),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProblemDescription(Incident incident) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DESCRIPCIÓN DE LA INCIDENCIA',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Por medio del presente, me permito informar la incidencia presentada en el ${incident.labName} respecto a un equipo de cómputo. ${incident.description ?? 'Sin descripción adicional.'}',
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.justify,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'RESOLUCIÓN APLICADA',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              incident.resolutionNotes ?? 'Sin notas de resolución.',
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEquipmentDetails(Computer computer, Incident incident) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LOS DETALLES SE CONSIGNAN A CONTINUACIÓN',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'DETALLES DEL EQUIPO AFECTADO',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              _buildTableRow('Tipo de Equipo:', computer.equipmentTypeDisplayName),
              _buildTableRow('Número de Equipo:', 'PC ${computer.computerNumber}'),
              _buildTableRow('Laboratorio:', computer.labName),
              _buildTableRow('Números de PC Afectados:', incident.computerNumbers.join(', ')),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'ESPECIFICACIONES TÉCNICAS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Componente', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Marca', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Modelo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Número de Serie', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              _buildComponentRow('CPU', computer.cpu),
              _buildComponentRow('Monitor', computer.monitor),
              _buildComponentRow('Mouse', computer.mouse),
              _buildComponentRow('Teclado', computer.keyboard),
              if (computer.projector != null)
                _buildComponentRow('Proyector', computer.projector!),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildResolutionEvidence(pw.ImageProvider imageProvider) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'EVIDENCIA FOTOGRÁFICA DE LA RESOLUCIÓN',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            width: double.infinity,
            child: pw.Center(
              child: pw.Container(
                width: 400,
                height: 300,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Image(
                  imageProvider,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(String supportUserName, Incident incident) {
    return pw.Container(
      child: pw.Column(
        children: [
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    width: 200,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    supportUserName,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Personal de Soporte Técnico'),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(
                    width: 200,
                    height: 1,
                    color: PdfColors.black,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    incident.reportedBy,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Usuario Reportante'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Container(
            width: double.infinity,
            child: pw.Center(
              child: pw.Text(
                'Fecha de generación del reporte: ${DateFormat.yMd().add_jm().format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  static pw.TableRow _buildComponentRow(String componentName, ComputerComponent component) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(componentName),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(component.brand.isNotEmpty ? component.brand : 'N/A'),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(component.model.isNotEmpty ? component.model : 'N/A'),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(component.serialNumber.isNotEmpty ? component.serialNumber : 'N/A'),
        ),
      ],
    );
  }
}