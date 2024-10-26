import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class EmailService {
  final String apiKey = dotenv.env['SENDGRID_API_KEY'] ?? '';

  Future<void> sendInvoiceByEmail(String email, File pdfInvoice) async {
    print("Enviando correo a: $email");

    final response = await http.post(
      Uri.parse('https://api.sendgrid.com/v3/mail/send'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "personalizations": [
          {
            "to": [{"email": email}],
            "subject": "Tu Factura de Facturacion.cl"
          }
        ],
        "from": {"email": "jeremiascampos2010@hotmail.com"},
        "content": [
          {
            "type": "text/plain",
            "value": "Adjunto encontrarás tu factura en formato PDF."
          }
        ],
        "attachments": [
          {
            "content": base64Encode(pdfInvoice.readAsBytesSync()),
            "filename": "factura.pdf",
            "type": "application/pdf",
            "disposition": "attachment"
          }
        ]
      }),
    );

    if (response.statusCode == 202) {
      print("Correo enviado exitosamente.");
    } else {
      print("Error al enviar correo: ${response.body}");
    }
  }
}
