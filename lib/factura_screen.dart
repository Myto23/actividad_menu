import 'dart:io';
import 'package:actividad_menu/login_screen.dart';
import 'package:actividad_menu/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'send_email_service.dart';
import 'openai_service.dart';
import 'creacion_cuenta_screen.dart';
import 'listado_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;

class FacturaScreen extends StatefulWidget {
  final String loggedInUserEmail;

  FacturaScreen({required this.loggedInUserEmail});

  @override
  _FacturaScreenState createState() => _FacturaScreenState();
}

class _FacturaScreenState extends State<FacturaScreen> {
  final EmailService emailService = EmailService();
  final OpenAIService openAIService = OpenAIService();

  final _clienteController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _productoController = TextEditingController();
  final _precioController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _impuestoController = TextEditingController(text: '19.0');

  List<Map<String, dynamic>> items = [];
  bool _isFormValid = false;
  bool _isGeneratingInvoice = false;
  bool _isInvoiceSent = false;

  String _formatCurrency(double amount) {
    final formatCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    return formatCurrency.format(amount);
  }

  void _addItem() {
    if (_validateFields()) {
      setState(() {
        items.add({
          'producto': _productoController.text,
          'precio': double.parse(_precioController.text),
          'cantidad': int.parse(_cantidadController.text),
        });
        _isFormValid = items.isNotEmpty;
      });

      _productoController.clear();
      _precioController.clear();
      _cantidadController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto/Servicio añadido exitosamente.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, complete todos los campos antes de añadir un producto o servicio.')),
      );
    }
  }

  bool _validateFields() {
    if (_clienteController.text.isEmpty ||
        _direccionController.text.isEmpty ||
        _telefonoController.text.isEmpty ||
        _productoController.text.isEmpty ||
        _precioController.text.isEmpty ||
        _cantidadController.text.isEmpty ||
        _impuestoController.text.isEmpty) {
      return false;
    }

    if (double.tryParse(_precioController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El precio debe ser un número válido.')),
      );
      return false;
    }

    return true;
  }

  Future<void> _generateInvoice() async {
    setState(() {
      _isGeneratingInvoice = true;
    });

    try {
      final total = items.fold<double>(
        0,
            (sum, item) => sum + (item['precio'] * item['cantidad']),
      );

      final impuesto = double.parse(_impuestoController.text);
      final ivaMonto = total * impuesto / 100;
      final totalConImpuesto = total + ivaMonto;

      final cliente = _clienteController.text;
      final direccion = _direccionController.text;
      final telefono = _telefonoController.text;
      final email = widget.loggedInUserEmail;

      tz.initializeTimeZones();
      final chileTimeZone = tz.getLocation('America/Santiago');
      final chileTime = tz.TZDateTime.now(chileTimeZone);

      final String fecha = DateFormat('dd-MM-yyyy').format(chileTime);
      final String hora = DateFormat('HH:mm').format(chileTime);

      // Cargamos las imágenes de manera anticipada.
      final logoData = await rootBundle.load('assets/logo.png');
      final qrCodeData = await rootBundle.load('assets/qr.png');

      final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
      final qrCodeImage = pw.MemoryImage(qrCodeData.buffer.asUint8List());

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Container(
              padding: pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(logoImage, width: 100),
                      pw.Text('Factura', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    cellStyle: pw.TextStyle(fontSize: 14),
                    headers: null,
                    data: [
                      ['Nombre:', cliente],
                      ['Dirección:', direccion],
                      ['Teléfono:', telefono],
                      ['Email:', email],
                      ['Fecha:', fecha],
                      ['Hora:', hora],
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: ['Cantidad', 'Concepto', 'Precio Unitario', 'Total'],
                    data: items.map((item) {
                      final totalItem = item['precio'] * item['cantidad'];
                      return [
                        item['cantidad'].toString(),
                        item['producto'],
                        _formatCurrency(item['precio']),
                        _formatCurrency(totalItem),
                      ];
                    }).toList(),
                    border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
                    headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                    headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    headers: null,
                    data: [
                      ['Subtotal:', _formatCurrency(total)],
                      ['IVA (${impuesto}%):', _formatCurrency(ivaMonto)],
                      ['Total:', _formatCurrency(totalConImpuesto)],
                    ],
                    cellAlignment: pw.Alignment.centerRight,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '"La alteración, falsificación o comercialización ilegal de este documento está penado por la ley"',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 20),
                  pw.Image(qrCodeImage, width: 100),
                ],
              ),
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/factura.pdf");
      await file.writeAsBytes(await pdf.save());

      await emailService.sendInvoiceByEmail(widget.loggedInUserEmail, file);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Factura enviada al cliente.')),
      );

      _clienteController.clear();
      _direccionController.clear();
      _telefonoController.clear();
      _productoController.clear();
      _precioController.clear();
      _cantidadController.clear();
      _impuestoController.clear();
      setState(() {
        items.clear();
        _isInvoiceSent = true;
      });
    } catch (e) {
      print('Error al generar factura: $e');
    } finally {
      setState(() {
        _isGeneratingInvoice = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generar y Enviar Factura',
          style: TextStyle(
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1A5DD9),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _clienteController,
                decoration: InputDecoration(labelText: 'Nombre del Cliente'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _direccionController,
                decoration: InputDecoration(labelText: 'Dirección del Cliente'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _telefonoController,
                decoration: InputDecoration(labelText: 'Teléfono del Cliente'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _productoController,
                decoration: InputDecoration(labelText: 'Producto/Servicio'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Precio'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Cantidad'),
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A5DD9),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Añadir Producto/Servicio'),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _impuestoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Impuesto (%)'),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isFormValid && !_isGeneratingInvoice && !_isInvoiceSent
                      ? _generateInvoice
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A5DD9),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isGeneratingInvoice ? 'Generando Factura...' : 'Generar y Enviar Factura'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
