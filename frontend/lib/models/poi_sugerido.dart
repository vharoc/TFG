class PoiSugerido {
  final String id;
  final String nombre;
  // Si true, el chip es una pregunta sobre el monumento actual (modo ruta);
  // si false, es un monumento cercano al que navegar (modo normal).
  final bool esPregunta;

  const PoiSugerido({
    required this.id,
    required this.nombre,
    this.esPregunta = false,
  });

  factory PoiSugerido.fromMap(Map<String, dynamic> map) => PoiSugerido(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        esPregunta: map['esPregunta'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'esPregunta': esPregunta,
      };
}
