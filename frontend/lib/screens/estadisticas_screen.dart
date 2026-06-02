import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/estadisticas_service.dart';
import '../theme/theme.dart';
import '../viewmodels/estadisticas_view_model.dart';
import '../widgets/common/back_title_app_bar.dart';

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EstadisticasViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7F4),
        appBar: const BackTitleAppBar(title: 'Estadísticas'),
        body: const _EstadisticasBody(),
      ),
    );
  }
}

class _EstadisticasBody extends StatelessWidget {
  const _EstadisticasBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EstadisticasViewModel>();

    if (vm.cargando) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.ocre));
    }
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vm.error!, textAlign: TextAlign.center),
        ),
      );
    }

    final s = vm.stats;
    return RefreshIndicator(
      color: AppTheme.ocre,
      onRefresh: vm.cargar,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Destacados en cuadrícula 2x2
          Row(
            children: [
              _StatCard(
                icono: Icons.photo_camera_rounded,
                valor: '${s.poisCapturados}',
                etiqueta: 'Monumentos capturados',
                color: AppTheme.usal,
              ),
              const SizedBox(width: 12),
              _StatCard(
                icono: Icons.location_city_rounded,
                valor: '${s.ciudadesVisitadas}',
                etiqueta: 'Ciudades visitadas',
                color: AppTheme.ocre,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                icono: Icons.chat_bubble_outline_rounded,
                valor: '${s.totalChats}',
                etiqueta: 'Conversaciones',
                color: const Color(0xFF5B6FA6),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icono: Icons.forum_outlined,
                valor: '${s.totalMensajes}',
                etiqueta: 'Mensajes enviados',
                color: const Color(0xFF4C9A6B),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Detalle en filas
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0DAD4)),
            ),
            child: Column(
              children: [
                _FilaDetalle(
                  icono: Icons.bar_chart_rounded,
                  etiqueta: 'Media de mensajes por chat',
                  valor: s.mediaMensajesPorChat.toStringAsFixed(1),
                ),
              ],
            ),
          ),

          // Progreso por ciudad
          if (s.progresoPorCiudad.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Progreso por ciudad',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE0DAD4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  for (final p in s.progresoPorCiudad)
                    _ProgresoTile(
                      progreso: p,
                      onTap: () => _confirmarBorrarCiudad(context, vm, p),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _confirmarBorrarCiudad(
  BuildContext context,
  EstadisticasViewModel vm,
  ProgresoCiudad p,
) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Restablecer ${p.nombre}'),
      content: const Text(
        'Se borrarán todos los monumentos identificados en esta ciudad. '
        'Tu cuenta no se elimina.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Restablecer'),
        ),
      ],
    ),
  );
  if (ok == true) await vm.eliminarCiudad(p.ciudadId);
}

class _StatCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;

  const _StatCard({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 140,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0DAD4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 26, color: color),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                etiqueta,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDetalle extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;

  const _FilaDetalle({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icono, size: 22, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Text(etiqueta, style: const TextStyle(fontSize: 15)),
          ),
          Text(
            valor,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ProgresoTile extends StatelessWidget {
  final ProgresoCiudad progreso;
  final VoidCallback onTap;

  const _ProgresoTile({required this.progreso, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (progreso.fraccion * 100).round();
    final completa = progreso.total > 0 && progreso.capturados >= progreso.total;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progreso.nombre,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                if (completa)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.emoji_events_rounded, size: 18, color: AppTheme.ocre),
                  ),
                Text(
                  '${progreso.capturados}/${progreso.total}  ·  $pct%',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.black26),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progreso.fraccion,
                minHeight: 8,
                backgroundColor: const Color(0xFFEDE7E0),
                valueColor: AlwaysStoppedAnimation(
                  completa ? AppTheme.ocre : AppTheme.usal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
