import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/ciudad.dart';
import '../services/auth_services.dart';
import '../services/chat_services.dart';
import '../services/ciudad_services.dart';

class LateralViewModel extends ChangeNotifier {
  final _auth = AuthService.instance;

  List<Chat> chats = [];
  List<Ciudad> ciudades = [];
  bool cargandoChats = true;
  bool cargandoCiudades = true;
  String? error;

  StreamSubscription<List<Chat>>? _chatSub;
  StreamSubscription<List<Ciudad>>? _ciudadSub;

  LateralViewModel() {
    _suscribir();
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
    super.dispose();
  }
}
