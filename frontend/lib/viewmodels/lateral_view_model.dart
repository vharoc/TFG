import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/ciudad.dart';
import '../models/poi_sugerido.dart';
import '../services/auth_services.dart';
import '../services/chat_services.dart';
import '../services/ciudad_services.dart';
import '../services/ollama_service.dart';
import '../services/poi_visitado_service.dart';

class LateralViewModel extends ChangeNotifier {
  final _auth = AuthService.instance;

  List<Chat> chats = [];
  List<Ciudad> ciudades = [];
  bool cargandoChats = true;
  bool cargandoCiudades = true;
  String? error;

  Set<String> _visitados = {};
  List<PoiSugerido> todosLosPois = [];
  bool cargandoPois = false;

  StreamSubscription<List<Chat>>? _chatSub;
  StreamSubscription<List<Ciudad>>? _ciudadSub;
  StreamSubscription<Set<String>>? _visitadosSub;

  LateralViewModel() {
    _suscribir();
    _visitadosSub = PoiVisitadoService.instance.visitadosStream().listen((ids) {
      _visitados = ids;
      notifyListeners();
    });
  }

  bool poiVisitado(String id) => _visitados.contains(id);

  Future<void> cargarPois(String ciudad) async {
    if (todosLosPois.isNotEmpty || cargandoPois) return;
    cargandoPois = true;
    notifyListeners();
    try {
      todosLosPois = await OllamaService.monumentos(ciudad: ciudad);
    } catch (_) {
      todosLosPois = [];
    } finally {
      cargandoPois = false;
      notifyListeners();
    }
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

      _ciudadSub = CiudadServices.instance.ciudadesStream.listen(
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

  @override
  void dispose() {
    _chatSub?.cancel();
    _ciudadSub?.cancel();
    _visitadosSub?.cancel();
    super.dispose();
  }
}
