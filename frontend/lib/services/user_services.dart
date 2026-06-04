import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario.dart';

class UserServices {
  UserServices._();
  static final UserServices instance = UserServices._();

  final _firestore = FirebaseFirestore.instance;

  Future<void> crearUsuario(Usuario usuario) async {
    await _firestore
        .collection('users')
        .doc(usuario.id)
        .set(usuario.toMap(), SetOptions(merge: true));
  }

  /// Crea el documento Firestore del usuario solo si todavía no existe.
  /// Llamar tras verificación de email (en HomeViewModel.init).
  Future<void> ensureUsuario(User authUser) async {
    final ref = _firestore.collection('users').doc(authUser.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'nombre': authUser.displayName ?? '',
        'email': authUser.email ?? '',
      });
    }
  }

  Future<Usuario?> obtenerUsuario(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if(!doc.exists) return null;
    return Usuario.fromFirestore(doc);
  }

  Future<void> actualizarNombre({
    required String id,
    required String nombre,
  }) async {
    await _firestore.collection('users').doc(id).set({
      'nombre': nombre,
    }, SetOptions(merge: true));
  }

  /// Borra el documento raíz del usuario y su subcolección de uso.
  /// Llamar antes de `deleteCurrentUser` en el flujo de borrado de cuenta.
  Future<void> eliminarUsuario(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    await userRef.collection('uso').doc('diario').delete();
    await userRef.delete();
  }
  
}
