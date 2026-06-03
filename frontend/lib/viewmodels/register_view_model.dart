import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_services.dart';
import '../services/user_services.dart';

class RegisterViewModel extends ChangeNotifier {

  final _authService = AuthService.instance;
  final _userService = UserServices.instance;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  String? validar(String email, String pswd, String nombre){
    if (email.isEmpty || pswd.isEmpty || nombre.isEmpty) {
      return 'Rellena todos los campos';
    }
    if (pswd.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
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
      final credenciales = await _authService.createAccount(
        email: email,
        passwd: passwd,
      );
      await _authService.updateUsername(username: nombre);
      await _authService.sendEmailVerification();

      final usuario = Usuario(
        id: credenciales.user!.uid,
        nombre: nombre,
        email: email,
      );
      await _userService.crearUsuario(usuario);

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