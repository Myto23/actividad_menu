import 'package:actividad_menu/creacion_cuenta_screen.dart';
import 'package:actividad_menu/detalle_cuenta_screen.dart';
import 'package:actividad_menu/factura_screen.dart';
import 'package:actividad_menu/login_screen.dart';
import 'package:actividad_menu/main.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class ListadoScreen extends StatefulWidget {
  final String loggedInUserEmail;

  ListadoScreen({required this.loggedInUserEmail});

  @override
  _ListadoScreenState createState() => _ListadoScreenState();
}

class _ListadoScreenState extends State<ListadoScreen> {
  late Database database;
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> usuariosFiltrados = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _searchController.addListener(_filtrarUsuarios);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'usuarios.db');

    database = await openDatabase(
      path,
      version: 1,
    );
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final List<Map<String, dynamic>> usuariosRecuperados = await database.query('usuarios');
    setState(() {
      usuarios = usuariosRecuperados;
      usuariosFiltrados = usuarios;
    });
  }

  void _filtrarUsuarios() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      usuariosFiltrados = usuarios
          .where((usuario) => usuario['nombre'].toLowerCase().contains(query))
          .toList();
    });
  }

  String formatPhoneNumber(String phoneNumber) {
    phoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneNumber.length == 10) {
      return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6, 10)}';
    } else {
      return phoneNumber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Listado',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1A5DD9),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            color: Colors.white,
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreacionCuentaScreen(loggedInUserEmail: widget.loggedInUserEmail),
                      )                  );
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FacturaScreen(loggedInUserEmail: widget.loggedInUserEmail),
                    ),
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.93,
              margin: EdgeInsets.only(bottom: 6.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Nombre',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: usuariosFiltrados.isEmpty
                  ? Center(
                child: Text('No hay usuarios registrados.'),
              )
                  : ListView.builder(
                itemCount: usuariosFiltrados.length,
                itemBuilder: (context, index) {
                  final usuario = usuariosFiltrados[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: index.isEven ? Color(0xFFD5E5ED) : Color(0xFFEFF3F6),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12.0,
                      ),
                      title: Text(
                        usuario['nombre'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              formatPhoneNumber(usuario['celular'] ?? '(No encontrado)'),
                              style: TextStyle(fontSize: 12.0),
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            flex: 3,
                            child: Text(
                              usuario['correo'] ?? 'Correo no disponible',
                              style: TextStyle(color: Color(0xFF2A11CC), fontSize: 16.0),
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(0xFFF4F0F0),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 15.0,
                          color: Color(0xFF606163),
                        ),
                      ),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleCuentaScreen(
                              usuario: usuario,
                              database: database,
                            ),
                          ),
                        );
                        if (result == true) {
                          _cargarUsuarios();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
