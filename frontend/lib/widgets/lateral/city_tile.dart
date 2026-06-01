import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ciudad_visitada.dart';
import '../../theme/theme.dart';
import '../../viewmodels/lateral_view_model.dart';
import 'pois_ciudad_sheet.dart';

class LateralCityTile extends StatelessWidget {
  final CiudadVisitada ciudad;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LateralCityTile({
    super.key,
    required this.ciudad,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: const Icon(Icons.location_city_outlined, size: 18, color: AppTheme.usal),
        title: Text(ciudad.nombre, style: AppTheme.cuerpo.copyWith(fontSize: 14)),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline,
            size: 18,
            color: Colors.black38,
          ),
          onPressed: onDelete,
        ),
        onTap: () => _mostrarPois(context),
      ),
    );
  }

  void _mostrarPois(BuildContext context) {
    final vm = context.read<LateralViewModel>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: PoisCiudadSheet(ciudad: ciudad.nombre),
      ),
    );
  }
}
