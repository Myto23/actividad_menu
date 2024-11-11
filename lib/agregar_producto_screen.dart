import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'globals.dart';

class AgregarProductoScreen extends StatefulWidget {
  @override
  _AgregarProductoScreenState createState() => _AgregarProductoScreenState();
}

class _AgregarProductoScreenState extends State<AgregarProductoScreen> {
  final _codigoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _bodegaController = TextEditingController();
  final _precioController = TextEditingController();
  String _estado = 'SI';

  Future<void> _guardarProducto() async {
    if (_codigoController.text.isNotEmpty &&
        _descripcionController.text.isNotEmpty &&
        _precioController.text.isNotEmpty) {
      Map<String, dynamic> producto = {
        'codigo': _codigoController.text,
        'descripcion': _descripcionController.text,
        'activo': _estado,
        'bodega': _bodegaController.text.isNotEmpty ? _bodegaController.text : null,
        'precio': double.tryParse(_precioController.text) ?? 0.0
      };

      await DatabaseHelper().insertarProducto(producto);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto agregado exitosamente')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, complete todos los campos obligatorios')),
      );
    }
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
        title: Text('Agregar Producto', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _precioController,
              decoration: InputDecoration(
                labelText: 'Precio *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _estado,
              onChanged: (String? newValue) {
                setState(() {
                  _estado = newValue!;
                });
              },
              items: ['SI', 'NO'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Activo *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _bodegaController,
              decoration: InputDecoration(
                labelText: 'Bodega (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _guardarProducto,
                child: Text('Guardar Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A5DD9),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
