import 'package:flutter/material.dart';
import '../services/estadisticas_service.dart';

class EstadisticasViewModel extends ChangeNotifier {
  Estadisticas _stats = const Estadisticas.vacias();
  Estadisticas get stats => _stats;

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
      _stats = await EstadisticasService.instance.calcular();
    } catch (_) {
      _error = 'No se pudieron cargar las estadísticas.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
