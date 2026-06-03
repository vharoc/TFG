import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
        ),
          const SizedBox(height: 20),
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
          if (s.progresoPorCiudad.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Progreso por ciudad',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
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
                      onDelete: () =>
                          _confirmarBorrarCiudad(context, vm, p),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Sheets ────────────────────────────────────────────────────────────────

  void _mostrarChats(BuildContext context, Estadisticas s) {
    _abrirSheet(
      context,
      titulo: 'Conversaciones',
      icono: Icons.chat_bubble_outline_rounded,
      color: const Color(0xFF5B6FA6),
      child: s.chats.isEmpty
          ? const _Vacio(mensaje: 'Aún no tienes conversaciones.')
          : Column(
              children: [
                for (int i = 0; i < s.chats.length; i++) ...[
                  _ChatTile(
                    chat: s.chats[i],
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      context.go('/home?chatId=${s.chats[i].id}');
                    },
                  ),
                  if (i < s.chats.length - 1)
                    const Divider(height: 1, color: Color(0xFFEDE7E0)),
                ],
              ],
            ),
    );
  }

  void _mostrarCiudades(
      BuildContext context, Estadisticas s, EstadisticasViewModel vm) {
    _abrirSheet(
      context,
      titulo: 'Ciudades visitadas',
      icono: Icons.location_city_rounded,
      color: AppTheme.ocre,
      child: s.progresoPorCiudad.isEmpty
          ? const _Vacio(mensaje: 'Aún no has visitado ninguna ciudad.')
          : Column(
              children: [
                for (int i = 0; i < s.progresoPorCiudad.length; i++) ...[
                  _CiudadExpandibleTile(
                    progreso: s.progresoPorCiudad[i],
                    onDelete: () => _confirmarBorrarCiudad(
                        context, vm, s.progresoPorCiudad[i]),
                  ),
                  if (i < s.progresoPorCiudad.length - 1)
                    const Divider(height: 1, color: Color(0xFFEDE7E0)),
                ],
              ],
            ),
    );
  }

  void _mostrarPois(BuildContext context, Estadisticas s) {
    final ciudades = s.progresoPorCiudad;
    final totalPois = ciudades.fold(0, (sum, c) => sum + c.total);
    final totalCapturados =
        ciudades.fold(0, (sum, c) => sum + c.capturados);

    _abrirSheet(
      context,
      titulo: 'Puntos de interés',
      icono: Icons.photo_camera_rounded,
      color: AppTheme.usal,
      subtitulo: '$totalCapturados / $totalPois',
      child: ciudades.isEmpty
          ? const _Vacio(mensaje: 'Aún no has capturado ningún monumento.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < ciudades.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                    child: Text(
                      ciudades[i].nombre,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...ciudades[i].pois.map((poi) => _PoiTile(poi: poi)),
                  if (i < ciudades.length - 1)
                    const Divider(height: 20, color: Color(0xFFEDE7E0)),
                ],
              ],
            ),
    );
  }

  void _abrirSheet(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required Color color,
    String? subtitulo,
    required Widget child,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(
        titulo: titulo,
        icono: icono,
        color: color,
        subtitulo: subtitulo,
        child: child,
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

// ── StatCard ──────────────────────────────────────────────────────────────

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
            // Sin height fija — la tarjeta crece con el contenido.
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0DAD4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icono, size: 24, color: color),
                const SizedBox(height: 8),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  etiqueta,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11.5, color: Colors.black54, height: 1.3),
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 6),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: color.withValues(alpha: 0.4)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── FilaDetalle ───────────────────────────────────────────────────────────

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
          Icon(icono, size: 20, color: Colors.black45),
          const SizedBox(width: 12),
          Expanded(
            child: Text(etiqueta,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(
            valor,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── ProgresoTile (pantalla principal) ─────────────────────────────────────

class _ProgresoTile extends StatelessWidget {
  final ProgresoCiudad progreso;
  final VoidCallback onDelete;

  const _ProgresoTile({required this.progreso, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final pct = (progreso.fraccion * 100).round();
    final completa =
        progreso.total > 0 && progreso.capturados >= progreso.total;
    return Padding(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                style:
                    const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: Colors.black26),
              ),
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
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(icono, size: 20, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (subtitulo != null)
                    Text(
                      subtitulo!,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black45),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEDE7E0)),
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(
                    20, 12, 20, 20 + bottomPadding),
                children: [child],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile ciudad expandible (sheet de ciudades) ────────────────────────────

class _CiudadExpandibleTile extends StatelessWidget {
  final ProgresoCiudad progreso;
  final VoidCallback onDelete;

  const _CiudadExpandibleTile({
    required this.progreso,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progreso.fraccion * 100).round();
    final completa =
        progreso.total > 0 && progreso.capturados >= progreso.total;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding:
          const EdgeInsets.only(left: 4, bottom: 12, top: 4),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progreso.nombre,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${progreso.capturados}/${progreso.total} · $pct%',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          if (completa)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.emoji_events_rounded,
                  size: 16, color: AppTheme.ocre),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: Colors.black26),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 18,
          ),
          const SizedBox(width: 4),
        ],
      ),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progreso.fraccion,
            minHeight: 6,
            backgroundColor: const Color(0xFFEDE7E0),
            valueColor: AlwaysStoppedAnimation(
                completa ? AppTheme.ocre : AppTheme.usal),
          ),
        ),
        const SizedBox(height: 8),
        if (progreso.pois.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin monumentos registrados',
                style: TextStyle(fontSize: 13, color: Colors.black38)),
          )
        else
          ...progreso.pois.map((poi) => _PoiTile(poi: poi)),
      ],
    );
  }
}

// ── Tile chat ─────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback? onTap;

  const _ChatTile({required this.chat, this.onTap});

  @override
  Widget build(BuildContext context) {
    final f = chat.fechaCreacion;
    final hoy = DateTime.now();
    final esHoy = f.year == hoy.year &&
        f.month == hoy.month &&
        f.day == hoy.day;
    final fechaStr = esHoy
        ? '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}'
        : '${f.day}/${f.month}/${f.year}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
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
                  size: 17, color: Color(0xFF5B6FA6)),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fechaStr,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black38),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: Colors.black26),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tile POI ──────────────────────────────────────────────────────────────

class _PoiTile extends StatelessWidget {
  final PoiVisitado poi;

  const _PoiTile({required this.poi});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              poi.visitado
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: poi.visitado ? AppTheme.usal : Colors.black26,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              poi.nombre,
              style: TextStyle(
                fontSize: 13.5,
                color:
                    poi.visitado ? Colors.black87 : Colors.black38,
                fontWeight: poi.visitado
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (poi.visitadoEn != null) ...[
            const SizedBox(width: 8),
            Text(
              '${poi.visitadoEn!.day}/${poi.visitadoEn!.month}',
              style: const TextStyle(
                  fontSize: 11, color: Colors.black38),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Vacío ─────────────────────────────────────────────────────────────────

class _Vacio extends StatelessWidget {
  final String mensaje;

  const _Vacio({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          mensaje,
          style: const TextStyle(fontSize: 14, color: Colors.black45),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
