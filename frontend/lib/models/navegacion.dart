class Navegacion {
  final String nombre;
  final double lat;
  final double lon;

  const Navegacion({
    required this.nombre,
    required this.lat,
    required this.lon,
  });

  factory Navegacion.fromJson(Map<String, dynamic> json) => Navegacion(
        nombre: json['nombre'] as String,
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        'lat': lat,
        'lon': lon,
      };
}
