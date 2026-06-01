import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/poi_visitado.dart';
import 'auth_services.dart';

class PoiVisitadoService {
  PoiVisitadoService._();
  static final instance = PoiVisitadoService._();

  CollectionReference<Map<String, dynamic>> get _ref {
    final uid = AuthService.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('visited_pois');
  }

  // Ordenado en cliente por fecha descendente: el más reciente primero.
  Stream<List<PoiVisitado>> visitadosStream() => _ref.snapshots().map((snap) {
        final lista = snap.docs.map(PoiVisitado.fromFirestore).toList();
        lista.sort((a, b) => b.visitadoEn.compareTo(a.visitadoEn));
        return lista;
      });

  Future<void> marcarVisitado(String poiId, String nombre) =>
      _ref.doc(poiId).set({
        'nombre': nombre,
        'visitadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> desmarcarVisitado(String poiId) => _ref.doc(poiId).delete();
}
