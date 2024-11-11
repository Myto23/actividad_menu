import 'package:actividad_menu/buscador_producto_screen.dart';
import 'package:actividad_menu/database/database_helper.dart';
import 'package:actividad_menu/lista_productos_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'globals.dart';

class BoletaExpressScreen extends StatefulWidget {
  final Map<String, dynamic>? producto;

  BoletaExpressScreen({this.producto, Key? key}) : super(key: key);

  @override
  _BoletaExpressScreenState createState() => _BoletaExpressScreenState();
}

class _BoletaExpressScreenState extends State<BoletaExpressScreen> {
  late TextEditingController _codigoController;
  late TextEditingController _descripcionController;
  TextEditingController? _bodegaController;
  late TextEditingController _cantidadController;
  late TextEditingController _precioUnitarioController;
  late PageController _pageController;

  final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 0,
  );

  double _valorTotal = 0.0;
  int _currentPage = 0;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();

    _codigoController = TextEditingController(text: widget.producto?['codigo'] ?? '');
    _descripcionController = TextEditingController(text: widget.producto?['descripcion'] ?? '');
    _precioUnitarioController = TextEditingController(
        text: widget.producto != null
            ? (widget.producto!['precio']?.toInt().toString() ?? '')
            : ''
    );
    _cantidadController = TextEditingController();
    _pageController = PageController();

    if (widget.producto != null && widget.producto!.containsKey('bodega')) {
      _bodegaController = TextEditingController(text: widget.producto!['bodega'] ?? '');
    } else {
      _bodegaController = null;
    }

    _cantidadController.text = widget.producto != null ? '1' : '';
    _cantidadController.addListener(_checkButtonState);
    _codigoController.addListener(_checkButtonState);
    _descripcionController.addListener(_checkButtonState);
    _precioUnitarioController.addListener(_checkButtonState);
    _cantidadController.addListener(_updateValorTotal);

    _updateValorTotal();
    _checkButtonState();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioUnitarioController.dispose();
    _bodegaController?.dispose();
    _pageController.dispose();

    super.dispose();
  }

  void _checkButtonState() {
    final isButtonEnabled = _codigoController.text.isNotEmpty &&
        _descripcionController.text.isNotEmpty &&
        _precioUnitarioController.text.isNotEmpty &&
        (_cantidadController.text.isNotEmpty && int.tryParse(_cantidadController.text) != null);

    setState(() {
      _isButtonEnabled = isButtonEnabled;
    });
  }

  void _updateValorTotal() {
    int cantidad = int.tryParse(_cantidadController.text) ?? 0;
    double precioUnitario = double.tryParse(_precioUnitarioController.text) ?? 0.0;
    setState(() {
      _valorTotal = cantidad * precioUnitario;
    });
  }

  String formatCurrency(double value) {
    return currencyFormat.format(value).replaceAll(',', '.');
  }

  void _agregarProducto() async {
    final producto = {
      'codigo': _codigoController.text,
      'descripcion': _descripcionController.text,
      'bodega': _bodegaController?.text ?? '',
      'cantidad': int.tryParse(_cantidadController.text) ?? 1,
      'precioUnitario': double.tryParse(_precioUnitarioController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
      'valorTotal': _valorTotal,
    };

    await DatabaseHelper().insertarProducto(producto);

    productosGlobal.add(producto);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ListaProductosScreen(),
      ),
    );
  }

  void _incrementQuantity() {
    setState(() {
      int currentQuantity = int.tryParse(_cantidadController.text) ?? 0;
      _cantidadController.text = (currentQuantity + 1).toString();
      _updateValorTotal();
    });
  }

  void _decrementQuantity() {
    setState(() {
      int currentQuantity = int.tryParse(_cantidadController.text) ?? 0;
      if (currentQuantity > 0) {
        _cantidadController.text = (currentQuantity - 1).toString();
        _updateValorTotal();
      }
    });
  }

  void _goToNextPage() {
    if (_currentPage < 2) {
      setState(() {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _onProductSelected(Map<String, dynamic> producto) {
    setState(() {
      _codigoController.text = producto['codigo'];
      _descripcionController.text = producto['descripcion'];
      _precioUnitarioController.text = (producto['precio'] as double).toInt().toString();
      _cantidadController.text = '1';
      _bodegaController = producto['bodega'] != null
          ? TextEditingController(text: producto['bodega'])
          : null;
      _updateValorTotal();
      _checkButtonState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Boleta Express', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Agregar Detalle',
              style: TextStyle(fontSize: 18, color: Color(0xFF1A5DD9)),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularArrowButton(
                  Icons.chevron_left,
                  enabled: _currentPage > 0,
                  onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                  iconSize: 20,
                ),
                SizedBox(width: 15),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: _currentPage == 0 ? Color(0xFF1A5DD9) : Colors.grey,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.circle,
                      color: _currentPage == 1 ? Color(0xFF1A5DD9) : Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
                SizedBox(width: 15),
                _buildCircularArrowButton(
                  Icons.chevron_right,
                  enabled: _currentPage < 1,
                  onPressed: _currentPage < 1 ? _goToNextPage : null,
                  iconSize: 20,
                ),
              ],
            ),
            SizedBox(height: 20),
            Flexible(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPageContent(),
                  Center(child: Text("Segunda página")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularArrowButton(IconData icon, {bool enabled = true, VoidCallback? onPressed, double iconSize = 20}) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: EdgeInsets.all(0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: enabled ? Color(0xFF1A5DD9) : Colors.grey, width: 1.5),
        ),
        child: Icon(
          icon,
          color: enabled ? Color(0xFF1A5DD9) : Colors.grey,
          size: iconSize,
        ),
      ),
    );
  }


  Widget _buildPageContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BuscadorProductoScreen()),
                    );
                  },
                  child: Icon(Icons.search, color: Color(0xFF1A5DD9), size: 24),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BuscadorProductoScreen()),
              );
            },
            child: AbsorbPointer(
              child: TextField(
                controller: _codigoController,
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
            controller: _descripcionController,
            decoration: InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
              fillColor: Colors.blue[50],
              filled: true,
            ),
            readOnly: true,
          ),
          if (_bodegaController?.text.isNotEmpty ?? false) ...[
            SizedBox(height: 10),
            TextField(
              controller: _bodegaController,
              decoration: InputDecoration(
                labelText: 'Bodega',
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
          ],
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cantidadController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                    fillColor: Colors.blue[50],
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _updateValorTotal();
                  },
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
            controller: _precioUnitarioController,
            decoration: InputDecoration(
              labelText: 'Precio Unitario',
              border: OutlineInputBorder(),
              fillColor: Colors.blue[50],
              filled: true,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _updateValorTotal();
            },
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
                formatCurrency(_valorTotal),
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton( onPressed: _isButtonEnabled
              ? () {
            final producto = {
              'codigo': _codigoController.text,
              'descripcion': _descripcionController.text,
              'bodega': _bodegaController?.text ?? '',
              'cantidad': int.tryParse(_cantidadController.text) ?? 1,
              'precioUnitario': double.tryParse(_precioUnitarioController.text) ?? 0.0,
              'valorTotal': _valorTotal,
            };

            productosGlobal.add(producto);

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ListaProductosScreen(),
              ),
            );
          }
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isButtonEnabled ? Color(0xFF1A5DD9) : Colors.grey,
              foregroundColor: Colors.black54,
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text(
              'Aceptar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
