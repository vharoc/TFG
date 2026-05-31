import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/chat.dart';
import '../models/ciudad_soportada.dart';
import '../models/mensaje.dart';
import '../models/poi_sugerido.dart';
import '../models/ruta_result.dart';
import '../services/chat_services.dart';
import '../services/ciudad_services.dart';
import '../services/ollama_service.dart';
import '../services/poi_visitado_service.dart';
import '../services/ubicacion_service.dart';

class HomeViewModel extends ChangeNotifier {
  List<Mensaje> _messages = [];
  List<Mensaje> _localImages = [];

  List<Mensaje> get messages {
    final combined = [..._messages, ..._localImages];
    combined.sort((a, b) => a.fecha.compareTo(b.fecha));
    return List.unmodifiable(combined);
  }

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

  bool _generando = false;
  bool get generando => _generando;
  http.Client? _clientActivo;

  String _modo = 'rapido'; // 'rapido' | 'pensar'
  String get modo => _modo;

  void toggleModo() {
    _modo = _modo == 'rapido' ? 'pensar' : 'rapido';
    notifyListeners();
  }

  void setModo(String modo) {
    if (_modo == modo) return;
    _modo = modo;
    notifyListeners();
  }

  // ID del último monumento clasificado por foto, persiste entre mensajes de texto.
  String? _monumentoIdActual;

  // Monumentos fotografiados — sincronizado con Firestore.
  final Set<String> _visitados = {};
  Set<String> get visitados => Set.unmodifiable(_visitados);
  StreamSubscription<Set<String>>? _visitadosSub;

  RutaState? _rutaState;
  RutaState? get rutaState => _rutaState;
  double? _rutaLat;
  double? _rutaLon;

  void cancelarRespuesta() {
    _clientActivo?.close();
    _clientActivo = null;
    _generando = false;
    notifyListeners();
  }

  StreamSubscription<List<Mensaje>>? _sub;
  StreamSubscription<Chat?>? _chatSub;
  bool _creandoChat = false;

