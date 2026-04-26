import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class OllamaService {
  OllamaService._();

  static const String _baseUrl = String.fromEnvironment(
    'OLLAMA_API_BASE_URL',
    defaultValue: 'http://212.128.144.8:8000/api',
  );

  static List<Uri> _queryUris() {
    final normalizedBase = _baseUrl.trim().replaceFirst(RegExp(r'/$'), '');
    if (normalizedBase.endsWith('/api')) {
      final rootBase = normalizedBase.substring(0, normalizedBase.length - 4);
      return [Uri.parse('$normalizedBase/query'), Uri.parse('$rootBase/query')];
    }

    return [
      Uri.parse('$normalizedBase/query'),
      Uri.parse('$normalizedBase/api/query'),
    ];
  }

  static Future<String> query(String prompt, {String system = ''}) async {
    Exception? lastError;

    for (final uri in _queryUris()) {
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'prompt': prompt, 'system': system}),
            )
            .timeout(const Duration(seconds: 270));

        if (response.statusCode == 404) {
          lastError = Exception('Endpoint no encontrado: $uri');
          continue;
        }

        if (response.statusCode != 200) {
          throw Exception('Error ${response.statusCode}: ${response.body}');
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = data['response'] ?? data['respuesta'];
        final respuesta = raw is String ? raw.trim() : null;
        if (respuesta == null || respuesta.isEmpty) {
          throw const FormatException('Respuesta vacia del servidor.');
        }

        return respuesta;
      } on TimeoutException {
        throw Exception('El servidor tardo demasiado en responder.');
      } on FormatException {
        rethrow;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw lastError ?? Exception('No se pudo contactar con el servidor.');
  }
}
