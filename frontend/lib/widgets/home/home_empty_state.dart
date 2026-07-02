import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class HomeEmptyState extends StatelessWidget {
  final String? ciudad;

  const HomeEmptyState({super.key, this.ciudad});

  // Franjas del saludo según la convención horaria española.
  String get _saludo {
    final int hora = DateTime.now().hour;
    if (hora >= 6 && hora < 14) return 'Buenos días';
    if (hora >= 14 && hora < 21) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _subtitulo => ciudad != null
      ? '¿Qué te apetece descubrir hoy en $ciudad?'
      : '¿Qué te apetece descubrir hoy?';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 48, height: 48),
            const SizedBox(height: 16),
            Text(
              _saludo,
              style: AppTheme.titulo.copyWith(fontSize: 24, color: AppTheme.usal),
            ),
            const SizedBox(height: 8),
            Text(
              _subtitulo,
              textAlign: TextAlign.center,
              style: AppTheme.cuerpo.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
