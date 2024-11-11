import 'package:actividad_menu/factura_screen.dart';
import 'package:actividad_menu/listado_screen.dart';
import 'package:actividad_menu/login_screen.dart';
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
  final String loggedInUserEmail;
  final bool fromLogin;

  CreacionCuentaScreen({required this.loggedInUserEmail, this.fromLogin = false});

  @override
  _CreacionCuentaScreenState createState() => _CreacionCuentaScreenState();
}

class _CreacionCuentaScreenState extends State<CreacionCuentaScreen> {

  final FocusNode _nombreFocusNode = FocusNode();
  final FocusNode _correoFocusNode = FocusNode();
  final FocusNode _direccionFocusNode = FocusNode();
  final FocusNode _fechaNacimientoFocusNode = FocusNode();
  final FocusNode _celularFocusNode = FocusNode();
  final FocusNode _contrasenaFocusNode = FocusNode();

  bool _hasInteractedNombre = false;
  bool _hasInteractedCorreo = false;
  bool _hasInteractedDireccion = false;
  bool _hasInteractedFechaNacimiento = false;
  bool _hasInteractedCelular = false;
  bool _hasInteractedContrasena = false;
  bool _hasInteractedConfirmacionContrasena = false;

  final _formKey = GlobalKey<FormState>();
  late Database database;
  bool _isDatabaseInitialized = false;
  bool _isObtenerDesdeApiButtonDisabled = false;
  bool _isRegistrarButtonEnabled = false;
  bool _isConfirmPasswordVisible = false;
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
  final TextEditingController _confirmacionContrasenaController = TextEditingController();

  bool _validateForm() {
    return _nombreController.text.isNotEmpty &&
        _correoController.text.isNotEmpty &&
        _direccionController.text.isNotEmpty &&
        _fechaNacimientoController.text.isNotEmpty &&
        _celularController.text.isNotEmpty &&
        _contrasenaController.text.isNotEmpty &&
        (widget.fromLogin ? _confirmacionContrasenaController.text.isNotEmpty &&
            _confirmacionContrasenaController.text == _contrasenaController.text : true) &&
        _formKey.currentState?.validate() == true;
  }

