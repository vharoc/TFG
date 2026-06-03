import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat.dart';
import '../models/poi_visitado.dart';
import 'auth_services.dart';

class ProgresoCiudad {
  final String nombre;
  final String ciudadId;
  final int capturados;
  final int total;
  final List<PoiVisitado> pois;

  const ProgresoCiudad({
    required this.nombre,
    required this.ciudadId,
    required this.capturados,
    required this.total,
    this.pois = const [],
  });

  double get fraccion => total == 0 ? 0 : capturados / total;
}

class Estadisticas {
  final int totalChats;
  final int totalMensajes;
  final double mediaMensajesPorChat;
  final int ciudadesVisitadas;
  final int poisCapturados;
  final List<ProgresoCiudad> progresoPorCiudad;
  final List<Chat> chats;

  const Estadisticas({
    required this.totalChats,
    required this.totalMensajes,
    required this.mediaMensajesPorChat,
    required this.ciudadesVisitadas,
    required this.poisCapturados,
    required this.progresoPorCiudad,
    this.chats = const [],
  });

  const Estadisticas.vacias()
      : totalChats = 0,
        totalMensajes = 0,
        mediaMensajesPorChat = 0,
        ciudadesVisitadas = 0,
        poisCapturados = 0,
        progresoPorCiudad = const [],
        chats = const [];
}

class EstadisticasService {
  EstadisticasService._();
  static final EstadisticasService instance = EstadisticasService._();

  final _db = FirebaseFirestore.instance;

  String get _uid {
    final user = AuthService.instance.currentUser;
    if (user == null) throw StateError('No hay usuario autenticado.');
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(_uid);

  Future<int> _contar(Query<Map<String, dynamic>> q) async {
    final snap = await q.count().get();
    return snap.count ?? 0;
  }

  Future<Estadisticas> calcular() async {
    final chatsRef = _userRef.collection('chats');
    final chatsSnap = await chatsRef.get();

    final chats = chatsSnap.docs
        .map((d) => Chat.fromFirestore(d))
        .toList()
      ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    // Mensajes: count por chat (evita descargar todos los mensajes)
    int totalMensajes = 0;
    for (final chat in chatsSnap.docs) {
      totalMensajes += await _contar(chat.reference.collection('mensajes'));
    }

    // POIs y progreso por ciudad — descargamos los docs para mostrarlos
    int pois = 0;
    final progreso = <ProgresoCiudad>[];
    final ciudadesSnap = await _userRef.collection('ciudades_visitadas').get();
    for (final ciudad in ciudadesSnap.docs) {
      final poisSnap = await ciudad.reference.collection('pois').get();
      final poisList = poisSnap.docs
          .map((d) => PoiVisitado.fromFirestore(d))
          .toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      final capturados = poisList.where((p) => p.visitado).length;
      pois += capturados;
      progreso.add(ProgresoCiudad(
        nombre: (ciudad.data()['nombre'] as String?) ?? ciudad.id,
        ciudadId: ciudad.id,
        capturados: capturados,
        total: poisList.length,
        pois: poisList,
      ));
    }
    progreso.sort((a, b) => b.fraccion.compareTo(a.fraccion));

    return Estadisticas(
      totalChats: chats.length,
      totalMensajes: totalMensajes,
      mediaMensajesPorChat:
          chats.isEmpty ? 0 : totalMensajes / chats.length,
      ciudadesVisitadas: ciudadesSnap.docs.length,
      poisCapturados: pois,
      progresoPorCiudad: progreso,
      chats: chats,
    );
  }
}
