import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/ciudad_visitada.dart';
import 'auth_services.dart';

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
      _db.collection('cities');

  // Sin orderBy en el query (evita índice compuesto); se ordena en cliente.
  Stream<List<CiudadVisitada>> get ciudadesStream => _ciudadesRef
      .where('userId', isEqualTo: _uid)
      .snapshots()
      .map((snap) {
        final lista = snap.docs.map(CiudadVisitada.fromFirestore).toList();
        lista.sort((a, b) => b.visitadaEn.compareTo(a.visitadaEn));
        return lista;
      });

  // ID determinista → idempotente y sin índices compuestos
  Future<void> registrarCiudad(String nombre) async {
    final docId = '${_uid}_${nombre.toLowerCase().replaceAll(' ', '_')}';
    await _ciudadesRef.doc(docId).set({
      'userId': _uid,
      'nombre': nombre,
      'visitadaEn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> eliminarCiudad(String ciudadId) async {
    await _ciudadesRef.doc(ciudadId).delete();
  }
}
