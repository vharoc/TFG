import 'package:flutter/material.dart';

import '../../constants/ciudades_permitidas.dart';
import '../../theme/theme.dart';

class CiudadSelectorSheet extends StatefulWidget {
  const CiudadSelectorSheet({super.key});

  @override
  State<CiudadSelectorSheet> createState() => _CiudadSelectorSheetState();
}

class _CiudadSelectorSheetState extends State<CiudadSelectorSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _filtradas = ciudadesPermitidas;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtradas = q.isEmpty
          ? ciudadesPermitidas
          : ciudadesPermitidas
              .where((c) => c.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿En qué ciudad estás?',
                    style: AppTheme.titulo.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Necesitamos tu ciudad para ofrecerte información relevante.',
                    style: AppTheme.cuerpo.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Buscar ciudad...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.usal),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _filtradas.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontró ninguna ciudad',
                        style: AppTheme.cuerpo.copyWith(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: _filtradas.length,
                      separatorBuilder: (context, i) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final ciudad = _filtradas[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(ciudad, style: AppTheme.cuerpo),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () => Navigator.of(context).pop(ciudad),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
