import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/mensaje.dart';

class ChatService {

  ChatService._();

  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No hay usuario autenticado para operar con chats.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _chatsRef => _db.collection('users').doc(_uid).collection('chats');
  CollectionReference<Map<String, dynamic>> _mensajesRef(String chatId) => _chatsRef.doc(chatId).collection('mensajes');

  Stream<List<Chat>> get chatsStream => _chatsRef
      .orderBy('fechaCreacion', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(Chat.fromFirestore).toList());

  // -- Stream de mensajes en tiempo real --
  Stream<List<Mensaje>> mensajesStream(String chatId) => _mensajesRef(chatId)
      .orderBy('fecha', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map(Mensaje.fromFirestore).toList());

  // -- Crear conversación --
  Future<String> crearConversacion({required String titulo}) async {
    final doc = await _chatsRef.add({
      'titulo': titulo,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'uid': _uid,
    });
    return doc.id;
  }

  // -- Guardar mensaje --
  Future<void> guardarMensaje({
    required String chatId,
    required Mensaje mensaje,
  }) async {
    await _mensajesRef(chatId).add(mensaje.toMap());
  }
 
  // -- Actualizar título --
  Future<void> actualizarTitulo({
    required String chatId,
    required String nuevoTitulo,
  }) async {
    await _chatsRef.doc(chatId).update({'titulo': nuevoTitulo});
  }
 
  // -- Eliminar conversación y sus mensajes --
  Future<void> eliminarConversacion(String chatId) async {
    final msgs = await _mensajesRef(chatId).get();
    final batch = _db.batch();
    for (final m in msgs.docs) {
      batch.delete(m.reference);
    }
    batch.delete(_chatsRef.doc(chatId));
    await batch.commit();
  }

  // -- Eliminar todos los chats (borrar cuenta) --
  Future<void> eliminarTodosLosChats() async {
    final snap = await _chatsRef.get();
    for (final doc in snap.docs) {
      await eliminarConversacion(doc.id);
    }
  }
}