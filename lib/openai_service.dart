import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> generateInvoiceDescription(List<Map<String, dynamic>> items, double totalConImpuesto) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    String prompt = "Genera una factura detallada para los siguientes productos:\n";

    double subtotal = 0;

    for (var item in items) {
      double itemTotal = item['precio'] * item['cantidad'];
      subtotal += itemTotal;
      prompt += "${item['producto']} - ${item['cantidad']} unidades a \$${item['precio']} cada una (Total: \$${itemTotal}).\n";
    }

    double impuesto = totalConImpuesto - subtotal;
    prompt += "\nResumen:\n";
    prompt += "Subtotal: \$${subtotal.toStringAsFixed(0)}\n";
    prompt += "Impuesto: \$${impuesto.toStringAsFixed(0)}\n";
    prompt += "Total con impuesto: \$${totalConImpuesto.toStringAsFixed(0)}\n";

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content': 'Eres un asistente útil que ayuda a generar descripciones de facturas.',
          },
          {
            'role': 'user',
            'content': prompt,
          },
        ],
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception('Error al generar descripción con IA: ${response.body}');
    }
  }
}
