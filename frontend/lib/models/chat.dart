import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String userId;
  final String titulo;
  final String ciudad;
  final DateTime fechaCreacion;

  Chat({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.ciudad,
    required this.fechaCreacion,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      id: id,
      userId: map['userId'] ?? '',
      titulo: map['titulo'] ?? '',
      ciudad: map['ciudad'] ?? '',
      // serverTimestamp() puede ser null en el snapshot local hasta que el
      // servidor lo confirma: en ese caso usamos la hora actual.
      fechaCreacion: (map['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    return Chat.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'titulo': titulo,
      'ciudad': ciudad,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  Chat copyWith({
    String? userId,
    String? titulo,
    String? ciudad,
    DateTime? fechaCreacion,
  }) {
    return Chat(
      id: id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      ciudad: ciudad ?? this.ciudad,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
