import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';
import '../services/chat_services.dart';
import '../services/ciudad_visitada_service.dart';
import '../services/user_services.dart';

class PerfilViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService.instance;
  final UserServices _users = UserServices.instance;

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

  /// Borra todos los chats y el progreso de ciudades sin eliminar la cuenta.
  Future<bool> borrarDatos() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      await ChatService.instance.eliminarTodosLosChats();
      await CiudadVisitadaService.instance.eliminarTodosDatos();
      return true;
    } catch (_) {
      _error = 'No se pudieron borrar los datos. Inténtalo de nuevo.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

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

  Future<bool> actualizarNombreUsuario(String nuevoNombre) async {
    final nombre = nuevoNombre.trim();
    if (nombre.isEmpty) {
      _error = 'El nombre de usuario no puede estar vacío.';
      notifyListeners();
      return false;
    }
    if (nombre.length < 3) {
      _error = 'El nombre de usuario debe tener al menos 3 caracteres.';
      notifyListeners();
      return false;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.updateUsername(username: nombre);

      final uid = user?.uid;
      if (uid != null) {
        await _users.actualizarNombre(id: uid, nombre: nombre);
      }

      await user?.reload();
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = switch (e.code) {
        'requires-recent-login' =>
          'Debes volver a iniciar sesión para actualizar el nombre.',
        _ => 'No se pudo actualizar el nombre. Inténtalo de nuevo.',
      };
      return false;
    } catch (_) {
      _error = 'No se pudo actualizar el nombre. Inténtalo de nuevo.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarContrasena({
    required String contrasenaActual,
    required String nuevaContrasena,
  }) async {
    final actual = contrasenaActual.trim();
    final nueva = nuevaContrasena.trim();

    if (actual.isEmpty || nueva.isEmpty) {
      _error = 'Completa ambos campos de contraseña.';
      notifyListeners();
      return false;
    }

    if (nueva.length < 8) {
      _error = 'La nueva contraseña debe tener al menos 8 caracteres.';
      notifyListeners();
      return false;
    }

    if (actual == nueva) {
      _error = 'La nueva contraseña debe ser distinta a la actual.';
      notifyListeners();
      return false;
    }

    final correo = email;
    if (correo.isEmpty) {
      _error = 'No se pudo obtener tu correo para cambiar la contraseña.';
      notifyListeners();
      return false;
    }

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.changePassword(
        currentPasswd: actual,
        newPasswd: nueva,
        email: correo,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = switch (e.code) {
        'wrong-password' || 'invalid-credential' =>
          'La contraseña actual es incorrecta.',
        'weak-password' => 'La nueva contraseña es demasiado débil.',
        'requires-recent-login' =>
          'Por seguridad, vuelve a iniciar sesión e inténtalo de nuevo.',
        'too-many-requests' =>
          'Demasiados intentos. Espera unos minutos e inténtalo otra vez.',
        _ => 'No se pudo cambiar la contraseña. Inténtalo de nuevo.',
      };
      return false;
    } catch (_) {
      _error = 'No se pudo cambiar la contraseña. Inténtalo de nuevo.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
