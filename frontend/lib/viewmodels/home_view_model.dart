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

  String? _chatId;
  String? get chatId => _chatId;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _ciudadActual;
  String? get ciudadActual => _ciudadActual;

  bool get necesitaCiudad => _chatId == null && _ciudadActual == null;

  StreamSubscription<List<Mensaje>>? _sub;
  StreamSubscription<Chat?>? _chatSub;
  bool _creandoChat = false;

  HomeViewModel({String? initialChatId}) {
    if (initialChatId != null) {
      _chatId = initialChatId;
      _suscribir();
    }
  }

  void seleccionarCiudad(String ciudad) {
    _ciudadActual = ciudad;
    notifyListeners();
  }

  void _suscribir() {
    if (_chatId == null) return;

    if (_messages.isEmpty) {
      _cargando = true;
      notifyListeners();
    }

    _sub?.cancel();
    _chatSub?.cancel();

    _chatSub = ChatService.instance.chatStream(_chatId!).listen((chat) {
      final nuevoTitulo = (chat?.titulo ?? '').trim();
      if (_tituloChat != nuevoTitulo) {
        _tituloChat = nuevoTitulo;
        notifyListeners();
      }
    });

    _sub = ChatService.instance
        .mensajesStream(_chatId!)
        .listen(
          (mensajes) {
            _messages = List.of(mensajes);
            _cargando = false;
            notifyListeners();
          },
          onError: (_) {
            _cargando = false;
            notifyListeners();
          },
        );
  }

  Future<void> cambiarChat(String? nuevoChatId) async {
    if (_chatId == nuevoChatId) return;
    _sub?.cancel();
    _chatSub?.cancel();
    _chatId = nuevoChatId;
    _messages = [];
    _tituloChat = '';
    _cargando = false;
    notifyListeners();

    if (nuevoChatId != null) {
      _suscribir();
    }
  }

  Future<void> enviarTexto(String texto) async {
    final textoTrimmed = texto.trim();
    if (textoTrimmed.isEmpty || _ciudadActual == null) return;

    await _crearChatSiNecesario();
    if (_chatId == null) return;

    final chatIdActual = _chatId!;

    await _guardarMensajeTexto(
      chatId: chatIdActual,
      contenido: textoTrimmed,
      role: MensajeRole.usuario,
    );

    await _actualizarTituloSiVacio(textoTrimmed);

    try {
      final respuesta = await OllamaService.query(
        textoTrimmed,
        ciudad: _ciudadActual!,
      );
      await _guardarMensajeTexto(
        chatId: chatIdActual,
        contenido: respuesta,
        role: MensajeRole.bot,
      );
    } catch (_) {
      await _guardarMensajeTexto(
        chatId: chatIdActual,
        contenido:
          'No he podido conectarme al servidor en este momento. Intentalo de nuevo en unos segundos.',
        role: MensajeRole.bot,
      );
    }
  }

  Future<void> enviarImagen(XFile img) async {
    if (_ciudadActual == null) return;

    await _crearChatSiNecesario();
    if (_chatId == null) return;

    await _guardarMensajeImagen(
      chatId: _chatId!,
      imgUrl: img.path,
      role: MensajeRole.usuario,
    );

    await _actualizarTituloSiVacio('[Imagen]');
  }

  Future<void> _crearChatSiNecesario() async {
    if (_chatId != null || _creandoChat) return;
    _creandoChat = true;
    try {
      final id = await ChatService.instance.crearConversacion(
        titulo: '',
        ciudad: _ciudadActual ?? '',
      );
      _chatId = id;
      _suscribir();
    } catch (_) {
      // Si falla la creación, _chatId sigue null
    } finally {
      _creandoChat = false;
    }
  }

  Future<void> _actualizarTituloSiVacio(String textoBase) async {
    if (_chatId == null || _tituloChat.trim().isNotEmpty) return;
    final titulo = _construirTitulo(textoBase);
    _tituloChat = titulo;
    notifyListeners();

    try {
      await ChatService.instance.actualizarTitulo(
        chatId: _chatId!,
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

  Future<void> _guardarMensajeTexto({
    required String chatId,
    required String contenido,
    required MensajeRole role,
  }) {
    return ChatService.instance.guardarMensaje(
      chatId: chatId,
      mensaje: Mensaje.texto(
        id: '',
        chatId: chatId,
        contenido: contenido,
        role: role,
        fecha: DateTime.now(),
      ),
    );
  }

  Future<void> _guardarMensajeImagen({
    required String chatId,
    required String imgUrl,
    required MensajeRole role,
  }) {
    return ChatService.instance.guardarMensaje(
      chatId: chatId,
      mensaje: Mensaje.imagen(
        id: '',
        chatId: chatId,
        imgUrl: imgUrl,
        role: role,
        fecha: DateTime.now(),
      ),
    );
  }

  void nuevaConversacion() {
    _sub?.cancel();
    _chatSub?.cancel();
    _chatId = null;
    _ciudadActual = null;
    _messages = [];
    _tituloChat = '';
    _cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _chatSub?.cancel();
    super.dispose();
  }
}
