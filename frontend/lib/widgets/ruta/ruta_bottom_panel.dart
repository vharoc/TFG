import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/poi_sugerido.dart';
import '../../models/ruta_result.dart';
import '../../theme/theme.dart';

class RutaBottomPanel extends StatelessWidget {
  final Parada parada;
  final int paradaActual;
  final int totalParadas;
  final List<PoiSugerido> poisCercanos;
  final bool generando;
  final VoidCallback onCamera;
  final VoidCallback onSiguiente;
  final void Function(PoiSugerido poi) onPoiTap;

  const RutaBottomPanel({
    super.key,
    required this.parada,
    required this.paradaActual,
    required this.totalParadas,
    required this.poisCercanos,
    required this.generando,
    required this.onCamera,
    required this.onSiguiente,
    required this.onPoiTap,
  });

  Future<void> _openGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${parada.lat},${parada.lon}'
      '&travelmode=walking',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, -3)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
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
          const SizedBox(height: 12),

          // Badge parada + nombre
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StopBadge(current: paradaActual + 1, total: totalParadas),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  parada.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),

          if (parada.descripcionCorta.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              parada.descripcionCorta,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black54,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 8),

          // Chips distancia + tiempo
          Row(
            children: [
              _InfoChip(
                icon: Icons.directions_walk_rounded,
                label: '${parada.distanciaM} m',
              ),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.access_time_rounded,
                label: '~${parada.tiempoMin} min',
              ),
            ],
          ),

          // Chips POI
          if (poisCercanos.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: poisCercanos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final poi = poisCercanos[i];
                  return _PoiChip(
                    label: poi.nombre,
                    onTap: () => onPoiTap(poi),
                    disabled: generando,
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Botones
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: generando ? null : onCamera,
                  icon: const Icon(Icons.camera_alt_rounded, size: 18),
                  label: const Text('Foto'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.ocre,
                    disabledBackgroundColor: AppTheme.ocre.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openGoogleMaps,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Navegar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.usal,
                    side: const BorderSide(color: AppTheme.usal),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: generando ? null : onSiguiente,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.usal,
                    disabledBackgroundColor: AppTheme.usal.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Siguiente →'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopBadge extends StatelessWidget {
  final int current;
  final int total;

  const _StopBadge({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.usal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.usal.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$current/$total',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.usal,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _PoiChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  const _PoiChip({
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: disabled
              ? AppTheme.ocre.withValues(alpha: 0.08)
              : AppTheme.ocre.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: disabled
                ? AppTheme.ocre.withValues(alpha: 0.2)
                : AppTheme.ocre.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: disabled ? Colors.black38 : AppTheme.ocre,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
