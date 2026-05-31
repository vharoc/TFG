import 'package:cloud_firestore/cloud_firestore.dart';
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

  Stream<Set<String>> visitadosStream() =>
      _ref.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());

  Future<void> marcarVisitado(String poiId, String nombre) =>
      _ref.doc(poiId).set({
        'nombre': nombre,
        'visitadoEn': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
