import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ciudad_visitada.dart';
import '../models/poi_sugerido.dart';
import '../models/poi_visitado.dart';
import 'auth_services.dart';

/// Estructura en Firestore:
///   users/{uid}/ciudades_visitadas/{ciudadId}
///       - nombre, visitadaEn
///       /pois/{poiId}
///           - nombre, visitado (bool), visitadoEn
class CiudadVisitadaService {
  CiudadVisitadaService._();
  static final CiudadVisitadaService instance = CiudadVisitadaService._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final user = AuthService.instance.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _ciudadesRef =>
      _db.collection('users').doc(_uid).collection('ciudades_visitadas');

  CollectionReference<Map<String, dynamic>> _poisRef(String ciudadId) =>
      _ciudadesRef.doc(ciudadId).collection('pois');

  String _ciudadId(String nombre) =>
      nombre.trim().toLowerCase().replaceAll(' ', '_');

  Stream<List<CiudadVisitada>> get ciudadesStream =>
      _ciudadesRef.snapshots().map((snap) {
        final lista = snap.docs.map(CiudadVisitada.fromFirestore).toList();
        lista.sort((a, b) => b.visitadaEn.compareTo(a.visitadaEn));
        return lista;
      });

  Stream<List<PoiVisitado>> poisStream(String nombreCiudad) =>
      _poisRef(_ciudadId(nombreCiudad)).snapshots().map((snap) {
        final lista = snap.docs.map(PoiVisitado.fromFirestore).toList();
        lista.sort((a, b) => a.nombre.compareTo(b.nombre));
        return lista;
      });

  /// Siembra el catálogo de la ciudad la primera vez; no pisa los POIs existentes.
  Future<void> sembrarCatalogo(String nombreCiudad, List<PoiSugerido> catalogo) async {
    final ciudadId = _ciudadId(nombreCiudad);
    await _ciudadesRef.doc(ciudadId).set({
      'nombre': nombreCiudad,
      'visitadaEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final existentes = await _poisRef(ciudadId).get();
    final idsExistentes = existentes.docs.map((d) => d.id).toSet();

    final batch = _db.batch();
    for (final poi in catalogo) {
      if (idsExistentes.contains(poi.id)) continue;
      batch.set(_poisRef(ciudadId).doc(poi.id), {
        'nombre': poi.nombre,
        'visitado': false,
      });
    }
    await batch.commit();
  }

  Future<void> marcarVisitado(String nombreCiudad, String poiId, String nombrePoi) {
    return _poisRef(_ciudadId(nombreCiudad)).doc(poiId).set({
      'nombre': nombrePoi,
      'visitado': true,
      'visitadoEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> desmarcarVisitado(String nombreCiudad, String poiId) {
    return _poisRef(_ciudadId(nombreCiudad)).doc(poiId).set({
      'visitado': false,
    }, SetOptions(merge: true));
  }

  Future<void> eliminarCiudad(String ciudadId) async {
    final pois = await _poisRef(ciudadId).get();
    final batch = _db.batch();
    for (final d in pois.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_ciudadesRef.doc(ciudadId));
    await batch.commit();
  }

  Future<void> eliminarTodosDatos() async {
    final ciudades = await _ciudadesRef.get();
    for (final ciudad in ciudades.docs) {
      await eliminarCiudad(ciudad.id);
    }
  }
}
