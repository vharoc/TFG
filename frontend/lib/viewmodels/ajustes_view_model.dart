import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';

class AjustesViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService.instance;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  /// Cierra la sesión del usuario actual.
  Future<bool> cerrarSesion() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.signOut();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = 'Error al cerrar sesión: ${e.message}';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}