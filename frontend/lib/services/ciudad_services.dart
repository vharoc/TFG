import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ciudad.dart';
import 'auth_services.dart';

class CiudadServices {
  CiudadServices._();

  static final CiudadServices instance = CiudadServices._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final user = AuthService.instance.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _ciudadesRef =>
      _db.collection('cities');

  // -- Stream de ciudades del usuario --
  Stream<List<Ciudad>> get ciudadesStream => _ciudadesRef
      .where('userId', isEqualTo: _uid)
      .orderBy('visitadaEn', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Ciudad.fromFirestore).toList());

  // -- Añadir ciudad visitada (solo si no existe ya para este usuario) --
  Future<void> registrarCiudad(String nombre) async {
    final snap = await _ciudadesRef
        .where('userId', isEqualTo: _uid)
        .where('nombre', isEqualTo: nombre)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) {
      await _ciudadesRef.add({
        'userId': _uid,
        'nombre': nombre,
        'visitadaEn': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> crearCiudad(Ciudad ciudad) async {
    await _ciudadesRef.add(ciudad.toMap());
  }

  // -- Eliminar ciudad --
  Future<void> eliminarCiudad(String ciudadId) async {
    await _ciudadesRef.doc(ciudadId).delete();
  }
}