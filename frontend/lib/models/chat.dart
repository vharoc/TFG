import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String userId;
  final String titulo;
  final DateTime fechaCreacion;

  Chat({
    required this.id,
    required this.userId,
    required this.titulo,
    required this.fechaCreacion,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      id: id,
      userId: map['userId'] ?? map['uid'] ?? '',
      titulo: map['titulo'] ?? '',
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
    );
  }

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    return Chat.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'titulo': titulo,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  Chat copyWith({String? userId, String? titulo, DateTime? fechaCreacion}) {
    return Chat(
      id: id,
      userId: userId ?? this.userId,
      titulo: titulo ?? this.titulo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
