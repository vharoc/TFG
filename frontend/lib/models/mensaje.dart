import 'package:cloud_firestore/cloud_firestore.dart';

enum MensajeTipo { 
  texto, 
  imagen, 
}
enum MensajeRole{
  usario,
  bot,
}

class Mensaje {
  final String id;
  final String chatId;
  final String? contenido;
  final String? imgUrl;
  final MensajeTipo tipo;
  final MensajeRole role;
  final DateTime fecha;

  const Mensaje({
    required this.id,
    required this.chatId,
    this.contenido,
    this.imgUrl,
    required this.tipo,
    required this.role,
    required this.fecha,
  }): assert(
    // si es un texto o imagen no pueden ser null
    tipo == MensajeTipo.texto && contenido != null || tipo == MensajeTipo.imagen && imgUrl != null,
  );

  factory Mensaje.fromMap(Map<String, dynamic> map, String id){
    return Mensaje(
      id: id,
      chatId: map['chatId'] ?? '',
      contenido: map['contenido'],
      imgUrl: map['imgUrl'],
      tipo: MensajeTipo.values.firstWhere(
        (e) => e.name == (map['tipo'] ?? 'texto'),
        orElse: () => MensajeTipo.texto,
      ),
      role: MensajeRole.values.firstWhere(
        (e) => e.name == (map['role'] ?? 'usuario'),
        orElse: () => MensajeRole.usario,
      ),
      fecha: (map['fecha'] as Timestamp).toDate(),
    );
  }

  factory Mensaje.fromFirestore(DocumentSnapshot doc) {
    return Mensaje.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Map<String, dynamic> toMap(){
    return {
      'chatId': chatId,
      'contenido': contenido,
      'imgUrl': imgUrl,
      'tipo': tipo.name,
      'role': role.name,
      'fecha': Timestamp.fromDate(fecha),
    };
  }

  Mensaje copyWith({
    String? chatId,
    String? contenido,
    String? imgUrl,
    MensajeTipo? tipo,
    MensajeRole? role,
    DateTime? fecha,
  }) {
    return Mensaje(
      id: id,
      chatId: chatId ?? this.chatId,
      contenido: contenido ?? this.contenido,
      imgUrl: imgUrl ?? this.imgUrl,
      tipo: tipo ?? this.tipo,
      role: role ?? this.role,
      fecha: fecha ?? this.fecha,
    );
  }

  // contructores para hacer Mensaje.texto o Mensaje.imagen
  factory Mensaje.texto({
    required String id,
    required String chatId,
    required String contenido,
    required MensajeRole role,
    required DateTime fecha,
  }) {
    return Mensaje(
      id: id,
      chatId: chatId,
      contenido: contenido,
      tipo: MensajeTipo.texto,
      role: role,
      fecha: fecha,
    );
  }
 
  factory Mensaje.imagen({
    required String id,
    required String chatId,
    required String imgUrl,
    required MensajeRole role,
    required DateTime fecha,
  }) {
    return Mensaje(
      id: id,
      chatId: chatId,
      imgUrl: imgUrl,
      tipo: MensajeTipo.imagen,
      role: role,
      fecha: fecha,
    );
  }

}