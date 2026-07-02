import 'package:cloud_firestore/cloud_firestore.dart';

class PoiVisitado {
  final String id;
  final String nombre;
  final bool visitado;
  final DateTime? visitadoEn;

  PoiVisitado({
    required this.id,
    required this.nombre,
    required this.visitado,
    this.visitadoEn,
  });

  factory PoiVisitado.fromMap(Map<String, dynamic> map, String id) {
    return PoiVisitado(
      id: id,
      nombre: map['nombre'] ?? '',
      visitado: map['visitado'] as bool? ?? false,
      // Los no visitados no tienen fecha.
      visitadoEn: (map['visitadoEn'] as Timestamp?)?.toDate(),
    );
  }

  factory PoiVisitado.fromFirestore(DocumentSnapshot doc) {
    return PoiVisitado.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'visitado': visitado,
      if (visitadoEn != null) 'visitadoEn': Timestamp.fromDate(visitadoEn!),
    };
  }

  PoiVisitado copyWith({String? nombre, bool? visitado, DateTime? visitadoEn}) {
    return PoiVisitado(
      id: id,
      nombre: nombre ?? this.nombre,
      visitado: visitado ?? this.visitado,
      visitadoEn: visitadoEn ?? this.visitadoEn,
    );
  }
}
