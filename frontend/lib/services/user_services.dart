import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class UserServices {
  final _firestore = FirebaseFirestore.instance;

  Future<void> crearUsuario(Usuario usuario) async {
    await _firestore.collection('users').doc(usuario.id).set(usuario.toMap());
  }

  Future<Usuario?> obtenerUsuario(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if(!doc.exists) return null;
    return Usuario.fromFirestore(doc);
  }
  
}