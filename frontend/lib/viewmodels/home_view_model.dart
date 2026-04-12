import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mensaje.dart';
import '../services/chat_services.dart';

class HomeViewModel extends ChangeNotifier {
  final List<Mensaje> messages = [];
 
  String? chatId;
  bool cargando = false;
 
  StreamSubscription<List<Mensaje>>? _sub;
  bool _creandoChat = false;
 
  HomeViewModel({String? initialChatId}) {
    if (initialChatId != null) {
      chatId = initialChatId;
      _suscribir();
    }
  }
 
  void _suscribir() {
    if (chatId == null) return;
 
    cargando = true;
    notifyListeners();
 
    _sub?.cancel();
    _sub = ChatService.instance.mensajesStream(chatId!).listen((mensajes) {
      messages
        ..clear()
        ..addAll(mensajes);
      cargando = false;
      notifyListeners();
    });
  }
 
  Future<void> cambiarChat(String? nuevoChatId) async {
    _sub?.cancel();
    chatId = nuevoChatId;
    messages.clear();
    notifyListeners();
 
    if (nuevoChatId != null) {
      chatId = nuevoChatId;
      _suscribir();
    }
  }
 
  Future<void> enviarTexto(String texto) async {
    await _crearChatSiNecesario(texto);
    await ChatService.instance.guardarMensaje(
      chatId: chatId!,
      mensaje: Mensaje.texto(
        id: '',
        chatId: chatId!,
        contenido: texto,
        role: MensajeRole.usuario,
        fecha: DateTime.now(),
      ),
    );
  }
 
  Future<void> enviarImagen(XFile img) async {
    await _crearChatSiNecesario('[Imagen]');
    await ChatService.instance.guardarMensaje(
      chatId: chatId!,
      mensaje: Mensaje.imagen(
        id: '',
        chatId: chatId!,
        imgUrl: img.path,
        role: MensajeRole.usuario,
        fecha: DateTime.now(),
      ),
    );
  }
 
  Future<void> _crearChatSiNecesario(String primerTexto) async {
    if (chatId != null || _creandoChat) return;
    _creandoChat = true;
    try {
      final titulo = primerTexto.length > 40
          ? '${primerTexto.substring(0, 40)}...'
          : primerTexto;
      final id = await ChatService.instance.crearConversacion(titulo: titulo);
      chatId = id;
      _suscribir();
    } finally {
      _creandoChat = false;
    }
  }
 
  void nuevaConversacion() {
    _sub?.cancel();
    chatId = null;
    messages.clear();
    notifyListeners();
  }
 
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}