import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/chat.dart';
import '../models/ciudad_soportada.dart';
import '../models/mensaje.dart';
import '../models/navegacion.dart';
import '../models/poi_sugerido.dart';
import '../models/poi_visitado.dart';
import '../models/ruta_result.dart';
import '../services/chat_services.dart';
import '../services/ciudad_visitada_service.dart';
import '../services/imagen_local_service.dart';
import '../services/ollama_service.dart';
import '../services/ubicacion_service.dart';
import '../services/uso_tokens_service.dart';

class HomeViewModel extends ChangeNotifier {
  List<Mensaje> _messages = [];

  List<Mensaje> get messages => List.unmodifiable(_messages);

  String _tituloChat = '';
  String get tituloChat => _tituloChat;

  String? _chatId;
  String? get chatId => _chatId;

  bool _cargando = false;
  // Solo refleja la carga de mensajes de un chat. Sin chat abierto mostramos el
  // estado vacío (saludo), no un spinner.
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

  // Fuerza el selector manual cuando hay permiso de GPS pero no resuelve ciudad.
  bool _pedirCiudadManual = false;

  bool get necesitaCiudad =>
      _chatId == null &&
      _ciudadActual == null &&
      (!_gpsDisponible || _pedirCiudadManual);

  bool _generando = false;
  bool get generando => _generando;
  http.Client? _clientActivo;

  String? _poiCargandoKey;
  String? get poiCargandoKey => _poiCargandoKey;

  static String poiKey(PoiSugerido poi) => '${poi.id}::${poi.nombre}';

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

  String? _monumentoIdActual;

  List<PoiVisitado> _visitados = [];
  List<PoiVisitado> get visitados =>
      List.unmodifiable(_visitados.where((p) => p.visitado));
  StreamSubscription<List<PoiVisitado>>? _visitadosSub;

  RutaState? _rutaState;
  RutaState? get rutaState => _rutaState;
  double? _rutaLat;
  double? _rutaLon;

  void cancelarRespuesta() {
    _clientActivo?.close();
    _clientActivo = null;
    _generando = false;
    _poiCargandoKey = null;
    notifyListeners();
  }

  StreamSubscription<List<Mensaje>>? _sub;
  StreamSubscription<Chat?>? _chatSub;
  bool _creandoChat = false;

  HomeViewModel({String? initialChatId}) {
    if (initialChatId != null) {
      _chatId = initialChatId;
      _suscribir();
    }
  }

  void _suscribirVisitados() {
    _visitadosSub?.cancel();
    if (_ciudadActual == null) {
      _visitados = [];
      return;
    }
    _visitadosSub = CiudadVisitadaService.instance
        .poisStream(_ciudadActual!)
        .listen((lista) {
      _visitados = lista;
      notifyListeners();
    });
  }

  Future<void> _registrarVisitaPoi(String ciudad, String poiId, String nombrePoi) async {
    try {
      final catalogo = await OllamaService.monumentos(ciudad: ciudad);
      if (catalogo.isNotEmpty) {
        await CiudadVisitadaService.instance.sembrarCatalogo(ciudad, catalogo);
      }
    } catch (_) {
      // Si el catálogo no carga, igualmente marcamos el POI visitado.
    }
    await CiudadVisitadaService.instance
        .marcarVisitado(ciudad, poiId, nombrePoi)
        .catchError((_) {});
  }

  Future<void> inicializarUbicacion() async {
    try {
      final estado = await UbicacionService.instance.verificarPermiso();
      _gpsDisponible = estado == EstadoPermiso.concedido;
      _gpsPermanentementeDenegado =
          estado == EstadoPermiso.permanentementeDenegado;
    } catch (_) {
      // Si el plugin de ubicación falla, seguimos sin GPS (queda el selector manual).
      _gpsDisponible = false;
      _gpsPermanentementeDenegado = false;
    }
    notifyListeners();

    // Con permiso de GPS y sin ciudad aún, la resolvemos en segundo plano para
    // personalizar el saludo del chat vacío con el nombre de la ciudad.
    if (_gpsDisponible && _ciudadActual == null) {
      await _detectarCiudadDesdeGps();
    }
  }

