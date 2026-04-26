import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat.dart';
import '../models/mensaje.dart';
import '../services/chat_services.dart';
import '../services/ollama_service.dart';

class HomeViewModel extends ChangeNotifier {
  List<Mensaje> _messages = [];
  List<Mensaje> get messages => List.unmodifiable(_messages);

  String _tituloChat = '';
  String get tituloChat => _tituloChat;

  String? chatId;
  bool cargando = false;

  StreamSubscription<List<Mensaje>>? _sub;
  StreamSubscription<Chat?>? _chatSub;
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
    _chatSub?.cancel();

    _chatSub = ChatService.instance.chatStream(chatId!).listen((chat) {
      final nuevoTitulo = (chat?.titulo ?? '').trim();
      if (_tituloChat != nuevoTitulo) {
        _tituloChat = nuevoTitulo;
        notifyListeners();
      }
    });

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
    _chatSub?.cancel();
    chatId = nuevoChatId;
    _messages = [];
    _tituloChat = '';
    cargando = false;
    notifyListeners();

    if (nuevoChatId != null) {
      _suscribir();
    }
  }

  Future<void> enviarTexto(String texto) async {
    final textoTrimmed = texto.trim();
    if (textoTrimmed.isEmpty) return;

    await _crearChatSiNecesario();
    if (chatId == null) return;

    final chatIdActual = chatId!;

    await ChatService.instance.guardarMensaje(
      chatId: chatIdActual,
      mensaje: Mensaje.texto(
        id: '',
        chatId: chatIdActual,
        contenido: textoTrimmed,
        role: MensajeRole.usuario,
        fecha: DateTime.now(),
      ),
    );

    await _actualizarTituloSiVacio(textoTrimmed);

    try {
      final respuesta = await OllamaService.query(textoTrimmed);
      await ChatService.instance.guardarMensaje(
        chatId: chatIdActual,
        mensaje: Mensaje.texto(
          id: '',
          chatId: chatIdActual,
          contenido: respuesta,
          role: MensajeRole.bot,
          fecha: DateTime.now(),
        ),
      );
    } catch (_) {
      await ChatService.instance.guardarMensaje(
        chatId: chatIdActual,
        mensaje: Mensaje.texto(
          id: '',
          chatId: chatIdActual,
          contenido:
              'No he podido conectarme al servidor en este momento. Intentalo de nuevo en unos segundos.',
          role: MensajeRole.bot,
          fecha: DateTime.now(),
        ),
      );
    }
  }

  Future<void> enviarImagen(XFile img) async {
    await _crearChatSiNecesario();
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

    await _actualizarTituloSiVacio('[Imagen]');
  }

  Future<void> _crearChatSiNecesario() async {
    if (chatId != null || _creandoChat) return;
    _creandoChat = true;
    try {
      final id = await ChatService.instance.crearConversacion(titulo: '');
      chatId = id;
      _suscribir();
    } catch (_) {
      // Si falla la creación, chatId sigue null
    } finally {
      _creandoChat = false;
    }
  }

  Future<void> _actualizarTituloSiVacio(String textoBase) async {
    if (chatId == null || _tituloChat.trim().isNotEmpty) return;
    final titulo = _construirTitulo(textoBase);
    _tituloChat = titulo;
    notifyListeners();

    try {
      await ChatService.instance.actualizarTitulo(
        chatId: chatId!,
        nuevoTitulo: titulo,
      );
    } catch (_) {
      // Si falla Firestore, mantenemos el título local para evitar parpadeos.
    }
  }

  String _construirTitulo(String texto) {
    final base = texto.trim();
    if (base.length <= 40) return base;
    return '${base.substring(0, 40)}...';
  }

  void nuevaConversacion() {
    _sub?.cancel();
    _chatSub?.cancel();
    chatId = null;
    _messages = [];
    _tituloChat = '';
    cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }
}