import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/ciudad_visitada.dart';
import '../models/poi_visitado.dart';
import '../services/auth_services.dart';
import '../services/chat_services.dart';
import '../services/ciudad_visitada_service.dart';

class LateralViewModel extends ChangeNotifier {
  final _auth = AuthService.instance;

  List<Chat> chats = [];
  List<CiudadVisitada> ciudades = [];
  bool cargandoChats = true;
  bool cargandoCiudades = true;
  String? error;

  // POIs (con flag visitado) de la ciudad cuyo sheet está abierto.
  List<PoiVisitado> _pois = [];
  List<PoiVisitado> get pois => List.unmodifiable(_pois);
  bool cargandoPois = false;
  String? _ciudadAbierta;

  StreamSubscription<List<Chat>>? _chatSub;
  StreamSubscription<List<CiudadVisitada>>? _ciudadSub;
  StreamSubscription<List<PoiVisitado>>? _poisSub;

  LateralViewModel() {
    _suscribir();
  }

  // Suscribe al stream de POIs de la ciudad cuyo sheet se abre.
  void cargarPois(String ciudad) {
    if (_ciudadAbierta == ciudad) return;
    _ciudadAbierta = ciudad;
    _pois = [];
    cargandoPois = true;
    notifyListeners();

    _poisSub?.cancel();
    _poisSub = CiudadVisitadaService.instance.poisStream(ciudad).listen((lista) {
      _pois = lista;
      cargandoPois = false;
      notifyListeners();
    }, onError: (_) {
      cargandoPois = false;
      notifyListeners();
    });
  }

  String get inicial {
    final user = _auth.currentUser;
    if (user?.displayName?.isNotEmpty == true) return user!.displayName![0].toUpperCase();
    if (user?.email?.isNotEmpty == true) return user!.email![0].toUpperCase();
    return '?';
  }

  String get nombre =>
      _auth.currentUser?.displayName ?? _auth.currentUser?.email ?? 'Usuario';

  void _suscribir() {
    try {
      _chatSub = ChatService.instance.chatsStream.listen(
        (data) {
          chats = data;
          cargandoChats = false;
          notifyListeners();
        },
        onError: (Object e, StackTrace st) {
          cargandoChats = false;
          error = 'No se pudo cargar el historial de chats.';
          notifyListeners();
        },
      );

      _ciudadSub = CiudadVisitadaService.instance.ciudadesStream.listen(
        (data) {
          ciudades = data;
          cargandoCiudades = false;
          notifyListeners();
        },
        onError: (Object e, StackTrace st) {
          cargandoCiudades = false;
          error = 'No se pudieron cargar las ciudades visitadas.';
          notifyListeners();
        },
      );
    } on StateError {
      cargandoChats = false;
      cargandoCiudades = false;
      error = 'Debes iniciar sesión para ver esta pantalla.';
      notifyListeners();
    }
  }

  Future<void> eliminarChat(String id) async {
    await ChatService.instance.eliminarConversacion(id);
  }

  Future<void> eliminarCiudadVisitada(String id) async {
    await CiudadVisitadaService.instance.eliminarCiudad(id);
  }

  Future<void> desmarcarPoi(String ciudad, String poiId) async {
    await CiudadVisitadaService.instance.desmarcarVisitado(ciudad, poiId);
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _ciudadSub?.cancel();
    _poisSub?.cancel();
    super.dispose();
  }
}