  void seleccionarCiudad(String ciudad) {
    _ciudadActual = ciudad;
    _pedirCiudadManual = false;
    _suscribirVisitados();
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

  Future<bool> _detectarCiudadDesdeGps() async {
    try {
      final pos = await UbicacionService.instance.obtenerPosicion();
      final ciudad = await UbicacionService.instance
          .detectarCiudad(pos.latitude, pos.longitude);
      if (ciudad == null) return false;
      _ciudadActual = ciudad.nombre;
      _ciudadSoportada = ciudad;
      _pedirCiudadManual = false;
      _suscribirVisitados();
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

  // Resuelve la ciudad de un chat nuevo: GPS primero, selector manual si no hay fix.
  Future<void> _resolverCiudad() async {
    if (_ciudadActual != null) return;
    if (_gpsDisponible && await _detectarCiudadDesdeGps()) return;
    _pedirCiudadManual = true;
    notifyListeners();
  }

  // Solo rechaza la foto con una lectura GPS precisa y fuera del radio de la
  // ciudad; ante GPS lento, impreciso o error, la foto pasa igualmente.
  Future<bool> _fotoEnRangoDeCiudad() async {
    if (!_gpsDisponible || _ciudadSoportada == null) return true;
    try {
      final pos = await UbicacionService.instance
          .obtenerPosicion()
          .timeout(const Duration(seconds: 4));
      // accuracy: radio de error en metros; si es pobre (>150 m) no rechazamos.
      if (pos.accuracy > 150) return true;
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
        // Un chat ya guardado con título se considera consolidado (nivel 2)
        // para que un nuevo mensaje no lo degrade.
        if (nuevoTitulo.isNotEmpty && _nivelTitulo == 0) _nivelTitulo = 2;
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
    _nivelTitulo = 0;
    _monumentoIdActual = null;
    _rutaState = null;
    _cargando = false;
    notifyListeners();

    if (nuevoChatId != null) {
      _suscribir();
    }
  }

  /// Si el usuario agotó su cupo diario de IA, deja constancia en el chat y
  /// devuelve true para que el llamante aborte sin gastar más tokens.
  Future<bool> _bloqueadoPorLimite(String chatId) async {
    bool alcanzado;
    try {
      alcanzado = await UsoTokensService.instance.limiteAlcanzado();
    } catch (_) {
      return false; // ante un fallo de lectura, no bloqueamos al usuario
    }
    if (!alcanzado) return false;
    await _guardarMensajeTexto(
      chatId: chatId,
      contenido:
          '⛔ Has alcanzado tu límite diario de IA (${UsoTokensService.limiteDiario} tokens). '
          'Se restablece a medianoche.',
      role: MensajeRole.bot,
    );
    notifyListeners();
    return true;
  }

  void _registrarTokens(int tokens) {
    if (tokens <= 0) return;
    UsoTokensService.instance.registrar(tokens);
  }

  Future<void> enviarTexto(String texto) async {
    // Ignora el tap si ya hay una petición en curso (doble tap en enviar o en chips).
    if (_generando) return;
    final textoTrimmed = texto.trim();
    if (textoTrimmed.isEmpty) return;

    // Antes de cualquier await, para que la UI se desactive al primer tap.
    _generando = true;
    notifyListeners();

    try {
      if (_ciudadActual == null) {
        if (_gpsDisponible) await _detectarCiudadDesdeGps();
        if (_ciudadActual == null) {
          // Sin ciudad resoluble: abrimos el selector en vez de descartar el mensaje.
          _pedirCiudadManual = true;
          return;
        }
      }

      await _crearChatSiNecesario();
      if (_chatId == null) return;

      final chatIdActual = _chatId!;

      final modoEfectivo = (_rutaState != null) ? 'pensar' : _modo;

      final List<Mensaje> historialReciente;
      if (_monumentoIdActual != null && modoEfectivo == 'rapido') {
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

      await _titularDesdeTexto(textoTrimmed);

      if (await _bloqueadoPorLimite(chatIdActual)) return;

      double? lat, lon;
      if (_gpsDisponible) {
        try {
          final pos = await UbicacionService.instance.obtenerPosicion()
              .timeout(const Duration(seconds: 3));
          lat = pos.latitude;
          lon = pos.longitude;
        } catch (_) {}
      }

      final client = http.Client();
      _clientActivo = client;
      notifyListeners();

      try {
        final resultado = await OllamaService.query(
          textoTrimmed,
          ciudad: _ciudadActual!,
          history: historialReciente,
          monumentoId: _monumentoIdActual,
          modo: modoEfectivo,
          lat: lat,
          lon: lon,
          client: client,
        );
        _registrarTokens(resultado.tokens);
        if (resultado.monumentoId != null) {
          _monumentoIdActual = resultado.monumentoId;
        }
        await _guardarMensajeTexto(
          chatId: chatIdActual,
          contenido: resultado.response,
          role: MensajeRole.bot,
          navegacion: resultado.navegacion,
        );
      } catch (_) {
        if (_clientActivo == null) return; // cancelado por el usuario
        await _guardarMensajeTexto(
          chatId: chatIdActual,
          contenido: 'No he podido conectarme al servidor en este momento. Intentalo de nuevo en unos segundos.',
          role: MensajeRole.bot,
        );
      }
    } finally {
      _clientActivo = null;
      _generando = false;
      _poiCargandoKey = null;
      notifyListeners();
    }
  }

  Future<void> enviarImagen(XFile img) async {
    // Evita procesar dos fotos a la vez o solapar foto con una consulta en curso.
    if (_generando) return;
    if (_ciudadActual == null) {
      if (_gpsDisponible) {
        final detectada = await _detectarCiudadDesdeGps();
        if (!detectada) {
          // GPS sin fix o fuera de cobertura: aviso y selector manual.
          _pedirCiudadManual = true;
          _mensajeErrorFoto =
              'No se encontró ninguna ciudad compatible con tu ubicación.';
          notifyListeners();
          return;
        }
      } else {
        // Sin GPS ni ciudad: abrimos el selector en vez de descartar la foto.
        _pedirCiudadManual = true;
        notifyListeners();
        return;
      }
    } else {
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

    final pathPersistente = await ImagenLocalService.instance.guardarPersistente(img);

    await ChatService.instance.guardarMensaje(
      chatId: chatIdActual,
      mensaje: Mensaje.imagen(
        id: '',
        chatId: chatIdActual,
        imgUrl: pathPersistente,
        role: MensajeRole.usuario,
        fecha: ahora,
      ),
    );

    await _aplicarTitulo('Foto en ${_ciudadActual ?? 'la ciudad'}', 1);

    if (await _bloqueadoPorLimite(chatIdActual)) return;

    final client = http.Client();
    _clientActivo = client;
    _generando = true;
    notifyListeners();

    try {
      if (_rutaState?.estado == EstadoRuta.esperandoFoto && _gpsDisponible) {
        try {
          final pos = await UbicacionService.instance.obtenerPosicion();
          _rutaLat = pos.latitude;
          _rutaLon = pos.longitude;
        } catch (_) {}
      }

      final modoEfectivo = (_rutaState != null) ? 'pensar' : _modo;

      final resultado = await OllamaService.classify(
        File(pathPersistente),
        modo: modoEfectivo,
        ciudad: _ciudadActual,
        client: client,
      );
      _registrarTokens(resultado.tokens);

      if (resultado.id != null && _ciudadActual != null) {
        _monumentoIdActual = resultado.id;
        await _registrarVisitaPoi(_ciudadActual!, resultado.id!, resultado.nombre);
        await _aplicarTitulo(resultado.nombre, 2);
      }

      // Contexto de ruta antes de mutar el estado (la foto puede ser inicio o parada).
      final esFotoDeRuta = _rutaState?.estado == EstadoRuta.esperandoFoto ||
          _rutaState?.estado == EstadoRuta.activo;
      final eraRutaActiva = _rutaState?.estado == EstadoRuta.activo;
      final paradaActualId = eraRutaActiva ? _rutaState?.paradaActualObj?.id : null;
      final iniciaRuta =
          _rutaState?.estado == EstadoRuta.esperandoFoto && resultado.id != null;

      // Si el monumento no se reconoce, no se puede iniciar la ruta.
      if (_rutaState?.estado == EstadoRuta.esperandoFoto) {
        if (resultado.id == null) {
          _rutaState = null;
          _rutaLat = null;
          _rutaLon = null;
          _mensajeErrorFoto =
              'No he reconocido este lugar. Acércate a un monumento para empezar la ruta.';
          notifyListeners();
        } else {
          _rutaLat ??= resultado.lat; // fallback si GPS no disponible
          _rutaLon ??= resultado.lon;
          _rutaState = RutaState.seleccionando();
          notifyListeners();
        }
      }

      final descripcion = (resultado.descripcionCorta?.trim().isNotEmpty == true)
          ? resultado.descripcionCorta!.trim()
          : '';
      final respuesta = (resultado.id != null)
          ? (descripcion.isNotEmpty
              ? '📍 ${resultado.nombre}\n\n$descripcion'
              : '📍 ${resultado.nombre}')
          : (descripcion.isNotEmpty ? descripcion : resultado.nombre);

      // En ruta: chips de curiosidad sobre el monumento. Normal: POIs cercanos.
      final chips = (esFotoDeRuta && resultado.id != null)
          ? _chipsPreguntaMonumento(resultado.id!)
          : resultado.poisCercanos;
      await _guardarMensajeTexto(
        chatId: chatIdActual,
        contenido: respuesta,
        role: MensajeRole.bot,
        poisCercanos: chips,
      );

      if (iniciaRuta) {
        await _guardarMensajeTexto(
          chatId: chatIdActual,
          contenido: '¿Qué recorrido quieres? Elige abajo 👇\n'
              '• Todos — todos los monumentos de la ciudad\n'
              '• Pendientes — los que aún no has visitado\n'
              '• Visitados — repasa los que ya conoces',
          role: MensajeRole.bot,
        );
      }

      // Auto-avanza solo si la foto reconoce el monumento de la parada actual.
      if (eraRutaActiva && resultado.id != null && resultado.id == paradaActualId) {
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
    if (_generando) return;
    _monumentoIdActual = poi.id;
    _poiCargandoKey = poiKey(poi);
    if (poi.esPregunta) {
      // Chip de curiosidad: el texto del chip ya es la pregunta
      await enviarTexto(poi.nombre);
    } else {
      await enviarTexto('Cuéntame más sobre ${poi.nombre}');
    }
  }

  List<PoiSugerido> _chipsPreguntaMonumento(String monumentoId) => [
        PoiSugerido(id: monumentoId, nombre: '¿Cuál es su historia?', esPregunta: true),
        PoiSugerido(id: monumentoId, nombre: '¿Qué tiene de especial?', esPregunta: true),
        PoiSugerido(id: monumentoId, nombre: 'Cuéntame una curiosidad', esPregunta: true),
      ];

  // Ruta

  Future<void> iniciarFlujoRuta() async {
    if (_generando) return;

    if (!_gpsDisponible) {
      final estado = await UbicacionService.instance.solicitarPermiso();
      if (estado == EstadoPermiso.concedido) {
        _gpsDisponible = true;
      } else {
        _mensajeErrorFoto =
            'El modo ruta necesita acceso a tu ubicación. '
            'Actívala en los ajustes del móvil e inténtalo de nuevo.';
        notifyListeners();
        return;
      }
    }

    _rutaLat = null;
    _rutaLon = null;
    _rutaState = RutaState.esperandoFoto();
    notifyListeners();

    if (_ciudadActual != null) {
      await _crearChatSiNecesario();
      if (_chatId != null) {
        await _guardarMensajeTexto(
          chatId: _chatId!,
          contenido:
              '🗺️ Modo ruta activado. Hazle una foto al monumento donde estás '
              'ahora y te montaré un recorrido a pie por los alrededores.',
          role: MensajeRole.bot,
        );
      }
    }
  }

  Future<void> seleccionarFiltroRuta(String filtro) async {
    // El filtro solo se procesa desde el estado de selección: evita el doble tap.
    if (_rutaState?.estado != EstadoRuta.seleccionandoFiltro) return;

    if (_chatId != null && await _bloqueadoPorLimite(_chatId!)) {
      _rutaState = null;
      notifyListeners();
      return;
    }

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
        visitados: _visitados.where((p) => p.visitado).map((p) => p.id).toList(),
        ciudad: _ciudadActual,
      );
      _registrarTokens(resultado.tokens);
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
      contenido: '📍 Primera parada: ${primera.nombre}\n¡Hazle una foto cuando llegues!',
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
        contenido: ' ¡Ruta completada! Has visitado ${rs.resultado!.paradas.length} monumentos.',
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
      contenido: '$prefijo ${parada.nombre}\n¡Hazle una foto cuando llegues!',
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
      // La ciudad se registra al fotografiar un monumento (ver enviarImagen),
      // no al crear el chat: "ciudad visitada" = ciudad donde has visto algo.
    } catch (_) {
    } finally {
      _creandoChat = false;
    }
  }

  // Nivel de "calidad" del título actual: un título solo se sustituye por otro
  // de nivel mayor. 0=sin título, 1=genérico, 2=significativo (tema concreto).
  int _nivelTitulo = 0;

  static const _stopwords = {
    'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'al',
    'a', 'ante', 'con', 'en', 'por', 'para', 'sin', 'sobre', 'tras', 'y', 'o',
    'que', 'cual', 'cuales', 'cuál', 'cuáles', 'como', 'cómo', 'cuando',
    'cuándo', 'donde', 'dónde', 'es', 'son', 'esta', 'está', 'este', 'esto',
    'me', 'te', 'se', 'le', 'lo', 'su', 'mi', 'tu', 'hay', 'tiene', 'puedo',
    'quiero', 'dime', 'cuentame', 'cuéntame', 'sabes', 'mas', 'más', 'muy',
    // Saludos y cortesía: no deben generar título significativo.
    'hola', 'tal', 'buenas', 'buenos', 'dias', 'días', 'tardes',
    'noches', 'hey', 'holi', 'saludos', 'adios', 'adiós', 'gracias',
    'porfa', 'porfavor', 'favor', 'vale', 'ok', 'oye', 'eh', 'aja', 'ajá',
  };

  String? _tituloDesdeTexto(String texto) {
    final palabras = texto
        .toLowerCase()
        .replaceAll(RegExp(r'[¿?¡!.,;:]'), '')
        .split(RegExp(r'\s+'))
        .where((p) => p.length > 2 && !_stopwords.contains(p))
        .toList();
    if (palabras.isEmpty) return null;
    final titulo = palabras.take(4).join(' ');
    return titulo[0].toUpperCase() + titulo.substring(1);
  }

  Future<void> _aplicarTitulo(String titulo, int nivel) async {
    if (_chatId == null || nivel <= _nivelTitulo) return;
    _nivelTitulo = nivel;
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

  Future<void> _titularDesdeTexto(String texto) async {
    final clave = _tituloDesdeTexto(texto);
    if (clave != null) {
      await _aplicarTitulo(clave, 2);
    } else {
      await _aplicarTitulo('Charla con Clicky', 1);
    }
  }

  Future<void> _guardarMensajeTexto({
    required String chatId,
    required String contenido,
    required MensajeRole role,
    List<PoiSugerido> poisCercanos = const [],
    Navegacion? navegacion,
  }) {
    return ChatService.instance.guardarMensaje(
      chatId: chatId,
      mensaje: Mensaje(
        id: '',
        chatId: chatId,
        contenido: contenido,
        tipo: MensajeTipo.texto,
        role: role,
        fecha: DateTime.now(),
        poisCercanos: poisCercanos,
        navegacion: navegacion,
      ),
    );
  }

  void nuevaConversacion() {
    _sub?.cancel();
    _chatSub?.cancel();
    _chatId = null;
    _ciudadActual = null;
    _ciudadSoportada = null;
    _pedirCiudadManual = false;
    _monumentoIdActual = null;
    _rutaState = null;
    _messages = [];
    _tituloChat = '';
    _nivelTitulo = 0;
    _cargando = false;
    _visitadosSub?.cancel();
    _visitados = [];
    notifyListeners();
    // Repuebla la ciudad del nuevo chat por GPS o abre el selector manual.
    unawaited(_resolverCiudad());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _chatSub?.cancel();
    _visitadosSub?.cancel();
    super.dispose();
  }
}
