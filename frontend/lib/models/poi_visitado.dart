import 'package:cloud_firestore/cloud_firestore.dart';

class PoiVisitado {
  final String id;
  final String nombre;
  final DateTime visitadoEn;

  PoiVisitado({
    required this.id,
    required this.nombre,
    required this.visitadoEn,
  });

  factory PoiVisitado.fromMap(Map<String, dynamic> map, String id) {
    return PoiVisitado(
      id: id,
      nombre: map['nombre'] ?? '',
      // serverTimestamp() puede ser null en el snapshot local hasta que el
      // servidor lo confirma: en ese caso usamos la hora actual.
      visitadoEn: (map['visitadoEn'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory PoiVisitado.fromFirestore(DocumentSnapshot doc) {
    return PoiVisitado.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'visitadoEn': Timestamp.fromDate(visitadoEn),
    };
  }

  PoiVisitado copyWith({
    String? nombre,
    DateTime? visitadoEn,
  }) {
    return PoiVisitado(
      id: id,
      nombre: nombre ?? this.nombre,
      visitadoEn: visitadoEn ?? this.visitadoEn,
    );
  }
}
