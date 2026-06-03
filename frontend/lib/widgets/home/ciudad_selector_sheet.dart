import 'package:flutter/material.dart';
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
    // cargarCiudadesSoportadas ya cae a un fallback local si el backend falla,
    // así que esta lista nunca llega vacía.
    final lista = await UbicacionService.instance.cargarCiudadesSoportadas();
    _ciudades = lista.map((c) => c.nombre).toList();
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Image.asset('assets/images/logo_only.png', width: 56, height: 56),
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
