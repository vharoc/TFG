import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat.dart';
import '../models/ciudad_soportada.dart';
import '../models/mensaje.dart';
import '../services/chat_services.dart';
import '../services/ollama_service.dart';
import '../services/ubicacion_service.dart';

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

  CiudadSoportada? _ciudadSoportada;

  String? _mensajeErrorFoto;
  String? get mensajeErrorFoto => _mensajeErrorFoto;

  void limpiarErrorFoto() {
    _mensajeErrorFoto = null;
  }

  bool _gpsDisponible = false;
  bool get gpsDisponible => _gpsDisponible;

  bool _gpsPermanentementeDenegado = false;
  bool get gpsPermanentementeDenegado => _gpsPermanentementeDenegado;

  // Necesita selector manual solo si no hay ciudad, no hay GPS y no hay chat abierto
  bool get necesitaCiudad => _chatId == null && _ciudadActual == null && !_gpsDisponible;

  StreamSubscription<List<Mensaje>>? _sub;
  StreamSubscription<Chat?>? _chatSub;
  bool _creandoChat = false;

  HomeViewModel({String? initialChatId}) {
    if (initialChatId != null) {
      _chatId = initialChatId;
      _suscribir();
    }
  }

  Future<void> inicializarUbicacion() async {
    final estado = await UbicacionService.instance.verificarPermiso();
    _gpsDisponible = estado == EstadoPermiso.concedido;
    _gpsPermanentementeDenegado = estado == EstadoPermiso.permanentementeDenegado;
    notifyListeners();
  }

  void seleccionarCiudad(String ciudad) {
    _ciudadActual = ciudad;
    notifyListeners();
    // Carga los datos de la ciudad en segundo plano para validar fotos posteriores
    UbicacionService.instance.cargarCiudadesSoportadas().then((lista) {
      for (final c in lista) {
        if (c.nombre == ciudad) {
          _ciudadSoportada = c;
          break;
        }
      }
    }).catchError((_) {});
  }

  // Intenta detectar la ciudad a partir de las coordenadas GPS actuales.
  // Devuelve true si se encontró una ciudad soportada y la cacheó.
  Future<bool> _detectarCiudadDesdeGps() async {
    try {
      final pos = await UbicacionService.instance.obtenerPosicion();
      final ciudad = await UbicacionService.instance
          .detectarCiudad(pos.latitude, pos.longitude);
      if (ciudad == null) return false;
      _ciudadActual = ciudad.nombre;
      _ciudadSoportada = ciudad;
      notifyListeners();
      if (_chatId != null) {
        ChatService.instance
            .actualizarCiudad(chatId: _chatId!, ciudad: ciudad.nombre)
            .catchError((_) {});
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Comprueba si las coordenadas actuales del dispositivo están dentro del
  // radio de la ciudad en curso. Devuelve true si no puede validar (fail open).
  Future<bool> _fotoEnRangoDeCiudad() async {
    if (!_gpsDisponible || _ciudadSoportada == null) return true;
    try {
      final pos = await UbicacionService.instance.obtenerPosicion();
      return UbicacionService.instance
          .dentroDeRadio(pos.latitude, pos.longitude, _ciudadSoportada!);
    } catch (_) {
      return true;
    }
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
    if (textoTrimmed.isEmpty) return;

    if (_ciudadActual == null) {
      if (_gpsDisponible) await _detectarCiudadDesdeGps();
      if (_ciudadActual == null) return;
    }

    await _crearChatSiNecesario();
    if (_chatId == null) return;

    final chatIdActual = _chatId!;

    final historial = _messages
        .where((m) => m.tipo == MensajeTipo.texto)
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
    final historialReciente = historial.length > 10
        ? historial.sublist(historial.length - 10)
        : historial;

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
        history: historialReciente,
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
    if (_ciudadActual == null) {
      // Primera foto: detectar ciudad desde GPS
      if (_gpsDisponible) {
        final detectada = await _detectarCiudadDesdeGps();
        if (!detectada) {
          _mensajeErrorFoto =
              'No se encontró ninguna ciudad compatible con tu ubicación.';
          notifyListeners();
          return;
        }
      } else {
        return; // Sin GPS ni ciudad: el selector debería haberla pedido antes
      }
    } else {
      // Fotos posteriores: validar que siguen dentro del radio de la ciudad
      final enRango = await _fotoEnRangoDeCiudad();
      if (!enRango) {
        _mensajeErrorFoto = 'La foto está fuera del alcance de $_ciudadActual.';
        notifyListeners();
        return;
      }
    }

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
    _ciudadSoportada = null;
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
