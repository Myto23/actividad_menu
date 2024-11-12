import 'package:actividad_menu/anulacion_documento_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:typed_data'; // Asegúrate de incluir esta importación
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class DetalleVentaScreen extends StatelessWidget {
  final Map<String, dynamic> boleta;

  DetalleVentaScreen({required this.boleta});

  String formatCurrency(double value) {
    final currencyFormat = NumberFormat('#,##0', 'es_ES');
    return currencyFormat.format(value);
  }

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  String formatRut(String? rut) {
    if (rut == null) return 'RUT no disponible';
    final formattedRut = rut.replaceAllMapped(RegExp(r'(\d{7})(\d{1})'), (match) {
      return '${match[1]}-${match[2]}';
    });
    return formattedRut;
  }

  String getCurrentPeriod() {
    final now = DateTime.now();
    final format = DateFormat('MM-yyyy');
    return format.format(now);
  }

  Future<void> _openPDF(BuildContext context, int folio) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfPath = '${directory.path}/boletas_emitidas/boleta_$folio.pdf';
      final pdfFile = File(pdfPath);

      print('Intentando abrir el PDF desde la ruta: $pdfPath');

      if (await pdfFile.exists()) {
        Uint8List pdfData = await pdfFile.readAsBytes(); // Asegúrate que esto devuelve Uint8List correctamente

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFPreviewScreen(pdfData: pdfData, fileName: 'boleta_$folio.pdf'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("El archivo PDF para el folio $folio no existe.")),
        );
      }
    } catch (e) {
      print('Error al abrir el PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al abrir el PDF: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final folio = boleta['folio'] ?? 'Folio no disponible';
    final rut = boleta['rut'] ?? 'RUT no disponible';
    final total = boleta['total'] ?? 0.0;
    final date = boleta['date'] ?? DateTime.now().toString();
    final branch = boleta['branch'] ?? 'NO DISPONIBLE';
    final user = boleta['user'] ?? 'Usuario no disponible';

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Venta', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Cliente Boleta',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'BOLETA ELECTRONICA',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8),
            Table(
              columnWidths: {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2.5),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                _buildTableRow('Folio:', '$folio'),
                _buildTableRow('Rut:', formatRut(rut)),
                _buildTableRow('Monto Total:', '\$${formatCurrency(total)}'),
                _buildTableRow('Estado DTE en SII:', '📄 Enviado al SII', isHighlighted: true),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Periodo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 5),
            Table(
              columnWidths: {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2.5),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                _buildTableRow('Periodo Contable:', getCurrentPeriod()),
                _buildTableRow('Fecha documento:', formatDate(date)),
                _buildTableRow('Sucursal:', branch, addTopMargin: true),
                _buildTableRow('Usuario:', user),
                _buildTableRow('Fecha de Ingreso:', formatDate(date)),
              ],
            ),
            SizedBox(height: 70),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openPDF(context, folio),
                  icon: Icon(Icons.search, color: Colors.white),
                  label: Text('Ver PDF', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                /*
ElevatedButton(
  onPressed: () async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfPath = '${directory.path}/boletas_emitidas/boleta_$folio.pdf';
      final pdfFile = File(pdfPath);

      if (await pdfFile.exists()) {
        Uint8List pdfData = await pdfFile.readAsBytes();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnulacionDocumentoScreen(
              folio: folio,
              pdfData: pdfData,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("El archivo PDF para el folio $folio no existe.")),
        );
      }
    } catch (e) {
      print('Error al abrir el PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al abrir el PDF: ${e.toString()}")),
      );
    }
  },
  child: Text('Anular Documento', style: TextStyle(color: Colors.white)),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red,
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),
*/

              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String field, String value, {bool isHighlighted = false, bool addTopMargin = false}) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.only(top: addTopMargin ? 10.0 : 0.0),
          child: Text(
            field,
            style: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: addTopMargin ? 10.0 : 0.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isHighlighted ? Colors.orange : Colors.black,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PDFPreviewScreen extends StatelessWidget {
  final Uint8List pdfData;
  final String fileName;

  PDFPreviewScreen({required this.pdfData, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vista Previa del PDF',
          style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: PdfPreview(
        build: (format) async => pdfData,
        pdfFileName: fileName,
        canChangePageFormat: false,
        allowPrinting: false,
        allowSharing: false,
      ),
    );
  }
}
