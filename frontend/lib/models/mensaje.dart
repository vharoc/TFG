import 'package:cloud_firestore/cloud_firestore.dart';

enum MensajeTipo { 
  texto, imagen 
}

/* Estructura Firestore:
    users/{uid}/chats/{chatId}/mensajes/{msgId}
     - tipo: String (texto o imagen)
     - contenido: String
     - fecha: Timestamp
     - esUsuario: bool
*/

class Mensaje {
  final String id;
  final MensajeTipo tipo;
  final String contenido;
  final Timestamp fecha;
  final bool esUsuario;

  const Mensaje({
    required this.id,
    required this.tipo,
    required this.contenido,
    required this.fecha,
    required this.esUsuario
  });

  factory Mensaje.fromDoc(DocumentSnapshot doc){
    final d = doc.data() as Map<String, dynamic>;
    return Mensaje(
      id: doc.id,
      tipo: d['tipo'] == 'imagen' ? MensajeTipo.imagen : MensajeTipo.texto,
      contenido: d['contenido'] as String ?? '', 
      fecha: (d['fecha'] as Timestamp).toDate(),
      esUsuario: d['esUsuario'] as bool ?? true,
    ); 
  }

  Map<String, dynamic> toMap() => {
    'tipo': tipo == MensajeTipo.imagen? 'imagen' : 'texto',
    'contenido': contenido,
    'fecha': FieldValue.serverTimestamp(),
    'esUsuario': esUsuario,
  };

}