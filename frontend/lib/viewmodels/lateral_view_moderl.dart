// lib/viewmodels/lateral_view_model.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/ciudad.dart';
import '../services/chat_services.dart';
import '../services/ciudad_services.dart';

class LateralViewModel extends ChangeNotifier {
  List<Chat> chats = [];
  List<Ciudad> ciudades = [];
  bool cargandoChats = false;
  bool cargandoCiudades = false;

  StreamSubscription<List<Chat>>? _chatSub;
  StreamSubscription<List<Ciudad>>? _ciudadSub;

  LateralViewModel() {
    _suscribir();
  }

  void _suscribir() {
    cargandoChats = true;
    cargandoCiudades = true;

    _chatSub = ChatService.instance.chatsStream.listen((data) {
      chats = data;
      cargandoChats = false;
      notifyListeners();
    });

    _ciudadSub = CiudadServices.instance.ciudadesStream.listen((data) {
      ciudades = data;
      cargandoCiudades = false;
      notifyListeners();
    });
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