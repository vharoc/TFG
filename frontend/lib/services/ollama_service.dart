import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../models/mensaje.dart';

class OllamaService {
  OllamaService._();

  static const String _baseUrl = String.fromEnvironment(
    'OLLAMA_API_BASE_URL',
    defaultValue: 'http://212.128.144.8:8000/api',
  );

  static String get _normalizedBase =>
      _baseUrl.trim().replaceFirst(RegExp(r'/$'), '');

  static List<Uri> _queryUris() {
    final base = _normalizedBase;
    if (base.endsWith('/api')) {
      final rootBase = base.substring(0, base.length - 4);
      return [Uri.parse('$base/query'), Uri.parse('$rootBase/query')];
    }
    return [Uri.parse('$base/query'), Uri.parse('$base/api/query')];
  }

  static List<Uri> _classifyUris() {
    final base = _normalizedBase;
    if (base.endsWith('/api')) {
      final rootBase = base.substring(0, base.length - 4);
      return [Uri.parse('$base/classify'), Uri.parse('$rootBase/classify')];
    }
    return [Uri.parse('$base/classify'), Uri.parse('$base/api/classify')];
  }

  static List<Map<String, String>> _convertirHistorial(List<Mensaje> history) {
    return history
        .where((m) => m.tipo == MensajeTipo.texto && m.contenido != null)
        .map((m) => {
              'role': m.role == MensajeRole.usuario ? 'user' : 'assistant',
              'content': m.contenido!,
            })
        .toList();
  }

  static Future<String> query(
    String prompt, {
    String system = '',
    String ciudad = '',
    List<Mensaje> history = const [],
  }) async {
    Exception? lastError;

    for (final uri in _queryUris()) {
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'prompt': prompt,
                'system': system,
                'ciudad': ciudad,
                'history': _convertirHistorial(history),
              }),
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

  static Future<String> classify(File imagen) async {
    Exception? lastError;

    for (final uri in _classifyUris()) {
      try {
        final request = http.MultipartRequest('POST', uri)
          ..files.add(await http.MultipartFile.fromPath('imagen', imagen.path));

        final streamed = await request.send().timeout(const Duration(seconds: 60));
        final body = await streamed.stream.bytesToString();

        if (streamed.statusCode == 404) {
          lastError = Exception('Endpoint no encontrado: $uri');
          continue;
        }

        if (streamed.statusCode != 200) {
          throw Exception('Error ${streamed.statusCode}: $body');
        }

        final data = jsonDecode(body) as Map<String, dynamic>;
        final clase = data['clase'];
        if (clase is! String || clase.isEmpty) {
          throw const FormatException('Respuesta de clasificación vacía.');
        }
        return clase;
      } on TimeoutException {
        throw Exception('El servidor tardó demasiado en responder.');
      } on FormatException {
        rethrow;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    throw lastError ?? Exception('No se pudo contactar con el servidor.');
  }
}