  @override
  void initState() {
    super.initState();
    _initDatabase();

    _nombreFocusNode.addListener(() {
      if (!_nombreFocusNode.hasFocus && _nombreController.text.isEmpty) {
        setState(() {
          _hasInteractedNombre = true;
        });
      }
    });

    _correoFocusNode.addListener(() {
      if (!_correoFocusNode.hasFocus && _correoController.text.isEmpty) {
        setState(() {
          _hasInteractedCorreo = true;
        });
      }
    });

    _direccionFocusNode.addListener(() {
      if (!_direccionFocusNode.hasFocus && _direccionController.text.isEmpty) {
        setState(() {
          _hasInteractedDireccion = true;
        });
      }
    });

    _fechaNacimientoFocusNode.addListener(() {
      if (!_fechaNacimientoFocusNode.hasFocus && _fechaNacimientoController.text.isEmpty) {
        setState(() {
          _hasInteractedFechaNacimiento = true;
        });
      }
    });

    _celularFocusNode.addListener(() {
      if (!_celularFocusNode.hasFocus && _celularController.text.isEmpty) {
        setState(() {
          _hasInteractedCelular = true;
        });
      }
    });

    _contrasenaFocusNode.addListener(() {
      if (!_contrasenaFocusNode.hasFocus && _contrasenaController.text.isEmpty) {
        setState(() {
          _hasInteractedContrasena = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nombreFocusNode.dispose();
    _correoFocusNode.dispose();
    _direccionFocusNode.dispose();
    _fechaNacimientoFocusNode.dispose();
    _celularFocusNode.dispose();
    _contrasenaFocusNode.dispose();

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
      nombre = _nombreController.text;
      correo = _correoController.text;
      direccion = _direccionController.text;
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

      if (widget.loggedInUserEmail.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
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
          _hasInteractedContrasena = true;

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
        leading: widget.fromLogin
            ? IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        )
            : Builder(
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
      drawer: widget.fromLogin
          ? null
          : Drawer(
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
                  focusNode: _nombreFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hasInteractedNombre = true;
                      _isRegistrarButtonEnabled = _validateForm();
                    });
                  },
                  validator: (value) {
                    if (_hasInteractedNombre && (value == null || value.isEmpty)) {
                      return 'El campo Nombre es obligatorio';
                    } else if (value != null && !RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
                      return 'Solo se permiten letras y espacios';
                    } else if (value != null && (value.length < 2 || value.length > 50)) {
                      return 'El nombre debe tener entre 2 y 50 caracteres';
                    }
                    return null;
                  },
                  onSaved: (value) => nombre = value ?? '',
                  onFieldSubmitted: (value) {
                    setState(() {
                      _hasInteractedNombre = true;
                    });
                  },
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _correoController,
                  focusNode: _correoFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hasInteractedCorreo = true;
                      _isRegistrarButtonEnabled = _validateForm();

                    });
                  },
                  validator: (value) {
                    if (_hasInteractedCorreo) {
                      if (value == null || value.isEmpty) {
                        return 'El campo Correo es obligatorio';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Formato de correo electrónico no válido';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _direccionController,
                  focusNode: _direccionFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hasInteractedDireccion = true;
                      _isRegistrarButtonEnabled = _validateForm();

                    });
                  },
                  validator: (value) {
                    if (_hasInteractedDireccion) {
                      if (value == null || value.isEmpty) {
                        return 'El campo Dirección es obligatorio';
                      } else if (value.length < 5 || value.length > 100) {
                        return 'La dirección debe tener entre 5 y 100 caracteres';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _fechaNacimientoController,
                  focusNode: _fechaNacimientoFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    hintText: 'DD/MM/YYYY',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _hasInteractedFechaNacimiento = true;
                      _isRegistrarButtonEnabled = _validateForm();

                    });
                  },
                  validator: (value) {
                    if (_hasInteractedFechaNacimiento) {
                      if (value == null || value.isEmpty) {
                        return 'El campo Fecha de Nacimiento es obligatorio';
                      } else if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) {
                        final dateParts = value.split('/');
                        final inputDate = DateTime(
                          int.parse(dateParts[2]),
                          int.parse(dateParts[1]),
                          int.parse(dateParts[0]),
                        );
                        if (inputDate.isAfter(DateTime.now())) {
                          return 'Debe ser una fecha pasada';
                        }
                      } else {
                        return 'Formato de fecha inválido (DD/MM/YYYY)';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _celularController,
                  focusNode: _celularFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Número de Celular',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _hasInteractedCelular = true;
                      _isRegistrarButtonEnabled = _validateForm();

                    });
                  },
                  validator: (value) {
                    if (_hasInteractedCelular) {
                      if (value == null || value.isEmpty) {
                        return 'El campo Celular es obligatorio';
                      } else if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                        return 'El número debe tener entre 10 y 15 dígitos';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                TextFormField(
                  controller: _contrasenaController,
                  focusNode: _contrasenaFocusNode,
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
                  onChanged: (value) {
                    setState(() {
                      _hasInteractedContrasena = true;
                      _isRegistrarButtonEnabled = _validateForm();

                    });
                  },
                  validator: (value) {
                    if (_hasInteractedContrasena) {
                      if (value == null || value.isEmpty) {
                        return 'El campo Contraseña es obligatorio';
                      } else if (value.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      } else if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$').hasMatch(value)) {
                        return 'Debe incluir mayúscula, minúscula, número y carácter especial';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                if (widget.fromLogin)
                  TextFormField(
                    controller: _confirmacionContrasenaController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    onChanged: (value) {
                      setState(() {
                        _hasInteractedConfirmacionContrasena = true;
                        _isRegistrarButtonEnabled = _validateForm();
                      });
                    },
                    validator: (value) {
                      if (_hasInteractedConfirmacionContrasena) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma tu contraseña';
                        } else if (value != _contrasenaController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                      }
                      return null;
                    },
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

                if (!widget.fromLogin) // Solo muestra el botón si no se accede desde el login
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