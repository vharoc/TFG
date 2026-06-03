import 'poi_sugerido.dart';

class ClasificacionResult {
  final String clase;
  final String? id;
  final String nombre;
  final String? descripcionCorta;
  final List<PoiSugerido> poisCercanos;
  final double? lat;
  final double? lon;
  final int tokens;

  const ClasificacionResult({
    required this.clase,
    this.id,
    required this.nombre,
    this.descripcionCorta,
    required this.poisCercanos,
    this.lat,
    this.lon,
    this.tokens = 0,
  });

  factory ClasificacionResult.fromJson(Map<String, dynamic> json) {
    return ClasificacionResult(
      clase: json['clase'] as String,
      id: json['id'] as String?,
      nombre: (json['nombre'] as String?) ?? json['clase'] as String,
      descripcionCorta: json['descripcion_corta'] as String?,
      poisCercanos: (json['pois_cercanos'] as List<dynamic>? ?? [])
          .map((e) => PoiSugerido.fromMap(e as Map<String, dynamic>))
          .toList(),
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
    );
  }
}
