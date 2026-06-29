import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/mensaje.dart';
import 'auth_services.dart';
import 'imagen_local_service.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw StateError('No hay usuario autenticado para operar con chats.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _db.collection('users').doc(_uid).collection('chats');
  CollectionReference<Map<String, dynamic>> _mensajesRef(String chatId) =>
      _chatsRef.doc(chatId).collection('mensajes');

  Stream<Chat?> chatStream(String chatId) => _chatsRef
      .doc(chatId)
      .snapshots()
      .map((doc) => doc.exists ? Chat.fromFirestore(doc) : null);

  Stream<List<Chat>> get chatsStream => _chatsRef
      .orderBy('fechaCreacion', descending: true)
      .limit(20)
      .snapshots()
      .map((snap) => snap.docs.map(Chat.fromFirestore).toList());

  Stream<List<Mensaje>> mensajesStream(String chatId) => _mensajesRef(chatId)
      .orderBy('fecha', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map(Mensaje.fromFirestore).toList());

  Future<String> crearConversacion({
    required String titulo,
    required String ciudad,
  }) async {
    final id = '${_timestampPrefix()}_${_chatsRef.doc().id.substring(0, 6)}';
    await _chatsRef.doc(id).set({
      'titulo': titulo,
      'ciudad': ciudad,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'userId': _uid,
    });
    return id;
  }

  String _timestampPrefix() {
    final now = DateTime.now().toUtc();
    String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
    return '${p(now.year, 4)}${p(now.month)}${p(now.day)}'
        'T${p(now.hour)}${p(now.minute)}${p(now.second)}';
  }

  Future<void> guardarMensaje({
    required String chatId,
    required Mensaje mensaje,
  }) async {
    await _mensajesRef(chatId).add(mensaje.toMap());
  }

  Future<void> actualizarTitulo({
    required String chatId,
    required String nuevoTitulo,
  }) async {
    await _chatsRef.doc(chatId).update({'titulo': nuevoTitulo});
  }

  // GPS la detecta tras crear el chat.
  Future<void> actualizarCiudad({
    required String chatId,
    required String ciudad,
  }) async {
    await _chatsRef.doc(chatId).update({'ciudad': ciudad});
  }

  Future<void> eliminarConversacion(String chatId) async {
    final msgs = await _mensajesRef(chatId).get();

    for (final m in msgs.docs) {
      final data = m.data();
      if (data['tipo'] == 'imagen') {
        final url = data['imgUrl'] as String?;
        if (url != null && !url.startsWith('http')) {
          await ImagenLocalService.instance.borrar(url);
        }
      }
    }

    final batch = _db.batch();
    for (final m in msgs.docs) {
      batch.delete(m.reference);
    }
    batch.delete(_chatsRef.doc(chatId));
    await batch.commit();
  }

  Future<void> eliminarTodosLosChats() async {
    final snap = await _chatsRef.get();
    for (final doc in snap.docs) {
      await eliminarConversacion(doc.id);
    }
  }
}
