import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/poi_sugerido.dart';

class MonumentoService {
  MonumentoService._();
  static final MonumentoService instance = MonumentoService._();

  final _db = FirebaseFirestore.instance;

  // Cache en memoria por ciudad: el catálogo es estático, no merece la pena
  // pegar a Firestore cada vez que se abre el sheet de POIs de una ciudad.
  final Map<String, List<PoiSugerido>> _cache = {};

  CollectionReference<Map<String, dynamic>> _itemsRef(String ciudadId) =>
      _db.collection('monumentos').doc(ciudadId).collection('items');

  Future<List<PoiSugerido>> porCiudad(String ciudad) async {
    final id = _ciudadId(ciudad);
    final cached = _cache[id];
    if (cached != null) return cached;

    final snap = await _itemsRef(id).orderBy('nombre').get();
    final lista = snap.docs
        .map((d) => PoiSugerido(
              id: d.id,
              nombre: (d.data()['nombre'] as String?) ?? d.id,
            ))
        .toList();
    _cache[id] = lista;
    return lista;
  }

  // Normaliza el nombre de ciudad → id (igual que en el backend y en CiudadVisitadaService).
  String _ciudadId(String ciudad) =>
      ciudad.trim().toLowerCase().replaceAll(' ', '_');
}
