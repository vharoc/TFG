import 'package:cloud_firestore/cloud_firestore.dart';

enum MensajeTipo { 
  texto, 
  imagen, 
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
  final DateTime fecha;
  final bool esUsuario;

  const Mensaje({
    required this.id,
    required this.tipo,
    required this.contenido,
    required this.fecha,
    required this.esUsuario
  });

  factory Mensaje.fromDoc(DocumentSnapshot doc){
    final d = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
    final rawFecha = d['fecha'];
    return Mensaje(
      id: doc.id,
      tipo: d['tipo'] == 'imagen' ? MensajeTipo.imagen : MensajeTipo.texto,
      contenido: d['contenido'] as String? ?? '', 
      fecha: rawFecha is Timestamp ? rawFecha.toDate() : DateTime.now(),
      esUsuario: d['esUsuario'] as bool? ?? true,
    ); 
  }

  Map<String, dynamic> toMap() => {
    'tipo': tipo == MensajeTipo.imagen? 'imagen' : 'texto',
    'contenido': contenido,
    'fecha': FieldValue.serverTimestamp(),
    'esUsuario': esUsuario,
  };

}