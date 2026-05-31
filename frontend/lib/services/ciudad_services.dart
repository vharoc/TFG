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
  // Sin orderBy en el query (evita índice compuesto); se ordena en cliente.
  Stream<List<Ciudad>> get ciudadesStream => _ciudadesRef
      .where('userId', isEqualTo: _uid)
      .snapshots()
      .map((snap) {
        final lista = snap.docs.map(Ciudad.fromFirestore).toList();
        lista.sort((a, b) => b.visitadaEn.compareTo(a.visitadaEn));
        return lista;
      });

  // -- Añadir ciudad visitada (solo si no existe ya para este usuario) --
  // ID determinista → no necesita query compuesta ni índice, es idempotente
  Future<void> registrarCiudad(String nombre) async {
    final docId = '${_uid}_${nombre.toLowerCase().replaceAll(' ', '_')}';
    await _ciudadesRef.doc(docId).set({
      'userId': _uid,
      'nombre': nombre,
      'visitadaEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> crearCiudad(Ciudad ciudad) async {
    await _ciudadesRef.add(ciudad.toMap());
  }

  // -- Eliminar ciudad --
  Future<void> eliminarCiudad(String ciudadId) async {
    await _ciudadesRef.doc(ciudadId).delete();
  }
}