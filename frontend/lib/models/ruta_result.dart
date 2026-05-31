class Parada {
  final String id;
  final String nombre;
  final String descripcionCorta;
  final double lat;
  final double lon;
  final int distanciaM;
  final int tiempoMin;

  const Parada({
    required this.id,
    required this.nombre,
    required this.descripcionCorta,
    required this.lat,
    required this.lon,
    required this.distanciaM,
    required this.tiempoMin,
  });

  factory Parada.fromMap(Map<String, dynamic> map) => Parada(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        descripcionCorta: (map['descripcion_corta'] as String?) ?? '',
        lat: (map['lat'] as num).toDouble(),
        lon: (map['lon'] as num).toDouble(),
        distanciaM: (map['distancia_m'] as num).toInt(),
        tiempoMin: (map['tiempo_min'] as num).toInt(),
      );
}

class RutaResult {
  final List<Parada> paradas;
  final int tiempoTotalMin;
  final String resumen;

  const RutaResult({
    required this.paradas,
    required this.tiempoTotalMin,
    required this.resumen,
  });

  factory RutaResult.fromMap(Map<String, dynamic> map) => RutaResult(
        paradas: (map['paradas'] as List<dynamic>)
            .map((e) => Parada.fromMap(e as Map<String, dynamic>))
            .toList(),
        tiempoTotalMin: (map['tiempo_total_min'] as num).toInt(),
        resumen: (map['resumen'] as String?) ?? '',
      );
}

// ---------------------------------------------------------------------------

enum EstadoRuta { esperandoFoto, seleccionandoFiltro, cargando, mostrandoResumen, activo }

class RutaState {
  final EstadoRuta estado;
  final RutaResult? resultado;
  final int paradaActual;

  const RutaState._({
    required this.estado,
    this.resultado,
    this.paradaActual = 0,
  });

  factory RutaState.esperandoFoto() =>
      const RutaState._(estado: EstadoRuta.esperandoFoto);

  factory RutaState.seleccionando() =>
      const RutaState._(estado: EstadoRuta.seleccionandoFiltro);

  factory RutaState.cargando() =>
      const RutaState._(estado: EstadoRuta.cargando);

  factory RutaState.resumen(RutaResult r) =>
      RutaState._(estado: EstadoRuta.mostrandoResumen, resultado: r);

  factory RutaState.activo(RutaResult r, [int parada = 0]) =>
      RutaState._(estado: EstadoRuta.activo, resultado: r, paradaActual: parada);

  RutaState copyWith({EstadoRuta? estado, RutaResult? resultado, int? paradaActual}) =>
      RutaState._(
        estado: estado ?? this.estado,
        resultado: resultado ?? this.resultado,
        paradaActual: paradaActual ?? this.paradaActual,
      );

  Parada? get paradaActualObj =>
      resultado != null && paradaActual < resultado!.paradas.length
          ? resultado!.paradas[paradaActual]
          : null;

  int get totalParadas => resultado?.paradas.length ?? 0;

  bool get bloqueaInput =>
      estado == EstadoRuta.esperandoFoto ||
      estado == EstadoRuta.seleccionandoFiltro ||
      estado == EstadoRuta.cargando;
}
