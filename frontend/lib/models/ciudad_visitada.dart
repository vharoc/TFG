import 'package:cloud_firestore/cloud_firestore.dart';

class CiudadVisitada {
  final String id;
  final String userId;
  final String nombre;
  final DateTime visitadaEn;

  CiudadVisitada({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.visitadaEn,
  });

  factory CiudadVisitada.fromMap(Map<String, dynamic> map, String id) {
    return CiudadVisitada(
      id: id,
      userId: map['userId'] ?? '',
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
      'userId': userId,
      'nombre': nombre,
      'visitadaEn': Timestamp.fromDate(visitadaEn),
    };
  }

  CiudadVisitada copyWith({
    String? userId,
    String? nombre,
    DateTime? visitadaEn,
  }) {
    return CiudadVisitada(
      id: id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      visitadaEn: visitadaEn ?? this.visitadaEn,
    );
  }
}
