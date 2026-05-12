class PoiSugerido {
  final String id;
  final String nombre;

  const PoiSugerido({required this.id, required this.nombre});

  factory PoiSugerido.fromMap(Map<String, dynamic> map) =>
      PoiSugerido(id: map['id'] as String, nombre: map['nombre'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre};
}
