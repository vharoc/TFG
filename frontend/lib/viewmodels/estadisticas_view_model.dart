import 'package:flutter/material.dart';
import '../services/ciudad_visitada_service.dart';
import '../services/estadisticas_service.dart';
import '../services/uso_tokens_service.dart';

class EstadisticasViewModel extends ChangeNotifier {
  Estadisticas _stats = const Estadisticas.vacias();
  Estadisticas get stats => _stats;

  UsoTokens _uso = const UsoTokens.vacio();
  UsoTokens get uso => _uso;

  bool _cargando = true;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  EstadisticasViewModel() {
    cargar();
  }

  Future<void> cargar() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        EstadisticasService.instance.calcular(),
        UsoTokensService.instance.estado(),
      ]);
      _stats = results[0] as Estadisticas;
      _uso = results[1] as UsoTokens;
    } catch (_) {
      _error = 'No se pudieron cargar las estadísticas.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> eliminarCiudad(String ciudadId) async {
    await CiudadVisitadaService.instance.eliminarCiudad(ciudadId);
    await cargar();
  }
}
