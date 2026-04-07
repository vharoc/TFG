import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConversacionMeta {
  final String id;
  final String titulo;
  final DateTime fecha;

  const ConversacionMeta({
    required this.id,
    required this.titulo,
    required this.fecha,
  });

  factory ConversacionMeta.fromDoc(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;
    return ConversacionMeta(
      id: doc.id, 
      titulo: data['titulo'] as String? ?? 'Sin titulo', 
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }

}


class ChatService {

  ChatService._();

  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _chatsRef => _db.collection('users').doc(_uid).collection('chats');

  Stream<List<ConversacionMeta>> get chatsStream => _chatsRef
      .orderBy('fecha', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(ConversacionMeta.fromDoc).toList());

  // -- Crear conversación --
  Future<String> crearConversacion({required String titulo}) async {
    final doc = await _chatsRef.add({
      'titulo': titulo,
      'fecha': FieldValue.serverTimestamp(),
      'uid': _uid,
    });
    return doc.id;
  }
 
  // -- Actualizar título si luego se quiere cambiar --
  Future<void> actualizarTitulo({
    required String chatId,
    required String nuevoTitulo,
  }) async {
    await _chatsRef.doc(chatId).update({'titulo': nuevoTitulo});
  }
 
  // -- Eliminar conversación --
  Future<void> eliminarConversacion(String chatId) async {
    await _chatsRef.doc(chatId).delete();
  }
 
  // -- Eliminar TODOS los chats del usuario (pa borrar la cuenta) --
  Future<void> eliminarTodosLosChats() async {
    final snap = await _chatsRef.get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
  


}