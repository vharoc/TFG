import 'package:flutter/material.dart';

import '../../models/ciudad.dart';
import '../../theme/theme.dart';
import 'city_tile.dart';
import 'empty_card.dart';
import 'section_header.dart';
import 'see_all_button.dart';

class LateralCitiesPanel extends StatelessWidget {
  final bool expanded;
  final bool loading;
  final List<Ciudad> ciudades;
  final double spacing;
  final int maxItems;
  final ScrollController scrollController;
  final ValueChanged<Ciudad> onCiudadTap;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  const LateralCitiesPanel({
    super.key,
    required this.expanded,
    required this.loading,
    required this.ciudades,
    required this.spacing,
    required this.maxItems,
    required this.scrollController,
    required this.onCiudadTap,
    required this.onExpand,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    if (expanded) {
      return Column(
        children: [
          const SectionHeader(header: 'Ciudades visitadas'),
          SizedBox(height: spacing),
          Expanded(child: _buildExpandedContent()),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onCollapse,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Ocultar ciudades',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.usal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const SectionHeader(header: 'Ciudades visitadas'),
        SizedBox(height: spacing),
        Flexible(child: _buildCollapsedContent()),
      ],
    );
  }

  Widget _buildExpandedContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (ciudades.isEmpty) {
      return const LateralEmptyCard(
        mensaje: 'Aún no has visitado ninguna ciudad',
      );
    }

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        itemCount: ciudades.length,
        itemBuilder: (_, i) {
          final ciudad = ciudades[i];
          return LateralCityTile(
            ciudad: ciudad,
            onTap: () => onCiudadTap(ciudad),
          );
        },
      ),
    );
  }

  Widget _buildCollapsedContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ciudades.isEmpty)
          const LateralEmptyCard(mensaje: 'Aún no has visitado ninguna ciudad')
        else
          ...ciudades
              .take(maxItems)
              .map(
                (ciudad) => LateralCityTile(
                  ciudad: ciudad,
                  onTap: () => onCiudadTap(ciudad),
                ),
              ),
        LateralSeeAllButton(onTap: onExpand),
      ],
    );
  }
}
