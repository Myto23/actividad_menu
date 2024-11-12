import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AnulacionDocumentoScreen extends StatelessWidget {
  final int folio;
  final Uint8List pdfData;
  final TextEditingController motivoController = TextEditingController();
  String fechaEmision = DateFormat('dd-MM-yyyy').format(DateTime.now());

  AnulacionDocumentoScreen({required this.folio, required this.pdfData});

  Future<pw.Font> loadRobotoFont() async {
    return await PdfGoogleFonts.robotoRegular();
  }

  Future<pw.Font> loadRobotoBoldFont() async {
    return await PdfGoogleFonts.robotoBold();
  }

  String formatCurrency(double value) {
    final format = NumberFormat.currency(locale: 'es_ES', symbol: '\$');
    return format.format(value);
  }

  void _previewPDF(BuildContext context) async {
    if (motivoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El motivo de anulación es obligatorio')),
      );
      return;
    }

    final modifiedPdfData = await _generateAnulacionPDF(motivoController.text, folio, fechaEmision);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFPreviewScreen(
          pdfData: modifiedPdfData,
          fileName: 'boleta_anulada_$folio.pdf',
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Folio N° $folio ha sido ingresado al Libro de Ventas del período',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF1A5DD9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Icon(Icons.check_circle, color: Colors.green, size: 50),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _previewPDF(context),
                    icon: Icon(Icons.search, color: Colors.white),
                    label: Text('Ver PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A5DD9),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                    },
                    icon: Icon(Icons.share, color: Colors.white),
                    label: Text('Compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1A5DD9),
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Aceptar', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Future<Uint8List> _generateAnulacionPDF(String motivoAnulacion, int folio, String fechaEmision) async {
    final pdf = pw.Document();
    final robotoFont = await loadRobotoFont();
    final robotoBoldFont = await loadRobotoBoldFont();

    double montoTotal = 1000;
    double iva = montoTotal * 0.19;

    pdf.addPage(
      pw.Page(
        margin: pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'SERVICIOS Y TECNOLOGIA\nIMPORTACION Y EXPORTACION DE SOFTWARE, SUMINISTROS Y COMPUTADORES',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: robotoBoldFont),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'GRAN AVENIDA 5018, Depto. 208\nSAN MIGUEL - SANTIAGO\nFono: (56-2) 550 552 51\nSAN MIGUEL-GRAN AVENIDA - M',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, font: robotoFont),
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red, width: 1),
                  ),
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('R.U.T.: 77.574.330-1', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: robotoBoldFont)),
                      pw.Text('BOLETA ELECTRONICA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: robotoBoldFont)),
                      pw.Text('N° $folio', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: robotoBoldFont)),
                      pw.Text('S.I.I. - SANTIAGO SUR', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: robotoBoldFont)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('COD. Cliente: APP_FACTURACION', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                  pw.Text('Santiago, $fechaEmision', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: ['Item', 'Código', 'Descripción', 'U.M', 'Cantidad', 'Precio Unit.', 'Valor Exento', 'Valor'],
                data: [
                  ['1', '001', 'Producto Ejemplo', 'UN', '1', formatCurrency(100), '0', formatCurrency(100)],
                  ...List.generate(35, (index) => List.filled(8, '')),
                ],
                cellAlignment: pw.Alignment.center,
                cellStyle: pw.TextStyle(fontSize: 12, font: robotoFont),
                headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: robotoBoldFont, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.black,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
                border: pw.TableBorder.symmetric(
                  outside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Container(
                          height: 80,
                          color: PdfColors.black,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Timbre Electrónico S.I.I.\nResolución Nro. 80 del 22-08-2014\nVerifique Documento: http://www.facturacion.cl/desisw/boleta',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 8, font: robotoFont),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('IVA:', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$ ${iva.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL :', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$ ${montoTotal.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Monto no fact:', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$ 0', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.Divider(thickness: 0.5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Valor a pagar:', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$ 0', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 0.5),
                          ),
                          child: pw.Text('Observaciones: $motivoAnulacion en BOLETA ELECTRONICA: Nro. $folio ($fechaEmision)', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Desarrollado por www.facturacion.cl',
                style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, font: robotoFont),
                textAlign: pw.TextAlign.left,
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Anulación de documento', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1A5DD9),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mediante esta opción emitirá una Nota de Crédito, anulando el documento seleccionado',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: fechaEmision,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Fecha Emisión',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.blue[50],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.calendar_today, color: Colors.blue),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      fechaEmision = DateFormat('dd-MM-yyyy').format(pickedDate);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo de anulación',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.blue[50],
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _previewPDF(context),
              icon: Icon(Icons.search, color: Colors.white),
              label: Text('Vista Previa', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A5DD9),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (motivoController.text.isNotEmpty) {
                  _showSuccessDialog(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('El motivo de anulación es obligatorio')),
                  );
                }
              },
              child: Text('Emitir', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

          ],
        ),
      ),
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
        title: Text('Vista Previa del PDF'),
        backgroundColor: Color(0xFF1A5DD9),
      ),
      body: PdfPreview(
        build: (format) async => pdfData,
        pdfFileName: fileName,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
