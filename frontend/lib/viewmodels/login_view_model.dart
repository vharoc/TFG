import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_services.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<bool> login({required String email, required String passwd}) async {
    final cleanEmail = email.trim();
    final cleanPasswd = passwd.trim();

    if (cleanEmail.isEmpty || cleanPasswd.isEmpty) {
      _error = 'Rellena todos los campos';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signIn(email: cleanEmail, passwd: cleanPasswd);
      return true;
    } catch (e) {
      _error = _parseError(e);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _parseError(Object e) {
    if (e is FirebaseAuthException) {
      return switch (e.code) {
        'user-not-found' => 'No existe usuario asociado al correo',
        'wrong-password' => 'Contraseña incorrecta',
        'invalid-email' => 'Formato de email no válido',
        'invalid-credential' => 'Email o contraseña incorrectos',
        'too-many-requests' => 'Demasiados intentos, espera unos minutos',
        _ => 'Error inesperado, inténtalo de nuevo',
      };
    }
    return 'Error, inténtalo de nuevo';
  }
}
