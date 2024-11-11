import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'boleta_express_screen.dart';

class ResultadosBusquedaScreen extends StatelessWidget {
  final List<Map<String, dynamic>> productos;

  ResultadosBusquedaScreen({required this.productos});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat('#,##0', 'es_CL');

    return Scaffold(
      appBar: AppBar(
        title: Text('Buscador de Producto', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Otras Coincidencias',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: productos.isEmpty
                ? Center(child: Text('No se encontraron productos'))
                : ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                var producto = productos[index];
                return Container(
                  color: index % 2 == 0 ? Colors.blue[50] : Colors.white,
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                    title: Text(
                      producto['descripcion'] ?? 'Sin descripción',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto['codigo'] ?? 'Sin código',
                          style: TextStyle(color: Colors.black54),
                        ),
                        if (producto['exento'] == true)
                          Text(
                            "(Exento)",
                            style: TextStyle(color: Colors.blue),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '\$ ${currencyFormat.format(producto['precio'] ?? 0)}',
                          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right, color: Colors.black54),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoletaExpressScreen(
                            producto: producto,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
