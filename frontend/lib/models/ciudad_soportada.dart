import 'package:cloud_firestore/cloud_firestore.dart';

class CiudadSoportada {
  final String id;
  final String nombre;
  final double lat;
  final double lng;
  final double radioKm;

  const CiudadSoportada({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lng,
    required this.radioKm,
  });

  factory CiudadSoportada.fromMap(Map<String, dynamic> map, String id) {
    return CiudadSoportada(
      id: id,
      nombre: map['nombre'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      radioKm: (map['radio_km'] as num).toDouble(),
    );
  }

  factory CiudadSoportada.fromFirestore(DocumentSnapshot doc) {
    return CiudadSoportada.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
