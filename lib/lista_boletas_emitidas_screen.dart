import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'detalle_venta_screen.dart';

class ListaBoletasEmitidasScreen extends StatefulWidget {
  @override
  _ListaBoletasEmitidasScreenState createState() => _ListaBoletasEmitidasScreenState();
}

class _ListaBoletasEmitidasScreenState extends State<ListaBoletasEmitidasScreen> {
  List<Map<String, dynamic>> boletasInfo = [];

  @override
  void initState() {
    super.initState();
    _loadBoletasInfo();
  }

  Future<void> _loadBoletasInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> boletas = prefs.getStringList('boletas_emitidas') ?? [];

    setState(() {
      boletasInfo = boletas
          .map((boleta) => Map<String, dynamic>.from(jsonDecode(boleta)))
          .toList();
    });
  }

  String formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String formatRut(String rut) {
    return '${rut.substring(0, rut.length - 1)}-${rut[rut.length - 1]}';
  }

  String formatCurrency(double value) {
    final currencyFormat = NumberFormat('#,##0', 'es_ES');
    return currencyFormat.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Boletas Emitidas', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
      ),
      body: ListView.builder(
        itemCount: boletasInfo.length,
        itemBuilder: (context, index) {
          final boleta = boletasInfo[index];
          final folio = boleta['folio'];
          final rut = boleta['rut'];
          final total = boleta['total'];
          final date = boleta['date'];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleVentaScreen(boleta: boleta),
                ),
              );

            },
            child: Container(
              color: index % 2 == 0 ? Colors.blue[50] : Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          color: Colors.blue,
                          size: 40,
                        ),
                        Text(
                          'BOL',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cliente Boleta',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'BOLETA ELECTRONICA',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '$folio / ${formatRut(rut)}',
                          style: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${formatCurrency(total)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formatDate(date),
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
