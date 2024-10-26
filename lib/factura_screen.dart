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
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
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

  Future<void> _generateInvoiceFromHtml() async {
    setState(() {
      _isGeneratingInvoice = true;
    });

    try {
      String htmlTemplate = await rootBundle.loadString('assets/factura.html');

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

      String htmlContent = htmlTemplate
          .replaceAll('{{cliente}}', cliente)
          .replaceAll('{{direccion}}', direccion)
          .replaceAll('{{fecha}}', fecha)
          .replaceAll('{{hora}}', hora)
          .replaceAll('{{telefono}}', telefono)
          .replaceAll('{{email}}', email)
          .replaceAll('{{productos}}', _buildHtmlProducts())
          .replaceAll('{{subtotal}}', _formatCurrency(total))
          .replaceAll('{{iva}}', impuesto.toString())
          .replaceAll('{{ivaMonto}}', _formatCurrency(ivaMonto))
          .replaceAll('{{total}}', _formatCurrency(totalConImpuesto));

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/factura.pdf");

      await Printing.convertHtml(
        format: PdfPageFormat.a4,
        html: htmlContent,
      ).then((pdfBytes) async {
        await file.writeAsBytes(pdfBytes);
      });

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
      print('Error al generar factura desde HTML: $e');
    } finally {
      setState(() {
        _isGeneratingInvoice = false;
      });
    }
  }


  String _buildHtmlProducts() {
    StringBuffer productBuffer = StringBuffer();
    for (var item in items) {
      final totalItem = _formatCurrency(item['precio'] * item['cantidad']);
      productBuffer.writeln('''
      <tr>
        <td>${item['cantidad']}</td>
        <td>${item['producto']}</td>
        <td>${_formatCurrency(item['precio'])}</td>
        <td>$totalItem</td>
      </tr>
    ''');
    }
    return productBuffer.toString();
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
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              SizedBox(height: 40),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Inicio',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => MainScreen(loggedInUserEmail: widget.loggedInUserEmail)),
                  );
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Creación Cuenta',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreacionCuentaScreen(loggedInUserEmail: widget.loggedInUserEmail)),
                  );
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Listado',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ListadoScreen(loggedInUserEmail: widget.loggedInUserEmail)),
                  );
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Generar Factura',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FacturaScreen(loggedInUserEmail: widget.loggedInUserEmail)),
                  );
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cerrar Sesión',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                    Icon(Icons.logout, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
              )
            ],
          ),
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
                      ? _generateInvoiceFromHtml
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
