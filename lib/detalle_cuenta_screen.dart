import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class DetalleCuentaScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final Database database;

  DetalleCuentaScreen({required this.usuario, required this.database});

  Future<void> _eliminarUsuario(BuildContext context) async {
    bool confirmarEliminacion = await _mostrarDialogoConfirmacion(context);

    if (confirmarEliminacion) {
      await database.delete('usuarios', where: 'id = ?', whereArgs: [usuario['id']]);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario eliminado con éxito')),
      );

      Navigator.pop(context, true);
    }
  }

  Future<bool> _mostrarDialogoConfirmacion(BuildContext context) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmación'),
          content: Text('¿Estás seguro de que deseas eliminar esta cuenta?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle Cuenta', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1A5DD9),
        centerTitle: true,
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
            Text('Nombre:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(usuario['nombre'] ?? 'No disponible', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Correo Electrónico:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(usuario['correo'] ?? 'No disponible', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Dirección:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(usuario['direccion'] ?? 'No disponible', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Fecha Nacimiento:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(usuario['fechaNacimiento'] ?? 'No disponible', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Contraseña:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(usuario['contrasena'] ?? 'No disponible', style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),

            Center(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    shadowColor: Colors.black,
                    elevation: 5,
                  ),
                  onPressed: () => _eliminarUsuario(context),
                  child: Text(
                    'Eliminar Cuenta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