  HomeViewModel({String? initialChatId}) {
    _visitadosSub = PoiVisitadoService.instance.visitadosStream().listen((ids) {
      _visitados
        ..clear()
        ..addAll(ids);
      notifyListeners();
    });
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
    _localImages = [];
    _tituloChat = '';
    _monumentoIdActual = null;
    _rutaState = null;
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

    // En modo rápido con monumento activo el backend va directo al RAG: historial innecesario
    final List<Mensaje> historialReciente;
    if (_monumentoIdActual != null && _modo == 'rapido') {
      historialReciente = const [];
    } else {
      final historial = _messages
          .where((m) => m.tipo == MensajeTipo.texto)
          .toList()
        ..sort((a, b) => a.fecha.compareTo(b.fecha));
      historialReciente = historial.length > 10
          ? historial.sublist(historial.length - 10)
          : historial;
    }

    await _guardarMensajeTexto(
      chatId: chatIdActual,
      contenido: textoTrimmed,
      role: MensajeRole.usuario,
    );

    await _actualizarTituloSiVacio(textoTrimmed);

    final client = http.Client();
    _clientActivo = client;
    _generando = true;
    notifyListeners();

    try {
      final resultado = await OllamaService.query(
        textoTrimmed,
        ciudad: _ciudadActual!,
        history: historialReciente,
        monumentoId: _monumentoIdActual,
        modo: _modo,
        client: client,
      );
      if (resultado.monumentoId != null) {
        _monumentoIdActual = resultado.monumentoId;
      }
      await _guardarMensajeTexto(
        chatId: chatIdActual,
        contenido: resultado.response,
        role: MensajeRole.bot,
        poisCercanos: resultado.poisCercanos,
      );
    } catch (_) {
      if (_clientActivo == null) return; // cancelado por el usuario
      await _guardarMensajeTexto(
        chatId: chatIdActual,
        contenido: 'No he podido conectarme al servidor en este momento. Intentalo de nuevo en unos segundos.',
        role: MensajeRole.bot,
      );
    } finally {
      _clientActivo = null;
      _generando = false;
      notifyListeners();
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

    final chatIdActual = _chatId!;
    final ahora = DateTime.now();

    final localId = 'local_${ahora.millisecondsSinceEpoch}';
    _localImages.add(Mensaje.imagen(
      id: localId,
      chatId: chatIdActual,
      imgUrl: img.path,
      role: MensajeRole.usuario,
      fecha: ahora,
    ));
    notifyListeners();

    await _actualizarTituloSiVacio('[Imagen]');

    final client = http.Client();
    _clientActivo = client;
    _generando = true;
    notifyListeners();

    try {
      // GPS real del móvil para el inicio de ruta (antes del classify)
      if (_rutaState?.estado == EstadoRuta.esperandoFoto && _gpsDisponible) {
        try {
          final pos = await UbicacionService.instance.obtenerPosicion();
          _rutaLat = pos.latitude;
          _rutaLon = pos.longitude;
        } catch (_) {}
      }

      // En modo ruta activa siempre se usa pensar para dar formato a la respuesta
      final modoEfectivo =
          (_rutaState?.estado == EstadoRuta.activo) ? 'pensar' : _modo;

      final resultado = await OllamaService.classify(
        File(img.path),
        modo: modoEfectivo,
        client: client,
      );

      if (resultado.id != null) {
        _monumentoIdActual = resultado.id;
        PoiVisitadoService.instance
            .marcarVisitado(resultado.id!, resultado.nombre)
            .catchError((_) {});
      }

      // Transición esperandoFoto → seleccionandoFiltro
      if (_rutaState?.estado == EstadoRuta.esperandoFoto) {
        _rutaLat ??= resultado.lat; // fallback si GPS no disponible
        _rutaLon ??= resultado.lon;
        _rutaState = RutaState.seleccionando();
        notifyListeners();
      }

      final respuesta = (resultado.descripcionCorta?.trim().isNotEmpty == true)
          ? resultado.descripcionCorta!
          : resultado.nombre;
      await _guardarMensajeTexto(
        chatId: chatIdActual,
        contenido: respuesta,
        role: MensajeRole.bot,
        poisCercanos: resultado.poisCercanos,
      );

      // Auto-avanzar en modo ruta activa tras responder
      if (_rutaState?.estado == EstadoRuta.activo) {
        await siguienteParada();
      }
    } catch (_) {
      if (_clientActivo == null) return; // cancelado por el usuario
      await _guardarMensajeTexto(
        chatId: chatIdActual,
        contenido: 'No he podido analizar la imagen. Intentalo de nuevo.',
        role: MensajeRole.bot,
      );
    } finally {
      _clientActivo = null;
      _generando = false;
      notifyListeners();
    }
  }

  Future<void> preguntarSobrePoi(PoiSugerido poi) async {
    _monumentoIdActual = poi.id;
    await enviarTexto('Cuéntame más sobre ${poi.nombre}');
  }

  // ── Ruta ──────────────────────────────────────────────────────────────────

  void iniciarFlujoRuta() {
    if (_generando) return;
    _rutaLat = null;
    _rutaLon = null;
    _rutaState = RutaState.esperandoFoto();
    notifyListeners();
  }

  Future<void> seleccionarFiltroRuta(String filtro) async {
    _rutaState = RutaState.cargando();
    notifyListeners();

    try {
      // Usar coordenadas capturadas de la foto; si no hay, intentar GPS
      double lat = _rutaLat ?? 40.9640;
      double lon = _rutaLon ?? -5.6640;
      if (_rutaLat == null && _gpsDisponible) {
        try {
          final pos = await UbicacionService.instance.obtenerPosicion();
          lat = pos.latitude;
          lon = pos.longitude;
        } catch (_) {}
      }

      final resultado = await OllamaService.ruta(
        lat: lat,
        lon: lon,
        filtro: filtro,
        visitados: _visitados.toList(),
      );
      _rutaState = RutaState.resumen(resultado);
    } catch (_) {
      _rutaState = null;
    } finally {
      notifyListeners();
    }
  }

  Future<void> comenzarRuta() async {
    final rs = _rutaState;
    if (rs == null || rs.estado != EstadoRuta.mostrandoResumen || rs.resultado == null) return;
    if (rs.resultado!.paradas.isEmpty) {
      _rutaState = null;
      notifyListeners();
      return;
    }

    await _crearChatSiNecesario();
    if (_chatId == null) return;

    _rutaState = RutaState.activo(rs.resultado!);
    final primera = rs.resultado!.paradas.first;
    _monumentoIdActual = primera.id;
    notifyListeners();

    await _guardarMensajeTexto(
      chatId: _chatId!,
      contenido: '📍 Primera parada: ${primera.nombre}\n¡Hazte una foto cuando llegues!',
      role: MensajeRole.bot,
    );
  }

  Future<void> siguienteParada() async {
    final rs = _rutaState;
    if (rs == null || rs.estado != EstadoRuta.activo || rs.resultado == null) return;

    final siguiente = rs.paradaActual + 1;

    if (siguiente >= rs.resultado!.paradas.length) {
      _rutaState = null;
      _monumentoIdActual = null;
      notifyListeners();
      await _guardarMensajeTexto(
        chatId: _chatId!,
        contenido: '🎉 ¡Ruta completada! Has visitado ${rs.resultado!.paradas.length} monumentos.',
        role: MensajeRole.bot,
      );
      return;
    }

    _rutaState = rs.copyWith(paradaActual: siguiente);
    final parada = rs.resultado!.paradas[siguiente];
    _monumentoIdActual = parada.id;
    notifyListeners();

    final esUltima = siguiente == rs.resultado!.paradas.length - 1;
    final prefijo = esUltima ? '📍 ¡Última parada!' : '📍 Parada ${siguiente + 1} de ${rs.resultado!.paradas.length}:';
    await _guardarMensajeTexto(
      chatId: _chatId!,
      contenido: '$prefijo ${parada.nombre}\n¡Hazte una foto cuando llegues!',
      role: MensajeRole.bot,
    );
  }

  void cancelarRuta() {
    _rutaState = null;
    _rutaLat = null;
    _rutaLon = null;
    notifyListeners();
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
      if (_ciudadActual != null) {
        CiudadServices.instance.registrarCiudad(_ciudadActual!).catchError((_) {});
      }
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
    List<PoiSugerido> poisCercanos = const [],
  }) {
    return ChatService.instance.guardarMensaje(
      chatId: chatId,
      mensaje: Mensaje.texto(
        id: '',
        chatId: chatId,
        contenido: contenido,
        role: role,
        fecha: DateTime.now(),
        poisCercanos: poisCercanos,
      ),
    );
  }

  void nuevaConversacion() {
    _sub?.cancel();
    _chatSub?.cancel();
    _chatId = null;
    _ciudadActual = null;
    _ciudadSoportada = null;
    _monumentoIdActual = null;
    _rutaState = null;
    _messages = [];
    _localImages = [];
    _tituloChat = '';
    _cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _chatSub?.cancel();
    _visitadosSub?.cancel();
    super.dispose();
  }
}
