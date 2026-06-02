import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_services.dart';

/// Estadísticas agregadas del usuario, calculadas directamente sobre Firestore
/// con aggregate queries (count) — no descargan los documentos, solo cuentan.
/// No dependen del backend: funcionan con solo tener conexión a Firebase.
/// Progreso de capturas en una ciudad concreta.
class ProgresoCiudad {
  final String nombre;
  final int capturados;
  final int total;

  const ProgresoCiudad({
    required this.nombre,
    required this.capturados,
    required this.total,
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

  const Estadisticas({
    required this.totalChats,
    required this.totalMensajes,
    required this.mediaMensajesPorChat,
    required this.ciudadesVisitadas,
    required this.poisCapturados,
    required this.progresoPorCiudad,
  });

  const Estadisticas.vacias()
      : totalChats = 0,
        totalMensajes = 0,
        mediaMensajesPorChat = 0,
        ciudadesVisitadas = 0,
        poisCapturados = 0,
        progresoPorCiudad = const [];
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
    final totalChats = chatsSnap.docs.length;

    // Mensajes: sumamos el count() de la subcolección de cada chat.
    int totalMensajes = 0;
    for (final chat in chatsSnap.docs) {
      totalMensajes += await _contar(chat.reference.collection('mensajes'));
    }

    // POIs capturados y progreso por ciudad en una sola pasada.
    int pois = 0;
    final progreso = <ProgresoCiudad>[];
    final ciudadesSnap = await _userRef.collection('ciudades_visitadas').get();
    for (final ciudad in ciudadesSnap.docs) {
      final poisRef = ciudad.reference.collection('pois');
      final capturados = await _contar(poisRef.where('visitado', isEqualTo: true));
      final total = await _contar(poisRef);
      pois += capturados;
      progreso.add(ProgresoCiudad(
        nombre: (ciudad.data()['nombre'] as String?) ?? ciudad.id,
        capturados: capturados,
        total: total,
      ));
    }
    progreso.sort((a, b) => b.fraccion.compareTo(a.fraccion));

    return Estadisticas(
      totalChats: totalChats,
      totalMensajes: totalMensajes,
      mediaMensajesPorChat: totalChats == 0 ? 0 : totalMensajes / totalChats,
      ciudadesVisitadas: ciudadesSnap.docs.length,
      poisCapturados: pois,
      progresoPorCiudad: progreso,
    );
  }
}
