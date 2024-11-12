import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:printing/printing.dart';

class PDFPreviewScreen extends StatelessWidget {
  final Uint8List pdfData;
  final String fileName;
  final String referencia;

  PDFPreviewScreen({required this.pdfData, required this.fileName, required this.referencia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Vista Previa del PDF',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: PdfPreview(
        build: (format) async {
          final modifiedPdfData = await _addReferenciaToPdf(pdfData, referencia);
          return modifiedPdfData;
        },
        pdfFileName: fileName,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }

  Future<Uint8List> _addReferenciaToPdf(Uint8List pdfData, String referencia) async {
    return pdfData;
  }
}
