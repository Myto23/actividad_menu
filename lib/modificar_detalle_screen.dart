import 'package:actividad_menu/lista_productos_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'buscador_producto_screen.dart';

class ModificarDetalleScreen extends StatefulWidget {
  final String codigo;
  final String descripcion;
  final double cantidad;
  final double precioUnitario;

  ModificarDetalleScreen({
    required this.codigo,
    required this.descripcion,
    required this.cantidad,
    required this.precioUnitario,
  });

  @override
  _ModificarDetalleScreenState createState() => _ModificarDetalleScreenState();
}

class _ModificarDetalleScreenState extends State<ModificarDetalleScreen> {
  late TextEditingController codigoController;
  late TextEditingController descripcionController;
  late TextEditingController cantidadController;
  late TextEditingController precioUnitarioController;
  late TextEditingController valorTotalController;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 0,
  );

  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    codigoController = TextEditingController(text: widget.codigo);
    descripcionController = TextEditingController(text: widget.descripcion);
    cantidadController = TextEditingController(text: widget.cantidad.toStringAsFixed(0));
    precioUnitarioController = TextEditingController(text: widget.precioUnitario.toStringAsFixed(2));
    valorTotalController = TextEditingController(
      text: (widget.cantidad * widget.precioUnitario).toStringAsFixed(2),
    );

    cantidadController.addListener(_updateValorTotal);
    precioUnitarioController.addListener(_updateValorTotal);
  }

  @override
  void dispose() {
    codigoController.dispose();
    descripcionController.dispose();
    cantidadController.dispose();
    precioUnitarioController.dispose();
    valorTotalController.dispose();
    super.dispose();
  }

  void _updateValorTotal() {
    double cantidad = double.tryParse(cantidadController.text) ?? 0.0;
    double precioUnitario = double.tryParse(precioUnitarioController.text) ?? 0.0;
    setState(() {
      valorTotalController.text = (cantidad * precioUnitario).toStringAsFixed(2);
    });
  }

  void _incrementQuantity() {
    setState(() {
      int currentQuantity = int.tryParse(cantidadController.text) ?? 0;
      cantidadController.text = (currentQuantity + 1).toString();
    });
  }

  void _decrementQuantity() {
    setState(() {
      int currentQuantity = int.tryParse(cantidadController.text) ?? 0;
      if (currentQuantity > 0) {
        cantidadController.text = (currentQuantity - 1).toString();
      }
    });
  }

  void _guardarCambios() {
    double nuevaCantidad = double.parse(cantidadController.text);
    double nuevoPrecioUnitario = double.parse(precioUnitarioController.text);
    Navigator.pop(context, {
      'codigo': codigoController.text,
      'descripcion': descripcionController.text,
      'cantidad': nuevaCantidad,
      'precioUnitario': nuevoPrecioUnitario,
      'valorTotal': nuevaCantidad * nuevoPrecioUnitario,
    });
  }

  String formatCurrency(double value) {
    return currencyFormat.format(value).replaceAll(',', '.');
  }

  Widget _buildCircularArrowButton(IconData icon, {VoidCallback? onPressed, double iconSize = 20}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: onPressed == null ? Colors.grey : Color(0xFF1A5DD9),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: onPressed == null ? Colors.grey : Color(0xFF1A5DD9),
          size: iconSize,
        ),
      ),
    );
  }


  void _openProductSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BuscadorProductoScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF1A5DD9),
        title: Text("Boleta Express", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  "Modificar Detalle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A5DD9)),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircularArrowButton(
                    Icons.chevron_left,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ListaProductosScreen()),
                      );
                    },
                    iconSize: 20,
                  ),
                  SizedBox(width: 15),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: Color(0xFF1A5DD9),
                        size: 15,
                      ),
                      SizedBox(width: 5),
                      Icon(
                        Icons.circle,
                        color: Colors.grey,
                        size: 15,
                      ),
                    ],
                  ),
                  SizedBox(width: 15),
                  _buildCircularArrowButton(
                    Icons.chevron_right,
                    onPressed: null,
                    iconSize: 20,
                  ),
                ],
              ),
              SizedBox(height: 16),
              GestureDetector(
                onTap: _openProductSearch,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.search, color: Color(0xFF1A5DD9), size: 24),
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: _openProductSearch,
                child: AbsorbPointer(
                  child: TextField(
                    controller: codigoController,
                    decoration: InputDecoration(
                      labelText: 'Código',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide(color: Color(0xFF1A5DD9)),
                      ),
                      fillColor: Colors.grey[300],
                      filled: true,
                    ),
                    readOnly: true,
                  ),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                  fillColor: Colors.grey[300],
                  filled: true,
                ),
                readOnly: true,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cantidadController,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                        fillColor: Colors.blue[50],
                        filled: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8),
                  _buildCircularArrowButton(
                    Icons.arrow_downward,
                    onPressed: _decrementQuantity,
                    iconSize: 14,
                  ),
                  SizedBox(width: 14),
                  _buildCircularArrowButton(
                    Icons.arrow_upward,
                    onPressed: _incrementQuantity,
                    iconSize: 14,
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextField(
                controller: precioUnitarioController,
                decoration: InputDecoration(
                  labelText: 'Precio Unitario',
                  border: OutlineInputBorder(),
                  fillColor: Colors.blue[50],
                  filled: true,
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              Text(
                'Valor Total',
                style: TextStyle(color: Color(0xFF1A5DD9), fontSize: 13),
              ),
              Container(
                margin: EdgeInsets.only(top: 0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF1A5DD9), width: 2),
                  ),
                ),
                child: Container(
                  margin: EdgeInsets.only(top: 8.0),
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5.0),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    formatCurrency(double.parse(valorTotalController.text)),
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _guardarCambios,
                  child: Text("Aceptar", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A5DD9),
                    minimumSize: Size(double.infinity, 50),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }
}
