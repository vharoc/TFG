import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_services.dart';
import '../services/ubicacion_service.dart';

class AjustesViewModel extends ChangeNotifier {
  final AuthService _auth = AuthService.instance;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  bool _ubicacionActiva = false;
  bool get ubicacionActiva => _ubicacionActiva;

  bool _camaraActiva = false;
  bool get camaraActiva => _camaraActiva;

  bool _albumActivo = false;
  bool get albumActivo => _albumActivo;

  AjustesViewModel() {
    _cargarEstadoPermisos();
  }

  Future<void> _cargarEstadoPermisos() async {
    try {
      final estadoUbicacion = await UbicacionService.instance.verificarPermiso();
      _ubicacionActiva = estadoUbicacion == EstadoPermiso.concedido;
      _camaraActiva = await Permission.camera.isGranted;
      _albumActivo = await Permission.photos.isGranted;
    } catch (_) {
      // mantener los valores actuales si falla la consulta
    } finally {
      notifyListeners();
    }
  }

  Future<void> recargarUbicacion() => _cargarEstadoPermisos();

  Future<EstadoPermiso> activarUbicacion() async {
    final estado = await UbicacionService.instance.solicitarPermiso();
    _ubicacionActiva = estado == EstadoPermiso.concedido;
    notifyListeners();
    return estado;
  }

  Future<bool> activarCamara() async {
    final status = await Permission.camera.request();
    _camaraActiva = status.isGranted;
    notifyListeners();
    return status.isGranted;
  }

  Future<bool> camaraPermanentementeDenegada() async =>
      await Permission.camera.isPermanentlyDenied;

  Future<bool> activarAlbum() async {
    final status = await Permission.photos.request();
    _albumActivo = status.isGranted;
    notifyListeners();
    return status.isGranted;
  }

  Future<bool> albumPermanentementeDenegado() async =>
      await Permission.photos.isPermanentlyDenied;

  Future<void> abrirAjustesApp() => openAppSettings();

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
