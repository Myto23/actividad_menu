import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'main.dart';
import 'creacion_cuenta_screen.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late Database database;
  TextEditingController _correoController = TextEditingController();
  TextEditingController _contrasenaController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'usuarios.db');

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
  }

  Future<void> _ingresar(BuildContext context) async {
    String correo = _correoController.text;
    String contrasena = _contrasenaController.text;

    List<Map<String, dynamic>> result = await database.query(
      'usuarios',
      where: 'correo = ?',
      whereArgs: [correo],
    );

    if (result.isNotEmpty) {
      String contrasenaGuardada = result[0]['contrasena'];
      String userName = result[0]['nombre'];

      if (contrasena == contrasenaGuardada) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userName', userName);
        await prefs.setString('email', correo);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(loggedInUserEmail: correo),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Contraseña incorrecta'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Usuario no encontrado'),
      ));
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facturacion.cl', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1A5DD9),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person, size: 28, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _correoController,
                    decoration: InputDecoration(
                      labelText: 'Usuario',
                      labelStyle: TextStyle(fontSize: 16, color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key, size: 26, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _contrasenaController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Clave',
                      labelStyle: TextStyle(fontSize: 16, color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _ingresar(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A5DD9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: Text(
                  'Ingresar',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreacionCuentaScreen(
                      loggedInUserEmail: '',
                      fromLogin: true,
                    ),
                  ),
                );
              },
              child: Text(
                "¿No tienes cuenta? Crea una aquí",
                style: TextStyle(color: Color(0xFF1A5DD9), fontSize: 16),
              ),
            ),
            Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
