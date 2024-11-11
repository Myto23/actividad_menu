import 'package:flutter/material.dart';

class RutInputScreen extends StatefulWidget {
  final Function(String) onRutSubmitted;

  RutInputScreen({required this.onRutSubmitted});

  @override
  _RutInputScreenState createState() => _RutInputScreenState();
}

class _RutInputScreenState extends State<RutInputScreen> {
  final TextEditingController _rutController = TextEditingController();
  bool _isRutValid = false;

  void _addDigit(String digit) {
    setState(() {
      _rutController.text += digit;
      _validateRut();
    });
  }
  void _clearLastDigit() {
    setState(() {
      if (_rutController.text.isNotEmpty) {
        _rutController.text = _rutController.text.substring(0, _rutController.text.length - 1);
        _validateRut();
      }
    });
  }
  void _clearRut() {
    setState(() {
      _rutController.clear();
      _isRutValid = false;
    });
  }

  void _validateRut() {
    String rut = _rutController.text.replaceAll('.', '').replaceAll('-', '');
    if (rut.length < 2) {
      _isRutValid = false;
      return;
    }

    String body = rut.substring(0, rut.length - 1);
    String dv = rut.substring(rut.length - 1).toUpperCase();
    String calculatedDv = _calculateCheckDigit(body);

    setState(() {
      _isRutValid = (dv == calculatedDv);
    });
  }

  String _calculateCheckDigit(String rutBody) {
    int sum = 0;
    int factor = 2;

    for (int i = rutBody.length - 1; i >= 0; i--) {
      sum += int.parse(rutBody[i]) * factor;
      factor = factor < 7 ? factor + 1 : 2;
    }

    int remainder = sum % 11;
    String dv;

    if (remainder == 0) {
      dv = '0';
    } else if (remainder == 1) {
      dv = 'K';
    } else {
      dv = (11 - remainder).toString();
    }
    return dv;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Digitar RUT',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFF1A5DD9),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            TextField(
              controller: _rutController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'RUT',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
                prefixIcon: _isRutValid
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
                suffixIcon: IconButton(
                  icon: Image.asset(
                    'assets/images/arrow_icon.png',
                    width: 24,
                    height: 24,
                    color: Colors.grey,
                  ),
                  onPressed: _clearLastDigit,
                ),
              ),
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 1.7,
              children: List.generate(12, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: ElevatedButton(
                    onPressed: index < 9
                        ? () => _addDigit('${index + 1}')
                        : index == 9
                        ? () => _addDigit('0')
                        : index == 10
                        ? () => _addDigit('K')
                        : _clearRut,
                    child: index < 9
                        ? Text('${index + 1}', style: TextStyle(fontSize: 22, color: Colors.white))
                        : index == 9
                        ? Text('0', style: TextStyle(fontSize: 22, color: Colors.white))
                        : index == 10
                        ? Text('K', style: TextStyle(fontSize: 22, color: Colors.white))
                        : Text('BORRAR', style: TextStyle(fontSize: 22, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: index == 11 ? Colors.red : Color(0xFF4EB0F6),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRutValid ? () {
                String rut = _rutController.text;
                if (rut.isNotEmpty) {
                  widget.onRutSubmitted(rut);
                  Navigator.pop(context);
                }
              } : null,
              child: Text('Aceptar', style: TextStyle(color: Colors.white, fontSize: 20)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A5DD9),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
