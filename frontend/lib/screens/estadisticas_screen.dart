import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../models/poi_visitado.dart';
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
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.ocre));
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
          // Cuadrícula 2x2
          Row(
            children: [
              _StatCard(
                icono: Icons.photo_camera_rounded,
                valor: '${s.poisCapturados}',
                etiqueta: 'Monumentos capturados',
                color: AppTheme.usal,
                onTap: () => _mostrarPois(context, s),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icono: Icons.location_city_rounded,
                valor: '${s.ciudadesVisitadas}',
                etiqueta: 'Ciudades visitadas',
                color: AppTheme.ocre,
                onTap: () => _mostrarCiudades(context, s, vm),
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
                onTap: () => _mostrarChats(context, s),
              ),
              const SizedBox(width: 12),
              _StatCard(
                icono: Icons.bolt_rounded,
                valor: '${vm.uso.porcentaje}%',
                etiqueta: 'IA usada hoy',
                color: vm.uso.limiteAlcanzado
                    ? AppTheme.usal
                    : const Color(0xFF4C9A6B),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Detalle
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
                const Divider(height: 1, color: Color(0xFFEDE7E0)),
                _FilaDetalle(
                  icono: Icons.bolt_rounded,
                  etiqueta: 'Tokens de IA usados hoy',
                  valor: '${vm.uso.tokensUsados} / ${vm.uso.limite}',
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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

  // ── Sheets ───────────────────────────────────────────────────────────────

  void _mostrarChats(BuildContext context, Estadisticas s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(
        titulo: 'Conversaciones',
        icono: Icons.chat_bubble_outline_rounded,
        color: const Color(0xFF5B6FA6),
        child: s.chats.isEmpty
            ? const _Vacio(mensaje: 'Aún no tienes conversaciones.')
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: s.chats.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: Color(0xFFEDE7E0)),
                itemBuilder: (_, i) => _ChatTile(chat: s.chats[i]),
              ),
      ),
    );
  }

  void _mostrarCiudades(
      BuildContext context, Estadisticas s, EstadisticasViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(
        titulo: 'Ciudades visitadas',
        icono: Icons.location_city_rounded,
        color: AppTheme.ocre,
        child: s.progresoPorCiudad.isEmpty
            ? const _Vacio(mensaje: 'Aún no has visitado ninguna ciudad.')
            : Column(
                children: [
                  for (final p in s.progresoPorCiudad) ...[
                    _ProgresoTile(
                      progreso: p,
                      onTap: () => _confirmarBorrarCiudad(context, vm, p),
                    ),
                    if (p.pois.isNotEmpty)
                      _PoisCiudadExpanded(pois: p.pois),
                    if (p != s.progresoPorCiudad.last)
                      const Divider(
                          height: 1, color: Color(0xFFEDE7E0)),
                  ],
                ],
              ),
      ),
    );
  }

  void _mostrarPois(BuildContext context, Estadisticas s) {
    final todasCiudades = s.progresoPorCiudad;
    final totalPois =
        todasCiudades.fold(0, (sum, c) => sum + c.total);
    final totalCapturados =
        todasCiudades.fold(0, (sum, c) => sum + c.capturados);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(
        titulo: 'Puntos de interés',
        icono: Icons.photo_camera_rounded,
        color: AppTheme.usal,
        subtitulo: '$totalCapturados / $totalPois capturados',
        child: todasCiudades.isEmpty
            ? const _Vacio(mensaje: 'Aún no has capturado ningún monumento.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final ciudad in todasCiudades) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                      child: Text(
                        ciudad.nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    ...ciudad.pois.map((poi) => _PoiTile(poi: poi)),
                    if (ciudad != todasCiudades.last)
                      const Divider(height: 16, color: Color(0xFFEDE7E0)),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Diálogo borrar ciudad ─────────────────────────────────────────────────

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

// ── Widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 140,
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
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
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54, height: 1.2),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 4),
                  Icon(Icons.expand_more_rounded,
                      size: 14, color: color.withValues(alpha: 0.5)),
                ],
              ],
            ),
          ),
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
              child: Text(etiqueta,
                  style: const TextStyle(fontSize: 15))),
          Text(
            valor,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700),
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
    final completa = progreso.total > 0 &&
        progreso.capturados >= progreso.total;
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
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                if (completa)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.emoji_events_rounded,
                        size: 18, color: AppTheme.ocre),
                  ),
                Text(
                  '${progreso.capturados}/${progreso.total}  ·  $pct%',
                  style: const TextStyle(
                      fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.black26),
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
                    completa ? AppTheme.ocre : AppTheme.usal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet base ────────────────────────────────────────────────────────────

class _Sheet extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final String? subtitulo;
  final Widget child;

  const _Sheet({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.child,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Cabecera
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(icono, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(
                    titulo,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  if (subtitulo != null) ...[
                    const Spacer(),
                    Text(
                      subtitulo!,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black45),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEDE7E0)),
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, 20 + bottomPadding),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tiles de contenido ────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final Chat chat;

  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final fecha = chat.fechaCreacion;
    final hoy = DateTime.now();
    final esHoy = fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
    final fechaStr = esHoy
        ? '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'
        : '${fecha.day}/${fecha.month}/${fecha.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF5B6FA6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 18, color: Color(0xFF5B6FA6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.titulo.isEmpty ? 'Sin título' : chat.titulo,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (chat.ciudad.isNotEmpty)
                  Text(
                    chat.ciudad,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black45),
                  ),
              ],
            ),
          ),
          Text(
            fechaStr,
            style: const TextStyle(fontSize: 12, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

class _PoiTile extends StatelessWidget {
  final PoiVisitado poi;

  const _PoiTile({required this.poi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            poi.visitado
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: poi.visitado ? AppTheme.usal : Colors.black26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              poi.nombre,
              style: TextStyle(
                fontSize: 14,
                color: poi.visitado ? Colors.black87 : Colors.black45,
                fontWeight: poi.visitado
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
          ),
          if (poi.visitadoEn != null)
            Text(
              '${poi.visitadoEn!.day}/${poi.visitadoEn!.month}',
              style:
                  const TextStyle(fontSize: 11, color: Colors.black38),
            ),
        ],
      ),
    );
  }
}

class _PoisCiudadExpanded extends StatelessWidget {
  final List<PoiVisitado> pois;

  const _PoisCiudadExpanded({required this.pois});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Column(
        children: pois.map((poi) => _PoiTile(poi: poi)).toList(),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  final String mensaje;

  const _Vacio({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          mensaje,
          style:
              const TextStyle(fontSize: 14, color: Colors.black45),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
