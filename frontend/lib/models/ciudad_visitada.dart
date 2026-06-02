import 'package:cloud_firestore/cloud_firestore.dart';

class CiudadVisitada {
  final String id;
  final String nombre;
  final DateTime visitadaEn;

  CiudadVisitada({
    required this.id,
    required this.nombre,
    required this.visitadaEn,
  });

  factory CiudadVisitada.fromMap(Map<String, dynamic> map, String id) {
    return CiudadVisitada(
      id: id,
      nombre: map['nombre'] ?? '',
      // serverTimestamp() puede ser null en el snapshot local hasta que el
      // servidor lo confirma: en ese caso usamos la hora actual.
      visitadaEn: (map['visitadaEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory CiudadVisitada.fromFirestore(DocumentSnapshot doc) {
    return CiudadVisitada.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'visitadaEn': Timestamp.fromDate(visitadaEn),
    };
  }
}
