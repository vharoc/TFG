import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';
import '../services/chat_services.dart';

class PerfilViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService();

  User? get user => _auth.currentUser;

  String get displayName =>
      user?.displayName?.isNotEmpty == true ? user!.displayName! : 'Usuario';

  String get email => user?.email ?? '';

  String get inicial {
    if (user?.displayName?.isNotEmpty == true) {
      return user!.displayName![0].toUpperCase();
    }
    if (user?.email?.isNotEmpty == true) {
      return user!.email![0].toUpperCase();
    }
    return '?';
  }

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  /// Reautentica y elimina la cuenta junto con todos sus chats.
  Future<bool> eliminarCuenta(String passwd) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.reauthenticate(email: email, passwd: passwd);

      try {
        await ChatService.instance.eliminarTodosLosChats();
      } on Exception {
        // Si falla al borrar chats, continuamos igual con el borrado de cuenta.
      }

      await _auth.deleteCurrentUser();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mensajeError(e.code);
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  String _mensajeError(String code) {
    return switch (code) {
      'wrong-password' || 'invalid-credential' => 'Contraseña incorrecta.',
      'too-many-requests' => 'Demasiados intentos. Prueba más tarde.',
      _ => 'Error al eliminar la cuenta. Inténtalo de nuevo.',
    };
  }
}