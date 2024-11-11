import 'package:actividad_menu/agregar_producto_screen.dart';
import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'resultados_busqueda_screen.dart';
import 'globals.dart';

class BuscadorProductoScreen extends StatefulWidget {
  @override
  _BuscadorProductoScreenState createState() => _BuscadorProductoScreenState();
}

class _BuscadorProductoScreenState extends State<BuscadorProductoScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  bool _cargando = false;
  String _activoSeleccionado = 'SI';

  Future<void> _buscarProductos() async {
    String codigo = _codigoController.text;
    String descripcion = _descripcionController.text;

    setState(() {
      _cargando = true;
    });

    try {
      final productos = await DatabaseHelper().buscarProductos(codigo, descripcion);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultadosBusquedaScreen(productos: productos),
        ),
      );
    } catch (e) {
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscador de Producto', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AgregarProductoScreen()),
              );
            },
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código',
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción',
                border: UnderlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Activo',
                labelStyle: TextStyle(color: Color(0xFF1A5DD9)),
                border: UnderlineInputBorder(),
              ),
              value: _activoSeleccionado,
              items: ['SI', 'NO'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _activoSeleccionado = value!;
                });
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_codigoController.text.isEmpty && _descripcionController.text.isEmpty) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Buscar Producto'),
                          content: Text('Debe agregar algún parámetro de búsqueda'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Aceptar'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    _buscarProductos();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A5DD9),
                  minimumSize: Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                ),
                child: _cargando
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Buscar', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
