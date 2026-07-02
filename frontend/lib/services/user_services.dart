import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserServices {
  UserServices._();
  static final UserServices instance = UserServices._();

  final _firestore = FirebaseFirestore.instance;

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

  Future<void> actualizarNombre({
    required String id,
    required String nombre,
  }) async {
    await _firestore.collection('users').doc(id).set({
      'nombre': nombre,
    }, SetOptions(merge: true));
  }

  /// Llamar antes de deleteCurrentUser en el flujo de borrado de cuenta.
  Future<void> eliminarUsuario(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);
    await userRef.collection('uso').doc('diario').delete();
    await userRef.delete();
  }
  
}
