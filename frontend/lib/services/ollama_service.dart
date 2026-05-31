import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../models/clasificacion_result.dart';
import '../models/mensaje.dart';
import '../models/poi_sugerido.dart';
import '../models/ruta_result.dart';

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

  static List<Uri> _rutaUris() {
    final base = _normalizedBase;
    if (base.endsWith('/api')) {
      final rootBase = base.substring(0, base.length - 4);
      return [Uri.parse('$base/ruta'), Uri.parse('$rootBase/ruta')];
    }
    return [Uri.parse('$base/ruta'), Uri.parse('$base/api/ruta')];
  }

  static List<Uri> _monumentosUris() {
    final base = _normalizedBase;
    if (base.endsWith('/api')) {
      final rootBase = base.substring(0, base.length - 4);
      return [Uri.parse('$base/monumentos'), Uri.parse('$rootBase/monumentos')];
    }
    return [Uri.parse('$base/monumentos'), Uri.parse('$base/api/monumentos')];
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

  static Future<({String response, String? monumentoId, List<PoiSugerido> poisCercanos})> query(
    String prompt, {
    String system = '',
    String ciudad = '',
    List<Mensaje> history = const [],
    String? monumentoId,
    String modo = 'rapido',
    http.Client? client,
  }) async {
    Exception? lastError;
    final ownClient = client == null;
    final c = client ?? http.Client();

    try {
      for (final uri in _queryUris()) {
        try {
          final response = await c
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'prompt': prompt,
                  'system': system,
                  'ciudad': ciudad,
                  'history': _convertirHistorial(history),
                  'monumento_id': monumentoId,
                  'modo': modo,
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
          final mId = data['monumento_id'] as String?;
          final pois = (data['pois_cercanos'] as List<dynamic>? ?? [])
              .map((e) => PoiSugerido.fromMap(e as Map<String, dynamic>))
              .toList();

          return (response: respuesta, monumentoId: mId, poisCercanos: pois);
        } on TimeoutException {
          throw Exception('El servidor tardo demasiado en responder.');
        } on FormatException {
          rethrow;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
        }
      }
    } finally {
      if (ownClient) c.close();
    }

    throw lastError ?? Exception('No se pudo contactar con el servidor.');
  }

  static Future<ClasificacionResult> classify(
    File imagen, {
    String modo = 'rapido',
    http.Client? client,
  }) async {
    Exception? lastError;
    final ownClient = client == null;
    final c = client ?? http.Client();

    try {
      for (final uri in _classifyUris()) {
        try {
          final request = http.MultipartRequest('POST', uri)
            ..files.add(await http.MultipartFile.fromPath('imagen', imagen.path))
            ..fields['modo'] = modo;

          final streamed = await c.send(request).timeout(const Duration(seconds: 60));
          final body = await streamed.stream.bytesToString();

          if (streamed.statusCode == 404) {
            lastError = Exception('Endpoint no encontrado: $uri');
            continue;
          }

          if (streamed.statusCode != 200) {
            throw Exception('Error ${streamed.statusCode}: $body');
          }

          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['clase'] is! String || (data['clase'] as String).isEmpty) {
            throw const FormatException('Respuesta de clasificación vacía.');
          }
          return ClasificacionResult.fromJson(data);
        } on TimeoutException {
          throw Exception('El servidor tardó demasiado en responder.');
        } on FormatException {
          rethrow;
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
        }
      }
    } finally {
      if (ownClient) c.close();
    }

    throw lastError ?? Exception('No se pudo contactar con el servidor.');
  }

  static Future<RutaResult> ruta({
    required double lat,
    required double lon,
    required String filtro,
    required List<String> visitados,
  }) async {
    Exception? lastError;
    final c = http.Client();
    try {
      for (final uri in _rutaUris()) {
        try {
          final response = await c
              .post(
                uri,
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'lat': lat,
                  'lon': lon,
                  'filtro': filtro,
                  'visitados': visitados,
                }),
              )
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 404) {
            lastError = Exception('Endpoint no encontrado: $uri');
            continue;
          }
          if (response.statusCode != 200) {
            throw Exception('Error ${response.statusCode}: ${response.body}');
          }
          return RutaResult.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
        } on TimeoutException {
          throw Exception('El servidor tardó demasiado en responder.');
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
        }
      }
    } finally {
      c.close();
    }
    throw lastError ?? Exception('No se pudo contactar con el servidor.');
  }

  static Future<List<PoiSugerido>> monumentos() async {
    Exception? lastError;
    final c = http.Client();
    try {
      for (final uri in _monumentosUris()) {
        try {
          final response = await c.get(uri).timeout(const Duration(seconds: 15));
          if (response.statusCode == 404) {
            lastError = Exception('Endpoint no encontrado: $uri');
            continue;
          }
          if (response.statusCode != 200) {
            throw Exception('Error ${response.statusCode}');
          }
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return (data['monumentos'] as List<dynamic>)
              .map((e) => PoiSugerido.fromMap(e as Map<String, dynamic>))
              .toList();
        } on TimeoutException {
          throw Exception('Timeout al cargar monumentos.');
        } catch (e) {
          lastError = e is Exception ? e : Exception(e.toString());
        }
      }
    } finally {
      c.close();
    }
    throw lastError ?? Exception('No se pudo contactar con el servidor.');
  }
}
