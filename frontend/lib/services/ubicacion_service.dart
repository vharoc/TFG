import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ciudad_soportada.dart';

enum EstadoPermiso {
  concedido,
  denegado,
  permanentementeDenegado,
  servicioDesactivado,
}

class UbicacionService {
  UbicacionService._();
  static final UbicacionService instance = UbicacionService._();

  final _db = FirebaseFirestore.instance;

  // Solo comprueba el estado actual sin mostrar ningún diálogo
  Future<EstadoPermiso> verificarPermiso() async {
    final servicio = await Geolocator.isLocationServiceEnabled();
    if (!servicio) return EstadoPermiso.servicioDesactivado;

    final permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.deniedForever) {
      return EstadoPermiso.permanentementeDenegado;
    }
    if (permiso == LocationPermission.whileInUse ||
        permiso == LocationPermission.always) {
      return EstadoPermiso.concedido;
    }
    return EstadoPermiso.denegado;
  }

  // Solicita el permiso si no se ha pedido antes y devuelve el estado resultante
  Future<EstadoPermiso> solicitarPermiso() async {
    final servicio = await Geolocator.isLocationServiceEnabled();
    if (!servicio) return EstadoPermiso.servicioDesactivado;

    LocationPermission permiso = await Geolocator.checkPermission();

    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (permiso == LocationPermission.deniedForever) {
      return EstadoPermiso.permanentementeDenegado;
    }

    if (permiso == LocationPermission.whileInUse ||
        permiso == LocationPermission.always) {
      return EstadoPermiso.concedido;
    }

    return EstadoPermiso.denegado;
  }

  Future<void> abrirAjustes() => Geolocator.openAppSettings();

  // Obtiene la posición actual del dispositivo
  Future<Position> obtenerPosicion() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  static const _ciudadesFallback = [
    CiudadSoportada(
      id: 'salamanca',
      nombre: 'Salamanca',
      lat: 40.9701,
      lng: -5.6635,
      radioKm: 15.0,
    ),
  ];

  // Carga todas las ciudades soportadas desde Firestore, con fallback local
  Future<List<CiudadSoportada>> cargarCiudadesSoportadas() async {
    try {
      final snap = await _db.collection('supported_cities').get();
      if (snap.docs.isEmpty) return _ciudadesFallback;
      return snap.docs.map(CiudadSoportada.fromFirestore).toList();
    } catch (_) {
      return _ciudadesFallback;
    }
  }

  // Devuelve la ciudad soportada en cuyo radio se encuentran las coordenadas,
  // o null si no hay ninguna dentro del rango.
  Future<CiudadSoportada?> detectarCiudad(double lat, double lng) async {
    final ciudades = await cargarCiudadesSoportadas();
    for (final ciudad in ciudades) {
      if (_distanciaKm(lat, lng, ciudad.lat, ciudad.lng) <= ciudad.radioKm) {
        return ciudad;
      }
    }
    return null;
  }

  // Comprueba si unas coordenadas siguen dentro del radio de una ciudad concreta
  bool dentroDeRadio(double lat, double lng, CiudadSoportada ciudad) {
    return _distanciaKm(lat, lng, ciudad.lat, ciudad.lng) <= ciudad.radioKm;
  }

  // Fórmula de Haversine — distancia en km entre dos puntos GPS
  double _distanciaKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double deg) => deg * pi / 180;
}
