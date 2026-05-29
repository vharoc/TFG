import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FotoService {
  FotoService._();
  static final FotoService instance = FotoService._();

  Future<String> subirFoto({
    required File file,
    required String uid,
    required String chatId,
    required DateTime fecha,
  }) async {
    final nombre = '${fecha.millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref('users/$uid/chats/$chatId/$nombre');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
