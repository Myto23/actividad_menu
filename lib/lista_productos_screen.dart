import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:actividad_menu/boleta_express_screen.dart';
import 'package:actividad_menu/main.dart';
import 'package:actividad_menu/modificar_detalle_screen.dart';
import 'package:actividad_menu/rut_input_screen.dart';
import 'package:actividad_menu/send_email_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'globals.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class ListaProductosScreen extends StatefulWidget {
  ListaProductosScreen({Key? key}) : super(key: key);

  @override
  _ListaProductosScreenState createState() => _ListaProductosScreenState();
}

class _ListaProductosScreenState extends State<ListaProductosScreen> with RouteAware{
  bool _isEmailEnabled = false;
  bool _enviarPorCorreo = false;
  bool _isPlusButtonVisible = true;
  late PageController _pageController;
  final _rutController = TextEditingController();
  final _emailController = TextEditingController();
  double montoTotal = 0;
  int _currentPage = 0;


  bool _isValidRUT(String rut) {
    return true;
  }

  void _showConfirmationDialog(int folioActual) {
    final currentDate = DateTime.now();
    final formattedDate = '${currentDate.day}/${currentDate.month}/${currentDate.year}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Folio N° $folioActual ha sido\n ingresado al Libro de Ventas\n del período $formattedDate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              Icon(Icons.check_circle, size: 80, color: Colors.green),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  Uint8List pdfData = await _previewPDF();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(
                          title: Text('Vista Previa del PDF'),
                          backgroundColor: Color(0xFF1A5DD9),
                        ),
                        body: Center(
                          child: PdfPreview(
                            build: (format) => pdfData,
                            allowPrinting: true,
                            allowSharing: true,
                            canChangePageFormat: false,
                            pdfFileName: 'factura.pdf',
                          ),
                        ),
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.picture_as_pdf, color: Colors.white),
                label: Text('Ver PDF', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A5DD9),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  await _sharePDF();
                },
                icon: Icon(Icons.share, color: Colors.white),
                label: Text('Compartir', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A5DD9),
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainScreen(loggedInUserEmail: loggedInUserEmail ?? ''),
                    ),
                        (Route<dynamic> route) => false,
                  );
                },
                child: Text('Aceptar', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> saveBoletaInfo(int folio, String rut, double total) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userName = prefs.getString('userName') ?? 'Usuario Desconocido';

    List<String> boletas = prefs.getStringList('boletas_emitidas') ?? [];

    Map<String, dynamic> boletaData = {
      'folio': folio,
      'rut': rut,
      'total': total,
      'date': DateTime.now().toIso8601String(),
      'user': userName,
    };

    boletas.add(jsonEncode(boletaData));
    await prefs.setStringList('boletas_emitidas', boletas);
  }



  Future<void> _sharePDF() async {
    try {
      Uint8List pdfData = await _generatePDF();
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/factura_temporal.pdf';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(pdfData);
      final xFile = XFile(tempFile.path);
      await Share.shareXFiles([xFile], text: 'Aquí está el PDF de la factura.');
    } catch (e) {
      print('Error al compartir el PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al compartir el PDF")),
      );
    }
  }

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 0,
  );

  String formatCurrency(double value) {
    return currencyFormat.format(value).replaceAll(',', '.');
  }


  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _enviarPorCorreo = false;
  }

  Future<pw.Font> loadRobotoFont() async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  Future<pw.Font> loadRobotoBoldFont() async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    return pw.Font.ttf(fontData);
  }

  Future<Uint8List> _previewPDF() async {
    final pdf = pw.Document();
    final robotoFont = await loadRobotoFont();
    final robotoBoldFont = await loadRobotoBoldFont();

    double montoTotal = productosGlobal.fold(0, (sum, item) {
      return sum + (double.tryParse(item['valorTotal'].toString()) ?? 0);
    });
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
                      pw.Text('N° SIN FOLIO', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: robotoBoldFont)),
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
                  pw.Text('Santiago, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                ],
              ),
              pw.SizedBox(height: 12),

              pw.Container(
                width: double.infinity,
                child: pw.Table.fromTextArray(
                  headers: ['Item', 'Código', 'Descripción', 'U.M', 'Cantidad', 'Precio Unit.', 'Valor Exento', 'Valor'],
                  data: [
                    ...productosGlobal.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      var producto = entry.value;
                      return [
                        '$index',
                        producto['codigo'] ?? 'Sin código',
                        producto['descripcion'] ?? 'Producto sin descripción',
                        'UN',
                        producto['cantidad'].toString(),
                        formatCurrency(double.parse(producto['precioUnitario'].toString())),
                        '0',
                        formatCurrency(double.parse(producto['valorTotal'].toString())),
                      ];
                    }),
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
                            pw.Text('\$      ${iva.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL :', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$      ${montoTotal.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Monto no fact:', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$      0', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.Divider(thickness: 0.5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Valor a pagar:', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$      0', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 0.5),
                          ),
                          child: pw.Text('Observaciones: null', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
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


  void showPDFPreview(BuildContext context, double montoTotal) async {
    Uint8List pdfData = await _previewPDF();

    showDialog(
      context: context,
      builder: (context) => Scaffold(
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
        body: Center(
          heightFactor: MediaQuery.of(context).size.height,
          child: PdfPreview(
            build: (format) => pdfData,
            allowPrinting: false,
            allowSharing: false,
            canChangePageFormat: false,
            pdfFileName: 'vista_previa.pdf',
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _generatePDF() async {
    final pdf = pw.Document();
    final robotoFont = await loadRobotoFont();
    final robotoBoldFont = await loadRobotoBoldFont();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentFolio = prefs.getInt('folioNumber') ?? 328128;
    int nextFolio = currentFolio + 1;
    await prefs.setInt('folioNumber', nextFolio);

    double montoTotal = productosGlobal.fold(0, (sum, item) {
      return sum + (double.tryParse(item['valorTotal'].toString()) ?? 0);
    });
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
                      pw.Text('R.U.T.: ${_rutController.text}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: robotoBoldFont)),
                      pw.Text('BOLETA ELECTRONICA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: robotoBoldFont)),
                      pw.Text('N° Folio: $currentFolio', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.red, font: robotoBoldFont)),
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
                  pw.Text('Santiago, ${DateFormat('dd/MM/yyyy').format(DateTime.now())}', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(
                width: double.infinity,
                child: pw.Table.fromTextArray(
                  headers: ['Item', 'Código', 'Descripción', 'U.M', 'Cantidad', 'Precio Unit.', 'Valor Exento', 'Valor'],
                  data: [
                    ...productosGlobal.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      var producto = entry.value;
                      return [
                        '$index',
                        producto['codigo'] ?? 'Sin código',
                        producto['descripcion'] ?? 'Producto sin descripción',
                        'UN',
                        producto['cantidad'].toString(),
                        formatCurrency(double.parse(producto['precioUnitario'].toString())),
                        '0',
                        formatCurrency(double.parse(producto['valorTotal'].toString())),
                      ];
                    }),
                    ...List.generate(35, (index) => List.filled(8, '')),
                  ],
                  cellAlignment: pw.Alignment.center,
                  cellStyle: pw.TextStyle(fontSize: 10, font: robotoFont),
                  headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, font: robotoBoldFont, color: PdfColors.white),
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
                            pw.Text('\$${iva.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$${montoTotal.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Monto no fact:', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$      0', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.Divider(thickness: 0.5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Valor a pagar:', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                            pw.Text('\$      0', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
                          ],
                        ),
                        pw.SizedBox(height: 12),
                        pw.Container(
                          padding: pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.black, width: 0.5),
                          ),
                          child: pw.Text('Observaciones: null', style: pw.TextStyle(fontSize: 10, font: robotoFont)),
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

    Uint8List pdfData = await pdf.save();

    await _savePDF(pdfData, 'boleta_$currentFolio');

    return pdfData;
  }




  void _sendEmailWithPDF() async {
    if (_emailController.text.isEmpty || _rutController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Por favor ingrese el RUT y el correo")));
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int folioActual = prefs.getInt('folioNumber') ?? 328128;

      Uint8List pdfData = await _generatePDF();

      final pdfFile = File('${Directory.systemTemp.path}/factura_$folioActual.pdf');
      await pdfFile.writeAsBytes(pdfData);

      double montoTotal = productosGlobal.fold(0, (sum, item) {
        return sum + (double.tryParse(item['valorTotal'].toString()) ?? 0);
      });

      await saveBoletaInfo(folioActual, _rutController.text, montoTotal);

      final emailService = EmailService();
      await emailService.sendInvoiceByEmail(_emailController.text, pdfFile);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Correo enviado exitosamente")));

      _showConfirmationDialog(folioActual);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al enviar correo")));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _savePDF(Uint8List pdfData, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${directory.path}/boletas_emitidas');
      if (!pdfDir.existsSync()) {
        pdfDir.createSync();
      }
      final file = File('${pdfDir.path}/$fileName.pdf');
      await file.writeAsBytes(pdfData);
      print('PDF guardado en la ruta: ${file.path}');
    } catch (e) {
      print('Error al guardar PDF: $e');
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Eliminar Detalle"),
          content: Text("¿Desea borrar esta línea de detalle?"),
          actions: [
            TextButton(
              child: Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Sí"),
              onPressed: () {
                setState(() {
                  productosGlobal.removeAt(index);
                });
                Navigator.of(context).pop();

                if (productosGlobal.isEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => BoletaExpressScreen()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _enviarPorCorreo = false;
        _pageController.animateToPage(
          _currentPage - 1,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double montoTotal = productosGlobal.fold<double>(
      0,
          (sum, item) => sum + (item['valorTotal'] as num).toDouble(),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("¿Desea volver al menú principal?"),
                  content: Text("Si regresa perderá los datos ingresados."),
                  actions: [
                    TextButton(
                      child: Text("No"),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child: Text("Sí"),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => MainScreen(loggedInUserEmail: loggedInUserEmail ?? '')),
                              (Route<dynamic> route) => false,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
        title: Text('Boleta Express', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
        actions: [
          if (_isPlusButtonVisible)
            IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                final nuevoProducto = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BoletaExpressScreen(),
                  ),
                );

                if (nuevoProducto != null) {
                  setState(() {
                    productosGlobal.addAll(nuevoProducto);
                  });
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
            child: Column(
              children: [
                Text(
                  _currentPage == 0 ? 'Detalle' : 'Totales',
                  style: TextStyle(color: Color(0xFF1A5DD9), fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _currentPage > 0 ? _goToPreviousPage : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentPage > 0 ? Color(0xFF1A5DD9) : Colors.grey.shade400,
                          ),
                        ),
                        padding: EdgeInsets.all(0),
                        child: Icon(
                          Icons.chevron_left,
                          color: _currentPage > 0 ? Color(0xFF1A5DD9) : Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.circle,
                      color: _currentPage >= 0 ? Color(0xFF1A5DD9) : Colors.grey.shade300,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.circle,
                      color: _currentPage == 1 ? Color(0xFF1A5DD9) : Colors.grey.shade300,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: _currentPage < 1 ? _goToNextPage : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentPage < 1 ? Color(0xFF1A5DD9) : Colors.grey.shade400,
                          ),
                        ),
                        padding: EdgeInsets.all(0),
                        child: Icon(
                          Icons.chevron_right,
                          color: _currentPage < 1 ? Color(0xFF1A5DD9) : Colors.grey.shade400,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int index) {
                setState(() {
                  _isPlusButtonVisible = (index == 0);
                  _currentPage = index;
                });
              },
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: productosGlobal.length,
                          itemBuilder: (context, index) {
                            var producto = productosGlobal[index];
                            double cantidad = producto['cantidad'] is int
                                ? (producto['cantidad'] as int).toDouble()
                                : producto['cantidad'];
                            double precioUnitario = producto['precioUnitario'] is int
                                ? (producto['precioUnitario'] as int).toDouble()
                                : producto['precioUnitario'];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ModificarDetalleScreen(
                                      codigo: producto['codigo'] ?? '',
                                      descripcion: producto['descripcion'] ?? 'Producto sin descripción',
                                      cantidad: cantidad,
                                      precioUnitario: precioUnitario,
                                    ),
                                  ),
                                ).then((updatedProduct) {
                                  if (updatedProduct != null) {
                                    setState(() {
                                      productosGlobal[index] = updatedProduct;
                                    });
                                  }
                                });
                              },
                              child: Card(
                                color: Colors.white,
                                margin: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: Colors.black, width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              producto['descripcion'] ?? 'Producto sin descripción',
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'Cantidad: ',
                                                  style: TextStyle(fontSize: 12, color: Colors.black),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  '${cantidad.toStringAsFixed(1)} UN',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  'Precio Unitario: ',
                                                  style: TextStyle(fontSize: 12, color: Colors.black),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  formatCurrency(precioUnitario),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Valor Total: ',
                                                  style: TextStyle(fontSize: 12, color: Colors.black),
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  formatCurrency(precioUnitario * cantidad),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: PopupMenuButton<String>(
                                          onSelected: (String result) {
                                            if (result == 'Borrar') {
                                              _showDeleteConfirmationDialog(context, index);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => [
                                            PopupMenuItem<String>(
                                              value: 'Borrar',
                                              child: Text('Borrar'),
                                            ),
                                          ],
                                          icon: Icon(Icons.more_vert, color: Colors.black, size: 18),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Container(
                            color: Color(0xFF1A5DD9),
                            padding: EdgeInsets.symmetric(vertical: 1),
                            child: Center(
                              child: Text(
                                'Monto Total',
                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.normal),
                              ),
                            ),
                          ),
                          Container(
                            color: Colors.grey[200],
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(
                                formatCurrency(montoTotal),
                                style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.normal),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        color: Color(0xFF1A5DD9),
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Center(
                          child: Text(
                            'Valor Total',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        color: Colors.grey[200],
                        padding: EdgeInsets.symmetric(vertical: 1),
                        child: Center(
                          child: Text(
                            formatCurrency(montoTotal),
                            style: TextStyle(
                              color: Color(0xFF1A5DD9),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Enviar por correo',
                            style: TextStyle(fontSize: 14),
                          ),
                          Switch(
                            value: _enviarPorCorreo,
                            onChanged: (value) {
                              setState(() {
                                _enviarPorCorreo = value;
                                if (_enviarPorCorreo) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RutInputScreen(
                                        onRutSubmitted: (rut) {
                                          _rutController.text = rut;
                                          _isEmailEnabled = true;
                                        },
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _rutController,
                        enabled: _enviarPorCorreo,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'RUT',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        enabled: _enviarPorCorreo,
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_enviarPorCorreo && !_isValidRUT(_rutController.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('RUT inválido')),
                            );
                            return;
                          }
                          showPDFPreview(context, montoTotal);
                        },
                        icon: Icon(Icons.search, color: Colors.white),
                        label: Text(
                          'Vista Previa',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A5DD9),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _sendEmailWithPDF,
                        child: Text(
                          'Emitir',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
