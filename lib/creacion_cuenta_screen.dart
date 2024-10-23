import 'package:actividad_menu/listado_screen.dart';
import 'package:actividad_menu/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class CreacionCuentaScreen extends StatefulWidget {
  @override
  _CreacionCuentaScreenState createState() => _CreacionCuentaScreenState();
}

class _CreacionCuentaScreenState extends State<CreacionCuentaScreen> {
  final _formKey = GlobalKey<FormState>();
  late Database database;
  bool _isDatabaseInitialized = false;
  bool _isObtenerDesdeApiButtonDisabled = false;
  bool _isRegistrarButtonEnabled = false;

  bool _shouldValidate = true;

  String nombre = '';
  String correo = '';
  String direccion = '';
  String fechaNacimiento = '';
  String celular = '';

  bool _isPasswordVisible = false;

  final MaskedTextController _fechaNacimientoController = MaskedTextController(mask: '00/00/0000');
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  @override
  void dispose() {
    _fechaNacimientoController.dispose();
    _celularController.dispose();
    _nombreController.dispose();
    _correoController.dispose();
    _direccionController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, 'usuarios.db');

    database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE usuarios(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT,
          correo TEXT,
          direccion TEXT,
          fechaNacimiento TEXT,
          contrasena TEXT,
          celular TEXT
        )
      ''');
      },
    );

    setState(() {
      _isDatabaseInitialized = true;
    });
  }


  Future<void> _guardarUsuario() async {
    if (_formKey.currentState!.validate()) {
      fechaNacimiento = _fechaNacimientoController.text;
      celular = _celularController.text;

      await database.insert('usuarios', {
        'nombre': nombre,
        'correo': correo,
        'direccion': direccion,
        'fechaNacimiento': fechaNacimiento,
        'contrasena': _contrasenaController.text,
        'celular': celular,
      });

      _mostrarSnackBar('Usuario registrado con éxito.');

      setState(() {
        _shouldValidate = false;
        _formKey.currentState!.reset();

        _nombreController.clear();
        _correoController.clear();
        _direccionController.clear();
        _fechaNacimientoController.text = '';
        _celularController.clear();
        _contrasenaController.clear();
        _isRegistrarButtonEnabled = false;
      });

      Future.delayed(Duration(milliseconds: 100), () {
        setState(() {
          _shouldValidate = true;
        });
      });
    }
  }

  Future<void> _obtenerDesdeApi() async {
    setState(() {
      _isObtenerDesdeApiButtonDisabled = true;
    });

    try {
      final response = await http.get(Uri.parse('https://randomuser.me/api/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['results'][0];
        setState(() {
          _nombreController.text = '${data['name']['first']} ${data['name']['last']}';
          _correoController.text = data['email'];
          DateTime fecha = DateTime.parse(data['dob']['date']);
          fechaNacimiento = '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
          _direccionController.text = data['location']['street']['name'];
          _fechaNacimientoController.text = fechaNacimiento;

          String celularApi = data['cell'] ?? '0000000000';
          _celularController.text = celularApi.replaceAll(RegExp(r'[^0-9]'), '');

          _contrasenaController.text = data['login']['password'] ?? 'Password123';

          _isRegistrarButtonEnabled = _formKey.currentState!.validate();
        });

        _mostrarSnackBar('Datos obtenidos correctamente.');
      } else {
        print('Error en la respuesta de la API. Código: ${response.statusCode}');
        print('Respuesta: ${response.body}');
        _mostrarSnackBar('Error al obtener datos de la API.');
      }
    } catch (e) {
      print('Error durante la solicitud HTTP: $e');
      _mostrarSnackBar('Error al obtener datos de la API.');
    } finally {
      setState(() {
        _isObtenerDesdeApiButtonDisabled = false;
      });
    }
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _onFormChanged() {
    if (_shouldValidate) {
      setState(() {
        _isRegistrarButtonEnabled = _formKey.currentState!.validate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Creación Cuenta', style: TextStyle(color: Colors.white)),
        centerTitle: true,

        backgroundColor: Color(0xFF1A5DD9),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
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
                    MaterialPageRoute(builder: (context) => MainScreen()),
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
                    MaterialPageRoute(builder: (context) => CreacionCuentaScreen()),
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
                    MaterialPageRoute(builder: (context) => ListadoScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _isDatabaseInitialized
          ? SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            onChanged: _onFormChanged,
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El campo Nombre es obligatorio';
                    } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return 'Solo se permiten letras y espacios';
                    } else if (value.length < 2 || value.length > 50) {
                      return 'El nombre debe tener entre 2 y 50 caracteres';
                    }
                    return null;
                  },
                  onSaved: (value) => nombre = value!,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _correoController,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El campo Correo es obligatorio';
                    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Ingrese un correo válido';
                    }
                    return null;
                  },
                  onSaved: (value) => correo = value!,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _direccionController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El campo Dirección es obligatorio';
                    } else if (value.length < 5 || value.length > 100) {
                      return 'La dirección debe tener entre 5 y 100 caracteres';
                    }
                    return null;
                  },
                  onSaved: (value) => direccion = value!,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _fechaNacimientoController,
                  decoration: InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    hintText: 'DD/MM/YYYY',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El campo Fecha de Nacimiento es obligatorio';
                    }
                    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                      return 'Ingrese una fecha en el formato DD/MM/YYYY';
                    }
                    DateTime currentDate = DateTime.now();
                    DateTime inputDate = DateTime.parse(
                      '${value.substring(6)}-${value.substring(3, 5)}-${value.substring(0, 2)}',
                    );
                    if (inputDate.isAfter(currentDate)) {
                      return 'La fecha debe ser pasada';
                    }
                    return null;
                  },
                  onSaved: (value) => fechaNacimiento = value!,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _celularController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Número de Celular',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El campo Celular es obligatorio';
                    } else if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                      return 'Ingrese un celular válido (10-15 dígitos)';
                    }
                    return null;
                  },
                  onSaved: (value) => celular = value!,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _contrasenaController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El campo Contraseña es obligatorio';
                    } else if (value.length < 8) {
                      return 'La contraseña debe tener al menos 8 caracteres';
                    } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[.,\/!@#\$%^&*()\-_=+{}|;:<>?\[\]])[A-Za-z\d.,\/!@#\$%^&*()\-_=+{}|;:<>?\[\]]{8,}$').hasMatch(value)) {
                      return 'Debe incluir mayúscula, minúscula, número y carácter especial válido (.,/!@#\$%^&*()...)';
                    }
                    return null;
                  },
                  onSaved: (value) => _contrasenaController.text = value!,
                ),

                SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRegistrarButtonEnabled ? Color(0xFF1A5DD9) : Colors.grey,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  onPressed: _isRegistrarButtonEnabled
                      ? () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      _guardarUsuario();
                    }
                  }
                      : null,
                  child: Text('Registrar Usuario', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isObtenerDesdeApiButtonDisabled ? Colors.grey : Color(0xFF1A5DD9),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  onPressed: _isObtenerDesdeApiButtonDisabled ? null : _obtenerDesdeApi,
                  child: Text('Obtener Desde API', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
