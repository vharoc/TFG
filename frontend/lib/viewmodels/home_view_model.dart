import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/mensaje.dart';
import '../services/chat_services.dart';

class HomeViewModel extends ChangeNotifier {
  List<Mensaje> _messages = [];
  List<Mensaje> get messages => List.unmodifiable(_messages);

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

    // Solo mostrar loading si no tenemos mensajes aún
    if (_messages.isEmpty) {
      cargando = true;
      notifyListeners();
    }

    _sub?.cancel();
    _sub = ChatService.instance.mensajesStream(chatId!).listen(
      (mensajes) {
        _messages = List.of(mensajes);
        cargando = false;
        notifyListeners();
      },
      onError: (_) {
        cargando = false;
        notifyListeners();
      },
    );
  }

  Future<void> cambiarChat(String? nuevoChatId) async {
    if (chatId == nuevoChatId) return;
    _sub?.cancel();
    chatId = nuevoChatId;
    _messages = [];
    cargando = false;
    notifyListeners();

    if (nuevoChatId != null) {
      _suscribir();
    }
  }

  Future<void> enviarTexto(String texto) async {
    final textoTrimmed = texto.trim();
    if (textoTrimmed.isEmpty) return;

    await _crearChatSiNecesario(textoTrimmed);
    if (chatId == null) return;

    await ChatService.instance.guardarMensaje(
      chatId: chatId!,
      mensaje: Mensaje.texto(
        id: '',
        chatId: chatId!,
        contenido: textoTrimmed,
        role: MensajeRole.usuario,
        fecha: DateTime.now(),
      ),
    );
  }

  Future<void> enviarImagen(XFile img) async {
    await _crearChatSiNecesario('[Imagen]');
    if (chatId == null) return;

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
    } catch (_) {
      // Si falla la creación, chatId sigue null
    } finally {
      _creandoChat = false;
    }
  }

  void nuevaConversacion() {
    _sub?.cancel();
    chatId = null;
    _messages = [];
    cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}