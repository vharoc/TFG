import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/poi_sugerido.dart';
import '../../theme/theme.dart';
import '../../viewmodels/lateral_view_model.dart';

class PoisCiudadSheet extends StatefulWidget {
  final String ciudad;

  const PoisCiudadSheet({super.key, required this.ciudad});

  @override
  State<PoisCiudadSheet> createState() => _PoisCiudadSheetState();
}

class _PoisCiudadSheetState extends State<PoisCiudadSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LateralViewModel>().cargarPois();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LateralViewModel>();

    final visitados = vm.todosLosPois.where((p) => vm.poiVisitado(p.id)).toList();
    final pendientes = vm.todosLosPois.where((p) => !vm.poiVisitado(p.id)).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_city_outlined, color: AppTheme.usal, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.ciudad,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (vm.cargandoPois)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppTheme.ocre),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (visitados.isNotEmpty) ...[
                      _SeccionHeader(
                        icono: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        texto: 'Visitados (${visitados.length})',
                      ),
                      const SizedBox(height: 8),
                      ...visitados.map((p) => _PoiRow(poi: p, visitado: true)),
                      const SizedBox(height: 16),
                    ],
                    _SeccionHeader(
                      icono: Icons.radio_button_unchecked_rounded,
                      color: Colors.black38,
                      texto: 'Por visitar (${pendientes.length})',
                    ),
                    const SizedBox(height: 8),
                    ...pendientes.map((p) => _PoiRow(poi: p, visitado: false)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SeccionHeader extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String texto;

  const _SeccionHeader({required this.icono, required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _PoiRow extends StatelessWidget {
  final PoiSugerido poi;
  final bool visitado;

  const _PoiRow({required this.poi, required this.visitado});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            visitado ? Icons.place_rounded : Icons.place_outlined,
            size: 18,
            color: visitado ? AppTheme.usal : Colors.black26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              poi.nombre,
              style: TextStyle(
                fontSize: 14,
                color: visitado ? Colors.black87 : Colors.black45,
                fontWeight: visitado ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
