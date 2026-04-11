import 'package:cloud_firestore/cloud_firestore.dart';


class Ciudad{

  final String id;
  final String userId;
  final String nombre;
  final DateTime visitadaEn;

  Ciudad({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.visitadaEn,
  });

  factory Ciudad.fromMap(Map<String, dynamic> map, String id) {
    return Ciudad(
      id: id,
      userId: map['userId'] ?? '',
      nombre: map['nombre'] ?? '',
      visitadaEn: (map['visitadaEn'] as Timestamp).toDate(),
    );
  }
 
  factory Ciudad.fromFirestore(DocumentSnapshot doc) {
    return Ciudad.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
 
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombre': nombre,
      'visitadaEn': Timestamp.fromDate(visitadaEn),
    };
  }
 
  Ciudad copyWith({
    String? userId,
    String? nombre,
    DateTime? visitadaEn,
  }) {
    return Ciudad(
      id: id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      visitadaEn: visitadaEn ?? this.visitadaEn,
    );
  }


}