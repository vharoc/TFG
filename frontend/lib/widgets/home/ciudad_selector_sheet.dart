import 'package:flutter/material.dart';
import '../../constants/ciudades_permitidas.dart';
import '../../services/ubicacion_service.dart';

class CiudadSelectorSheet extends StatefulWidget {
  const CiudadSelectorSheet({super.key});

  @override
  State<CiudadSelectorSheet> createState() => _CiudadSelectorSheetState();
}

class _CiudadSelectorSheetState extends State<CiudadSelectorSheet> {
  List<String> _ciudades = const [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await UbicacionService.instance.cargarCiudadesSoportadas();
      _ciudades = lista.map((c) => c.nombre).toList();
    } catch (_) {
      _ciudades = ciudadesPermitidas; // fallback local
    }
    if (_ciudades.isEmpty) _ciudades = ciudadesPermitidas;
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Selecciona tu ciudad',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else
            ..._ciudades.map(
              (ciudad) => ListTile(
                title: Text(ciudad),
                onTap: () => Navigator.of(context).pop(ciudad),
              ),
            ),
        ],
      ),
    );
  }
}
