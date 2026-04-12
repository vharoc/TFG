import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ciudad.dart';

class CiudadServices {
  CiudadServices._();

  static final CiudadServices instance = CiudadServices._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
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

  // -- Añadir ciudad visitada --
  Future<void> crearCiudad(Ciudad ciudad) async {
    await _ciudadesRef.add(ciudad.toMap());
  }

  // -- Eliminar ciudad --
  Future<void> eliminarCiudad(String ciudadId) async {
    await _ciudadesRef.doc(ciudadId).delete();
  }
}