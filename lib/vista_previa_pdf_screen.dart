import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class VistaPreviaPDFScreen extends StatefulWidget {
  final Uint8List pdfData;

  VistaPreviaPDFScreen({required this.pdfData});

  @override
  _VistaPreviaPDFScreenState createState() => _VistaPreviaPDFScreenState();
}

class _VistaPreviaPDFScreenState extends State<VistaPreviaPDFScreen> {
  String? pdfPath;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  Future<void> _loadPDF() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/temp_preview.pdf');
    await file.writeAsBytes(widget.pdfData);
    setState(() {
      pdfPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1A5DD9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Vista Previa',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: pdfPath != null
          ? PDFView(
        filePath: pdfPath!,
        onError: (error) {
          print("Error al cargar PDF: $error");
        },
        onRender: (_pages) {
          setState(() {});
        },
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
