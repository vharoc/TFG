import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class RegisterViewModel extends ChangeNotifier {

  AuthService get _authService => AuthService.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
  );

  String? validar(String email, String pswd, String nombre) {
    if (email.isEmpty || pswd.isEmpty || nombre.isEmpty) {
      return 'Rellena todos los campos';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Introduce un correo electrónico válido';
    }
    if (pswd.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(pswd)) {
      return 'La contraseña debe incluir al menos una mayúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(pswd)) {
      return 'La contraseña debe incluir al menos un número';
    }
    return null;
  }
  
  Future<bool> register({
    required String email,
    required String passwd,
    required String nombre,
  }) async {
    final validationError = validar(email, passwd, nombre);
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return false;
    }
 
    _loading = true;
    _error = null;
    notifyListeners();
 
    try {
      await _authService.createAccount(
        email: email,
        passwd: passwd,
      );
      await _authService.updateUsername(username: nombre);
      await _authService.sendEmailVerification();

      return true;
    } on FirebaseAuthException catch (e) {
      _error = _parseError(e);
      return false;
    } catch (e) {
      _error = 'Error: inténtalo de nuevo';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
 
  String _parseError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'El email ya está registrado',
      'invalid-email' => 'Formato del email no válido',
      'weak-password' => 'Contraseña demasiado débil',
      'too-many-requests' => 'Demasiados intentos, espera unos minutos',
      _ => 'Error: inténtalo de nuevo',
    };
  }

}