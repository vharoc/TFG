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
                  for (final p in s.progresoPorCiudad) _ProgresoTile(progreso: p),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0DAD4)),
        ),
        child: Column(
          children: [
            Icon(icono, size: 28, color: color),
            const SizedBox(height: 10),
            Text(
              valor,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
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
